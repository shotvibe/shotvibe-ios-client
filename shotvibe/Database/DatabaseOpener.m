//
//  DatabaseOpener.m
//  shotvibe
//
//  Created by raptor on 9/18/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <SL/SQLException.h>

#import "FMDatabase.h"

#import "FileUtils.h"

#import "IosSQLConnection.h"
#import "DatabaseOpener.h"

@implementation DatabaseOpener

+ (id)open:(SLSQLDatabaseRecipe *)recipe
{
    NSString *databaseDirectory = [FileUtils getApplicationSupportDirectory];
    NSString *databasePath = [databaseDirectory stringByAppendingPathComponent:[recipe getDatabaseFilename]];

    BOOL databaseExists = [[NSFileManager defaultManager] fileExistsAtPath:databasePath];

    FMDatabase *db = [FMDatabase databaseWithPath:databasePath];
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
        [resultSet close];

        if (oldVersion < [recipe getDatabaseVersion]) {
            RCLog(@"Upgrading database from version %d to %d", oldVersion, [recipe getDatabaseVersion]);
            [conn beginTransaction];
            @try {
                [recipe upgradeDBWithSLSQLConnection:conn withInt:oldVersion];
                [self writeDatabaseVersion:db version:[recipe getDatabaseVersion]];

                [conn setTransactionSuccesful];
            } @finally {
                [conn endTransaction];
            }
        } else if (oldVersion > [recipe getDatabaseVersion]) {
            // An old verson of the app must have been installed over a newer database version.
            //
            // We don't support reverse migrations
            @throw [[SLSQLException alloc] initWithNSString:[NSString stringWithFormat:
                                                             @"Incompatible database version: %d. Required: %d", oldVersion, [recipe getDatabaseVersion]]];
        }
    } else {
        NSLog(@"Creating new database version %d", [recipe getDatabaseVersion]);
        [conn beginTransaction];
        @try {
            [recipe populateNewDBWithSLSQLConnection:conn];
            [self writeDatabaseVersion:db version:[recipe getDatabaseVersion]];

            [conn setTransactionSuccesful];
        } @finally {
            [conn endTransaction];
        }
    }

    return [recipe openDBWithSLSQLConnection:conn];
}


+ (void)writeDatabaseVersion:(FMDatabase *)db version:(int)version
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


@end
