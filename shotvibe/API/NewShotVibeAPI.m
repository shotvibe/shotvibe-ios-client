//
//  NewShotVibeAPI.m
//  shotvibe
//
//  Created by Oblosys on 21-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "NewShotVibeAPI.h"
#import "SL/ArrayList.h"
#import "SL/APIException.h"

@implementation NewShotVibeAPI {
    NSString *baseURL_;
    ShotVibeAPI *oldShotVibeAPI_;

    dispatch_queue_t uploadQueue_; // Queue for uploading photos on iOS < 7, where NSURLSession is not available

    NSOperationQueue *completionQueue_; // Operation queue for executing NSURLSession completion handlers

    NSURLSession *uploadNSURLSession_;
}

NSString *const kUploadSessionId = @"shotvibe.uploadSession";

- (id)initWithBaseURL:(NSString *)baseURL oldShotVibeAPI:(ShotVibeAPI *)oldShotVibeAPI
{
    self = [super init];

    if (self) {
        baseURL_ = baseURL;
        oldShotVibeAPI_ = oldShotVibeAPI;

        UploadSessionDelegate *uploadListener = [[UploadSessionDelegate alloc] init];

        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfiguration:kUploadSessionId];
        //NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];

        completionQueue_ = [[NSOperationQueue alloc] init];

        uploadNSURLSession_ = [NSURLSession sessionWithConfiguration:config delegate:uploadListener delegateQueue:completionQueue_];

        // *INDENT-OFF* Uncrustify @""/cast problem https://github.com/shotvibe/shotvibe-ios-client/issues/260
        [uploadNSURLSession_ getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
            RCLog(@"NSURLSession with id %@, nr of current upload tasks: %d\n", kUploadSessionId, [uploadTasks count]);
            for (NSURLSessionUploadTask *task in uploadTasks) {
                RCLog(@"Cancelling upload task #%d", task.taskIdentifier);
                [task cancel];
                /* We currently don't support tasks that persist after the app was terminated, as this requires us to restore the task-specific delegates and upload and uploaded queues.
                 For now, background tasks finishing while the app was terminated, or that were still running when the
                 app started will be canceled.
                 TODO: provide a fail safe similar to Android, or resurrect the previous tasks
                 */
            }
        }];
        // *INDENT-ON*
        uploadQueue_ = dispatch_queue_create(NULL, NULL);
    }
    return self;
}


// TODO: cleanup and refactor when combining with old ShotVibeAPI

static const NSTimeInterval RETRY_TIME = 5;

- (void)photoUploadAsync:(NSString *)photoId filePath:(NSString *)filePath isFullRes:(BOOL)isFullRes progressHandler:(ProgressHandlerType)progressHandler completionHandler:(CompletionHandlerType)completionHandler
{
    if (!uploadNSURLSession_) { // if there's no session, we're on iOS < 7
        RCLog(@"Starting asynchronous upload task as UIBackgroundTask (max 10 minutes)");
        [self photoUploadAsyncNoSession:photoId filePath:filePath isFullRes:isFullRes progressHandler:progressHandler completionHandler:completionHandler];
    } else {
        RCLog(@"Starting asynchronous upload task in NSURLSession");
        NSURL *uploadURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/photos/upload/%@/%@", baseURL_, photoId, isFullRes ? @"original/":@""]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:uploadURL];
        [request setHTTPMethod:@"PUT"];
        if (oldShotVibeAPI_.authData != nil) {
            [request setValue:[@"Token " stringByAppendingString : oldShotVibeAPI_.authData.authToken] forHTTPHeaderField:@"Authorization"];
        } else { // This is a serious error; it should not be possible to start tasks without authentication.
            RCLog(@"ERROR: upload task started without authentication.\nFile: %@", filePath);
        }

        NSURL *photoFileUrl = [NSURL fileURLWithPath:filePath];

        NSURLSessionUploadTask *uploadTask = [uploadNSURLSession_ uploadTaskWithRequest:request fromFile:photoFileUrl];

        [((UploadSessionDelegate *)[uploadNSURLSession_ delegate])setDelegateForTask : uploadTask progressHandler : progressHandler completionHandler : completionHandler];

        [uploadTask resume];
    }
}


// Asynchronous upload for iOS <7, when NSURLSession is not available
// Note: callee must guarantee this function can execute in the background
- (void)photoUploadAsyncNoSession:(NSString *)photoId filePath:(NSString *)filePath isFullRes:(BOOL)isFullRes progressHandler:(ProgressHandlerType)progressHandler completionHandler:(CompletionHandlerType)completionHandler
{
    // *INDENT-OFF* Uncrustify block problem: https://github.com/bengardner/uncrustify/pull/233
    dispatch_async(uploadQueue_, ^{ // TODO: also want parallelism here?
        BOOL photoSuccesfullyUploaded = NO;
        while (!photoSuccesfullyUploaded) {
            NSError *error;
            photoSuccesfullyUploaded = [oldShotVibeAPI_ photoUpload:photoId filePath:filePath isFullRes:(BOOL)isFullRes uploadProgress:^(int bytesUploaded, int bytesTotal) {
                progressHandler(bytesUploaded, bytesTotal);
            } withError:&error];

            if (!photoSuccesfullyUploaded) {
                RCLog(@"Error uploading photo (photoId: %@):\n%@", photoId, [error description]);
                [NSThread sleepForTimeInterval:RETRY_TIME];
            }
        }
        completionHandler();
    });
    // *INDENT-ON*
}


- (void)albumAddPhotosAsync:(int64_t)albumId photoIds:(NSArray *)photoIds completionHandler:(CompletionHandlerType)completionHandler
{
    if (!uploadNSURLSession_) { // if there's no session, we're on iOS < 7
        RCLog(@"Starting asynchronous add-photos task as UIBackgroundTask (max 10 minutes)");
        [self albumAddPhotosAsyncNoSession:albumId photoIds:photoIds completionHandler:completionHandler];
    } else {
        RCLog(@"Starting asynchronous add-photos task in NSURLSession");

        // NOTE: duplicated code from ShotVibeAPI albumAddPhotos
        NSMutableArray *photosArray = [[NSMutableArray alloc] init];
        for (NSString *photoId in photoIds) {
            NSDictionary *photoObj = [NSDictionary dictionaryWithObjectsAndKeys:
                                      photoId, @"photo_id",
                                      nil];
            [photosArray addObject:photoObj];
        }

        NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:
                              photosArray, @"add_photos",
                              nil];

        NSError *jsonError;

        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonError];

        NSAssert(jsonData != nil, @"Error serializing JSON data: %@", [jsonError localizedDescription]);
        // End of duplicated code

        NSURL *uploadURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/albums/%lld/", baseURL_, albumId]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:uploadURL];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        if (oldShotVibeAPI_.authData != nil) {
            [request setValue:[@"Token " stringByAppendingString : oldShotVibeAPI_.authData.authToken] forHTTPHeaderField:@"Authorization"];
        } else { // This is a serious error; it should not be possible to start tasks without authentication.
            RCLog(@"ERROR: albumAddPhotos task started without authentication.\nAlbum: %lld", albumId);
        }

        // We need to save the request body to a file, since only tasks using files are allowed in the background
        NSString *jsonDataFilePath = [self createTempFileWithPrefix:@"albumAddPhotosRequestData"];
        [jsonData writeToFile:jsonDataFilePath atomically:YES];
        NSURL *jsonDataUrl = [NSURL fileURLWithPath:jsonDataFilePath];

        NSURLSessionUploadTask *uploadTask = [uploadNSURLSession_ uploadTaskWithRequest:request fromFile:jsonDataUrl];

        [((UploadSessionDelegate *)[uploadNSURLSession_ delegate])setDelegateForTask : uploadTask progressHandler : nil completionHandler : completionHandler];
        [uploadTask resume];
        RCLog(@"Started asynchronous add-photos task in NSURLSession");
    }
}


// Asynchronous add to album for iOS <7, when NSURLSession is not available
// Note: callee must guarantee this function can execute in the background
- (void)albumAddPhotosAsyncNoSession:(int64_t)albumId photoIds:(NSArray *)photoIds completionHandler:(CompletionHandlerType)completionHandler
{
    // *INDENT-OFF* Uncrustify block problem: https://github.com/bengardner/uncrustify/pull/233
    dispatch_async(uploadQueue_, ^{ // TODO: also want parallelism here?
        BOOL photosSuccesfullyAdded = NO;
        // TODO: this loop is not okay for background thread


        while (!photosSuccesfullyAdded) {
            @try {
                [oldShotVibeAPI_ albumAddPhotos:albumId photoIds:[[SLArrayList alloc] initWithInitialArray:[NSMutableArray arrayWithArray:photoIds]]];
                photosSuccesfullyAdded = YES;
            }
            @catch (SLAPIException *exception) {
                RCLog(@"Error adding photos to album: %lld %@", albumId, exception.description);
                [NSThread sleepForTimeInterval:RETRY_TIME];
            }
        }


        completionHandler();
    });
    // *INDENT-ON*
}


- (NSString *)createTempFileWithPrefix:prefix
{
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *uniqueFileName = [NSString stringWithFormat:@"%@_%@", prefix, guid];

    return [NSTemporaryDirectory() stringByAppendingPathComponent:uniqueFileName];
}


@end
