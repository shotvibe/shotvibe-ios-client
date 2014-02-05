//
//  AlbumUploadingPhoto.h
//  shotvibe
//
//  Created by benny on 8/25/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SL/AlbumUploadingPhoto.h"

#import "PhotoUploadRequest.h"

@interface AlbumUploadingPhoto : SLAlbumUploadingPhoto

@property (atomic, copy) NSString *photoId;

- (id)initWithPhotoUploadRequest:(PhotoUploadRequest *)photoUploadRequest album:(int64_t)album;

- (BOOL)isUploadComplete;

- (void)setUploadComplete;

- (BOOL)isAddingToAlbum;

- (void)setAddingToAlbum;

- (float)getUploadProgress;

- (void)setUploadProgress:(int)bytesUploaded bytesTotal:(int)bytesTotal;

- (void)prepareTmpFiles:(dispatch_queue_t)dispatchQueue;

- (NSString *)getLowResFilename;
- (NSString *)getFullResFilename;

- (UIImage *)getThumbnail;

@end
