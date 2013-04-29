//
//  SVBusinessDelegate.h
//  shotvibe
//
//  Created by John Gabelmann on 4/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Photo;
@class Album;

@interface SVBusinessDelegate : NSObject

+ (void)saveImage:(UIImage *)image forPhoto:(Photo *)photo;
+ (void)cleanupOfflineStorageForAlbum:(Album *)album;
+ (NSInteger)numberOfViewedImagesInAlbum:(Album *)album;
+ (UIImage *)loadImageFromAlbum:(Album *)album withPath:(NSString *)path;
+ (void)loadImageFromAlbum:(Album *)album withPath:(NSString *)path WithCompletion:(void (^)(UIImage *image, NSError *error))block;
@end
