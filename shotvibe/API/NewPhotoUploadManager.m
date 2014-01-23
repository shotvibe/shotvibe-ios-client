//
//  UploadManager.m
//  ViewControllerExperiments
//
//  Created by martijn on 20-01-14.
//  Copyright (c) 2014 Oblomov Systems. All rights reserved.
//

#import "NewPhotoUploadManager.h"
#import "NewShotVibeAPI.h"
#import "PhotoUploadRequest.h"
#import "AlbumUploadingPhoto.h"
#import "PhotosUploadListener.h"
#import "AlbumPhoto.h"

// TODO different name for class and methods, since this is not a queue
@interface PhotoQueue : NSObject

- (void)addPhoto:(AlbumUploadingPhoto *)photo album:(int64_t)albumId;

- (NSArray *)getPhotosForAlbum:(int64_t)albumId;

- (NSArray *)getAllAlbumIds;

- (NSArray *)getAllPhotos;

@end

@implementation PhotoQueue {
    NSMutableDictionary *photosIndexedByAlbum_; // (int64_t)albumId -> NSMutableArray of (PhotoUploadRequest *)
}

- (id)init
{
    self = [super init];

    if (self) {
        photosIndexedByAlbum_ = [[NSMutableDictionary alloc] init];
    }
    return self;
}


- (void)addPhoto:(AlbumUploadingPhoto *)photo album:(int64_t)albumId
{
    NSMutableArray *photosAlreadyInQueue = [photosIndexedByAlbum_ objectForKey:[NSNumber numberWithLongLong:albumId]];

    if (!photosAlreadyInQueue) {
        photosAlreadyInQueue = [[NSMutableArray alloc] init];
        [photosIndexedByAlbum_ setObject:photosAlreadyInQueue forKey:[NSNumber numberWithLongLong:albumId]];
    }

    [photosAlreadyInQueue addObject:photo];
}


- (BOOL)removePhoto:(AlbumUploadingPhoto *)photo album:(int64_t)albumId
{
    NSMutableArray *photosInQueue = [photosIndexedByAlbum_ objectForKey:[NSNumber numberWithLongLong:albumId]];

    if (photosInQueue && [photosInQueue containsObject:photo]) {
        [photosInQueue removeObject:photo];

        if ([photosInQueue count] == 0) {
            [photosIndexedByAlbum_ removeObjectForKey:[NSNumber numberWithLongLong:albumId]];
        }
        return YES;
    } else {
        return NO;
    }
}


- (NSArray *)getPhotosForAlbum:(int64_t)albumId
{ // return a non-mutable array for safety
    return [NSArray arrayWithArray:[photosIndexedByAlbum_ objectForKey:[NSNumber numberWithLongLong:albumId]]];
}


- (void)removePhotosForAlbum:(int64_t)albumId
{
    [photosIndexedByAlbum_ removeObjectForKey:[NSNumber numberWithLongLong:albumId]];
}


- (NSArray *)getAllAlbumIds
{
    return photosIndexedByAlbum_.allKeys;
}


// Return AlbumUploadingPhotos for all albums
- (NSArray *)getAllPhotos
{
    NSMutableArray *allPhotos = [[NSMutableArray alloc] init];

    for (NSNumber *albumId in photosIndexedByAlbum_.allKeys) {
        [allPhotos addObjectsFromArray:[photosIndexedByAlbum_ objectForKey:albumId]];
    }

    return [NSArray arrayWithArray:allPhotos];
}


- (NSString *)description
{
    NSString *str = @"PhotoQueue:";
    for (NSNumber *albumId in photosIndexedByAlbum_.allKeys) {
        str = [NSString stringWithFormat:@"%@ (album:%@, #photos:%lu)", str, albumId, (unsigned long)[[photosIndexedByAlbum_ objectForKey:albumId] count]];
    }

    return str;
}


@end

@interface NewPhotoUploadManager ()

@end

@implementation NewPhotoUploadManager {
    ShotVibeAPI *shotVibeAPI_;
    NewShotVibeAPI *newShotVibeAPI_;

    id<PhotosUploadListener> listener_; // This is the AlbumManager

    dispatch_queue_t photosLoadQueue_;

    NSMutableArray *photoIds_; // A list of available photo ids, elements are `NSString`

    PhotoQueue *uploadingPhotos_; // contains the AlbumUploadingPhotos that are currently uploading to the server
    PhotoQueue *uploadedPhotos_; // contains the AlbumUploadingPhotos that have been uploaded, but not added to the album yet
}

static const NSTimeInterval RETRY_TIME = 5;


- (id)initWithBaseURL:(NSString *)baseURL shotVibeAPI:(ShotVibeAPI *)shotVibeAPI listener:(id<PhotosUploadListener>)listener
{
    self = [super init];

    if (self) {
        shotVibeAPI_ = shotVibeAPI;
        listener_ = listener;

        newShotVibeAPI_ = [[NewShotVibeAPI alloc] initWithBaseURL:(NSString *)baseURL oldShotVibeAPI:shotVibeAPI];

        photosLoadQueue_ = dispatch_queue_create(NULL, NULL);

        photoIds_ = [[NSMutableArray alloc] init];

        uploadingPhotos_ = [[PhotoQueue alloc] init];
        uploadedPhotos_ = [[PhotoQueue alloc] init];
    }

    return self;
}


- (void)uploadPhotos:(int64_t)albumId photoUploadRequests:(NSArray *)photoUploadRequests
{
    // Request new ids if there are not enough
    if ([photoIds_ count] < [photoUploadRequests count]) {
        RCLog(@"PhotoUploadManager Requesting Photo IDs");

        NSArray *newPhotoIds = nil;
        while (!newPhotoIds) {
            NSError *error;
            // TODO: optimize this by requesting ids for all pending uploads? (prob. need different list for that)
            // maybe not worth it since when calling this, usually all existing uploads will already have ids
            newPhotoIds = [shotVibeAPI_ photosUploadRequest:(int)[photoUploadRequests count] + 1 withError:&error];
            if (!newPhotoIds) {
                RCLog(@"Error requesting photo IDS: %@", [error description]);
                [NSThread sleepForTimeInterval:RETRY_TIME];
            }
        }

        [photoIds_ addObjectsFromArray:newPhotoIds];
    }

    for (int i = 0; i < [photoUploadRequests count]; i++) {
        PhotoUploadRequest *req = [photoUploadRequests objectAtIndex:i];

        AlbumUploadingPhoto *photo = [[AlbumUploadingPhoto alloc] initWithPhotoUploadRequest:req album:albumId];

        [photo setPhotoId:[photoIds_ objectAtIndex:0]];
        [photoIds_ removeObjectAtIndex:0];

        [photo prepareTmpFile:photosLoadQueue_];
        [uploadingPhotos_ addPhoto:photo album:albumId];

        NSString *filePath = [photo getFilename];

        [newShotVibeAPI_ photoUploadAsync:photo.photoId filePath:filePath progressHandler:^(int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
            //RCLog(@"Task progress: photo %@ %.2f", photo.photoId, 100.0 * totalBytesSent / totalBytesExpectedToSend);
            [photo reportUploadProgress:(int)totalBytesSent bytesTotal:(int)totalBytesExpectedToSend];
            dispatch_async(dispatch_get_main_queue(), ^{
                [listener_ photoUploadProgress:albumId];
            });
        } completionHandler:^{
            // TODO: error handling
            RCLog(@"Task completion: photo %@ %@", photo.photoId, [req getFilename]);
            [photo reportUploadComplete];
            dispatch_async(dispatch_get_main_queue(), ^{
                [listener_ photoUploadComplete:albumId];
            });

            [self photoWasUploaded:photo album:albumId];
        }];
    }

    // Show the newly created UploadingAlbumPhotos in the UI.
    dispatch_async(dispatch_get_main_queue(), ^{
        [listener_ photoUploadAdditions:albumId];
    });

}


// Note: Cannot run for more than 30 seconds because it may be called from a background session.
- (void)photoWasUploaded:(AlbumUploadingPhoto *)photo album:(int64_t)albumId
{
    // TODO: uploadingPhoto.setComplete // maybe, if we want this flag to survive
    //RCLog(@"uploadingPhotos_: %@", [uploadingPhotos_ description]);
    //RCLog(@"uploadedPhotos_: %@", [uploadedPhotos_ description]);

    @synchronized(uploadingPhotos_) {
        [uploadingPhotos_ removePhoto:photo album:albumId];
        [uploadedPhotos_ addPhoto:photo album:albumId];
    }

    NSArray *photosToAdd = nil;
    @synchronized(uploadingPhotos_) {
        if ([uploadingPhotos_ getPhotosForAlbum:albumId].count == 0) {
            // Only when there are no other photos for this album currently uploading, we
            // will add the photos to the album. This way only one push notification will be sent.
            photosToAdd = [uploadedPhotos_ getPhotosForAlbum:albumId];

            [uploadedPhotos_ removePhotosForAlbum:albumId];
        }
    }

    if (photosToAdd) {
        NSMutableArray *photoIdsToAdd = [[NSMutableArray alloc] init];

        for (AlbumUploadingPhoto *photo in photosToAdd) {
            [photo reportAddingToAlbum]; // TODO: this state is no longer used
            [photoIdsToAdd addObject:photo.photoId];
        }

        BOOL photosSuccesfullyAdded = NO;
        // TODO: this loop is not okay for background thread

        while (!photosSuccesfullyAdded) {
            NSError *error;
            if (![shotVibeAPI_ albumAddPhotos:albumId photoIds:photoIdsToAdd withError:&error]) {
                RCLog(@"Error adding photos to album: %lld %@", albumId, [error description]);
                [NSThread sleepForTimeInterval:RETRY_TIME];
            } else {
                photosSuccesfullyAdded = YES;
            }
        }
        RCLog(@"Added %d photo(s) to album %lld: %@", (int)[photosToAdd count], albumId, showAlbumUploadingPhotoIds(photosToAdd));
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener_ photoAlbumAllPhotosUploaded:albumId];
        });
    }
}


- (NSArray *)getUploadingPhotos:(int64_t)albumId
{
    NSMutableArray *result = [[NSMutableArray alloc] init];

    @synchronized(uploadingPhotos_) {
        NSArray *uploads = [uploadingPhotos_ getAllPhotos];

        for (AlbumUploadingPhoto *upload in uploads) {
            AlbumPhoto *albumPhoto = [[AlbumPhoto alloc] initWithAlbumUploadingPhoto:upload];
            [result addObject:albumPhoto];
        }
    }

    return [NSArray arrayWithArray:result];
}


#pragma mark - Utility functions


NSString * showAlbumUploadingPhotoIds(NSArray *albumUploadingPhotos)
{
    NSString *str = @"Photo id's:";
    for (AlbumUploadingPhoto *photo in albumUploadingPhotos) {
        str = [NSString stringWithFormat:@"%@ %@", str, photo.photoId];
    }
    return str;
}


@end
