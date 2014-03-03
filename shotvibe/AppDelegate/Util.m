//
//  Util.m
//  shotvibe
//
//  Created by martijn on 13-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "Util.h"

@implementation Util


+ (float)screenWidth
{
    return [[UIScreen mainScreen] bounds].size.width;
}


+ (float)screenHeight
{
    return [[UIScreen mainScreen] bounds].size.height;
}


NSString *showBool(BOOL b)
{
	return b ? @"YES" : @"NO";
}

NSString *showNSData(NSData *d)
{
    return [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
}

@end
