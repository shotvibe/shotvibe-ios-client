//
//  NewShotVibeAPI.m
//  ShotVibeUploadTest
//
//  Created by Oblosys on 21-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "NewShotVibeAPI.h"

@interface UploadTaskDelegate : NSObject

@property (nonatomic, copy) ProgressHandlerType progressHandler;

@property (nonatomic, copy) CompletionHandlerType completionHandler;

- (id)initWithProgress:(ProgressHandlerType)progressHandler completion:(CompletionHandlerType)completionHandler;

@end

@implementation UploadTaskDelegate

- (id)initWithProgress:(ProgressHandlerType)progressHandler completion:(CompletionHandlerType)completionHandler
{
    self = [super init];

    if (self) {
        _progressHandler = progressHandler;
        _completionHandler = completionHandler;
    }

    return self;
}


@end


@interface UploadSessionDelegate : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate>

- (void)setDelegateForTask:(NSURLSessionTask *)task progressHandler:(ProgressHandlerType)progressHandler completionHandler:(CompletionHandlerType)completionHandler;

- (UploadTaskDelegate *)getDelegateForTask:(NSURLSessionTask *)task;

@end

@implementation UploadSessionDelegate {
    NSMutableDictionary *taskSpecificDelegates_; // (NSUInteger)taskIdentifier -> UploadTaskDelegate
    // Dictionary to store the task-specific delegates, indexed by the task identifier
}

- (id)init
{
    self = [super init];

    if (self) {
        taskSpecificDelegates_ = [[NSMutableDictionary alloc] init];
    }
    return self;
}


- (void)setDelegateForTask:(NSURLSessionTask *)task progressHandler:(ProgressHandlerType)progressHandler completionHandler:(CompletionHandlerType)completionHandler
{
    UploadTaskDelegate *taskDelegate = [[UploadTaskDelegate alloc] initWithProgress:progressHandler completion:completionHandler];
    [taskSpecificDelegates_ setObject:taskDelegate forKey:[NSNumber numberWithLongLong:task.taskIdentifier]];
}


- (UploadTaskDelegate *)getDelegateForTask:(NSURLSessionTask *)task
{
    return [taskSpecificDelegates_ objectForKey:[NSNumber numberWithLongLong:task.taskIdentifier]];
} // TODO: synchronize, remove after task, and remove all after session tasks finish (thread safe?)


#pragma mark - NSURLSessionTaskDelegate Methods


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    //RCLog(@"Session handler: task %lu completed", (unsigned long)task.taskIdentifier);


    UploadTaskDelegate *delegateForTask = [self getDelegateForTask:task];

    if (delegateForTask) {
        delegateForTask.completionHandler();
    } else {
        RCLog(@"No task-specific delegate for task %d:%@", task.taskIdentifier, task.taskDescription);
        // TODO: need to restore these on app init
    }

    if (error) {
        RCLog(@"Error in task %lu\n%@", (unsigned long)task.taskIdentifier, [error localizedDescription]);
    }
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    UploadTaskDelegate *delegateForTask = [self getDelegateForTask:task];

    if (delegateForTask) {
        delegateForTask.progressHandler(totalBytesSent, totalBytesExpectedToSend);
    } else {
        RCLog(@"No task-specific delegate for task %d:%@", task.taskIdentifier, task.taskDescription);
        // TODO: need to restore these on app init
    }
}


#pragma mark - NSURLSessionDelegate Methods


// TODO: implement these
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    RCLog(@"didBecomeInvalidWithError");
}


// No need for didReceiveChallenge: since we set the authentication token in the url request for the upload task


// TODO: also implement background method in AppDelegate
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    RCLog(@"URLSessionDidFinishEventsForBackgroundURLSession");
}


@end



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
                RCLog(@"  UploadTask #%d", task.taskIdentifier);
            }
        }];
        // *INDENT-ON*
        uploadQueue_ = dispatch_queue_create(NULL, NULL);
    }
    return self;
}


const NSTimeInterval RETRY_TIME = 5;

- (void)photoUploadAsync:(NSString *)photoId filePath:(NSString *)filePath progressHandler:(ProgressHandlerType)progressHandler completionHandler:(CompletionHandlerType)completionHandler
{
    if (!self.uploadNSURLSession) { // if there's no session, we're on iOS < 7
        [self photoUploadAsyncNoSession:photoId filePath:filePath progressHandler:progressHandler completionHandler:completionHandler];
    } else {
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
