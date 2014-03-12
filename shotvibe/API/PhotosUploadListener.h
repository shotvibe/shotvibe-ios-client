//
//  PhotosUploadListener.h
//  shotvibe
//
//  Created by benny on 8/25/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PhotosUploadListener <NSObject>

// NOTE: Methods below need to be called on main thread

- (void)photoUploadAdditions:(int64_t)albumId;

- (void)photoUploadProgress:(int64_t)albumId;

- (void)photoAlbumAllPhotosUploaded:(int64_t)albumId;

- (void)photoUploadError:(NSError *)error;

@end
