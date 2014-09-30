//
//  IosBackgroundUploadSession.m
//  shotvibe
//
//  Created by raptor on 9/26/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "SL/ArrayList.h"
#import "SL/AuthData.h"
#import "SL/BackgroundUploadSession.h"
#import "SL/ShotVibeAPI.h"

#import "IosBackgroundUploadSession.h"

/*
@interface RunningTask : NSObject

@property (nonatomic, strong) NSURLSessionUploadTask *task;
@property (nonatomic, assign) BOOL canceled;

@end

@implementation RunningTask
@end
 */

@interface IosBackgroundUploadSession () < NSURLSessionDelegate, NSURLSessionTaskDelegate >
@end

@implementation IosBackgroundUploadSession
{
    id<SLBackgroundUploadSession_TaskDataFactory> taskDataFactory_;
    id<SLBackgroundUploadSession_Listener> listener_;

    NSURLSession *session_;

    // This is needed as a workaround for a bug with the NSURLSession behaviour. See its usage for details.
    NSMapTable *startedTasks_;
}

- (id)initWithIdentifier:(NSString *)sessionIdentifier
             shotVibeAPI:(SLShotVibeAPI *)shotVibeAPI
         taskDataFactory:(id<SLBackgroundUploadSession_TaskDataFactory>)taskDataFactory
                listener:(id<SLBackgroundUploadSession_Listener>)listener
{
    self = [super init];
    if (self) {
        taskDataFactory_ = taskDataFactory;
        listener_ = listener;

        startedTasks_ = [[NSMapTable alloc] initWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableStrongMemory capacity:8];

        NSString *authToken = [[shotVibeAPI getAuthData] getAuthToken];

        session_ = [self createSession:sessionIdentifier authToken:authToken];
    }
    return self;
}


- (NSURLSession *)createSession:(NSString *)sessionIdentifier
                      authToken:(NSString *)authToken
{
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration
                                         backgroundSessionConfiguration:sessionIdentifier];
    config.URLCache = nil;
    config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    config.HTTPMaximumConnectionsPerHost = 2;

    NSString *authHeaderVal = [NSString stringWithFormat:@"Token %@", authToken];
    config.HTTPAdditionalHeaders = @{
        @"Content-Type" : @"application/octet-stream",
        @"Authorization" : authHeaderVal
    };

    return [NSURLSession sessionWithConfiguration:config
                                         delegate:self
                                    delegateQueue:nil];
}


- (void)startUploadTaskWithId:(id)taskData
                 withNSString:(NSString *)url
                 withNSString:(NSString *)uploadFile
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"PUT"];
    NSURLSessionUploadTask *task = [session_ uploadTaskWithRequest:request
                                                          fromFile:[NSURL fileURLWithPath:uploadFile]];

    NSString *taskDataSerialized = [taskDataFactory_ serializeWithId:taskData];

    task.taskDescription = taskDataSerialized;

    NSLog(@"Starting upload of %@ to %@", uploadFile, url);

    [task resume];

    // Store the fact that this task is started
    [startedTasks_ setObject:task forKey:taskDataSerialized];
}


- (void)cancelTaskWithSLBackgroundUploadSession_Task:(SLBackgroundUploadSession_Task *)task
{
    IosBackgroundUploadSession_Task *realTask = (IosBackgroundUploadSession_Task *)task;
    [[realTask getTask] cancel];
}


- (void)processCurrentTasksWithSLBackgroundUploadSession_TaskProcessor:(id<SLBackgroundUploadSession_TaskProcessor>)taskProcessor
{
    [session_ getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        NSMutableArray *currentTasks = [[NSMutableArray alloc] initWithCapacity:uploadTasks.count];

        // NSURLSession has a bug: tasks that were very recently created(started) do not show up in the
        // `uploadTasks` array. So we manually keep track of all started tasks in the `startedTasks_`
        // array. When a task does show up in `uploadTasks` we remove it from `startedTasks_` (do prevent
        // reporting it as a duplicate, and to free memory)

        for (NSURLSessionUploadTask * uploadTask in uploadTasks) {
            if (uploadTask.state == NSURLSessionTaskStateRunning) {
                [startedTasks_ removeObjectForKey:uploadTask.taskDescription];

                id taskData = [taskDataFactory_ deserializeWithNSString:uploadTask.taskDescription];

                IosBackgroundUploadSession_Task *task = [[IosBackgroundUploadSession_Task alloc] initWithTask:uploadTask
                                                                                                     taskData:taskData];
                [currentTasks addObject:task];
            }
        }

        // Report the tasks that we are manually keeping track of
        for (NSString * startedTask in startedTasks_) {
            NSLog(@"Found startedTask: %@", startedTask);
            id taskData = [taskDataFactory_ deserializeWithNSString:startedTask];

            NSURLSessionUploadTask *uploadTask = [startedTasks_ objectForKey:startedTask];

            IosBackgroundUploadSession_Task *task = [[IosBackgroundUploadSession_Task alloc] initWithTask:uploadTask
                                                                                                 taskData:taskData];
            [currentTasks addObject:task];
        }

        [taskProcessor processTasksWithJavaUtilList:[[SLArrayList alloc] initWithInitialArray:currentTasks]];
    }];
}


/* Sent periodically to notify the delegate of upload progress.  This
 * information is also available as properties of the task.
 */
- (void)          URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
             didSendBodyData:(int64_t)bytesSent
              totalBytesSent:(int64_t)totalBytesSent
    totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    // TODO don't report an event for a canceled task

    id taskData = [taskDataFactory_ deserializeWithNSString:task.taskDescription];

    [listener_ onTaskUploadProgressWithId:taskData
                                 withLong:totalBytesSent
                                 withLong:totalBytesExpectedToSend];
}


/* Sent as the last message related to a specific task.  Error may be
 * nil, which implies that no error occurred and this task is complete.
 */
- (void)      URLSession:(NSURLSession *)session
                    task:(NSURLSessionTask *)task
    didCompleteWithError:(NSError *)error
{
    // TODO don't report an event for a canceled task

    id taskData = [taskDataFactory_ deserializeWithNSString:task.taskDescription];

    [startedTasks_ removeObjectForKey:task.taskDescription];

    SLBackgroundUploadSession_FinishedTask *finishedTask;
    if (error) {
        finishedTask = [[SLBackgroundUploadSession_FinishedTask alloc] initWithId:taskData withId:error];
    } else {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        finishedTask = [[SLBackgroundUploadSession_FinishedTask alloc] initWithId:taskData withInt:response.statusCode];
    }

    [listener_ onTaskUploadFinishedWithSLBackgroundUploadSession_FinishedTask:finishedTask];
}


@end


@implementation IosBackgroundUploadSession_Factory
{
    NSString *sessionIdentifier_;
    SLShotVibeAPI *shotVibeAPI_;
}

- (id)initWithSessionIdentifier:(NSString *)sessionIdentifier shotVibeAPI:(SLShotVibeAPI *)shotVibeAPI
{
    self = [super init];
    if (self) {
        sessionIdentifier_ = sessionIdentifier;
        shotVibeAPI_ = shotVibeAPI;
    }
    return self;
}


- (id<SLBackgroundUploadSession>)startSessionWithSLBackgroundUploadSession_TaskDataFactory:(id<SLBackgroundUploadSession_TaskDataFactory>)taskDataFactory
                                                    withSLBackgroundUploadSession_Listener:(id<SLBackgroundUploadSession_Listener>)listener
{
    return [[IosBackgroundUploadSession alloc] initWithIdentifier:sessionIdentifier_
                                                      shotVibeAPI:shotVibeAPI_
                                                  taskDataFactory:taskDataFactory
                                                         listener:listener];
}


@end

@implementation IosBackgroundUploadSession_Task
{
    NSURLSessionUploadTask *task_;
    id taskData_;
}

- (id)initWithTask:(NSURLSessionUploadTask *)task taskData:(id)taskData
{
    self = [super init];
    if (self) {
        task_ = task;
        taskData_ = taskData;
    }
    return self;
}


- (NSURLSessionUploadTask *)getTask
{
    return task_;
}


- (id)getTaskData
{
    return taskData_;
}


- (BOOL)isUploadInProgress
{
    return task_.countOfBytesSent > 0;
}


@end
