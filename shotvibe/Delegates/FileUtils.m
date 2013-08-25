//
//  FileUtils.m
//  shotvibe
//
//  Created by benny on 8/25/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "FileUtils.h"

@implementation FileUtils


+ (NSString *)getApplicationSupportDirectory
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    if (![manager fileExistsAtPath:appSupportDir]) {
        NSError *error;
        if (![manager createDirectoryAtPath:appSupportDir withIntermediateDirectories:NO attributes:nil error:&error]) {
            NSAssert(false, @"Error creating ApplicationSupportDirectory: %@", [error localizedDescription]);
        }
    }

    return appSupportDir;
}

// See: <http://developer.apple.com/library/ios/qa/qa1719/_index.html>
+ (void)addSkipBackupAttributeToItemAtURL:(NSString *)filePath
{
    NSURL *url = [NSURL fileURLWithPath:filePath isDirectory:NO];

    assert([[NSFileManager defaultManager] fileExistsAtPath:[url path]]);

    NSError *error = nil;
    if(![url setResourceValue: [NSNumber numberWithBool:YES]
                       forKey: NSURLIsExcludedFromBackupKey
                        error: &error]) {
        NSAssert(false, @"Error excluding %@ from backup %@", [url lastPathComponent], error);
    }
}

@end
