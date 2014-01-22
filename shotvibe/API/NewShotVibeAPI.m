//
//  NewShotVibeAPI.m
//  ShotVibeUploadTest
//
//  Created by martijn on 21-01-14.
//  Copyright (c) 2014 Oblomov Systems. All rights reserved.
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
    //NSLog(@"Session handler: task %lu completed", (unsigned long)task.taskIdentifier);


    UploadTaskDelegate *delegateForTask = [self getDelegateForTask:task];

    if (delegateForTask) {
        delegateForTask.completionHandler();
    } else {
        RCLog(@"No task-specific delegate for task %d:%@", task.taskIdentifier, task.taskDescription);
        // TODO: need to restore these on app init
    }

    if (error) {
        NSLog(@"Error in task %lu\n%@", (unsigned long)task.taskIdentifier, [error localizedDescription]);
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
    NSLog(@"didBecomeInvalidWithError");
}


- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
    NSLog(@"didReceiveChallenge");
    // TODO: handle authentication here?
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, NULL);
}


// TODO: also implement background method in AppDelegate
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    NSLog(@"URLSessionDidFinishEventsForBackgroundURLSession");
}


@end



@interface NewShotVibeAPI ()

@property (atomic, strong) NSURLSession *uploadNSURLSession;

@end


@implementation NewShotVibeAPI {
    NSString *baseURL_;
}

static NSString *const kSessionId = @"shotvibe.uploadSession";

- (id)initWithBaseURL:(NSString *)baseURL oldShotVibeAPI:(ShotVibeAPI *)oldShotVibeAPI
{
    self = [super init];

    if (self) {
        baseURL_ = baseURL;

        UploadSessionDelegate *uploadListener = [[UploadSessionDelegate alloc] init];

        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfiguration:kSessionId];
        //NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];

        // TODO: Put authorization in tasks because session may be created before app is authorized.
        NSString *authToken = [@"Token " stringByAppendingString:oldShotVibeAPI.authData.authToken];
        config.HTTPAdditionalHeaders = @{
            @"Authorization" : authToken
        };

        _uploadNSURLSession = [NSURLSession sessionWithConfiguration:config delegate:uploadListener delegateQueue:nil];
        // TODO: set queue?

        [_uploadNSURLSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
            RCLog(@"NSURLSession with id %@, nr of current upload tasks: %d\n", kSessionId, [uploadTasks count]);
            for (NSURLSessionUploadTask *task in uploadTasks) {
                RCLog(@"  UploadTask #%d", task.taskIdentifier);
            }
        }];
    }
    return self;
}


// TODO: handle for iOS < 7
- (void)photoUploadAsync:(NSString *)photoId filePath:(NSString *)filePath progressHandler:(ProgressHandlerType)progressHandler completionHandler:(CompletionHandlerType)completionHandler
{
    NSLog(@"%@", filePath);
    NSURL *uploadURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/photos/upload/%@/", baseURL_, photoId]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:uploadURL];
    [request setHTTPMethod:@"PUT"];
    NSURL *photoFileUrl = [NSURL fileURLWithPath:filePath];
    NSURLSessionUploadTask *uploadTask = [self.uploadNSURLSession uploadTaskWithRequest:request fromFile:photoFileUrl];

    [((UploadSessionDelegate *)[self.uploadNSURLSession delegate])setDelegateForTask:uploadTask progressHandler:progressHandler completionHandler:completionHandler];
    // TODO: need to access delegate type safe. Maybe subclass uploadTask?
    [uploadTask resume];
}


@end
