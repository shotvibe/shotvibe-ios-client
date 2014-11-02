//
//  IosBackgroundTaskManager.m
//  shotvibe
//
//  Created by raptor on 10/5/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "IosBackgroundTaskManager.h"


@interface IosBackgroundTask : NSObject <SLBackgroundTaskManager_BackgroundTask>

- (id)initWithUIBackgroundTaskIdentifier:(UIBackgroundTaskIdentifier)identifier;

@end


@implementation IosBackgroundTask
{
    UIBackgroundTaskIdentifier identifier_;
}

- (id)initWithUIBackgroundTaskIdentifier:(UIBackgroundTaskIdentifier)identifier
{
    self = [super init];
    if (self) {
        identifier_ = identifier;
    }
    return self;
}


- (void)reportFinished
{
    [[UIApplication sharedApplication] endBackgroundTask:identifier_];
}


@end

@implementation IosBackgroundTaskManager


- (id<SLBackgroundTaskManager_BackgroundTask>)beginBackgroundTaskWithSLBackgroundTaskManager_ExpirationHandler:(id<SLBackgroundTaskManager_ExpirationHandler>)expirationHandler
{
    UIBackgroundTaskIdentifier identifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (expirationHandler != nil) {
            [expirationHandler onAppWillTerminate];
        }
    }];

    return [[IosBackgroundTask alloc] initWithUIBackgroundTaskIdentifier:identifier];
}


- (void)showNotificationMessageWithSLBackgroundTaskManager_NotificationMessageEnum:(SLBackgroundTaskManager_NotificationMessageEnum *)message
{
    NSString *text;
    switch ([message ordinal]) {
        case SLBackgroundTaskManager_NotificationMessage_UPLOADS_STILL_SAVING:
            text = @"Photos still Saving";
            break;

        case SLBackgroundTaskManager_NotificationMessage_UPLOADS_STILL_PROCESSING:
            text = @"Photo Uploads are stuck. Tap to Resume";
            break;

        default:
            text = @"null";
            break;
    }

    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertAction = nil;
    notification.alertBody = text;
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}


@end
