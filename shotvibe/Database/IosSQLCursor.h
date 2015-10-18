//
//  IosSQLCursor.h
//  shotvibe
//
//  Created by benny on 1/15/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SL/SQLCursor.h"

@class FMResultSet;

@interface IosSQLCursor : NSObject < SLSQLCursor >

- (id)initWithResultSet:(FMResultSet *)set;

@end
