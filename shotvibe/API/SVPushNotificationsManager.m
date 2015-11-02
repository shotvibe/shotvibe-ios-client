//
//  SVPushNotificationsManager.m
//  shotvibe
//
//  Created by benny on 8/10/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVPushNotificationsManager.h"
#import "ShotVibeAppDelegate.h"
#import "SVDefines.h"
#import "SVNotificationHandler.h"
#import "SL/ShotVibeAPI.h"
#import "SL/APIException.h"
#import "SL/JSONObject.h"
#import "SL/NotificationMessage.h"

static NSString * const APPLICATION_APNS_DEVICE_TOKEN = @"apns_device_token";

@implementation SVPushNotificationsManager
{
    SLAlbumManager *albumManager_;
    
}

- (void)setup
{
    albumManager_ = [ShotVibeAppDelegate sharedDelegate].albumManager;

    self.notificationHandler_ = [[SVNotificationHandler alloc] initWithAlbumManager:albumManager_];

    NSLog(@"Setting up push notifications with AlbumManager: %@", [albumManager_ description]);
    
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        // use registerUserNotificationSettings
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        // use registerForRemoteNotificationTypes:
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
         (UIRemoteNotificationTypeAlert
          | UIRemoteNotificationTypeBadge
          | UIRemoteNotificationTypeSound)];
    }
#else
    // use registerForRemoteNotificationTypes:
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeAlert
      | UIRemoteNotificationTypeBadge
      | UIRemoteNotificationTypeSound)];
#endif

    
}


- (void)setAPNSDeviceToken:(NSData *)deviceToken
{
    // Convert the deviceToken to a hex-string.
    // See: <http://stackoverflow.com/a/12442672>
    NSUInteger dataLength = [deviceToken length];
    NSMutableString *deviceTokenString = [NSMutableString stringWithCapacity:dataLength*2];
    const unsigned char *dataBytes = [deviceToken bytes];
    for (NSInteger idx = 0; idx < dataLength; ++idx) {
        [deviceTokenString appendFormat:@"%02x", dataBytes[idx]];
    }

    NSString * storedDeviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:APPLICATION_APNS_DEVICE_TOKEN];

    if (![deviceTokenString isEqualToString:storedDeviceToken]) {
        [self sendAPNSDeviceToken:deviceTokenString];
    }
}


- (void)sendAPNSDeviceToken:(NSString *)deviceToken
{
    NSString *app;
#if CONFIGURATION_Debug
    app = @"dev";
#elif CONFIGURATION_AdHoc
    app = @"adhoc";
#elif CONFIGURATION_Release
    app = @"prod";
#else
#error "UNKNOWN CONFIGURATION"
#endif

    dispatch_queue_t backgroundQueue = dispatch_queue_create(NULL, NULL);

    dispatch_async(backgroundQueue, ^{
        RCLog(@"Registering deviceToken: %@", deviceToken);

        @try {
            [[albumManager_ getShotVibeAPI] registerDevicePushIOSWithNSString:app
                                                                 withNSString:deviceToken];
        } @catch (SLAPIException *exception) {
            // We weren't able to register with the API server.
			// So just give up now: the registrationId won't be saved in UserSettings,
			// and so this operation will be retried some time later on (the next time setup is called)
            NSLog(@"Error Registering: %@", [exception getTechnicalMessage]);
            return;
        }

        // TODO Store the deviceToken inside the user prefs so that the app won't keep reregistering
        RCLog(@"Registered!");
    });
}

- (void)handleNotification:(NSDictionary *)userInfo
{
    NSLog(@"handleNotification: %@", [userInfo description]);

    NSMutableDictionary *dataDict = [userInfo objectForKey:@"d"];

    if (dataDict) {
        SLJSONObject *data = [[SLJSONObject alloc] initWithDictionary:dataDict];

        @try {
            SLNotificationMessage *message = [SLNotificationMessage parseMessageWithSLJSONObject:data];

            
            
            
            [message handleWithSLNotificationMessage_NotificationHandler:self.notificationHandler_];
        } @catch (SLNotificationMessage_ParseException *exception) {
            NSLog(@"Invalid notification: %@", [exception getLocalizedMessage]);
        }
    }
}

@end
