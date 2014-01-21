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

// TODO different name for class and methods, since this is not a queue
@interface PhotoQueue : NSObject

-(void)addPhoto:(AlbumUploadingPhoto *)photo album:(int64_t)albumId;

-(NSArray *)getPhotosForAlbum:(int64_t)albumId;

-(NSArray *)getAllAlbumIds;

-(NSArray *)getAllPhotos;

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

-(void)addPhoto:(AlbumUploadingPhoto *)photo album:(int64_t)albumId
{
    NSMutableArray *photosAlreadyInQueue = [photosIndexedByAlbum_ objectForKey:[NSNumber numberWithLongLong:albumId]];

    if (!photosAlreadyInQueue) {
        photosAlreadyInQueue = [[NSMutableArray alloc] init];
        [photosIndexedByAlbum_ setObject:photosAlreadyInQueue forKey:[NSNumber numberWithLongLong:albumId]];
    }

    [photosAlreadyInQueue addObject:photo];
}

-(BOOL)removePhoto:(AlbumUploadingPhoto *)photo album:(int64_t)albumId
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

-(NSArray *)getPhotosForAlbum:(int64_t)albumId
{ // return a non-mutable array for safety
    return [NSArray arrayWithArray:[photosIndexedByAlbum_ objectForKey:[NSNumber numberWithLongLong:albumId]]];
}

-(void)removePhotosForAlbum:(int64_t)albumId
{
    [photosIndexedByAlbum_ removeObjectForKey:[NSNumber numberWithLongLong:albumId]];
}

-(NSArray *)getAllAlbumIds
{
    return photosIndexedByAlbum_.allKeys;
}

-(NSArray *)getAllPhotos
{
    return photosIndexedByAlbum_.allValues;
}

-(NSString *)description
{
    NSString *str = @"PhotoQueue:";
    for (NSNumber *albumId in photosIndexedByAlbum_.allKeys) {
        str = [NSString stringWithFormat:@"%@ (album:%@, #photos:%lu)", str, albumId, [[photosIndexedByAlbum_ objectForKey:albumId] count]];
    }

    return str;
}
@end



@interface NewPhotoUploadManager()

@end

@implementation NewPhotoUploadManager {

    ShotVibeAPI *shotVibeAPI_;
    NewShotVibeAPI *newShotVibeAPI_;

    id<PhotosUploadListener> listener_;

    dispatch_queue_t photosLoadQueue_;

    NSMutableArray *photoIds_; // Elements are `NSString`

    PhotoQueue *uploadingPhotos_; // contains the AlbumUploadingPhotos that are currently uploading to the server
    PhotoQueue *uploadedPhotos_; // contains the AlbumUploadingPhotos that have been uploaded, but not added to the album yet

}

static const NSTimeInterval RETRY_TIME = 5;


- (id)initWithShotVibeAPI:(ShotVibeAPI *)shotVibeAPI listener:(id<PhotosUploadListener>)listener
{
    self = [super init];

    if (self) {
        shotVibeAPI_ = shotVibeAPI;
        newShotVibeAPI_ = [[NewShotVibeAPI alloc] init];

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

        NSLog(@"PhotoUploadManager Requesting Photo IDs");

        NSArray *newPhotoIds = nil;
        while (!newPhotoIds) {
            NSError *error;
            // TODO: optimize this by requesting ids for all pending uploads? (prob. need different list for that)
            // maybe not worth it since when calling this, usually all existing uploads will already have ids
            newPhotoIds = [shotVibeAPI_ photosUploadRequest:(int)[photoUploadRequests count] + 1 withError:&error];
            if (!newPhotoIds) {
                NSLog(@"Error requesting photo IDS: %@", [error description]);
                [NSThread sleepForTimeInterval:RETRY_TIME];
            }
        }

        [photoIds_ addObjectsFromArray:newPhotoIds];
    }

    // TODO: check if all albumUpload report actions have been performed
    // TODO: inform this listener
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        [listener_ photoUploadAdditions:albumId];
    //    });

    for (int i=0; i< [photoUploadRequests count]; i++) {
        PhotoUploadRequest *req = [photoUploadRequests objectAtIndex:i];

        AlbumUploadingPhoto *photo = [[AlbumUploadingPhoto alloc] initWithPhotoUploadRequest:req album:albumId];

        [photo setPhotoId:[photoIds_ objectAtIndex:0]];
        [photoIds_ removeObjectAtIndex:0];
        
        [photo prepareTmpFile:photosLoadQueue_];
        [uploadingPhotos_ addPhoto:photo album:albumId];

        [newShotVibeAPI_ photoUploadAsync:photo.photoId filePath:[photo getFilename] progressHandler:^(int64_t totalBytesSent, int64_t totalBytesExpectedToSend){
            //NSLog(@"Task progress: photo %@ %.2f", photo.photoId, 100.0 * totalBytesSent / totalBytesExpectedToSend);
            [photo reportUploadProgress:(int)totalBytesSent bytesTotal:(int)totalBytesExpectedToSend];
            dispatch_async(dispatch_get_main_queue(), ^{
                [listener_ photoUploadProgress:albumId];
            });
        } completionHandler:^{
            // TODO: error handling
            NSLog(@"Task completion: photo %@ %@", photo.photoId, [req getFilename]);
            dispatch_async(dispatch_get_main_queue(), ^{
                [listener_ photoUploadComplete:albumId];
            });

            [self photoWasUploaded:photo album:albumId];
        }];
    }
}

// Note: Cannot run for more than 30 seconds because it may be called from a background session.
-(void)photoWasUploaded:(AlbumUploadingPhoto *)photo album:(int64_t)albumId
{
    
    // TODO: uploadingPhoto.setComplete // maybe, if we want this flag to survive
    //NSLog(@"uploadingPhotos_: %@", [uploadingPhotos_ description]);
    //NSLog(@"uploadedPhotos_: %@", [uploadedPhotos_ description]);

    @synchronized(uploadingPhotos_) {
        [uploadingPhotos_ removePhoto:photo album:albumId];
        [uploadedPhotos_ addPhoto:photo album:albumId];
    }

    NSArray *photosToAdd = nil;
    @synchronized(uploadingPhotos_) {
        if ([uploadingPhotos_ getPhotosForAlbum:albumId].count == 0) {
            photosToAdd = [uploadedPhotos_ getPhotosForAlbum:albumId];

            [uploadedPhotos_ removePhotosForAlbum:albumId];
        }
    }

    if (photosToAdd) {
        NSMutableArray *photoIdsToAdd = [[NSMutableArray alloc] init];

        for (AlbumUploadingPhoto *photo in photosToAdd) {
            [photoIdsToAdd addObject:photo.photoId];
        }

        BOOL photosSuccesfullyAdded = NO;
        // TODO: this loop is not okay for background thread

        while (!photosSuccesfullyAdded) {
            NSError *error;
            if (![shotVibeAPI_ albumAddPhotos:albumId photoIds:photoIdsToAdd withError:&error]) {
                NSLog(@"Error adding photos to album: %lld %@", albumId, [error description]);
                [NSThread sleepForTimeInterval:RETRY_TIME];
            }
            else {
                photosSuccesfullyAdded = YES;
            }
        }
        NSLog(@"Added %d photo(s) to album %lld: %@", (int)[photosToAdd count], albumId, showAlbumUploadingPhotoIds(photosToAdd));
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener_ photoAlbumAllPhotosUploaded:albumId];
        });
    }
}

- (NSArray *)getUploadingPhotos:(int64_t)albumId
{
    return [uploadingPhotos_ getAllPhotos];
}


#pragma mark - Utility functions


NSString *showAlbumUploadingPhotoIds(NSArray *albumUploadingPhotos)
{
    NSString *str = @"Photo id's:";
    for (AlbumUploadingPhoto *photo in albumUploadingPhotos) {
        str = [NSString stringWithFormat:@"%@ %@", str, photo.photoId];
    }
    return str;
}
@end
