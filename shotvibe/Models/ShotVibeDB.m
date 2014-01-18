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


- (SLHashMap *)getAlbumListEtagValues
{
    return [mDBActions_ getAlbumListEtagValues];
}

- (void)setAlbumListWithAlbums:(NSMutableArray *)albums
{
    [mDBActions_ setAlbumListWithSLArrayList:[[SLArrayList alloc] initWithInitialArray:albums]];
}


- (SLAlbumContents *)getAlbumContents:(int64_t)albumId
{
    return [mDBActions_ getAlbumContentsWithLong:albumId];
}


- (void)setAlbumContents:(int64_t)albumId withContents:(SLAlbumContents *)albumContents
{
    [mDBActions_ setAlbumContentsWithLong:albumId withSLAlbumContents:albumContents];
}


- (void)markAlbumAsViewed:(int64_t)albumId lastAccess:(SLDateTime *)lastAccess
{
    [mDBActions_ setAlbumLastAccessWithLong:albumId withSLDateTime:lastAccess];
}

@end
