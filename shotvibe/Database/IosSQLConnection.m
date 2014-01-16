//
//  IosSQLConnection.m
//  shotvibe
//
//  Created by benny on 1/15/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "IosSQLConnection.h"

#import "java/lang/IllegalStateException.h"
#import "SL/SQLValues.h"
#import "SL/SQLException.h"

#import "IosSQLCursor.h"

#import "FMDatabase.h"

@implementation IosSQLConnection
{
    FMDatabase *db_;
    BOOL transactionSuccesful_;
}


- (id)initWithDatabase:(FMDatabase *)db
{
    self = [super init];

    if (self) {
        db_ = db;
        transactionSuccesful_ = NO;
    }

    return self;
}


- (void)beginTransaction
{
    transactionSuccesful_ = NO;

    if (![db_ beginTransaction]) {
        @throw [[SLSQLException alloc] initWithNSString:[db_ lastErrorMessage]];
    }
}


- (void)setTransactionSuccesful
{
    transactionSuccesful_ = YES;
}


- (void)endTransaction
{
    BOOL returnVal;

    if (transactionSuccesful_) {
        returnVal = [db_ commit];
    } else {
        returnVal = [db_ rollback];
    }

    if (!returnVal) {
        @throw [[SLSQLException alloc] initWithNSString:[db_ lastErrorMessage]];
    }
}


static NSArray * valuesToArray(SLSQLValues *sqlValues)
{
    NSMutableArray *args = [[NSMutableArray alloc] initWithCapacity:[sqlValues size]];

    for (SLSQLValues_Val *val in sqlValues) {
        switch ([val getType].ordinal) {
            case SLSQLValues_Type_NULL:
                [args addObject:[NSNull null]];
                break;

            case SLSQLValues_Type_INT:
                [args addObject:[[NSNumber alloc] initWithInt:[val getIntValue]]];
                break;

            case SLSQLValues_Type_LONG:
                [args addObject:[[NSNumber alloc] initWithLongLong:[val getLongValue]]];
                break;

            case SLSQLValues_Type_DOUBLE:
                [args addObject:[[NSNumber alloc] initWithDouble:[val getDoubleValue]]];
                break;

            case SLSQLValues_Type_STRING:
                [args addObject:[val getStringValue]];
                break;

            default:
                @throw [[JavaLangIllegalStateException alloc] initWithNSString:[NSString stringWithFormat:@"Unknown SQLValue: %@", val.description]];
                break;
        }
    }

    return args;
}


- (id<SLSQLCursor>)queryWithNSString:(NSString *)query
{
    FMResultSet *set = [db_ executeQuery:query];

    if (!set) {
        @throw [[SLSQLException alloc] initWithNSString:[db_ lastErrorMessage]];
    }

    return [[IosSQLCursor alloc] initWithResultSet:set];
}


- (id<SLSQLCursor>)queryWithNSString:(NSString *)query
                     withSLSQLValues:(SLSQLValues *)sqlValues
{
    NSArray *args = valuesToArray(sqlValues);

    FMResultSet *set = [db_ executeQuery:query withArgumentsInArray:args];
    if (!set) {
        @throw [[SLSQLException alloc] initWithNSString:[db_ lastErrorMessage]];
    }

    return [[IosSQLCursor alloc] initWithResultSet:set];
}


- (void)updateWithNSString:(NSString *)query
{
    if (![db_ executeUpdate:query]) {
        @throw [[SLSQLException alloc] initWithNSString:[db_ lastErrorMessage]];
    }
}


- (void)updateWithNSString:(NSString *)query
           withSLSQLValues:(SLSQLValues *)sqlValues
{
    NSArray *args = valuesToArray(sqlValues);

    if (![db_ executeUpdate:query withArgumentsInArray:args]) {
        @throw [[SLSQLException alloc] initWithNSString:[db_ lastErrorMessage]];
    }
}


- (void)executeSQLScriptWithNSString:(NSString *)filename
{
    NSString *path = [filename stringByDeletingPathExtension];
    NSString *ext = [filename pathExtension];

    NSString *scriptFilePath = [[NSBundle mainBundle] pathForResource:path ofType:ext inDirectory:@""];
    NSLog(@"Executing SQL script: %@", scriptFilePath);

    NSError *error;
    NSString *contents = [NSString stringWithContentsOfFile:scriptFilePath encoding:NSUTF8StringEncoding error:&error];
    if (!contents) {
        @throw [[SLSQLException alloc] initWithNSString:[NSString stringWithFormat:@"Error reading file %@: %@", scriptFilePath, error.description]];
    }

    char *errmsg = 0;
    if (sqlite3_exec([db_ sqliteHandle], [contents UTF8String], 0, 0, &errmsg) != SQLITE_OK) {
        NSString *errString = [[NSString alloc] initWithCString:errmsg encoding:NSUTF8StringEncoding];
        sqlite3_free(errmsg);

        @throw [[SLSQLException alloc] initWithNSString:[NSString stringWithFormat:@"Error executing script %@: %@", scriptFilePath, errString]];
    }
    sqlite3_free(errmsg);
}


- (void)clearDatabase
{
    // TODO!
    @throw [[JavaLangIllegalStateException alloc] initWithNSString:@"Not implemented yet!"];
}


@end
