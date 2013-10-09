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
		   [file cStringUsingEncoding:NSStringEncodingConversionAllowLossy],
		   [[NSString stringWithFormat:@"%i", line] cStringUsingEncoding:NSStringEncodingConversionAllowLossy],
		   [message cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
}

@end
