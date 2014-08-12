//
//  UploadManager.m
//  shotvibe
//
//  Created by Oblosys on 20-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "PhotoUploadManager.h"
#import "PhotoUploadRequest.h"
#import "PhotosUploadListener.h"
#import "AlbumPhoto.h"
#import "AlbumUploadingPhoto.h"
#import "PhotoDictionary.h"
#import "ShotVibeAppDelegate.h"
#import "SL/APIException.h"
#import "SL/ArrayList.h"


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
    NSString *lowResFilePath = [coder decodeObjectForKey:@"lowResFilePath"];
    UploadStatus uploadStatus = [coder decodeIntForKey:@"uploadStatus"];

    self = [self initWithPhotoUploadRequest:[[PhotoUploadRequest alloc] initWithFullResPath:fullResFilePath lowResPath:lowResFilePath] album:albumId];

    [self prepareTmpFiles:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)]; // No work is done in prepareTmpFiles, as the images are already saved, so we don't need a shared serial queue here
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
    NSString *lowResFilePath = [self getLowResFilename];
    UploadStatus uploadStatus = [self getUploadStatus];

    [coder encodeObject:photoId forKey:@"photoId"];
    [coder encodeInt64:albumId forKey:@"albumId"];
    [coder encodeInt:uploadStatus forKey:@"uploadStatus"];
    [coder encodeObject:fullResFilePath forKey:@"fullResFilePath"];
    [coder encodeObject:lowResFilePath forKey:@"lowResFilePath"];
}


@end
// End of temporary code


@implementation PhotoUploadManager {
    ShotVibeAPI *shotVibeAPI_;

    id<PhotosUploadListener> listener_; // This is the AlbumManager

    dispatch_queue_t photoSaveQueue_; // Used for saving photos to temp files.

    NSMutableArray *photoIds_; // A list of available photo ids for uploading, elements are `NSString`

    PhotoDictionary *uploadingStage1Photos_; // AlbumUploadingPhotos for which the low res version is currently uploading to the server
    PhotoDictionary *uploadedStage1Photos_; // AlbumUploadingPhotos for which the low res version has been uploaded, but for which no add request has been sent (because other photos for that album are still uploading)

    PhotoDictionary *addingToAlbumPhotos_; // contains the AlbumUploadingPhotos for which an add request has been sent

    // Using just one queue instead of the two separate uploaded and adding queues will pose a problem in the (extremely hypothetical) situation that a photo is queued and completely uploaded while other photos for the same album are in the process of being added. (We wouldn't be able to determine which photos should be put in the add request for the single photo)

    NSMutableArray *pendingStage2Photos_; // AlbumUploadingPhotos that have been low-res uploaded and added, but are pending full res upload

    NSMutableArray *uploadingStage2Photos_; // AlbumUploadingPhotos for which the full-res version is currently uploading to the server
    // TODO: we need to keep track of these uploadingStage2Photos_, so we can store them in unfinishedUploads. Perhaps not necessary anymore once we store uploads in the database

    // In ShotVibeDB, photos will progress through these states: WaitingForId -> Stage1Uploading -> AddingToAlbum -> Stage2PendingOrUploading
}

static const NSTimeInterval RETRY_TIME = 5;


- (id)initWithShotVibeAPI:(ShotVibeAPI *)shotVibeAPI listener:(id<PhotosUploadListener>)listener
{
    self = [super init];

    if (self) {
        shotVibeAPI_ = shotVibeAPI;
        listener_ = listener;

        // dedicated photoSaveQueue to prevent parallel photo saves (which would take up too much memory)
        photoSaveQueue_ = dispatch_queue_create("ShotVibe.photoSaveQueue", NULL);

        photoIds_ = [[NSMutableArray alloc] init];

        uploadingStage1Photos_ = [[PhotoDictionary alloc] init];
        uploadedStage1Photos_ = [[PhotoDictionary alloc] init];
        addingToAlbumPhotos_ = [[PhotoDictionary alloc] init];
        pendingStage2Photos_ = [[NSMutableArray alloc] init];
        uploadingStage2Photos_ = [[NSMutableArray alloc] init];
    }

    // Temporarily delay the resumption of unfinished uploads.
    //
    // There is currently a bug in the resume upload code that sometimes causes a crash immediately during startup.
    //
    // This is bad since it prevents Crashlytics from sending a crash report (from the previous run). So we
    // temporarily add a delay so that Crashlytics has a chance to send the crash report.
    //
    // First we need to wait a short amount of time, since the CrashlyticsDelegate is notified about a previous
    // crash only after a short delay after startup (about 1 second)
    double resumeDelayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(resumeDelayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        if (![CrashlyticsDelegate sharedInstance].crashlyticsDidDetectCrashDuringPreviousExecution) {
            // There is no previous crash to report, resume uploads immediately
            [self resumeUnfinishedUploads];
        } else {
            // There was a previous crash. We need to wait for a long enough time now that will allow the crash report to be sent over the network
            double delayInSeconds = 60.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                [self resumeUnfinishedUploads];
            });
        }
    });

    return self;
}


- (void)uploadPhotos:(int64_t)albumId photoUploadRequests:(NSArray *)photoUploadRequests
{
    // Use a background task to initiate the uploads, in case the application is closed while requesting photo id's.
    // The uploads themselves have their own background task.
    UIBackgroundTaskIdentifier initiateUploadsBackgroundTaskID = [self beginBackgroundTaskWithDescription:@"Initiate-uploads"];

    NSMutableArray *newAlbumUploadingPhotos = [[NSMutableArray alloc] init];
    for (PhotoUploadRequest *req in photoUploadRequests) {
        AlbumUploadingPhoto *photo = [[AlbumUploadingPhoto alloc] initWithPhotoUploadRequest:req album:albumId];
        [newAlbumUploadingPhotos addObject:photo];
        [photo prepareTmpFiles:photoSaveQueue_]; // asynchronous

        @synchronized(self) {
            [uploadingStage1Photos_ addPhoto:photo album:albumId];
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [listener_ photoUploadAdditions:albumId]; // Show the newly created UploadingAlbumPhotos in the UI.
    });

    // On a separate queue, store the photo uploads as soon as they are available. We don't want this to wait on any network connection for requesting ids.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // TODO: this can be improved by storing the unfinished upload as soon as the full-res is available (which is immediate, in case of camera photos), rather than also waiting for the low-res. This will give rise to unfinished uploads with only a full-res image, so on resume, we will need to generate the low-res photo (and have a seperate queue for that) Better to do this once we will use the database instead of NSCoder and it will be easy to use the shared photoSaveQueue_. Until then, there is a risk of photo loss when crashing during the generation of the low-res photos. NOTE: when implementing this, make sure unfinished uploads are saved even if there is no low-res filepath (currently we require both).
        for (AlbumUploadingPhoto *photo in newAlbumUploadingPhotos) {
            if ([photo getFullResFilename] && [photo getLowResFilename]) { // force save, won't fail, just block
                [self storeUnfinishedUploads]; // TODO: at this point, store new AlbumUploadingPhotos as WaitingForId in ShotVibeDB
            } else {
                RCLog(@"INTERNAL ERROR: tmp file(s) empty");
            }
        }
    });

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self uploadPhotosWithoutIds:newAlbumUploadingPhotos];

        RCLog(@"Initiate-uploads background task %d ended", initiateUploadsBackgroundTaskID);
        [[UIApplication sharedApplication] endBackgroundTask:initiateUploadsBackgroundTaskID];
    });
}


// NOTE: Not thread safe, so should only be called from a synchronized block
// NOTE: may temporarily block on id request, so call from background thread
- (void)requestIdsForNewUploads:(NSUInteger)nrOfNewUploads
{
    NSUInteger remainingPhotoIds;
    remainingPhotoIds = [photoIds_ count];

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

        [photoIds_ addObjectsFromArray:newPhotoIds];
    }
}


// NOTE: may temporarily block on id request, so call from background thread
- (void)uploadPhotosWithoutIds:(NSArray *)photos
{
    @synchronized(photoIds_) {
        [self requestIdsForNewUploads:[photos count]];

        for (AlbumUploadingPhoto *photo in photos) {
            [photo setPhotoId:[photoIds_ objectAtIndex:0]];
            [photoIds_ removeObjectAtIndex:0];

            [photo setUploadStatus:UploadStatus_Stage1Uploading];
            [self storeUnfinishedUploads]; // TODO: at this point, store new AlbumUploadingPhotos as Stage1Pending in ShotVibeDB
        }
    }

    for (AlbumUploadingPhoto *photo in photos) {
        // On iOS < 7, the entire upload process will be in a background task, and needs to finish within 10 minutes.
        UIBackgroundTaskIdentifier photoUploadBackgroundTaskID = [self beginBackgroundTaskWithDescription:@"First-stage upload"];

        [self startFirstStagePhotoUpload:photo backgroundTaskID:photoUploadBackgroundTaskID];
    }
}


// *INDENT-OFF* Uncrustify block problem: https://github.com/bengardner/uncrustify/pull/233
- (void)startFirstStagePhotoUpload:(AlbumUploadingPhoto *)photo backgroundTaskID:(UIBackgroundTaskIdentifier)photoUploadBackgroundTaskID
{
    NSString *lowResFilePath = [photo getLowResFilename]; // Will block until the photo has been saved
    RCLog(@"START first-stage upload for %@", showShortPhotoId(photo.photoId));

    // Stage 1, upload low-res version of photo
    [shotVibeAPI_ photoUploadAsync:photo.photoId filePath:lowResFilePath isFullRes:NO progressHandler:^(int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        //RCLog(@"Task progress: photo %@ %.2f %.1fk", photo.photoId, 100.0 * totalBytesSent / totalBytesExpectedToSend, totalBytesExpectedToSend / 1024.0);
        [photo setUploadProgress:(float)totalBytesSent/(float)totalBytesExpectedToSend];
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener_ photoUploadProgress:photo.albumId];
        });
    } completionHandler:^(NSError *error) {
        //RCLog(@"Task completion: photo %@ %@", showShortPhotoId(photo.photoId), [req getFilename]);
        if (error) {
            RCLog(@"ERROR %@\nduring first-stage upload for %@\nRetrying in %.1f seconds.", [error localizedDescription], showShortPhotoId(photo.photoId), RETRY_TIME);
            [NSThread sleepForTimeInterval:RETRY_TIME];
            [self startFirstStagePhotoUpload:photo backgroundTaskID:photoUploadBackgroundTaskID];
        } else {
            [self lowResPhotoWasUploaded:photo backgroundTaskID:photoUploadBackgroundTaskID];
        }
    }];
}
// *INDENT-ON*


/* Completion handler that is called when upload task succeeds. On iOS 7, this is run within an NSURLSession, meaning that it may not execute for more than 30 seconds. On iOS < 7 it is run as a background task that is allowed to run for 10 minutes. For iOS 7, this background task is also active, but since completion may occur well after the 10 minute interval has passed, we need to stay within the 30 seconds limit.
 */
- (void)lowResPhotoWasUploaded:(AlbumUploadingPhoto *)photo backgroundTaskID:(UIBackgroundTaskIdentifier)photoUploadBackgroundTaskID
{
    RCLog(@"FINISH first-stage upload for %@", showShortPhotoId(photo.photoId));

    [photo setUploadStatus:UploadStatus_AddingToAlbum];
    [self storeUnfinishedUploads]; // TODO: at this point, store new AlbumUploadingPhotos as AddingToAlbum in ShotVibeDB

    dispatch_async(dispatch_get_main_queue(), ^{
        [photo setUploadProgress:1.0];
        [listener_ photoUploadProgress:photo.albumId];
    });

    @synchronized(self) { // move photo from uploading to uploaded
        [uploadingStage1Photos_ removePhoto:photo album:photo.albumId];
        [uploadedStage1Photos_ addPhoto:photo album:photo.albumId];
    }

    //RCLog(@"lowResPhotoWasUploaded:");
    //RCLog(@"uploadingPhotos_: %@", [uploadingStage1Photos_ description]);
    //RCLog(@"uploadedPhotos_: %@", [uploadedStage1Photos_ description]);
    //RCLog(@"addingPhotos_: %@", [addingToAlbumPhotos_ description]);
    //RCLog(@"pendingSecondStagePhotos_: %@", [pendingStage2Photos_ description]);
    //RCLog(@"uploadingSecondStagePhotos_: %@", [uploadingStage2Photos_ description]);

    NSArray *photosToAdd = nil;
    @synchronized(self) {
        if ([uploadingStage1Photos_ getAllPhotosForAlbum:photo.albumId].count == 0) {
            // Only when there are no other photos for this album currently uploading, we
            // will add the photos to the album. This way only one push notification will be sent.
            photosToAdd = [uploadedStage1Photos_ getAllPhotosForAlbum:photo.albumId];

            [uploadedStage1Photos_ removePhotos:photosToAdd album:photo.albumId];
            [addingToAlbumPhotos_ addPhotos:photosToAdd album:photo.albumId];
        }
    }

    if (!photosToAdd) {
        RCLog(@"Photo-upload background task %d ended", photoUploadBackgroundTaskID);
        [[UIApplication sharedApplication] endBackgroundTask:photoUploadBackgroundTaskID];
    } else {
        [self startAddToAlbumTask:photosToAdd album:photo.albumId backgroundTaskID:photoUploadBackgroundTaskID];
    }
}


/* NOTE: Because startAddToAlbumTask is called from an NSURLSession completion handler, it should not run longer than 30 seconds, or we risk termination of app while it is uploading in the background (I haven't observed this yet). The reason why we still use a possibly blocking synchronous albumAddPhotos call here is that it startAddToAlbumTask will be triggered by finishing a download, so it is highly unlikely that albumAddPhotos will block because of a connection problem. Also, in the rare case that the app would be terminated, the addition would be resumed on the next startup anyway. The alternative would be to use an NSURLSession task for albumAddPhoto, which is awkward and complex (requires writing the json data to a temporary file).
 */
- (void)startAddToAlbumTask:(NSArray *)photosToAdd album:(int64_t)albumId backgroundTaskID:(UIBackgroundTaskIdentifier)photoUploadBackgroundTaskID
{
    RCLog(@"Adding %d photo(s) to album %lld: %@", photosToAdd.count, albumId, showAlbumUploadingPhotoIds(photosToAdd));
    NSMutableArray *photoIdsToAdd = [[NSMutableArray alloc] init];

    for (AlbumUploadingPhoto *photo in photosToAdd) {
        [photoIdsToAdd addObject:photo.photoId];
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        BOOL photosSuccesfullyAdded = NO;

        while (!photosSuccesfullyAdded) { // keep trying synchronous albumAddPhotos
            @try {
                [shotVibeAPI_ albumAddPhotos:albumId photoIds:[[SLArrayList alloc] initWithInitialArray:photoIdsToAdd]];
                photosSuccesfullyAdded = YES;
            } @catch (SLAPIException *exception) {
                RCLog(@"ERROR: %@\nwhile adding %d photo(s) to album %lld: %@\nRetrying in %.1f seconds.", exception.description, photosToAdd.count, albumId, showAlbumUploadingPhotoIds(photosToAdd), RETRY_TIME);

                [NSThread sleepForTimeInterval:RETRY_TIME];
            }
        }
        RCLog(@"Added %d photo(s) to album %lld: %@", photosToAdd.count, albumId, showAlbumUploadingPhotoIds(photosToAdd));

        [self photosWereAdded:photosToAdd albumId:albumId];

        // Notify album manager that all photos are uploaded, causing a server refresh
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener_ photoAlbumAllPhotosUploaded:albumId];
            RCLog(@"Photo-upload background task %d ended", photoUploadBackgroundTaskID);
            [[UIApplication sharedApplication] endBackgroundTask:photoUploadBackgroundTaskID];
        });
    });
}


// NSArray photos has elements of type AlbumUploadingPhoto
- (void)photosWereAdded:(NSArray *)addedPhotos albumId:(int64_t)albumId
{
    for (AlbumUploadingPhoto *photo in addedPhotos) {
        [photo setUploadStatus:UploadStatus_Stage2PendingOrUploading];
        [self storeUnfinishedUploads]; // TODO: at this point, store new AlbumUploadingPhotos as Stage2Pending in ShotVibeDB
    }

    @synchronized(self) {
        [addingToAlbumPhotos_ removePhotos:addedPhotos album:albumId]; // move from adding to pending second stage
        [pendingStage2Photos_ addObjectsFromArray:addedPhotos];
    }

    [self initiateSecondStateUploadsIfIdle];
}


// In case all low-res photos have been uploaded and added, start uploading the pending stage-2 uploads.
- (void)initiateSecondStateUploadsIfIdle
{
    NSArray *newSecondStagePhotos = @[];

    @synchronized(self) {
        //RCLog(@"photosWereAdded:");
        //RCLog(@"uploadingPhotos_: %@", [uploadingStage1Photos_ description]);
        //RCLog(@"uploadedPhotos_: %@", [uploadedStage1Photos_ description]);
        //RCLog(@"addingPhotos_: %@", [addingToAlbumPhotos_ description]);
        //RCLog(@"pendingSecondStagePhotos_: %@", [pendingStage2Photos_ description]);
        //RCLog(@"uploadingSecondStagePhotos_: %@", [uploadingStage2Photos_ description]);

        int nrOfUnfinishedPhotos = [uploadingStage1Photos_ getAllPhotos].count + [uploadedStage1Photos_ getAllPhotos].count + [addingToAlbumPhotos_  getAllPhotos].count;

        if (nrOfUnfinishedPhotos == 0) { // all low res photos have been uploaded and added, so we can start the full res uploads
            RCLog(@"All queues empty, initiating second-stage uploads");
            newSecondStagePhotos = [NSArray arrayWithArray:pendingStage2Photos_];
            [pendingStage2Photos_ removeAllObjects];
            [uploadingStage2Photos_ addObjectsFromArray:newSecondStagePhotos];
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
    UIBackgroundTaskIdentifier secondStageUploadBackgroundTaskID = [self beginBackgroundTaskWithDescription:@"Second-stage upload"];

    RCLog(@"START second-stage upload for %@", showShortPhotoId(photo.photoId));
    NSString *fullResFilePath = [photo getFullResFilename];

    // Temporarily disable 2nd stage because server is not available
    [shotVibeAPI_ photoUploadAsync:photo.photoId filePath:fullResFilePath isFullRes:YES progressHandler:nil completionHandler:^(NSError *error) {
        if (error) {
            RCLog(@"ERROR %@\nduring second-stage upload for %@\nRetrying in %.1f seconds.", [error localizedDescription], showShortPhotoId(photo.photoId), RETRY_TIME);
            [NSThread sleepForTimeInterval:RETRY_TIME];
            [self startSecondStageUploadTask:photo];
        } else {
            RCLog(@"FINISH second-stage upload for %@", showShortPhotoId(photo.photoId));
            [uploadingStage2Photos_ removeObject:photo];
            [self storeUnfinishedUploads]; // TODO: at this point, remove the AlbumUploadingPhoto photo from ShotVibeDB

            RCLog(@"Second-stage upload background task %d ended", secondStageUploadBackgroundTaskID);
            [[UIApplication sharedApplication] endBackgroundTask:secondStageUploadBackgroundTaskID];
        }
    }];
}


// On init, resume any uploads that hadn't finished when the app last terminated or crashed.
- (void)resumeUnfinishedUploads
{
    NSArray *unfinishedUploads = [self loadUnfinishedUploads];
    RCLog(@"Found %d unfinished uploads", unfinishedUploads.count);
    logUploads(unfinishedUploads);

    // todo: maybe move set db actions to end of calling function

    // No need to notify listeners, since this method is called on init, before any listeners will be present.
    NSMutableArray *unfinishedUploadsWaitingForId = [[NSMutableArray alloc] init];
    NSMutableArray *unfinishedUploadsStage1Uploading = [[NSMutableArray alloc] init];
    NSMutableArray *unfinishedUploadsAddingToAlbum = [[NSMutableArray alloc] init];
    NSMutableArray *unfinishedUploadsStage2PendingOrUploading = [[NSMutableArray alloc] init];

    for (AlbumUploadingPhoto *unfinishedUpload in unfinishedUploads) {
        switch ([unfinishedUpload getUploadStatus]) {
            case UploadStatus_WaitingForId:
                [unfinishedUploadsWaitingForId addObject:unfinishedUpload];
                break;

            case UploadStatus_Stage1Uploading:
                [unfinishedUploadsStage1Uploading addObject:unfinishedUpload];
                break;

            case UploadStatus_AddingToAlbum:
                [unfinishedUploadsAddingToAlbum addObject:unfinishedUpload];
                break;

            case UploadStatus_Stage2PendingOrUploading:
                [unfinishedUploadsStage2PendingOrUploading addObject:unfinishedUpload];
                break;

            default:
                RCLog(@"INTERNAL ERROR: incorrect uploadStatus %d", [unfinishedUpload getUploadStatus]);
                break;
        }
    }


    // 1 Resume photos that did not complete the album addition
    // This one is handled first because activity from the resume code below may in very rare cases interfere with it
    @synchronized(self) { // add all photos to dictionary before calling photosWere added to prevent multiple additions per album
        for (AlbumUploadingPhoto *photo in unfinishedUploadsAddingToAlbum) {
            [uploadingStage1Photos_ addPhoto:photo album:photo.albumId];
        }
    }
    for (AlbumUploadingPhoto *photo in unfinishedUploadsAddingToAlbum) {
        RCLog(@"Resume add to album for photo %@", showShortPhotoId(photo.photoId));

        UIBackgroundTaskIdentifier resumedPhotoAdditionBackgroundTaskID = [self beginBackgroundTaskWithDescription:@"Resumed add-to-album"];

        [self lowResPhotoWasUploaded:photo backgroundTaskID:resumedPhotoAdditionBackgroundTaskID];
    }

    // 2 Resume photos that did not get an id yet
    @synchronized(self) {
        for (AlbumUploadingPhoto *photo in unfinishedUploadsWaitingForId) {
            [uploadingStage1Photos_ addPhoto:photo album:photo.albumId];
            RCLog(@"Resuming request upload id for photo %@", showShortPhotoId(photo.photoId));
        }
    }
    if ([unfinishedUploadsWaitingForId count]) {
        UIBackgroundTaskIdentifier resumedRequestIdsBackgroundTaskID = [self beginBackgroundTaskWithDescription:@"Resumed request for upload ids"];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self uploadPhotosWithoutIds:unfinishedUploadsWaitingForId];
        });

        [[UIApplication sharedApplication] endBackgroundTask:resumedRequestIdsBackgroundTaskID];
    }

    // 3 Resume photos that did not complete the stage 1 upload
    for (AlbumUploadingPhoto *photo in unfinishedUploadsStage1Uploading) {
        RCLog(@"Resume first-stage upload for photo %@", showShortPhotoId(photo.photoId));

        UIBackgroundTaskIdentifier resumedPhotoUploadBackgroundTaskID = [self beginBackgroundTaskWithDescription:@"Resumed first-stage upload"];

        [self startFirstStagePhotoUpload:photo backgroundTaskID:resumedPhotoUploadBackgroundTaskID];
    }

    // 4 Resume photos that did not complete the stage 2 upload
    for (AlbumUploadingPhoto *photo in unfinishedUploadsStage2PendingOrUploading) {
        RCLog(@"Resume second-stage upload for photo %@", showShortPhotoId(photo.photoId));
    }
    @synchronized(self) {
        [pendingStage2Photos_ addObjectsFromArray:unfinishedUploadsStage2PendingOrUploading];
    }
    if ([unfinishedUploadsStage2PendingOrUploading count]) {
        [self initiateSecondStateUploadsIfIdle];
    }
}


// Called by AlbumManager to get the uploading photos that need to be inserted in the album contents.
// Note: the returned array contains AlbumPhotos, not AlbumUploadingPhotos, and stage two photos are ignored
// since these don't show in the GUI as uploading.
// TODO: check GUI code to see what it's doing exactly with these photos
- (NSArray *)getUploadingAlbumPhotos:(int64_t)albumId
{
    NSMutableArray *uploadingPhotosForAlbum = [[NSMutableArray alloc] init];
    for (AlbumUploadingPhoto *photo in [self getAllUploadingPhotos]) {
        //RCLog(@"status is %d", [photo getUploadStatus]);
        if (photo.albumId == albumId && ([photo getUploadStatus] == UploadStatus_WaitingForId || [photo getUploadStatus] == UploadStatus_Stage1Uploading || [photo getUploadStatus] == UploadStatus_AddingToAlbum)) {
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
        NSArray *uploadingStage1 = [uploadingStage1Photos_ getAllPhotos];
        NSArray *uploadedStage1 = [uploadedStage1Photos_ getAllPhotos];
        NSArray *adding = [addingToAlbumPhotos_ getAllPhotos];
        result = [[[[uploadingStage1 arrayByAddingObjectsFromArray:uploadedStage1] arrayByAddingObjectsFromArray:adding] arrayByAddingObjectsFromArray:pendingStage2Photos_] arrayByAddingObjectsFromArray:uploadingStage2Photos_];
    }
    //RCLog(@"getUploadingPhotos: %d uploading photos", result.count);
    return result;
}


#pragma mark - Utility functions

- (UIBackgroundTaskIdentifier)beginBackgroundTaskWithDescription:(NSString *)description
{
    __block UIBackgroundTaskIdentifier backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        RCLog(@"%@ background task %d was forced to end", description, backgroundTaskID);
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskID];
    }];
    RCLog(@"%@ background task %d started", description, backgroundTaskID);
    return backgroundTaskID;
}


NSString * showAlbumUploadingPhotoIds(NSArray *albumUploadingPhotos)
{
    NSString *str = @"Photo id's:";
    for (AlbumUploadingPhoto *photo in albumUploadingPhotos) {
        str = [NSString stringWithFormat:@"%@ %@", str, showShortPhotoId(photo.photoId)];
    }
    return str;
}


/* For simplicity, we store ALL uploading photos EVERY time this method is called, rather than storing them one at a time and updating them in place in the file. As a consequence, we need isFullResSaved to prevent blocking on saves that are not ready yet. This will be remedied once we store the AlbumUploadingPhotos in the database (using the filename as a key, since the id's are not present at the start) */
- (void)storeUnfinishedUploads
{
    NSArray *albumUploadingPhotos = [self getAllUploadingPhotos];
    NSArray *albumUploadingPhotosWithFilename = [albumUploadingPhotos filteredArrayUsingPredicate:
                                                 [NSPredicate predicateWithBlock:^(AlbumUploadingPhoto *photo, NSDictionary *bindings) {
        return [photo isSaved];
    }]];
    RCLog(@"Storing %d unfinished uploads:", [albumUploadingPhotosWithFilename count]);
    logUploads(albumUploadingPhotosWithFilename);
    [NSKeyedArchiver archiveRootObject:albumUploadingPhotosWithFilename toFile:[AlbumUploadingPhoto getUnfinishedUploadsFilePath]];
}


- (NSArray *)loadUnfinishedUploads
{
    return [NSKeyedUnarchiver unarchiveObjectWithFile:[AlbumUploadingPhoto getUnfinishedUploadsFilePath]];
}


static void logUploads(NSArray *albumUploadingPhotos)
{
    for (AlbumUploadingPhoto *photo in albumUploadingPhotos) {
        //RCLog(@"Upload: %@ in album %lld, state %d file:%@", photo.photoId ? showShortPhotoId(photo.photoId) : @"Photo_with_no_ID_yet", photo.albumId, [photo getUploadStatus], [photo getFullResFilename]);
    }
}


@end
