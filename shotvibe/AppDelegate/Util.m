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


NSString * showPoint(CGPoint point)
{
    return [NSString stringWithFormat:@"(%.1f, %.1f)", point.x, point.y];
}


NSString * showSize(CGSize size)
{
    return [NSString stringWithFormat:@"(%.1f x %.1f)", size.width, size.height];
}


NSString * showRect(CGRect rect)
{
    return [NSString stringWithFormat:@"%@:%@", showPoint(rect.origin), showSize(rect.size)];
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
