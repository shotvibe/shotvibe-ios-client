//
//  AlbumUploadingPhoto.m
//  shotvibe
//
//  Created by benny on 8/25/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AlbumUploadingPhoto.h"

@implementation AlbumUploadingPhoto
{
    PhotoUploadRequest *photoUploadRequest_;
    dispatch_semaphore_t tmpFilesSaved;

    NSObject *lock_;
    UploadStatus uploadStatus_;

    float uploadProgress_;
}

- (id)initWithPhotoUploadRequest:(PhotoUploadRequest *)photoUploadRequest album:(int64_t)albumId
{
    self = [super init];

    if (self) {
        _photoId = nil;
        _albumId = albumId;

        photoUploadRequest_ = photoUploadRequest;
        tmpFilesSaved = dispatch_semaphore_create(0);

        lock_ = [[NSObject alloc] init];
        uploadStatus_ = UploadStatusQueued;

        uploadProgress_ = 0.0f;
    }

    return self;
}


// TODO: maybe make property for uploadStatus
- (UploadStatus)getUploadStatus
{
    return uploadStatus_;
}


- (void)setUploadStatus:(UploadStatus)newStatus
{
    uploadStatus_ = newStatus;
}


// used to show/hide upload progress in gui
- (BOOL)isUploadComplete
{
    @synchronized (lock_) {
        return uploadStatus_ == UploadStatusComplete || uploadStatus_ == UploadStatusAddingToAlbum || uploadStatus_ == NewUploader_UploadStatus_AddingToAlbum || uploadStatus_ == NewUploader_UploadStatus_Stage2Pending;
    }
}

- (void)setUploadComplete
{
    @synchronized (lock_) {
        uploadStatus_ = UploadStatusComplete;
    }
}

- (BOOL)isAddingToAlbum
{
    @synchronized (lock_) {
        return uploadStatus_ == UploadStatusAddingToAlbum;
    }
}

- (void)setAddingToAlbum
{
    @synchronized (lock_) {
        uploadStatus_ = UploadStatusAddingToAlbum;
    }
}

- (float)getUploadProgress
{
    @synchronized (lock_) {
        return uploadProgress_;
    }
}

- (void)setUploadProgress:(int)bytesUploaded bytesTotal:(int)bytesTotal
{
    @synchronized (lock_) {
        uploadStatus_ = UploadStatusUploading;
        uploadProgress_ = (float)bytesUploaded / (float)bytesTotal;
    }
}

- (void)prepareTmpFiles:(dispatch_queue_t)dispatchQueue
{
    dispatch_async(dispatchQueue, ^{
        [photoUploadRequest_ saveToFiles];
        dispatch_semaphore_signal(tmpFilesSaved);
    });
}

- (NSString *)getFullResFilename
{
    dispatch_semaphore_wait(tmpFilesSaved, DISPATCH_TIME_FOREVER);

    // Put back the semaphore so that the next call to `getFilename` will succeed
    dispatch_semaphore_signal(tmpFilesSaved);

    return [photoUploadRequest_ getFullResFilename];
}


- (NSString *)getLowResFilename
{
    dispatch_semaphore_wait(tmpFilesSaved, DISPATCH_TIME_FOREVER);

    // Put back the semaphore so that the next call to `getFilename` will succeed
    dispatch_semaphore_signal(tmpFilesSaved);

    return [photoUploadRequest_ getLowResFilename];
}

- (UIImage *)getThumbnail
{
    return [photoUploadRequest_ getThumbnail];
}

@end
