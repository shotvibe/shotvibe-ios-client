//
//  NSFileManager+Helper.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 6/27/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (Helper)
- (BOOL)isEmptyDirectoryAtURL:(NSURL*)url;
@end
