//
//  ImageDiskCache.h
//  shotvibe
//
//  Created by raptor on 9/29/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageDiskCache : NSObject

// refreshHandler will be called on the main thread
- (id)initWithRefreshHandler:(void (^)(void))refreshHandler;

// Will return nil if not yet loaded. The refreshHandler will eventually be called and then you should call this method again
- (UIImage *)getImage:(NSString *)filePath;

@end
