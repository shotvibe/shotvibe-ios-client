//
//  IosSQLCursor.m
//  shotvibe
//
//  Created by benny on 1/15/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "IosSQLCursor.h"

#import "FMResultSet.h"

#import "SL/SQLException.h"

@implementation IosSQLCursor
{
    FMResultSet *s_;
}

- (id)initWithResultSet:(FMResultSet *)set
{
    self = [super init];
    if (self) {
        s_ = set;
    }

    return self;
}


- (BOOL)moveToNext
{
    return [s_ next];
}


- (int)getIntWithInt:(int)columnIndex
{
    return [s_ intForColumnIndex:columnIndex];
}


- (long long int)getLongWithInt:(int)columnIndex
{
    return [s_ longLongIntForColumnIndex:columnIndex];
}


- (double)getDoubleWithInt:(int)columnIndex
{
    return [s_ doubleForColumnIndex:columnIndex];
}


- (NSString *)getStringWithInt:(int)columnIndex
{
    NSString *result = [s_ stringForColumnIndex:columnIndex];
    if (result) {
        return result;
    } else {
        // TODO Better exception
        @throw [[SLSQLException alloc] init];
    }
}


- (BOOL)isNullWithInt:(int)columnIndex
{
    return [s_ columnIndexIsNull:columnIndex];
}


- (void)close
{
    [s_ close];
}


@end
