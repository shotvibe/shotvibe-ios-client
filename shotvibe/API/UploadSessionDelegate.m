//
//  UploadDelegate.m
//  shotvibe
//
//  Created by martijn on 23-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "UploadSessionDelegate.h"
#import "ShotVibeAppDelegate.h"

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
    //RCLog(@"Session handler: task %d completed", task.taskIdentifier);

    UploadTaskDelegate *delegateForTask = [self getDelegateForTask:task];

    if (delegateForTask) {
        if (delegateForTask.completionHandler) { // could be nil, if there's no completionHandler handler for this task
            delegateForTask.completionHandler();
        }
    } else {
        RCLog(@"No task-specific delegate for task %d:%@", task.taskIdentifier, task.taskDescription);
        // TODO: need to restore these on app init
    }

    if (error) {
        RCLog(@"ERROR: Client-side error in task %d\n%@", task.taskIdentifier, [error localizedDescription]);
    }

    // No kidding, the only way to get server-side errors (which are not reported through `error`)
    // is to cast the response and access the statusCode..
    NSInteger statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
    if (statusCode != 200) {
        RCLog(@"ERROR: Server-side error %d in task %d", statusCode, task.taskIdentifier);
    }
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    UploadTaskDelegate *delegateForTask = [self getDelegateForTask:task];

    if (delegateForTask) {
        if (delegateForTask.progressHandler) { // could be nil, if there's no progress handler for this task
            delegateForTask.progressHandler(totalBytesSent, totalBytesExpectedToSend);
        }
    } else {
        RCLog(@"ERROR: No task-specific delegate for task %d:%@", task.taskIdentifier, task.taskDescription);
        // TODO: need to restore these on app init
    }
}


#pragma mark - NSURLSessionDelegate Methods


- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    RCLog(@"ERROR: didBecomeInvalidWithError"); // this should not occur
}


// No need for didReceiveChallenge: since we set the authentication token in the url request for the upload task

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    RCLog(@"URLSessionDidFinishEventsForBackgroundURLSession");
    ShotVibeAppDelegate *appDelegate = [ShotVibeAppDelegate sharedDelegate];

    if (appDelegate.uploadSessionCompletionHandler) {
        // In case the app was not in the foreground, after the task delegate calls have been completed,
        // call the completion handler that was set by the ShotVibeAppDelegate on handleEventsForBackgroundURLSession
        RCLog(@"Calling stored completion handler");
        void (^ completionHandler)() = appDelegate.uploadSessionCompletionHandler;
        appDelegate.uploadSessionCompletionHandler = nil;
        completionHandler();
    }
}


@end
