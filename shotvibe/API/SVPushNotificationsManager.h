//
//  SVPushNotificationsManager.h
//  shotvibe
//
//  Created by benny on 8/10/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SL/AlbumManager.h"
#import "SVNotificationHandler.h"

@interface SVPushNotificationsManager : NSObject

- (void)setup;

- (void)setAPNSDeviceToken:(NSData *)deviceToken;

- (void)handleNotification:(NSDictionary *)userInfo;

@property(nonatomic,retain) SVNotificationHandler *notificationHandler_;

@end
