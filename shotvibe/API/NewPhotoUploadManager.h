//
//  UploadManager.h
//  ViewControllerExperiments
//
//  Created by Oblosys on 20-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotosUploadListener.h"
#import "NewShotVibeAPI.h"

@interface NewPhotoUploadManager : NSObject

- (id)initWithBaseURL:(NSString *)baseURL shotVibeAPI:(ShotVibeAPI *)shotVibeAPI listener:(id<PhotosUploadListener>)listener;

- (void)uploadPhotos:(int64_t)albumId photoUploadRequests:(NSArray *)photoUploadRequests;

// Returns an array of `AlbumPhoto` objects
- (NSArray *)getUploadingPhotos:(int64_t)albumId;

@end
