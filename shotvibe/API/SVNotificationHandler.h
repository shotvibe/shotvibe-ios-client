//
//  SVNotificationHandler.h
//  shotvibe
//
//  Created by raptor on 12/4/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SL/NotificationMessage.h"
//#import "SL/AlbumManager.h"
#import "SL/AlbumManager.h"
#import "MPNotificationView.h"
#import "LNNotificationsUI.h"

@protocol NotificationManagerDelegate <NSObject>

@optional
- (void)commentPushPressed:(SLNotificationMessage_PhotoComment *)msg;


@end


@interface SVNotificationHandler : NSObject < SLNotificationMessage_NotificationHandler>

- (id)initWithAlbumManager:(SLAlbumManager *)albumManager;
@property (nonatomic, assign) id<NotificationManagerDelegate> delegate;

@end
