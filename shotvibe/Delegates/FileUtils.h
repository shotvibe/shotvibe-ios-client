//
//  FileUtils.h
//  shotvibe
//
//  Created by benny on 8/25/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileUtils : NSObject

+ (NSString *)getApplicationSupportDirectory;

+ (void)addSkipBackupAttributeToItemAtURL:(NSString *)filePath;

@end
