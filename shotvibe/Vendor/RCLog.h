//
//  RCLog.h
//
//  Created by Baluta Cristian on 09/10/2013.
//  Copyright (c) 2013 Baluta Cristian. All rights reserved.
//

#import <Foundation/Foundation.h>

#define RCLog(fmt, ... ) \
do { \
	[RCLog traceFile:[[NSString stringWithUTF8String:__FILE__] lastPathComponent] line:__LINE__ message:[NSString stringWithFormat:(fmt), ##__VA_ARGS__]]; \
} while(0)

#define RCLogO(obj) RCLog(@"%@", obj)
#define RCLogS(str) RCLog(@"%@", str)
#define RCLogI(integer) RCLog(@"%i", integer)
#define RCLogF(float) RCLog(@"%f", float)
#define RCLogRect(rect) RCLog(@"%@", NSStringFromCGRect(rect))
#define RCLogPoint(point) RCLog(@"%@", NSStringFromCGPoint(point))
#define RCLogSize(size) RCLog(@"%@", NSStringFromCGSize(size))
#define RCLogThread() RCLog([NSThread isMainThread] ? @"Log from Main Thread":@"Log from Secondary Thread")

@interface RCLog : NSObject

+ (void)traceFile:(NSString*)file line:(int)line message:(NSString*)message;

@end
