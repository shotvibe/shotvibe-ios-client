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
#import "PhotosUploadListener.h"
#import "AlbumPhoto.h"
#import "AlbumUploadingPhoto.h"
#import "PhotoDictionary.h"
#import "SL/APIException.h"


// TODO: temporary code for storing the AlbumUploadingPhotos in a file
@implementation AlbumUploadingPhoto (NSCoding)

+ (NSString *)getUnfinishedUploadsFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [NSString stringWithFormat:@"%@/UnfinishedUploads.plist", documentsDirectory];
}


- (id)initWithCoder:(NSCoder *)coder
{
    NSString *photoId = [coder decodeObjectForKey:@"photoId"];
    int64_t albumId = [coder decodeInt64ForKey:@"albumId"];
    NSString *fullResFilePath = [coder decodeObjectForKey:@"fullResFilePath"];
    UploadStatus uploadStatus = [coder decodeIntForKey:@"uploadStatus"];

    self = [self initWithPhotoUploadRequest:[[PhotoUploadRequest alloc] initWithPath:fullResFilePath] album:albumId];

    [self prepareTmpFiles:dispatch_queue_create(NULL, NULL)]; // TODO: hacky, but we can't store paths in AlbumUploadingPhoto
    [self setUploadStatus:uploadStatus];
    self.photoId = photoId;
    self.albumId = albumId;

    return self;
}


- (void)encodeWithCoder:(NSCoder *)coder
{
    NSString *photoId = self.photoId;
    int64_t albumId = self.albumId;
    NSString *fullResFilePath = [self getFullResFilename];
    UploadStatus uploadStatus = [self getUploadStatus];

    [coder encodeObject:photoId forKey:@"photoId"];
    [coder encodeInt64:albumId forKey:@"albumId"];
    [coder encodeInt:uploadStatus forKey:@"uploadStatus"];
    [coder encodeObject:fullResFilePath forKey:@"fullResFilePath"];
}


@end
// End of temporary code


@implementation NewPhotoUploadManager {
    ShotVibeAPI *shotVibeAPI_;
    NewShotVibeAPI *newShotVibeAPI_;

    id<PhotosUploadListener> listener_; // This is the AlbumManager

    dispatch_queue_t photoSaveQueue_; // Used for saving photos to temp files.

    NSMutableArray *photoIds_; // A list of available photo ids for uploading, elements are `NSString`

    PhotoDictionary *uploadingPhotos_; // contains the AlbumUploadingPhotos that are currently uploading to the server
    PhotoDictionary *uploadedPhotos_; // contains the AlbumUploadingPhotos that have been uploaded, but for which no add request has been sent (because other photos for that album are still uploading)

    PhotoDictionary *addingPhotos_; // contains the AlbumUploadingPhotos for which an add request has been sent

    // Using just one queue instead of the two separate uploaded and adding queues will pose a problem in the (extremely hypothetical) situation that a photo is queued and completely uploaded while other photos for the same album are in the process of being added. (We wouldn't be able to determine which photos should be put in the add request for the single photo)

    NSArray *pendingSecondStagePhotos_; // AlbumUploadingPhotos that have been low-res uploaded and added, but are pending full res upload

    // In ShotVibeDB, photos will progress through these states: Stage1Uploading -> AddingToAlbum -> Stage2Pending
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
        addingPhotos_ = [[PhotoDictionary alloc] init];
        pendingSecondStagePhotos_ = [[NSMutableArray alloc] init];
    }

    NSArray *unfinishedUploads = [self loadUnfinishedUploads];
    RCLog(@"Found %d unfinished uploads", unfinishedUploads.count);
    logUploads(unfinishedUploads);

    return self;
}


- (void)uploadPhotos:(int64_t)albumId photoUploadRequests:(NSArray *)photoUploadRequests
{
    // Use a background task to initiate the uploads, in case the application is closed while requesting photo id's.
    // The uploads themselves have their own background task.
    __block UIBackgroundTaskIdentifier initiateUploadsBackgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        RCLog(@"Initiate-uploads background task %d was forced to end", initiateUploadsBackgroundTaskID);
        [[UIApplication sharedApplication] endBackgroundTask:initiateUploadsBackgroundTaskID];
    }];
    RCLog(@"Initiate-uploads background task %d started", initiateUploadsBackgroundTaskID);

    NSMutableArray *newAlbumUploadingPhotos = [[NSMutableArray alloc] init];
    for (PhotoUploadRequest *req in photoUploadRequests) {
        AlbumUploadingPhoto *photo = [[AlbumUploadingPhoto alloc] initWithPhotoUploadRequest:req album:albumId];
        [newAlbumUploadingPhotos addObject:photo];
        [photo prepareTmpFiles:photoSaveQueue_]; // asynchronous

        @synchronized(self) {
            [uploadingPhotos_ addPhoto:photo album:albumId];
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [listener_ photoUploadAdditions:albumId]; // Show the newly created UploadingAlbumPhotos in the UI.
    });

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        for (AlbumUploadingPhoto *photo in newAlbumUploadingPhotos) {
            if ([photo getLowResFilename] && [photo getLowResFilename]) { // force save, won't fail, just block
                [photo setUploadStatus:NewUploader_UploadStatus_WaitingForId];
                [self storeUnfinishedUploads]; // TODO: at this point, store new AlbumUploadingPhotos as WaitingForId in ShotVibeDB
            } else {
                RCLog(@"INTERNAL ERROR: tmp file(s) empty");
            }
        }

        [self requestIdsForNewUploads:[photoUploadRequests count]];
        for (AlbumUploadingPhoto *photo in newAlbumUploadingPhotos) {
            [self uploadPhotoWithoutId:albumId photo:photo];
        }
        RCLog(@"Initiate-uploads background task %d ended", initiateUploadsBackgroundTaskID);
        [[UIApplication sharedApplication] endBackgroundTask:initiateUploadsBackgroundTaskID];
    });
}


// TODO: will loop on network failure and may be canceled after 10 minutes in the background.
- (void)requestIdsForNewUploads:(NSUInteger)nrOfNewUploads
{
    NSUInteger remainingPhotoIds;
    @synchronized(photoIds_) {
        remainingPhotoIds = [photoIds_ count]; // probably not necessary to synchronize this, but it doesn't hurt
    }

    if (remainingPhotoIds < nrOfNewUploads) { // Request new ids if there are not enough
        RCLog(@"PhotoUploadManager Requesting Photo IDs");

        NSArray *newPhotoIds = nil;

        while (!newPhotoIds) {
            @try {
                newPhotoIds = [shotVibeAPI_ photosUploadRequest:nrOfNewUploads + 1];
            } @catch (SLAPIException *exception) {
                RCLog(@"Error requesting photo IDS: %@", exception.description);
                [NSThread sleepForTimeInterval:RETRY_TIME];
            }
        }

        @synchronized(photoIds_) {
            [photoIds_ addObjectsFromArray:newPhotoIds];
        }
    }
}


- (void)uploadPhotoWithoutId:(int64_t)albumId photo:(AlbumUploadingPhoto *)photo
{
    // On iOS < 7, the entire upload process will be in a background task, and needs to finish within 10 minutes.
    __block UIBackgroundTaskIdentifier photoUploadBackgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        RCLog(@"Photo-upload background task %d was forced to end", photoUploadBackgroundTaskID);
        [[UIApplication sharedApplication] endBackgroundTask:photoUploadBackgroundTaskID];
    }];
    RCLog(@"Photo-upload background task %d started", photoUploadBackgroundTaskID);

    @synchronized(photoIds_) {
        [photo setPhotoId:[photoIds_ objectAtIndex:0]];
        [photoIds_ removeObjectAtIndex:0];
    }

    [photo setUploadStatus:NewUploader_UploadStatus_Stage1Pending];
    [self storeUnfinishedUploads]; // TODO: at this point, store new AlbumUploadingPhotos as Stage1Pending in ShotVibeDB

    [self startFirstStagePhotoUpload:albumId photo:photo backgroundTaskID:photoUploadBackgroundTaskID];
}


// *INDENT-OFF* Uncrustify block problem: https://github.com/bengardner/uncrustify/pull/233
- (void)startFirstStagePhotoUpload:(int64_t)albumId photo:(AlbumUploadingPhoto *)photo backgroundTaskID:(UIBackgroundTaskIdentifier)photoUploadBackgroundTaskID
{
    RCLog(@"START first-stage upload for %@", showShortPhotoId(photo.photoId));

    NSString *lowResFilePath = [photo getLowResFilename]; // Will block until the photo has been saved

    // Stage 1, upload low-res version of photo
    [newShotVibeAPI_ photoUploadAsync:photo.photoId filePath:lowResFilePath isFullRes:NO progressHandler:^(int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        RCLog(@"Task progress: photo %@ %.2f %.1fk", photo.photoId, 100.0 * totalBytesSent / totalBytesExpectedToSend, totalBytesExpectedToSend / 1024.0);
        [photo setUploadProgress:(int)totalBytesSent bytesTotal:(int)totalBytesExpectedToSend];
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener_ photoUploadProgress:albumId];
        });
    } completionHandler:^(NSError *error) {
        //RCLog(@"Task completion: photo %@ %@", showShortPhotoId(photo.photoId), [req getFilename]);
        if (error) {
            RCLog(@"ERROR %@\nduring first-stage upload for %@\nRetrying in %.1f seconds.", [error localizedDescription], showShortPhotoId(photo.photoId), RETRY_TIME);
            [NSThread sleepForTimeInterval:RETRY_TIME];
            [self startFirstStagePhotoUpload:albumId photo:photo backgroundTaskID:photoUploadBackgroundTaskID];
        } else {
            [self lowResPhotoWasUploaded:photo album:albumId backgroundTaskID:photoUploadBackgroundTaskID];
        }
    }];
}
// *INDENT-ON*


/* Completion handler that is called when upload task succeeds. On iOS 7, this is run within an NSURLSession, meaning that it may not execute for more than 30 seconds. On iOS < 7 it is run as a background task that is allowed to run for 10 minutes. For iOS 7, this background task is also active, but since completion may occur well after the 10 minute interval has passed, we need to stay within the 30 seconds limit.
 */
- (void)lowResPhotoWasUploaded:(AlbumUploadingPhoto *)photo album:(int64_t)albumId backgroundTaskID:(UIBackgroundTaskIdentifier)photoUploadBackgroundTaskID
{
    RCLog(@"FINISH first-stage upload for %@", showShortPhotoId(photo.photoId));

    [photo setUploadStatus:NewUploader_UploadStatus_AddingToAlbum];
    [self storeUnfinishedUploads]; // TODO: at this point, store new AlbumUploadingPhotos as AddingToAlbum in ShotVibeDB

    [photo setUploadComplete];
    dispatch_async(dispatch_get_main_queue(), ^{
        [listener_ photoUploadComplete:albumId]; // Remove progress bars in the UI
    });

    @synchronized(self) { // move photo from uploading to uploaded
        [uploadingPhotos_ removePhoto:photo album:albumId];
        [uploadedPhotos_ addPhoto:photo album:albumId];
    }

    RCLog(@"lowResPhotoWasUploaded:");
    RCLog(@"uploadingPhotos_: %@", [uploadingPhotos_ description]);
    RCLog(@"uploadedPhotos_: %@", [uploadedPhotos_ description]);
    RCLog(@"addingPhotos_: %@", [addingPhotos_ description]);
    RCLog(@"pendingSecondStagePhotos_: %@", [pendingSecondStagePhotos_ description]);

    NSArray *photosToAdd = nil;
    @synchronized(self) {
        if ([uploadingPhotos_ getAllPhotosForAlbum:albumId].count == 0) {
            // Only when there are no other photos for this album currently uploading, we
            // will add the photos to the album. This way only one push notification will be sent.
            photosToAdd = [uploadedPhotos_ getAllPhotosForAlbum:albumId];

            [uploadedPhotos_ removePhotos:photosToAdd album:albumId];
            [addingPhotos_ addPhotos:photosToAdd album:albumId];
        }
    }

    if (!photosToAdd) {
        RCLog(@"Photo-upload background task %d ended", photoUploadBackgroundTaskID);
        [[UIApplication sharedApplication] endBackgroundTask:photoUploadBackgroundTaskID];
    } else {
        for (AlbumUploadingPhoto *photo in photosToAdd) {
            [photo setAddingToAlbum]; // TODO: this state is no longer used
        }
        [self startAddToAlbumTask:photosToAdd album:albumId backgroundTaskID:photoUploadBackgroundTaskID];
    }
}


- (void)startAddToAlbumTask:(NSArray *)photosToAdd album:(int64_t)albumId backgroundTaskID:(UIBackgroundTaskIdentifier)photoUploadBackgroundTaskID
{
    RCLog(@"Adding %d photo(s) to album %lld: %@", photosToAdd.count, albumId, showAlbumUploadingPhotoIds(photosToAdd));
    NSMutableArray *photoIdsToAdd = [[NSMutableArray alloc] init];

    for (AlbumUploadingPhoto *photo in photosToAdd) {
        [photoIdsToAdd addObject:photo.photoId];
    }

    /* TODO: old way to call albumAddPhotos, can be removed if adding as an upload task is responsive enough.
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
     RCLog(@"Added %d photo(s) to album %lld: %@", photosToAdd.count, albumId, showAlbumUploadingPhotoIds(photosToAdd));

     [self photosWereAdded:photosToAdd albumId:albumId];

     // Notify album manager that all photos are uploaded, causing a server refresh
     dispatch_async(dispatch_get_main_queue(), ^{
     @synchronized(self) {
     [addingPhotos_ removePhotos:photosToAdd album:albumId];
     }

     [listener_ photoAlbumAllPhotosUploaded:albumId];
     RCLog(@"Background task %d ended", photoUploadBackgroundTaskID);
     [[UIApplication sharedApplication] endBackgroundTask:photoUploadBackgroundTaskID];
     });
     */


    // TODO: may suffer from a delay after photos were uploaded, when called from the background.
    [newShotVibeAPI_ albumAddPhotosAsync:albumId photoIds:photoIdsToAdd completionHandler:^(NSError *error) {
        if (error) {
            RCLog(@"ERROR: %@\nwhile adding %d photo(s) to album %lld: %@\nRetrying in %.1f seconds.", [error localizedDescription], photosToAdd.count, albumId, showAlbumUploadingPhotoIds(photosToAdd), RETRY_TIME);
            [NSThread sleepForTimeInterval:RETRY_TIME];

            [self startAddToAlbumTask:photosToAdd album:albumId backgroundTaskID:photoUploadBackgroundTaskID];
        } else {
            RCLog(@"Added %d photo(s) to album %lld: %@", photosToAdd.count, albumId, showAlbumUploadingPhotoIds(photosToAdd));

            [self photosWereAdded:photosToAdd albumId:albumId];

            // Notify album manager that all photos are uploaded, causing a server refresh
            dispatch_async(dispatch_get_main_queue(), ^{
                [listener_ photoAlbumAllPhotosUploaded:albumId];
                RCLog(@"Photo-upload background task %d ended", photoUploadBackgroundTaskID);
                [[UIApplication sharedApplication] endBackgroundTask:photoUploadBackgroundTaskID];
            });
        }
    }];
}


// NSArray photos has elements of type AlbumUploadingPhoto
- (void)photosWereAdded:(NSArray *)addedPhotos albumId:(int64_t)albumId
{
    for (AlbumUploadingPhoto *photo in addedPhotos) {
        [photo setUploadStatus:NewUploader_UploadStatus_Stage2Pending];
        [self storeUnfinishedUploads]; // TODO: at this point, store new AlbumUploadingPhotos as Stage2Pending in ShotVibeDB
    }

    NSArray *newSecondStagePhotos = @[];

    @synchronized(self) {
        [addingPhotos_ removePhotos:addedPhotos album:albumId]; // move from adding to pending second stage
        pendingSecondStagePhotos_ = [pendingSecondStagePhotos_ arrayByAddingObjectsFromArray:addedPhotos];

        RCLog(@"photosWereAdded:");
        RCLog(@"uploadingPhotos_: %@", [uploadingPhotos_ description]);
        RCLog(@"uploadedPhotos_: %@", [uploadedPhotos_ description]);
        RCLog(@"addingPhotos_: %@", [addingPhotos_ description]);
        RCLog(@"pendingSecondStagePhotos_: %@", [pendingSecondStagePhotos_ description]);

        int nrOfUnfinishedPhotos = [uploadingPhotos_ getAllPhotos].count + [uploadedPhotos_ getAllPhotos].count + [addingPhotos_  getAllPhotos].count;

        if (nrOfUnfinishedPhotos == 0) { // all low res photos have been uploaded and added, so we can start the full res uploads
            RCLog(@"All queues empty, initiating second-stage uploads");
            newSecondStagePhotos = pendingSecondStagePhotos_;
            pendingSecondStagePhotos_ = [[NSMutableArray alloc] init];
        }
    }

    // TODO: if new photos are added once the full res uploads have started, they will run in parallel and not get priority. Is that a problem?
    // There does not seem to be a straightforward way to prioritize iOS 7 background tasks, so perhaps we need to schedule them ourselves.

    for (AlbumUploadingPhoto *newSecondStagePhoto in newSecondStagePhotos) {
        [self startSecondStageUploadTask:newSecondStagePhoto];
    }
}


- (void)startSecondStageUploadTask:(AlbumUploadingPhoto *)photo
{
    __block UIBackgroundTaskIdentifier secondStageUploadBackgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        RCLog(@"Second-stage upload background task %d was forced to end", secondStageUploadBackgroundTaskID);
        [[UIApplication sharedApplication] endBackgroundTask:secondStageUploadBackgroundTaskID];
    }];
    RCLog(@"Second-stage upload background task %d started", secondStageUploadBackgroundTaskID);

    RCLog(@"START second-stage upload for %@", showShortPhotoId(photo.photoId));
    NSString *fullResFilePath = [photo getFullResFilename];

    [newShotVibeAPI_ photoUploadAsync:photo.photoId filePath:fullResFilePath isFullRes:YES progressHandler:nil completionHandler:^(NSError *error) {
        if (error) {
            RCLog(@"ERROR %@\nduring second-stage upload for %@\nRetrying in %.1f seconds.", [error localizedDescription], showShortPhotoId(photo.photoId), RETRY_TIME);
            [NSThread sleepForTimeInterval:RETRY_TIME];
            [self startSecondStageUploadTask:photo];
        } else {
            RCLog(@"FINISH second-stage upload for %@", showShortPhotoId(photo.photoId));
            [self storeUnfinishedUploads]; // TODO: at this point, remove the photo newSecondStageUpload from ShotVibeDB

            RCLog(@"Second-stage upload background task %d ended", secondStageUploadBackgroundTaskID);
            [[UIApplication sharedApplication] endBackgroundTask:secondStageUploadBackgroundTaskID];
        }
    }];
}


// Called by AlbumManager to get the uploading photos that need to be inserted in the album contents.
// Note: the returned array contains AlbumPhotos, not AlbumUploadingPhotos
- (NSArray *)getUploadingAlbumPhotos:(int64_t)albumId
{
    NSMutableArray *uploadingPhotosForAlbum = [[NSMutableArray alloc] init];
    for (AlbumUploadingPhoto *photo in [self getAllUploadingPhotos]) {
        if (photo.albumId == albumId) {
            SLAlbumPhoto *albumPhoto = [[SLAlbumPhoto alloc] initWithSLAlbumUploadingPhoto:photo];
            [uploadingPhotosForAlbum addObject:albumPhoto];
        }
    }
    return uploadingPhotosForAlbum;
}


- (NSArray *)getAllUploadingPhotos
{
    NSArray *result;

    @synchronized(self) {
        NSArray *uploading = [uploadingPhotos_ getAllPhotos];
        NSArray *uploaded = [uploadedPhotos_ getAllPhotos];
        NSArray *adding = [addingPhotos_ getAllPhotos];
        result = [[uploading arrayByAddingObjectsFromArray:uploaded] arrayByAddingObjectsFromArray:adding];
    }
    RCLog(@"getUploadingPhotos: %d uploading photos", result.count);
    return result;
}


#pragma mark - Utility functions

NSString * showAlbumUploadingPhotoIds(NSArray *albumUploadingPhotos)
{
    NSString *str = @"Photo id's:";
    for (AlbumUploadingPhoto *photo in albumUploadingPhotos) {
        str = [NSString stringWithFormat:@"%@ %@", str, showShortPhotoId(photo.photoId)];
    }
    return str;
}


- (void)storeUnfinishedUploads
{
    NSArray *albumUploadingPhotos = [self getAllUploadingPhotos];
    RCLog(@"Storing unfinished uploads:");
    logUploads(albumUploadingPhotos);
    [NSKeyedArchiver archiveRootObject:albumUploadingPhotos toFile:[AlbumUploadingPhoto getUnfinishedUploadsFilePath]];
}


- (NSArray *)loadUnfinishedUploads
{
    return [NSKeyedUnarchiver unarchiveObjectWithFile:[AlbumUploadingPhoto getUnfinishedUploadsFilePath]];
}


static void logUploads(NSArray *albumUploadingPhotos)
{
    for (AlbumUploadingPhoto *photo in albumUploadingPhotos) {
        RCLog(@"Upload: %@ in album %lld, state %d file:%@", showShortPhotoId(photo.photoId), photo.albumId, [photo getUploadStatus], [photo getFullResFilename]);
    }
}


@end
