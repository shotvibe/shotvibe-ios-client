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

-(void) setDelegateForTask:(NSURLSessionTask *)task progressHandler:(ProgressHandlerType)progressHandler completionHandler:(CompletionHandlerType)completionHandler;

-(UploadTaskDelegate *)getDelegateForTask:(NSURLSessionTask *)task;

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


-(void) setDelegateForTask:(NSURLSessionTask *)task progressHandler:(ProgressHandlerType)progressHandler completionHandler:(CompletionHandlerType)completionHandler
{
    UploadTaskDelegate *taskDelegate = [[UploadTaskDelegate alloc] initWithProgress:progressHandler completion:completionHandler];
    [taskSpecificDelegates_ setObject:taskDelegate forKey:[NSNumber numberWithLongLong:task.taskIdentifier]];
}

-(UploadTaskDelegate *)getDelegateForTask:(NSURLSessionTask *)task
{
    return [taskSpecificDelegates_ objectForKey:[NSNumber numberWithLongLong:task.taskIdentifier]];
}
// TODO: synchronize, remove after task, and remove all after session tasks finish (thread safe?)


#pragma mark - NSURLSessionTaskDelegate Methods


-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    //NSLog(@"Session handler: task %lu completed", (unsigned long)task.taskIdentifier);

    [self getDelegateForTask:task].completionHandler();

    if (error) {
        NSLog(@"Error in task %lu\n%@", (unsigned long)task.taskIdentifier,[error localizedDescription]);
    }
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    [self getDelegateForTask:task].progressHandler(totalBytesSent, totalBytesExpectedToSend);

}

#pragma mark - NSURLSessionDelegate Methods


// TODO: implement these
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{

}


- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{

}

// TODO: also implement background method in AppDelegate
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{

}

@end




@interface NewShotVibeAPI()

@property (atomic,strong) NSURLSession *uploadNSURLSession;

@end


@implementation NewShotVibeAPI

// Duplicated, since it is not accessible from ShotVibeAPI.m
static NSString *const BASE_URL = @"http://oblomov.local:8250";
//static NSString *const BASE_URL = @"http://localhost:8250";

static NSString * const kSessionId = @"shotvibe.uploadSession";

- (id)init
{
    self = [super init];

    if (self) {
        UploadSessionDelegate *uploadListener = [[UploadSessionDelegate alloc] init];

        //NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfiguration:kSessionId];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];

        config.HTTPAdditionalHeaders = @{@"Authorization": @"<auth token>"}; // todo: set authorization

        _uploadNSURLSession = [NSURLSession sessionWithConfiguration:config delegate:uploadListener delegateQueue:nil];
        // TODO: set queue?
    }
    return self;
}



// TODO: handle for iOS < 7
- (void)photoUploadAsync:(NSString *)photoId filePath:(NSString *)filePath progressHandler:(ProgressHandlerType)progressHandler completionHandler:(CompletionHandlerType)completionHandler
{
    NSLog(@"%@", filePath);
    NSURL *uploadURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/photos/upload/%@/", BASE_URL, photoId]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:uploadURL];
    [request setHTTPMethod:@"PUT"];
    NSURL *photoFileUrl = [NSURL fileURLWithPath:filePath];
    NSURLSessionUploadTask *uploadTask = [self.uploadNSURLSession uploadTaskWithRequest:request fromFile:photoFileUrl ];

    [((UploadSessionDelegate *)[self.uploadNSURLSession delegate]) setDelegateForTask:uploadTask progressHandler:progressHandler completionHandler:completionHandler];
    // TODO: need to access delegate type safe. Maybe subclass uploadTask?
    [uploadTask resume];
}



@end
