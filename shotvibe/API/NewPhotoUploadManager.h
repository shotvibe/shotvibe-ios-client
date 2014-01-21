//
//  UploadManager.h
//  ViewControllerExperiments
//
//  Created by martijn on 20-01-14.
//  Copyright (c) 2014 Oblomov Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotosUploadListener.h"
#import "NewShotVibeAPI.h"

@interface NewPhotoUploadManager : NSObject

- (id)initWithShotVibeAPI:(ShotVibeAPI *)shotVibeAPI listener:(id<PhotosUploadListener>)listener;

- (void)uploadPhotos:(int64_t)albumId photoUploadRequests:(NSArray *)photoUploadRequests;

// Returns an array of `AlbumPhoto` objects
- (NSArray *)getUploadingPhotos:(int64_t)albumId;

@end
