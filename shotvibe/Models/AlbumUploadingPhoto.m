//
//  AlbumUploadingPhoto.m
//  shotvibe
//
//  Created by benny on 8/25/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AlbumUploadingPhoto.h"

typedef NS_ENUM(NSInteger, UploadStatus) {
    UploadStatusQueued,
    UploadStatusUploading,
    UploadStatusComplete,
    UploadStatusAddingToAlbum
};

@implementation AlbumUploadingPhoto
{
    PhotoUploadRequest *photoUploadRequest_;
    dispatch_semaphore_t tmpFileSaved;

    NSObject *lock_;
    UploadStatus uploadStatus_;

    float uploadProgress_;
}

- (id)initWithPhotoUploadRequest:(PhotoUploadRequest *)photoUploadRequest album:(int64_t)album
{
    self = [super init];

    if (self) {
        _photoId = nil;

        photoUploadRequest_ = photoUploadRequest;
        tmpFileSaved = dispatch_semaphore_create(0);

        lock_ = [[NSObject alloc] init];
        uploadStatus_ = UploadStatusQueued;

        uploadProgress_ = 0.0f;
    }

    return self;
}

- (BOOL)isUploadComplete
{
    @synchronized (lock_) {
        return uploadStatus_ == UploadStatusComplete || uploadStatus_ == UploadStatusAddingToAlbum;
    }
}

- (void)reportUploadComplete
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

- (void)reportAddingToAlbum
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

- (void)reportUploadProgress:(int)bytesUploaded bytesTotal:(int)bytesTotal
{
    @synchronized (lock_) {
        uploadStatus_ = UploadStatusUploading;
        uploadProgress_ = (float)bytesUploaded / (float)bytesTotal;
    }
}

- (void)prepareTmpFile:(dispatch_queue_t)dispatchQueue
{
    dispatch_async(dispatchQueue, ^{
        [photoUploadRequest_ saveToFile];
        dispatch_semaphore_signal(tmpFileSaved);
    });
}

- (NSString *)getFilename
{
    dispatch_semaphore_wait(tmpFileSaved, DISPATCH_TIME_FOREVER);

    // Put back the semaphore so that the next call to `getFilename` will succeed
    dispatch_semaphore_signal(tmpFileSaved);

    return [photoUploadRequest_ getFilename];
}

- (UIImage *)getThumbnail
{
    return [photoUploadRequest_ getThumbnail];
}

@end
