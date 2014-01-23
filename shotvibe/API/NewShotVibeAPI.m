//
//  NewShotVibeAPI.m
//  shotvibe
//
//  Created by Oblosys on 21-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "NewShotVibeAPI.h"

@interface NewShotVibeAPI ()

@property (nonatomic, strong) NSURLSession *uploadNSURLSession;

@end


@implementation NewShotVibeAPI {
    NSString *baseURL_;
    ShotVibeAPI *oldShotVibeAPI_;

    dispatch_queue_t uploadQueue_;
}

static NSString *const kSessionId = @"shotvibe.uploadSession";

- (id)initWithBaseURL:(NSString *)baseURL oldShotVibeAPI:(ShotVibeAPI *)oldShotVibeAPI
{
    self = [super init];

    if (self) {
        baseURL_ = baseURL;
        oldShotVibeAPI_ = oldShotVibeAPI;

        UploadSessionDelegate *uploadListener = [[UploadSessionDelegate alloc] init];

        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfiguration:kSessionId];
        //NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];

        _uploadNSURLSession = [NSURLSession sessionWithConfiguration:config delegate:uploadListener delegateQueue:nil];
        // TODO: set queue?
        // *INDENT-OFF* Uncrustify @""/cast problem https://github.com/shotvibe/shotvibe-ios-client/issues/260
        [_uploadNSURLSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
            RCLog(@"NSURLSession with id %@, nr of current upload tasks: %d\n", kSessionId, [uploadTasks count]);
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


static const NSTimeInterval RETRY_TIME = 5;

- (void)photoUploadAsync:(NSString *)photoId filePath:(NSString *)filePath progressHandler:(ProgressHandlerType)progressHandler completionHandler:(CompletionHandlerType)completionHandler
{
    if (!self.uploadNSURLSession) { // if there's no session, we're on iOS < 7
        RCLog(@"Starting asynchronous upload task as UIBackgroundTask (max 10 minutes)");
        [self photoUploadAsyncNoSession:photoId filePath:filePath progressHandler:progressHandler completionHandler:completionHandler];
    } else {
        RCLog(@"Starting asynchronous upload task in NSURLSession");
        NSURL *uploadURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/photos/upload/%@/", baseURL_, photoId]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:uploadURL];
        [request setHTTPMethod:@"PUT"];
        if (oldShotVibeAPI_.authData != nil) {
            [request setValue:[@"Token " stringByAppendingString : oldShotVibeAPI_.authData.authToken] forHTTPHeaderField:@"Authorization"];
        } else { // This is a serious error; it should not be possible to start tasks without authentication.
            RCLog(@"ERROR: upload task started without authentication.\nFile: %@", filePath);
        }

        NSURL *photoFileUrl = [NSURL fileURLWithPath:filePath];

        NSURLSessionUploadTask *uploadTask = [self.uploadNSURLSession uploadTaskWithRequest:request fromFile:photoFileUrl];

        [((UploadSessionDelegate *)[self.uploadNSURLSession delegate])setDelegateForTask : uploadTask progressHandler : progressHandler completionHandler : completionHandler];
        // TODO: need to access delegate type safe. Maybe subclass uploadTask?
        [uploadTask resume];
    }
}


// Asynchronous upload for iOS <7, when NSURLSession is not available
// Note: callee must guarantee this function can execute in the background
- (void)photoUploadAsyncNoSession:(NSString *)photoId filePath:(NSString *)filePath progressHandler:(ProgressHandlerType)progressHandler completionHandler:(CompletionHandlerType)completionHandler
{
    // *INDENT-OFF* Uncrustify block problem: https://github.com/bengardner/uncrustify/pull/233
    dispatch_async(uploadQueue_, ^{ // TODO: also want parallelism here?
        BOOL photoSuccesfullyUploaded = NO;
        while (!photoSuccesfullyUploaded) {
            NSError *error;
            photoSuccesfullyUploaded = [oldShotVibeAPI_ photoUpload:photoId filePath:filePath uploadProgress:^(int bytesUploaded, int bytesTotal) {
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


@end
