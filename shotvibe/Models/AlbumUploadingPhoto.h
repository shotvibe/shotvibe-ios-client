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
    UploadStatusQueued,
    UploadStatusUploading,
    UploadStatusComplete,
    UploadStatusAddingToAlbum,
    NewUploader_UploadStatus_WaitingForId,
    NewUploader_UploadStatus_Stage1Uploading,
    NewUploader_UploadStatus_AddingToAlbum,
    NewUploader_UploadStatus_Stage2Pending
};


@interface AlbumUploadingPhoto : SLAlbumUploadingPhoto

@property (atomic, copy) NSString *photoId;
@property (nonatomic, assign) int64_t albumId;

- (id)initWithPhotoUploadRequest:(PhotoUploadRequest *)photoUploadRequest album:(int64_t)albumId;

- (UploadStatus)getUploadStatus;

- (void)setUploadStatus:(UploadStatus)newStatus;

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
