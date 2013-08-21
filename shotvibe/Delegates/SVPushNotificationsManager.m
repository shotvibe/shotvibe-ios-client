//
//  SVPushNotificationsManager.m
//  shotvibe
//
//  Created by benny on 8/10/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVPushNotificationsManager.h"
#import "ShotVibeAPI.h"
#import "SVDefines.h"

static NSString * const APPLICATION_APNS_DEVICE_TOKEN = @"apns_device_token";

@implementation SVPushNotificationsManager

+ (void)setup
{
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeAlert
      | UIRemoteNotificationTypeBadge
      | UIRemoteNotificationTypeSound)];
}


+ (void)setAPNSDeviceToken:(NSData *)deviceToken
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


+ (void)sendAPNSDeviceToken:(NSString *)deviceToken
{
    // TODO This is a temporary way to get the AuthData value from the legacy code system

    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:kApplicationUserId];
    NSString *userAuthToken = [[NSUserDefaults standardUserDefaults] objectForKey:kApplicationUserAuthToken];

    // Strip the prefix string "Token " that is stored by the legacy code
    NSString *realUserAuthToken = [userAuthToken substringFromIndex:[@"Token " length]];

    // TODO Temporary country code:
    NSString *userDefaultCountryCode = @"US";

    AuthData *authData = [[AuthData alloc] initWithUserID:userId authToken:realUserAuthToken defaultCountryCode:userDefaultCountryCode];

    ShotVibeAPI *shotvibeAPI = [[ShotVibeAPI alloc] initWithAuthData:authData];

    dispatch_queue_t backgroundQueue = dispatch_queue_create(NULL, NULL);

    dispatch_async(backgroundQueue, ^{
        NSError *error;
        NSLog(@"Registering deviceToken: %@", deviceToken);
        if (![shotvibeAPI registerDevicePushWithDeviceToken:deviceToken error:&error]) {
            // We weren't able to register with the API server.
			// So just give up now: the registrationId won't be saved in UserSettings,
			// and so this operation will be retried some time later on (the next time setup is called)
            NSLog(@"Error Registering: %@", [error localizedDescription]);
            return;
        }

        // TODO Store the deviceToken inside the user prefs so that the app won't keep reregistering
        NSLog(@"Registered!");
    });
}


@end