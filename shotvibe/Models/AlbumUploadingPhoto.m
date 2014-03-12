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
        uploadStatus_ = UploadStatus_WaitingForId;

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
// TODO: change name to reflect it's proper meaning
- (BOOL)isUploadComplete
{
    @synchronized (lock_) {
        return uploadStatus_ == UploadStatus_AddingToAlbum || uploadStatus_ == UploadStatus_Stage2PendingOrUploading;
    }
}

- (BOOL)isAddingToAlbum
{
    @synchronized (lock_) {
        return uploadStatus_ == UploadStatus_AddingToAlbum;
    }
}

- (float)getUploadProgress
{
    @synchronized (lock_) {
        return uploadProgress_;
    }
}

- (void)setUploadProgress:(float)uploadProgress
{
    @synchronized (lock_) {
        uploadProgress_ = uploadProgress;
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


// TODO: Temporary, until we store UploadingAlbumPhotos in the database
// Return YES if the file was saved and we can all -[AlbumUploadingPhoto getFullResFileName] without blocking.
- (BOOL)isSaved
{
    return [photoUploadRequest_ getFullResFilename] != nil && [photoUploadRequest_ getLowResFilename] != nil;
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
