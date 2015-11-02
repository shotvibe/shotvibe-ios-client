//
//  SVNotificationHandler.m
//  shotvibe
//
//  Created by raptor on 12/4/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "SVNotificationHandler.h"
#import "SDWebImageManager.h"





@implementation SVNotificationHandler
{
    SLAlbumManager *albumManager_;
}


- (id)initWithAlbumManager:(SLAlbumManager *)albumManager
{
    self = [super init];
    if (self) {
        albumManager_ = albumManager;
    }
    return self;
}


static void showNotificationBanner(NSString *message)
{
    NSString *title = @"Glance";

    [MPNotificationView notifyWithText:title
                                detail:message
                                 image:nil
                           andDuration:5.0];
}


- (void)HandleWithSLNotificationMessage_TestMessage:(SLNotificationMessage_TestMessage *)msg
{
    NSLog(@"TestMessage");

    NSString *message = [NSString stringWithFormat:@"Test Message: %@", [msg getMessage]];

    showNotificationBanner(message);
}


- (void)HandleWithSLNotificationMessage_AlbumListSync:(SLNotificationMessage_AlbumListSync *)msg
{
    [albumManager_ refreshAlbumListWithBoolean:NO];
}


- (void)HandleWithSLNotificationMessage_AlbumSync:(SLNotificationMessage_AlbumSync *)msg
{
    [albumManager_ reportAlbumUpdateWithLong:[msg getAlbumId]];
}


- (void)HandleWithSLNotificationMessage_PhotosAdded:(SLNotificationMessage_PhotosAdded *)msg
{
    [albumManager_ reportAlbumUpdateWithLong:[msg getAlbumId]];

    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"NOTIFICATION_PHOTOS_ADDED", nil), [msg getAuthorName], [NSString stringWithFormat:@"%d", [msg getNumPhotos]], [msg getAlbumName]];

    showNotificationBanner(message);
}


- (void)HandleWithSLNotificationMessage_AddedToAlbum:(SLNotificationMessage_AddedToAlbum *)msg
{
    [albumManager_ reportAlbumUpdateWithLong:[msg getAlbumId]];

    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"NOTIFICATION_ADDED_TO_ALBUM", nil), [msg getAdderName], [msg getAlbumName]];

    showNotificationBanner(message);
}

- (void)HandleWithSLNotificationMessage_PhotoComment:(SLNotificationMessage_PhotoComment *)msg {

    [albumManager_ reportAlbumUpdateWithLong:[msg getAlbumId]];
    
    
//    showNotificationBanner([msg getCommentAuthorNickname]);
    
//    [msg get]
    
    LNNotification* notification = [LNNotification notificationWithMessage:[NSString stringWithFormat:@"%@ commented on a photo @ %@",[msg getCommentAuthorNickname],[msg getAlbumName]]];
    notification.title = @"test title";
    notification.soundName = @"push.mp3";
    
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager downloadImageWithURL:[NSURL URLWithString:[msg getCommentAuthorAvatarUrl]]
                          options:0
                         progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                             // progression tracking code
                         }
                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                            if (image) {
                                
                                notification.icon = image;
                                notification.defaultAction = [LNNotificationAction actionWithTitle:@"Default Action" handler:^(LNNotificationAction *action) {
                                    //Handle default action
                                    NSLog(@"test");
                                    
                                    
                                    
                                    [self.delegate commentPushPressed:msg];
                                    
                                }];
                                
                                [[LNNotificationCenter defaultCenter] presentNotification:notification forApplicationIdentifier:@"glance_app"];
                                
                                // do something with image
                            }
                        }];
    
    
    
    
}


- (void)HandleWithSLNotificationMessage_PhotoGlance:(SLNotificationMessage_PhotoGlance *)msg
{
    // Ignore. Photo Glances have been removed
}


@end
