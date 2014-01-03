//
//  RCLog.m
//
//  Created by Baluta Cristian on 09/10/2013.
//  Copyright (c) 2013 Baluta Cristian. All rights reserved.
//

#import "RCLog.h"

@implementation RCLog

+ (void)traceFile:(NSString*)file line:(int)line message:(NSString*)message {
	
	printf("%s:%s: %s\n",
		   [file cStringUsingEncoding:NSUTF8StringEncoding],
		   [[NSString stringWithFormat:@"%i", line] cStringUsingEncoding:NSUTF8StringEncoding],
		   [message cStringUsingEncoding:NSUTF8StringEncoding]);
}

+ (void)traceTimestamp {
	
	static NSDate *lastDate;
	
	if (lastDate == nil) {
		lastDate = [NSDate date];
	}
	RCLog(@"Timestamp since last log: %f", (double)[lastDate timeIntervalSinceNow]);
	lastDate = [NSDate date];
}

@end
