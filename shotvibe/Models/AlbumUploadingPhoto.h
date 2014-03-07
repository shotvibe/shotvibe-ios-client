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

typedef NS_ENUM (NSInteger, UploadStatus) {
    UploadStatus_WaitingForId,
    UploadStatus_Stage1Uploading,
    UploadStatus_AddingToAlbum,
    UploadStatus_Stage2PendingOrUploading
};


@interface AlbumUploadingPhoto : SLAlbumUploadingPhoto

@property (atomic, copy) NSString *photoId;
@property (nonatomic, assign) int64_t albumId;

- (id)initWithPhotoUploadRequest:(PhotoUploadRequest *)photoUploadRequest album:(int64_t)albumId;

- (UploadStatus)getUploadStatus;

- (void)setUploadStatus:(UploadStatus)newStatus;

- (BOOL)isUploadComplete;

- (BOOL)isAddingToAlbum;

- (float)getUploadProgress;

- (void)setUploadProgress:(float)uploadProgress;

- (void)prepareTmpFiles:(dispatch_queue_t)dispatchQueue;

- (NSString *)getLowResFilename;

- (NSString *)getFullResFilename;

- (BOOL)isSaved;

- (UIImage *)getThumbnail;

@end
