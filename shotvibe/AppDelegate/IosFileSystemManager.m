//
//  IosFileSystemManager.m
//  shotvibe
//
//  Created by raptor on 11/5/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "IosFileSystemManager.h"

@implementation IosFileSystemManager


- (void)deleteFileWithNSString:(NSString *)filePath
{
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
}


@end
