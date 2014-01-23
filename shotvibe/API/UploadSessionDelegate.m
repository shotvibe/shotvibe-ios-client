//
//  UploadDelegate.m
//  shotvibe
//
//  Created by martijn on 23-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "UploadSessionDelegate.h"

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
