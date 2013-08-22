//
//  SVPushNotificationsManager.h
//  shotvibe
//
//  Created by benny on 8/10/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AlbumManager.h"

@interface SVPushNotificationsManager : NSObject

- (id)initWithAlbumManager:(AlbumManager *)albumManager;

- (void)setup;

- (void)setAPNSDeviceToken:(NSData *)deviceToken;

@end
