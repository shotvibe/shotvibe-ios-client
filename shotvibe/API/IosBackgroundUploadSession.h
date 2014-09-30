//
//  IosBackgroundUploadSession.h
//  shotvibe
//
//  Created by raptor on 9/26/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "SL/BackgroundUploadSession.h"

@interface IosBackgroundUploadSession : NSObject < SLBackgroundUploadSession >

- (id)initWithIdentifier:(NSString *)sessionIdentifier
             shotVibeAPI:(SLShotVibeAPI *)shotVibeAPI
         taskDataFactory:(id<SLBackgroundUploadSession_TaskDataFactory>)taskDataFactory
                listener:(id<SLBackgroundUploadSession_Listener>)listener;

- (void)startUploadTaskWithId:(id)taskData
                 withNSString:(NSString *)url
                 withNSString:(NSString *)uploadFile;

- (void)cancelTaskWithSLBackgroundUploadSession_Task:(SLBackgroundUploadSession_Task *)task;

- (void)processCurrentTasksWithSLBackgroundUploadSession_TaskProcessor:(id<SLBackgroundUploadSession_TaskProcessor>)taskProcessor;


@end


@interface IosBackgroundUploadSession_Factory : NSObject < SLBackgroundUploadSession_Factory >

- (id)initWithSessionIdentifier:(NSString *)sessionIdentifier shotVibeAPI:(SLShotVibeAPI *)shotVibeAPI;

- (id<SLBackgroundUploadSession>)startSessionWithSLBackgroundUploadSession_TaskDataFactory:(id<SLBackgroundUploadSession_TaskDataFactory>)taskDataFactory
                                                    withSLBackgroundUploadSession_Listener:(id<SLBackgroundUploadSession_Listener>)listener;

@end


@interface IosBackgroundUploadSession_Task : SLBackgroundUploadSession_Task

- (id)initWithTask:(NSURLSessionUploadTask *)task taskData:(id)taskData;

- (NSURLSessionUploadTask *)getTask;

- (id)getTaskData;

- (BOOL)isUploadInProgress;

@end
