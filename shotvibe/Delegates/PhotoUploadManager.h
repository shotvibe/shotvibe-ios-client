//
//  PhotoUploadManager.h
//  shotvibe
//
//  Created by benny on 8/25/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ShotVibeAPI.h"
#import "PhotosUploadListener.h"

@interface PhotoUploadManager : NSObject

- (id)initWithShotVibeAPI:(ShotVibeAPI *)shotvibeAPI listener:(id<PhotosUploadListener>)listener;

/**
 @param photoUploadRequests Array of `PhotoUploadRequest` objects
 */
- (void)uploadPhotos:(int64_t)albumId photoUploadRequests:(NSArray *)photoUploadRequests;

// Returns an array of `AlbumPhoto` objects
- (NSArray *)getUploadingPhotos:(int64_t)albumId;

@end
