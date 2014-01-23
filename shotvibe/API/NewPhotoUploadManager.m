//
//  UploadManager.m
//  shotvibe
//
//  Created by Oblosys on 20-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "NewPhotoUploadManager.h"
#import "NewShotVibeAPI.h"
#import "PhotoUploadRequest.h"
#import "AlbumUploadingPhoto.h"
#import "PhotosUploadListener.h"
#import "AlbumPhoto.h"

@interface PhotoDictionary : NSObject

/*
 * Dictionary for keeping lists of AlbumUploadingPhotos indexed by an album id.
 *
 * NOTE: this code is not thread safe
 */

- (void)addPhoto:(AlbumUploadingPhoto *)photo album:(int64_t)albumId;

- (NSArray *)getPhotosForAlbum:(int64_t)albumId;

- (NSArray *)getAllAlbumIds;

- (NSArray *)getAllPhotos;

@end

@implementation PhotoDictionary {
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



@implementation NewPhotoUploadManager {
    ShotVibeAPI *shotVibeAPI_;
    NewShotVibeAPI *newShotVibeAPI_;

    id<PhotosUploadListener> listener_; // This is the AlbumManager

    dispatch_queue_t photoSaveQueue_; // Used for saving photos to temp files.

    NSMutableArray *photoIds_; // A list of available photo ids for uploading, elements are `NSString`

    PhotoDictionary *uploadingPhotos_; // contains the AlbumUploadingPhotos that are currently uploading to the server
    PhotoDictionary *uploadedPhotos_; // contains the AlbumUploadingPhotos that have been uploaded, but not added to the album yet
}

static const NSTimeInterval RETRY_TIME = 5;


- (id)initWithBaseURL:(NSString *)baseURL shotVibeAPI:(ShotVibeAPI *)shotVibeAPI listener:(id<PhotosUploadListener>)listener
{
    self = [super init];

    if (self) {
        shotVibeAPI_ = shotVibeAPI;
        listener_ = listener;

        newShotVibeAPI_ = [[NewShotVibeAPI alloc] initWithBaseURL:(NSString *)baseURL oldShotVibeAPI:shotVibeAPI];

        photoSaveQueue_ = dispatch_queue_create(NULL, NULL);

        photoIds_ = [[NSMutableArray alloc] init];

        uploadingPhotos_ = [[PhotoDictionary alloc] init];
        uploadedPhotos_ = [[PhotoDictionary alloc] init];
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

    for (PhotoUploadRequest *req in photoUploadRequests) {
        [self uploadPhoto:albumId photoUploadRequest:req];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [listener_ photoUploadAdditions:albumId]; // Show the newly created UploadingAlbumPhotos in the UI.
    });
}


// *INDENT-OFF* Uncrustify block problem: https://github.com/bengardner/uncrustify/pull/233
- (void)uploadPhoto:(int64_t)albumId photoUploadRequest:(PhotoUploadRequest *)req
{
    // Create a background task for iOS < 7.
    __block UIBackgroundTaskIdentifier legacyBackgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        RCLog(@"background task ended");
        [[UIApplication sharedApplication] endBackgroundTask:legacyBackgroundTaskID];
    }];

    AlbumUploadingPhoto *photo = [[AlbumUploadingPhoto alloc] initWithPhotoUploadRequest:req album:albumId];

    [photo setPhotoId:[photoIds_ objectAtIndex:0]];
    [photoIds_ removeObjectAtIndex:0];

    [photo prepareTmpFile:photoSaveQueue_];
    [uploadingPhotos_ addPhoto:photo album:albumId];

    NSString *filePath = [photo getFilename]; // Will block until the photo has been saved

    [newShotVibeAPI_ photoUploadAsync:photo.photoId filePath:filePath progressHandler:^(int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        //RCLog(@"Task progress: photo %@ %.2f", photo.photoId, 100.0 * totalBytesSent / totalBytesExpectedToSend);
        [photo setUploadProgress:(int)totalBytesSent bytesTotal:(int)totalBytesExpectedToSend];
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener_ photoUploadProgress:albumId];
        });
    } completionHandler:^{
        //RCLog(@"Task completion: photo %@ %@", photo.photoId, [req getFilename]);

        // TODO: error handling

        [self photoWasUploaded:photo album:albumId legacyBackgroundTaskID:legacyBackgroundTaskID];
    }];
}
// *INDENT-ON*


/* Completion handler that is called when upload task succeeds. On iOS 7, this is run within an NSURLSession, meaning that it may not execute for more than 30 seconds. On iOS < 7 it is run as a background task that is allowed to run for 10 minutes. For iOS 7, this background task is also active, but since completion may occur well after the 10 minute interval has passed, we need to stay within the 30 seconds limit.
 */
- (void)photoWasUploaded:(AlbumUploadingPhoto *)photo album:(int64_t)albumId legacyBackgroundTaskID:(UIBackgroundTaskIdentifier)legacyBackgroundTaskID
{
    //RCLog(@"uploadingPhotos_: %@", [uploadingPhotos_ description]);
    //RCLog(@"uploadedPhotos_: %@", [uploadedPhotos_ description]);
    [photo setUploadComplete];
    dispatch_async(dispatch_get_main_queue(), ^{
        [listener_ photoUploadComplete:albumId]; // Remove progress bars in the UI
    });

    @synchronized(uploadingPhotos_) { // move photo from uploading to uploaded
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
            [photo setAddingToAlbum]; // TODO: this state is no longer used
            [photoIdsToAdd addObject:photo.photoId];
        }

        BOOL photosSuccesfullyAdded = NO;
        // TODO: this loop is not okay for background thread

        while (!photosSuccesfullyAdded) { // continuously try an add-to-album request, until success
            NSError *error;
            if (![shotVibeAPI_ albumAddPhotos:albumId photoIds:photoIdsToAdd withError:&error]) {
                RCLog(@"Error adding photos to album: %lld %@", albumId, [error description]);
                [NSThread sleepForTimeInterval:RETRY_TIME];
            } else {
                photosSuccesfullyAdded = YES;
            }
        }
        RCLog(@"Added %d photo(s) to album %lld: %@", (int)[photosToAdd count], albumId, showAlbumUploadingPhotoIds(photosToAdd));

        __block UIBackgroundTaskIdentifier blockLegacyBackgroundTaskID = legacyBackgroundTaskID;

        // Notify album manager that all photos are uploaded, causing a server refresh
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener_ photoAlbumAllPhotosUploaded:albumId];
            RCLog(@"End background task (id: #%d)", blockLegacyBackgroundTaskID);
            [[UIApplication sharedApplication] endBackgroundTask:blockLegacyBackgroundTaskID];
        });
    }
}


// Called by AlbumManager to get the uploading photos that need to be inserted in the album contents.
- (NSArray *)getUploadingPhotos:(int64_t)albumId
{
    NSMutableArray *result = [[NSMutableArray alloc] init];

    @synchronized(uploadingPhotos_) {
        NSArray *uploading = [uploadingPhotos_ getAllPhotos];
        NSArray *uploadingAndUploaded = [uploading arrayByAddingObjectsFromArray:[uploadedPhotos_ getAllPhotos]];
        for (AlbumUploadingPhoto *upload in uploadingAndUploaded) {
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
