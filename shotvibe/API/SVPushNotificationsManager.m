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
#import "JSONObject.h"
#import "JSONException.h"
#import "Notification.h"
#import "IconBadgeController.h"

static NSString * const APPLICATION_APNS_DEVICE_TOKEN = @"apns_device_token";

@implementation SVPushNotificationsManager
{
    AlbumManager *albumManager_;
    IconBadgeController *iconBadgeController_;
}

- (id)initWithAlbumManager:(AlbumManager *)albumManager
{
    self = [super init];

    if (self) {
        albumManager_ = albumManager;
        iconBadgeController_ = [[IconBadgeController alloc] init];
    }

    return self;
}

- (void)setup
{
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeAlert
      | UIRemoteNotificationTypeBadge
      | UIRemoteNotificationTypeSound)];
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
    dispatch_queue_t backgroundQueue = dispatch_queue_create(NULL, NULL);

    dispatch_async(backgroundQueue, ^{
        NSError *error;
        RCLog(@"Registering deviceToken: %@", deviceToken);
        if (![[albumManager_ getShotVibeAPI] registerDevicePushWithDeviceToken:deviceToken error:&error]) {
            // We weren't able to register with the API server.
			// So just give up now: the registrationId won't be saved in UserSettings,
			// and so this operation will be retried some time later on (the next time setup is called)
            RCLog(@"Error Registering: %@", [error localizedDescription]);
            return;
        }

        // TODO Store the deviceToken inside the user prefs so that the app won't keep reregistering
        RCLog(@"Registered!");
    });
}

- (void)handlePushNotification:(NSDictionary *)userInfo
{
    SLJSONObject *userInfoJSON = [[SLJSONObject alloc] initWithDictionary:[NSMutableDictionary dictionaryWithDictionary:userInfo]];
    @try {
        NSString *type = [userInfoJSON getStringWithNSString:@"type"];

        if ([type isEqualToString:@"added_to_album"]) {
            int64_t albumId = [userInfoJSON getLongWithNSString:@"album_id"];
            NSString *adder = [userInfoJSON getStringWithNSString:@"adder"];
            NSString *albumName = [userInfoJSON getStringWithNSString:@"album_name"];
            [self handleInviteWithAlbumId:albumId albumName:albumName adder:adder];
        } else if ([type isEqualToString:@"photos_added"]) {
            int64_t albumId = [userInfoJSON getLongWithNSString:@"album_id"];
            NSString *adder = [userInfoJSON getStringWithNSString:@"author"];
            NSString *albumName = [userInfoJSON getStringWithNSString:@"album_name"];
            int64_t nrOfPhotos = [userInfoJSON getLongWithNSString:@"num_photos"];
            [self handlePhotosAddedWithAlbumId:albumId albumName:albumName adder:adder nrOfPhotos:nrOfPhotos];
        } else if ([type isEqualToString:@"album_list_sync"]) {
            [self handleAlbumListSync];
        } else if ([type isEqualToString:@"album_sync"]) {
            int64_t albumId = [userInfoJSON getLongWithNSString:@"album_id"];
            [self handleAlbumSyncWithAlbumId:albumId];
        } else if ([type isEqualToString:@"test_message"]) {
            NSString *message = [userInfoJSON getStringWithNSString:@"message"];
            [self handleTestMessage:message];
        }
    } @catch (SLJSONException *exception) {
        [Notification notifyError:@"Push notification parse error" withMessage:[exception description]];
    }
}


- (void)handleInviteWithAlbumId:(int64_t)albumId albumName:(NSString *)albumName adder:(NSString *)adder
{
    RCLog(@"handleInviteWithAlbumId:%llu albumName:\"%@\" adder:\"%@\"", albumId, albumName, adder);
}


- (void)handlePhotosAddedWithAlbumId:(int64_t)albumId albumName:(NSString *)albumName adder:(NSString *)adder nrOfPhotos:(int64_t)nrOfPhotos
{
    RCLog(@"handlePhotosAddedWithAlbumId:%llu albumName:\"%@\" adder:\"%@\" nrOfPhotos:%llu", albumId, albumName, adder, nrOfPhotos);
}


- (void)handleAlbumListSync
{
    RCLog(@"handleAlbumListSync");
    [albumManager_ refreshAlbumList];
}


- (void)handleAlbumSyncWithAlbumId:(int64_t)albumId
{
    RCLog(@"handleAlbumSyncWithAlbumId:%llu", albumId);
    [albumManager_ reportAlbumUpdate:albumId];
}


- (void)handleTestMessage:(NSString *)message
{
    RCLog(@"handleTestMessage:\"%@\"", message);
}


@end
