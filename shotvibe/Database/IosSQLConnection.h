//
//  IosSQLConnection.h
//  shotvibe
//
//  Created by benny on 1/15/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SL/SQLConnection.h"

@class FMDatabase;

@interface IosSQLConnection : NSObject < SLSQLConnection >

- (id)initWithDatabase:(FMDatabase *)db;

@end
