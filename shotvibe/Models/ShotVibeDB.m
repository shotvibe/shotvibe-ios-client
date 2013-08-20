//
//  ShotVibeDB.m
//  shotvibe
//
//  Created by benny on 8/19/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "ShotVibeDB.h"
#import "AlbumSummary.h"

@implementation ShotVibeDB

static NSString * const DATABASE_FILE = @"shotvibe.db";

- (id)init
{
    self = [super init];

    NSString *databaseDirectory = [ShotVibeDB getApplicationSupportDirectory];
    NSString *databasePath = [databaseDirectory stringByAppendingPathComponent:DATABASE_FILE];

    BOOL databaseExists = [[NSFileManager defaultManager] fileExistsAtPath:databasePath];

    db = [FMDatabase databaseWithPath:databasePath];
    if (![db open]) {
        NSAssert(false, @"Error Opening database: %@", [db lastErrorMessage]);
    }

    [ShotVibeDB addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:databasePath isDirectory:NO]];

    if (!databaseExists) {
        [self createNewEmptyDatabase];
    }

    return self;
}

+ (NSString *)getApplicationSupportDirectory
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    if (![manager fileExistsAtPath:appSupportDir]) {
        NSError *error;
        if (![manager createDirectoryAtPath:appSupportDir withIntermediateDirectories:NO attributes:nil error:&error]) {
            NSAssert(false, @"Error creating ApplicationSupportDirectory: %@", [error localizedDescription]);
        }
    }

    return appSupportDir;
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

// See: <http://developer.apple.com/library/ios/qa/qa1719/_index.html>
+ (void)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    assert([[NSFileManager defaultManager] fileExistsAtPath:[URL path]]);

    NSError *error = nil;
    if(![URL setResourceValue: [NSNumber numberWithBool:YES]
                       forKey: NSURLIsExcludedFromBackupKey
                        error: &error]) {
        NSAssert(false, @"Error excluding %@ from backup %@", [URL lastPathComponent], error);
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

        // TODO Load the latest photos from the database
        NSArray *latestPhotos = [[NSArray alloc] init];

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
    FMResultSet* s = [db executeQuery:@"SELECT (album_id) FROM album"];
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

@end
