//
//  Util.m
//  shotvibe
//
//  Created by martijn on 13-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "Util.h"

@implementation Util

NSString *showBool(BOOL b)
{
	return b ? @"YES" : @"NO";
}


NSString *showNSData(NSData *d)
{
    return [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
}


NSString * showShortPhotoId(NSString *idStr)
{
    NSString *shortId = nil;

    if ([idStr length] >= 8) {
        shortId = [NSString stringWithFormat:@"%@..%@", [idStr substringToIndex:4], [idStr substringFromIndex:[idStr length] - 4]];
    } else {
        shortId = idStr;
    }
    return shortId;
}


@end
