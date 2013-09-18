//
//  ShotVibeDB.m
//  shotvibe
//
//  Created by benny on 8/19/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "ShotVibeDB.h"
#import "FileUtils.h"
#import "AlbumSummary.h"
#import "AlbumPhoto.h"
#import "AlbumServerPhoto.h"
#import "AlbumMember.h"
#import "AlbumContents.h"

@implementation ShotVibeDB

static NSString * const DATABASE_FILE = @"shotvibe.db";

- (id)init
{
    self = [super init];

    NSString *databaseDirectory = [FileUtils getApplicationSupportDirectory];
    NSString *databasePath = [databaseDirectory stringByAppendingPathComponent:DATABASE_FILE];

    BOOL databaseExists = [[NSFileManager defaultManager] fileExistsAtPath:databasePath];

    db = [FMDatabase databaseWithPath:databasePath];
    if (![db open]) {
        NSAssert(false, @"Error Opening database: %@", [db lastErrorMessage]);
    }

    [FileUtils addSkipBackupAttributeToItemAtURL:databasePath];

    if (!databaseExists) {
        [self createNewEmptyDatabase];
    }

    return self;
}

- (void)createNewEmptyDatabase
{
    NSString *scriptFilePath = [[NSBundle mainBundle] pathForResource:@"create" ofType:@"sql" inDirectory:@""];
    NSLog(@"%@", scriptFilePath);

    NSError *error;
    NSString *contents = [NSString stringWithContentsOfFile:scriptFilePath encoding:NSUTF8StringEncoding error:&error];
    if (!contents) {
        NSAssert(false, @"Error reading file %@: %@", scriptFilePath, [error localizedDescription]);
    }

    if(![db beginTransaction]) {
        NSAssert(false, @"Error beginning transaction: %@", [db lastErrorMessage]);
    }

    char *errmsg = 0;
    if (sqlite3_exec([db sqliteHandle], [contents UTF8String], 0, 0, &errmsg) != SQLITE_OK) {
        NSAssert(false, @"Error creating database: %s", errmsg);
    }
    sqlite3_free(errmsg);

    if(![db commit]) {
        NSAssert(false, @"Error committing transaction: %@", [db lastErrorMessage]);
    }
}

- (NSString *)lastErrorMessage
{
    return [db lastErrorMessage];
}

#pragma mark Data Store methods

#define ABORT_TRANSACTION [db rollback]; return NO;

- (NSArray *)getAlbumList
{
    FMResultSet* s = [db executeQuery:@"SELECT album_id, name, last_updated FROM album ORDER BY last_updated ASC"];
    if (!s) {
        return nil;
    }

    NSMutableArray *results = [[NSMutableArray alloc] init];
    while ([s next]) {
        int64_t albumId = [s longLongIntForColumnIndex:0];
        NSString *name = [s stringForColumnIndex:1];

        // TODO:
        NSDate *dateCreated = nil;

        NSDate *lastUpdated = [s dateForColumnIndex:2];

        // TODO hm...
        NSString *etag = nil;

        const int NUM_LATEST_PHOTOS = 2;
        NSArray *latestPhotos = [self getLatestPhotos:albumId numPhotos:NUM_LATEST_PHOTOS];
        if (!latestPhotos) {
            return nil;
        }

        AlbumSummary *albumSummary = [[AlbumSummary alloc] initWithAlbumId:albumId
                                                                      etag:etag
                                                                      name:name
                                                               dateCreated:dateCreated
                                                               dateUpdated:lastUpdated
                                                              latestPhotos:latestPhotos];
        [results addObject:albumSummary];
    }

    return results;
}

// Returns a list of `AlbumPhoto` objects
- (NSArray *)getLatestPhotos:(int64_t)albumId numPhotos:(int)numPhotos
{
    FMResultSet* s = [db executeQuery:@
                      "SELECT photo_id, url, author_id, created"
                      " FROM photo"
                      " WHERE photo_album=?"
                      " ORDER BY num DESC",
                      [NSNumber numberWithLongLong:albumId]];
    if (!s) {
        return nil;
    }

    NSMutableArray *results = [[NSMutableArray alloc] init];
    while ([s next]) {
        NSString *photoId = [s stringForColumnIndex:0];
        NSString *photoUrl = [s stringForColumnIndex:1];
        int64_t photoAuthorUserId = [s longLongIntForColumnIndex:2];
        NSString *photoAuthorNickname = @"TODO"; // TODO
        NSDate *photoDateAdded = [s dateForColumnIndex:3];

        AlbumServerPhoto *albumServerPhoto = [[AlbumServerPhoto alloc] initWithPhotoId:photoId
                                                                                  url:photoUrl
                                                                         authorUserId:photoAuthorUserId
                                                                       authorNickname:photoAuthorNickname
                                                                            dateAdded:photoDateAdded];
        AlbumPhoto *photo = [[AlbumPhoto alloc] initWithAlbumServerPhoto:albumServerPhoto];
        [results addObject:photo];
    }

    return results;
}

- (BOOL)setAlbumListWithAlbums:(NSArray *)albums
{
    if (![db beginTransaction]) {
        return NO;
    }

    // Keep track of all the new albumIds in an efficient data structure
    NSMutableSet *albumIds = [[NSMutableSet alloc] init];

    for(AlbumSummary *album in albums) {
        [albumIds addObject:[NSNumber numberWithLongLong:album.albumId]];

        // First try updating an existing row, in order to not erase an existing etag value
        if(![db executeUpdate:@"UPDATE album SET album_id=?, name=?, last_updated=? WHERE album_id=?",
             [NSNumber numberWithLongLong:album.albumId],
             album.name,
             album.dateUpdated,
             [NSNumber numberWithLongLong:album.albumId]]) {
            ABORT_TRANSACTION;
        }

        if ([db changes] == 0) {
            // A row didn't exist for the album, this will insert a new row
            // (while also not failing in the case of a rare race condition
            // where a row actually was just now added -- if that actually
            // does happen then we will unfortunately overwrite the etag
            // with a null value, but that won't cause much harm, it will
            // just cause the album to be unnecessary refreshed one more time)
            if(![db executeUpdate:@"INSERT OR REPLACE INTO album (album_id, name, last_updated) VALUES (?, ?, ?)",
                 [NSNumber numberWithLongLong:album.albumId],
                 album.name,
                 album.dateUpdated]) {
                ABORT_TRANSACTION;
            }
        }
    }

    // Delete any old rows in the database that are not in albums:
    FMResultSet* s = [db executeQuery:@"SELECT album_id FROM album"];
    if (!s) {
        ABORT_TRANSACTION;
    }

    while ([s next]) {
        int64_t albumId = [s longLongIntForColumnIndex:0];
        if (![albumIds containsObject:[NSNumber numberWithLongLong:albumId]]) {
            if (![db executeUpdate:@"DELETE FROM album WHERE album_id=?", [NSNumber numberWithLongLong:albumId]]) {
                ABORT_TRANSACTION;
            }
        }
    }

    if (![db commit]) {
        ABORT_TRANSACTION;
    }

    return YES;
}


- (AlbumContents *)getAlbumContents:(int64_t)albumId
{
    FMResultSet* s = [db executeQuery:@"SELECT name, last_updated FROM album WHERE album_id=?", [NSNumber numberWithLongLong:albumId]];
    if (!s) {
        return nil;
    }

    if (![s next]) {
        // No cached AlbumContents available, this is an error
        return nil;
    }

    NSString *albumName = [s stringForColumnIndex:0];
    NSDate *albumLastUpdated = [s dateForColumnIndex:1];
    NSString *etag = nil;

    s = [db executeQuery:@"SELECT photo_id, url, author_id, created FROM photo WHERE photo_album=?", [NSNumber numberWithLongLong:albumId]];

    NSMutableArray *albumPhotos = [[NSMutableArray alloc] init];
    while ([s next]) {
        NSString *photoId = [s stringForColumnIndex:0];
        NSString *photoUrl = [s stringForColumnIndex:1];
        int64_t photoAuthorUserId = [s longLongIntForColumnIndex:2];
        NSString *photoAuthorNickname = @"noname"; // TODO
        NSDate *photoDateAdded = [s dateForColumnIndex:3];

        AlbumServerPhoto *albumServerPhoto = [[AlbumServerPhoto alloc] initWithPhotoId:photoId
                                                                                   url:photoUrl
                                                                          authorUserId:photoAuthorUserId
                                                                        authorNickname:photoAuthorNickname
                                                                             dateAdded:photoDateAdded];
        AlbumPhoto *albumPhoto = [[AlbumPhoto alloc] initWithAlbumServerPhoto:albumServerPhoto];
        [albumPhotos addObject:albumPhoto];
    }

    s = [db executeQuery:@
         "SELECT album_member.user_id, user.nickname FROM album_member"
         " LEFT OUTER JOIN user"
         " ON album_member.user_id = user.user_id"
         " WHERE album_member.album_id=?"
         " ORDER BY user.nickname ASC",
         [NSNumber numberWithLongLong:albumId]];

    NSMutableArray *albumMembers = [[NSMutableArray alloc] init];
    while ([s next]) {
        int64_t memberId = [s longLongIntForColumnIndex:0];
        NSString *memberNickname = [s stringForColumnIndex:1];
        NSString *memberAvatarUrl = nil; // TODO
        AlbumMember *albumMember = [[AlbumMember alloc] initWithMemberId:memberId
                                                                nickname:memberNickname
                                                               avatarUrl:memberAvatarUrl
															inviteStatus:nil];
        [albumMembers addObject:albumMember];
    }


    AlbumContents *albumContents = [[AlbumContents alloc] initWithAlbumId:albumId
                                                                     etag:etag
                                                                     name:albumName
                                                              dateCreated:[[NSDate alloc] init]
                                                              dateUpdated:albumLastUpdated
                                                                   photos:albumPhotos
                                                                  members:albumMembers];

    return albumContents;
}

- (BOOL)setAlbumContents:(int64_t)albumId withContents:(AlbumContents *)albumContents
{
    if (![db beginTransaction]) {
        return NO;
    }

    if(![db executeUpdate:@"INSERT OR REPLACE INTO album (album_id, name, last_updated, last_etag) VALUES (?, ?, ?, ?)",
         [NSNumber numberWithLongLong:albumContents.albumId],
         albumContents.name,
         albumContents.dateUpdated,
         albumContents.etag]) {
        ABORT_TRANSACTION;
    }

    // Keep track of all the new photoIds in an efficient data structure
    NSMutableSet *photoIds = [[NSMutableSet alloc] init];

    int num = 0;
    for (AlbumPhoto *albumPhoto in albumContents.photos) {
        AlbumServerPhoto *photo = albumPhoto.serverPhoto;
        NSAssert(photo, @"albumContents must contain only photos of type AlbumServerPhoto");

        [photoIds addObject:photo.photoId];

        if(![db executeUpdate:@"INSERT OR REPLACE INTO photo (photo_album, num, photo_id, url, author_id, created) VALUES (?, ?, ?, ?, ?, ?)",
             [NSNumber numberWithLongLong:albumId],
             [NSNumber numberWithInt:num++],
             photo.photoId,
             photo.url,
             [NSNumber numberWithLongLong:photo.authorUserId],
             photo.dateAdded]) {
            ABORT_TRANSACTION;
        }
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

    for (AlbumMember *member in albumContents.members) {
        [memberIds addObject:[NSNumber numberWithLongLong:member.memberId]];

        if(![db executeUpdate:@"INSERT OR REPLACE INTO album_member (album_id, user_id) VALUES (?, ?)",
             [NSNumber numberWithLongLong:albumId],
             [NSNumber numberWithLongLong:member.memberId]]) {
            ABORT_TRANSACTION;
        }

        // TODO Also update field member.avatarUrl
        if(![db executeUpdate:@"INSERT OR REPLACE INTO user (user_id, nickname) VALUES (?, ?)",
             [NSNumber numberWithLongLong:member.memberId],
             member.nickname]) {
            ABORT_TRANSACTION;
        }
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

    if (![db commit]) {
        ABORT_TRANSACTION;
    }

    return YES;
}

@end
