//
//  ShotVibeDB.m
//  shotvibe
//
//  Created by benny on 8/19/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "ShotVibeDB.h"
#import "FileUtils.h"
#import "SL/AlbumSummary.h"
#import "SL/AlbumPhoto.h"
#import "SL/AlbumServerPhoto.h"
#import "SL/AlbumUser.h"
#import "SL/AlbumContents.h"
#import "SL/AlbumMember.h"
#import "SL/ArrayList.h"
#import "SL/DateTime.h"

#import "IosSQLConnection.h"

#import "SL/ShotVibeDB.h"
#import "SL/SQLException.h"

@implementation ShotVibeDB
{
    // Used to store the SQLite error string, before running a "rollback", since the rollback command will overwrite the SQLite error state.
    NSString *prevSQLiteError_;

    SLShotVibeDB *mDBActions_;
}


static NSString * const DATABASE_FILE = @"shotvibe.db";


- (id)init
{
    self = [super init];

    prevSQLiteError_ = nil;

    NSString *databaseDirectory = [FileUtils getApplicationSupportDirectory];
    NSString *databasePath = [databaseDirectory stringByAppendingPathComponent:DATABASE_FILE];

    BOOL databaseExists = [[NSFileManager defaultManager] fileExistsAtPath:databasePath];

    db = [FMDatabase databaseWithPath:databasePath];
    if (![db open]) {
        NSAssert(false, @"Error Opening database: %@", [db lastErrorMessage]);
    }

    IosSQLConnection *conn = [[IosSQLConnection alloc] initWithDatabase:db];

    [FileUtils addSkipBackupAttributeToItemAtURL:databasePath];

    if (databaseExists) {
        FMResultSet *resultSet = [db executeQuery:@"PRAGMA user_version"];
        int oldVersion = 0;
        if ([resultSet next]) {
            oldVersion = [resultSet intForColumnIndex:0];
        }

        if (oldVersion < [SLShotVibeDB DATABASE_VERSION]) {
            NSLog(@"Upgrading database from version %d to %d", oldVersion, [SLShotVibeDB DATABASE_VERSION]);
            [conn beginTransaction];
            @try {
                [SLShotVibeDB upgradeDBWithSLSQLConnection:conn withInt:oldVersion];
                [self writeDatabaseVersion:[SLShotVibeDB DATABASE_VERSION]];

                [conn setTransactionSuccesful];
            } @finally {
                [conn endTransaction];
            }
        } else if (oldVersion > [SLShotVibeDB DATABASE_VERSION]) {
            // An old verson of the app must have been installed over a newer database version.
            //
            // We don't support reverse migrations
            @throw [[SLSQLException alloc] initWithNSString:[NSString stringWithFormat:
                                                             @"Incompatible database version: %d. Required: %d", oldVersion, [SLShotVibeDB DATABASE_VERSION]]];
        }
    }
    else {
        NSLog(@"Creating new database version %d", [SLShotVibeDB DATABASE_VERSION]);
        [conn beginTransaction];
        @try {
            [SLShotVibeDB populateNewDBWithSLSQLConnection:conn];
            [self writeDatabaseVersion:[SLShotVibeDB DATABASE_VERSION]];

            [conn setTransactionSuccesful];
        } @finally {
            [conn endTransaction];
        }
    }

    mDBActions_ = [SLShotVibeDB openWithSLSQLConnection:conn];

    return self;
}


- (void)writeDatabaseVersion:(int)version
{
    char *errmsg = 0;
    if (sqlite3_exec([db sqliteHandle],
                     [[NSString stringWithFormat:@"PRAGMA user_version = %d", version] UTF8String],
                     NULL,
                     acl_get_qualifier,
                     &errmsg) != SQLITE_OK) {
        NSString *errString = [[NSString alloc] initWithCString:errmsg encoding:NSUTF8StringEncoding];
        sqlite3_free(errmsg);
        @throw [[SLSQLException alloc] initWithNSString:[NSString stringWithFormat:@"Error setting DB version: %@", errString]];
    }
    sqlite3_free(errmsg);
}


- (NSString *)lastErrorMessage
{
    // The string that SQLite returns when there is no error
    NSString *notErrorString = @"not an error";

    NSString *sqliteLastError = [db lastErrorMessage];

    if (!prevSQLiteError_ || [prevSQLiteError_ isEqualToString:notErrorString]) {
        // No previous error before DB "rollback"
        return sqliteLastError;
    }

    if ([sqliteLastError isEqualToString:notErrorString]) {
        // Only error was previous error before DB "rollback"
        return prevSQLiteError_;
    }

    // Previous error before DB "rollback" as well as error during "rollback"
    return [NSString stringWithFormat:@"Original Error: \"%@\" Rollback Error: \"%@\"", prevSQLiteError_, sqliteLastError];
}


#pragma mark Data Store methods


#define ABORT_TRANSACTION                     \
    prevSQLiteError_ = [db lastErrorMessage]; \
    [db rollback];                            \
    return NO;


static SLDateTime * getDateForColumnIndex(FMResultSet *s, int index)
{
    long long timestamp = [s longLongIntForColumnIndex:index];
    return [SLDateTime FromTimeStampWithLong:timestamp];
}


- (SLArrayList *)getAlbumList
{
    return [mDBActions_ getAlbumList];
}


- (NSDictionary *)getAlbumListEtagValues
{
    FMResultSet* s = [db executeQuery:@"SELECT album_id, last_etag FROM album"];
    if (!s) {
        return nil;
    }

    NSMutableDictionary *results = [[NSMutableDictionary alloc] init];

    while ([s next]) {
        int64_t albumId = [s longLongIntForColumnIndex:0];
        NSString *etag = [s stringForColumnIndex:1];

        // etag may be NULL if the full album hasn't been loaded yet
        if (etag) {
            [results setObject:etag forKey:[[NSNumber alloc] initWithLongLong:albumId]];
        }
    }

    return results;
}

- (void)setAlbumListWithAlbums:(NSMutableArray *)albums
{
    [mDBActions_ setAlbumListWithSLArrayList:[[SLArrayList alloc] initWithInitialArray:albums]];
}


- (SLAlbumContents *)getAlbumContents:(int64_t)albumId
{
    FMResultSet *s = [db executeQuery:@"SELECT name, last_updated, num_new_photos, last_access FROM album WHERE album_id=?", [NSNumber numberWithLongLong:albumId]];
    if (!s) {
        return nil;
    }

    if (![s next]) {
        // No cached AlbumContents available, this is an error
        return nil;
    }

    NSString *albumName = [s stringForColumnIndex:0];
    SLDateTime *albumLastUpdated = getDateForColumnIndex(s, 1);
    int64_t albumNumNewPhotos = [s longLongIntForColumnIndex:2];
    SLDateTime *albumLastAccess = getDateForColumnIndex(s, 3);
    NSString *etag = nil;

    s = [db executeQuery:@
         "SELECT photo.photo_id, photo.url, photo.created, user.user_id, user.nickname, user.avatar_url FROM photo"
         " LEFT OUTER JOIN user"
         " ON photo.author_id = user.user_id"
         " WHERE photo.photo_album=?"
         " ORDER BY photo.num ASC",
         [NSNumber numberWithLongLong:albumId]];

    NSMutableArray *albumPhotos = [[NSMutableArray alloc] init];
    while ([s next]) {
        NSString *photoId = [s stringForColumnIndex:0];
        NSString *photoUrl = [s stringForColumnIndex:1];
        SLDateTime *photoDateAdded = getDateForColumnIndex(s, 2);
        int64_t photoAuthorUserId = [s longLongIntForColumnIndex:3];
        NSString *photoAuthorNickname = [s stringForColumnIndex:4];
        NSString *photoAuthorAvatarUrl = [s stringForColumnIndex:5];

        SLAlbumUser *photoAuthor = [[SLAlbumUser alloc] initWithLong:photoAuthorUserId
                                                        withNSString:photoAuthorNickname
                                                        withNSString:photoAuthorAvatarUrl];

        SLAlbumServerPhoto *albumServerPhoto = [[SLAlbumServerPhoto alloc] initWithNSString:photoId
                                                                               withNSString:photoUrl
                                                                            withSLAlbumUser:photoAuthor
                                                                             withSLDateTime:photoDateAdded];

        SLAlbumPhoto *albumPhoto = [[SLAlbumPhoto alloc] initWithSLAlbumServerPhoto:albumServerPhoto];
        [albumPhotos addObject:albumPhoto];
    }

    s = [db executeQuery:@
         "SELECT album_member.user_id, user.nickname, user.avatar_url FROM album_member"
         " LEFT OUTER JOIN user"
         " ON album_member.user_id = user.user_id"
         " WHERE album_member.album_id=?"
         " ORDER BY user.nickname ASC",
         [NSNumber numberWithLongLong:albumId]];

    NSMutableArray *albumMembers = [[NSMutableArray alloc] init];
    while ([s next]) {
        int64_t memberId = [s longLongIntForColumnIndex:0];
        NSString *memberNickname = [s stringForColumnIndex:1];
        NSString *memberAvatarUrl = [s stringForColumnIndex:2];
        SLAlbumUser *user = [[SLAlbumUser alloc] initWithLong:memberId
                                                 withNSString:memberNickname
                                                 withNSString:memberAvatarUrl];
        SLAlbumMember *albumMember = [[SLAlbumMember alloc] initWithSLAlbumUser:user
                                             withSLAlbumMember_InviteStatusEnum:nil];
        [albumMembers addObject:albumMember];
    }

    // TODO:
    SLDateTime *dummyDateCreated = [SLDateTime ParseISO8601WithNSString:@"2000-01-01T00:00:00Z"];

    SLAlbumContents *albumContents = [[SLAlbumContents alloc] initWithLong:albumId
                                                              withNSString:etag
                                                              withNSString:albumName
                                                            withSLDateTime:dummyDateCreated
                                                            withSLDateTime:albumLastUpdated
                                                                  withLong:albumNumNewPhotos
                                                            withSLDateTime:albumLastAccess
                                                           withSLArrayList:[[SLArrayList alloc] initWithInitialArray:albumPhotos]
                                                           withSLArrayList:[[SLArrayList alloc] initWithInitialArray:albumMembers]];

    return albumContents;
}


- (BOOL)setAlbumContents:(int64_t)albumId withContents:(SLAlbumContents *)albumContents
{
    if (![db beginTransaction]) {
        return NO;
    }
    RCLog(@"setAlbumContents: name:%@ last_updated:%@ num_new_photos:%lld last_access:%@ last_etag:%@", [albumContents getName], [albumContents getDateUpdated], [albumContents getNumNewPhotos], [albumContents getLastAccess], [albumContents getEtag]);

    if (![db executeUpdate:@"INSERT OR REPLACE INTO album (album_id, name, last_updated, num_new_photos, last_access, last_etag) VALUES (?, ?, ?, ?, ?, ?)",
          [NSNumber numberWithLongLong:[albumContents getId]],
          [albumContents getName],
          [albumContents getDateUpdated],
          [NSNumber numberWithLongLong:[albumContents getNumNewPhotos]],
          [albumContents getLastAccess],
          [albumContents getEtag]]) {
        ABORT_TRANSACTION;
    }

    // Will be filled with all the users from:
    //  - The authors of all the photos
    //  - The album member list
    // And then will be written to the DB
    NSMutableDictionary *allUsers = [[NSMutableDictionary alloc] init];

    // Keep track of all the new photoIds in an efficient data structure
    NSMutableSet *photoIds = [[NSMutableSet alloc] init];

    int num = 0;
    for (SLAlbumPhoto *albumPhoto in [albumContents getPhotos].array) {
        SLAlbumServerPhoto *photo = [albumPhoto getServerPhoto];
        NSAssert(photo, @"albumContents must contain only photos of type AlbumServerPhoto");

        [photoIds addObject:[photo getId]];

        if (![db executeUpdate:@"INSERT OR REPLACE INTO photo (photo_album, num, photo_id, url, author_id, created) VALUES (?, ?, ?, ?, ?, ?)",
              [NSNumber numberWithLongLong:albumId],
              [NSNumber numberWithInt:num++],
              [photo getId],
              [photo getUrl],
              [NSNumber numberWithLongLong:[[photo getAuthor] getMemberId]],
              [photo getDateAdded]]) {
            ABORT_TRANSACTION;
        }

        SLAlbumUser *user = [photo getAuthor];
        [allUsers setObject:user forKey:[[NSNumber alloc] initWithLongLong:[user getMemberId]]];
    }

    // Delete any old rows in the database that are not in photoIds:
    FMResultSet* s = [db executeQuery:@"SELECT photo_id FROM photo WHERE photo_album=?", [NSNumber numberWithLongLong:albumId]];
    if (!s) {
        ABORT_TRANSACTION;
    }

    while ([s next]) {
        NSString *pid = [s stringForColumnIndex:0];
        if (![photoIds containsObject:pid]) {
            if (![db executeUpdate:@"DELETE FROM photo WHERE photo_album=? AND photo_id=?", [NSNumber numberWithLongLong:albumId], pid]) {
                ABORT_TRANSACTION;
            }
        }
    }

    // Keep track of all the new memberIds in an efficient data structure

    NSMutableSet *memberIds = [[NSMutableSet alloc] init];

    for (SLAlbumMember *member in [albumContents getMembers].array) {
        SLAlbumUser *user = [member getUser];

        [memberIds addObject:[NSNumber numberWithLongLong:[user getMemberId]]];

        if(![db executeUpdate:@"INSERT OR REPLACE INTO album_member (album_id, user_id) VALUES (?, ?)",
             [NSNumber numberWithLongLong:albumId],
             [NSNumber numberWithLongLong:[user getMemberId]]]) {
            ABORT_TRANSACTION;
        }

        [allUsers setObject:user forKey:[[NSNumber alloc] initWithLongLong:[user getMemberId]]];
    }

    // Delete any old rows in the database that are not in memberIds:
    s = [db executeQuery:@"SELECT user_id FROM album_member WHERE album_member.album_id=?", [NSNumber numberWithLongLong:albumId]];
    if (!s) {
        ABORT_TRANSACTION;
    }

    while ([s next]) {
        int64_t mid = [s longLongIntForColumnIndex:0];
        if (![memberIds containsObject:[NSNumber numberWithLongLong:mid]]) {
            if (![db executeUpdate:@"DELETE FROM album_member WHERE album_member.album_id=? AND user_id=?", [NSNumber numberWithLongLong:albumId], [NSNumber numberWithLongLong:mid]]) {
                ABORT_TRANSACTION;
            }
        }
    }

    for (id key in allUsers) {
        SLAlbumUser *user = [allUsers objectForKey:key];

        if(![db executeUpdate:@"INSERT OR REPLACE INTO user (user_id, nickname, avatar_url) VALUES (?, ?, ?)",
             [NSNumber numberWithLongLong:[user getMemberId]],
             [user getMemberNickname],
             [user getMemberAvatarUrl]]) {
            ABORT_TRANSACTION;
        }
    }

    if (![db commit]) {
        ABORT_TRANSACTION;
    }

    return YES;
}

- (BOOL)markAlbumAsViewed:(int64_t)albumId lastAccess:(SLDateTime *)lastAccess
{
    if (![db beginTransaction]) {
        return NO;
    }

    if(![db executeUpdate:@"UPDATE album SET last_access=?, num_new_photos=0 WHERE album_id=?",
         lastAccess,
         [NSNumber numberWithLongLong:albumId]]) {
    }
    
    if (![db commit]) {
        ABORT_TRANSACTION;
    }
    return YES;
}

@end
