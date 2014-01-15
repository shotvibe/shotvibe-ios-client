//
//  PhotoUploadManager.m
//  shotvibe
//
//  Created by benny on 8/25/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "PhotoUploadManager.h"
#import "ShotVibeAPI.h"
#import "AlbumUploadingPhoto.h"
#import "AlbumPhoto.h"
#import "PhotosUploadListener.h"

@implementation PhotoUploadManager
{
    ShotVibeAPI *shotvibeAPI_;
    id<PhotosUploadListener> listener_;
    NSObject *lock_;

    // Elements are `NSString`
    NSMutableArray *photoIds_;

    // Keys are `NSNumber` (long long)
    // Values are `NSMutableArray` (whose members are `AlbumUploadingPhoto`
    NSMutableDictionary *uploadingPhotos_;

    int uploadQueueSize_;
    dispatch_queue_t uploadQueue_;
    dispatch_queue_t photosLoadQueue_;
	
	UIBackgroundTaskIdentifier _backgroundRenderingID;
}

- (id)initWithShotVibeAPI:(ShotVibeAPI *)shotvibeAPI listener:(id<PhotosUploadListener>)listener
{
    self = [super init];

    if (self) {
        shotvibeAPI_ = shotvibeAPI;
        listener_ = listener;

        lock_ = [[NSObject alloc] init];
        photoIds_ = [[NSMutableArray alloc] init];
        uploadingPhotos_ = [[NSMutableDictionary alloc] init];
        uploadQueueSize_ = 0;

        uploadQueue_ = dispatch_queue_create(NULL, NULL);
        photosLoadQueue_ = dispatch_queue_create(NULL, NULL);
    }

    return self;
}

- (void)uploadPhotos:(int64_t)albumId photoUploadRequests:(NSArray *)photoUploadRequests
{
	
	// Start a background task
	
	_backgroundRenderingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
		RCLog(@"end background task prematurely, put the encoding on pause");
		[[UIApplication sharedApplication] endBackgroundTask:_backgroundRenderingID];
		_backgroundRenderingID = UIBackgroundTaskInvalid;
	}];
    RCLog(@"End background task (id: #%d)", _backgroundRenderingID);


    BOOL isCurrentlyUploading;

    NSMutableArray *addedPhotos = [[NSMutableArray alloc] init];

    @synchronized (lock_) {
        isCurrentlyUploading = uploadingPhotos_.count > 0;

        for (PhotoUploadRequest *photoUploadRequest in photoUploadRequests) {
            AlbumUploadingPhoto *newUpload = [[AlbumUploadingPhoto alloc] initWithPhotoUploadRequest:photoUploadRequest album:albumId];
            [addedPhotos addObject:newUpload];

            NSMutableArray *albumPhotoQueue = [uploadingPhotos_ objectForKey:[NSNumber numberWithLongLong:albumId]];
            if (!albumPhotoQueue) {
                albumPhotoQueue = [[NSMutableArray alloc] init];
                [uploadingPhotos_ setObject:albumPhotoQueue forKey:[NSNumber numberWithLongLong:albumId]];
            }
            [albumPhotoQueue addObject:newUpload];

            uploadQueueSize_++;
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [listener_ photoUploadAdditions:albumId];
    });

    for (AlbumUploadingPhoto *p in addedPhotos) {
        [p prepareTmpFile:photosLoadQueue_];
    }

    // TODO: DANGEROUS. If a thread was uploading when isCurrentlyUploading was set, but has finished
    // now, no new upload will be started. (rare case)
    if (!isCurrentlyUploading) {
        [self startProcessingUploads];
    }
}

- (NSArray *)getUploadingPhotos:(int64_t)albumId
{
    NSMutableArray *result = [[NSMutableArray alloc] init];

    @synchronized (lock_) {
        NSArray *uploads = [uploadingPhotos_ objectForKey:[NSNumber numberWithLongLong:albumId]];
        if (!uploads) {
            return result;
        }

        for (AlbumUploadingPhoto *upload in uploads) {
            AlbumPhoto *albumPhoto = [[AlbumPhoto alloc] initWithAlbumUploadingPhoto:upload];
            [result addObject:albumPhoto];
        }
    }

    return result;
}

- (void)startProcessingUploads
{
    dispatch_async(uploadQueue_, ^{
        [self processUploads];
    });
}

- (void)processUploads
{
    while (YES) {
        int64_t nextAlbumId;

        @synchronized (lock_) {
            // Grab the first album

            NSEnumerator *enumerator = [uploadingPhotos_ keyEnumerator];
            NSNumber *key = [enumerator nextObject];
            if (!key) {
                break;
            }

            nextAlbumId = [key longLongValue];
        }

        [self uploadAlbumPhotos:nextAlbumId];
    }
}

const NSTimeInterval RETRY_TIME = 5;

- (void)uploadAlbumPhotos:(int64_t)albumId
{
    RCLog(@"uploadAlbumPhotos: %lld", albumId);

    while (YES) {
        AlbumUploadingPhoto *nextPhotoUpload;
        int nextPhotoUploadIndex;
        int currentUploadQueueSize;
        @synchronized (lock_) {
            NSArray *albumUploads = [uploadingPhotos_ objectForKey:[NSNumber numberWithLongLong:albumId]];

            int indexOfFirstNotUploaded = [albumUploads indexOfObjectPassingTest:^BOOL (id albumUpload, NSUInteger idx, BOOL *stop) {
                return ![albumUpload isUploadComplete];
            }];

            if (indexOfFirstNotUploaded == NSNotFound) {
                // All of the uploading photos in the album have completed uploading
                // Prepare to add them to the album:
                for(AlbumUploadingPhoto *u in albumUploads) {
                    [u reportAddingToAlbum];
                }
                break; // break from the YES loop, since all albums have been uploaded
            }
            else {
                nextPhotoUploadIndex = indexOfFirstNotUploaded;
                nextPhotoUpload = [albumUploads objectAtIndex:indexOfFirstNotUploaded];
                uploadQueueSize_--;
            }

            // Make a copy since we need to access the value outside of the synchronized block
            currentUploadQueueSize = uploadQueueSize_;
        }

        RCLog(@"nextPhotoUploadIndex: %d", nextPhotoUploadIndex);

        if ([photoIds_ count] == 0) {
			
            RCLog(@"PhotoUploadManager Requesting Photo IDs");
				

            NSArray *newPhotoIds = nil;
            while (!newPhotoIds) {
                NSError *error;
                newPhotoIds = [shotvibeAPI_ photosUploadRequest:currentUploadQueueSize + 1 withError:&error];
                if (!newPhotoIds) {
                    RCLog(@"Error requesting photo IDS: %@", [error description]);
                    [NSThread sleepForTimeInterval:RETRY_TIME];
                }
            }

            [photoIds_ addObjectsFromArray:newPhotoIds];
        }

        nextPhotoUpload.photoId = [photoIds_ objectAtIndex:0];
        [photoIds_ removeObjectAtIndex:0];

        RCLog(@"About to upload photo (photoId: %@)", nextPhotoUpload.photoId);

        NSString *filename = [nextPhotoUpload getFilename];
        BOOL photoSuccesfullyUploaded = NO;
        while (!photoSuccesfullyUploaded) {
            NSError *error;
            if (![shotvibeAPI_ photoUpload:nextPhotoUpload.photoId filePath:filename uploadProgress:^(int bytesUploaded, int bytesTotal){
                [nextPhotoUpload reportUploadProgress:bytesUploaded bytesTotal:bytesTotal];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [listener_ photoUploadProgress:albumId];
                });
            } withError:&error]) {
                RCLog(@"Error uploading photo (photoId: %@):\n%@", nextPhotoUpload.photoId, [error description]);
                [NSThread sleepForTimeInterval:RETRY_TIME];
            }
            else {
                photoSuccesfullyUploaded = YES;
            }
        }

        RCLog(@"Succesfully uploaded photo (photoId: %@)", nextPhotoUpload.photoId);

        [nextPhotoUpload reportUploadComplete];

        dispatch_async(dispatch_get_main_queue(), ^{
            [listener_ photoUploadComplete:albumId];
        });
    }

    NSMutableArray *addPhotoIds = [[NSMutableArray alloc] init];
    @synchronized (lock_) {
        NSArray *albumUploads = [uploadingPhotos_ objectForKey:[NSNumber numberWithLongLong:albumId]];
        for (AlbumUploadingPhoto *p in albumUploads) {
            if ([p isAddingToAlbum]) {
                [addPhotoIds addObject:p.photoId];
            }
        }
    }

    BOOL photosSuccesfullyAdded = NO;

    while (!photosSuccesfullyAdded) {
        NSError *error;
        if (![shotvibeAPI_ albumAddPhotos:albumId photoIds:addPhotoIds withError:&error]) {
            RCLog(@"Error adding photos to album: %lld %@", albumId, [error description]);
            [NSThread sleepForTimeInterval:RETRY_TIME];
        }
        else {
            photosSuccesfullyAdded = YES;
        }
    }

    RCLog(@"Completely done uploading photos to album!");

    // Delete from uploadingPhotos_ the photos that were added to the album
    @synchronized (lock_) {
        NSMutableArray *albumUploads = [uploadingPhotos_ objectForKey:[NSNumber numberWithLongLong:albumId]];

        int i = 0;
        while (i < albumUploads.count) {
            if ([[albumUploads objectAtIndex:i] isAddingToAlbum]) {
                [albumUploads removeObjectAtIndex:0];
            }
            else {
                i++;
            }
        }

        if(albumUploads.count == 0) {
            [uploadingPhotos_ removeObjectForKey:[NSNumber numberWithLongLong:albumId]];
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [listener_ photoAlbumAllPhotosUploaded:albumId];
		
		// Exit background
		
        RCLog(@"End background task (id: #%d)", _backgroundRenderingID);
		[[UIApplication sharedApplication] endBackgroundTask:_backgroundRenderingID];
		_backgroundRenderingID = UIBackgroundTaskInvalid;
    });
}

@end
