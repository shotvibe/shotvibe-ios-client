//
//  NSFileManager+Helper.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 6/27/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "NSFileManager+Helper.h"

@implementation NSFileManager (Helper)
- (BOOL)isEmptyDirectoryAtURL:(NSURL*)url
{
    // This assumes you know the URL you have is actually a
    // directory and should be enhanced to ensure that
    return ([[self contentsOfDirectoryAtURL:url includingPropertiesForKeys:nil options:0 error:NULL] count] <= 1);
}
@end
