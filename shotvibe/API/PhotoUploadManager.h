//
//  UploadManager.h
//  shotvibe
//
//  Created by martijn on 20-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotosUploadListener.h"
#import "ShotVibeAPI.h"

@interface PhotoUploadManager : NSObject

- (id)initWithBaseURL:(NSString *)baseURL shotVibeAPI:(ShotVibeAPI *)shotVibeAPI listener:(id<PhotosUploadListener>)listener;

/**
 @param photoUploadRequests Array of `PhotoUploadRequest` objects
 */
- (void)uploadPhotos:(int64_t)albumId photoUploadRequests:(NSArray *)photoUploadRequests;

/**
 Return all photos that are currently uploading or have been uploaded but yet added to an album (because other photos for
 that album are still uploading.)
 @result Array of `AlbumPhoto` objects
 */
- (NSArray *)getUploadingAlbumPhotos:(int64_t)albumId;

@end
