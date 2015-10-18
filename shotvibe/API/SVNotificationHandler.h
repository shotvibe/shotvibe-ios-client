//
//  SVNotificationHandler.h
//  shotvibe
//
//  Created by raptor on 12/4/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SL/NotificationMessage.h"
#import "SL/AlbumManager.h"

@interface SVNotificationHandler : NSObject < SLNotificationMessage_NotificationHandler>

- (id)initWithAlbumManager:(SLAlbumManager *)albumManager;

@end
