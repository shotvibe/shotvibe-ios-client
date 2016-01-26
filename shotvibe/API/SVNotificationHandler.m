//
//  SVNotificationHandler.m
//  shotvibe
//
//  Created by raptor on 12/4/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "SVNotificationHandler.h"
#import "SDWebImageManager.h"
#import "GLFeedViewController.h"
//#import "ContainerViewController.h"
#import "SVAlbumListViewController.h"
#import "ShotVibeAppDelegate.h"



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
    NSLog(@"AlbumSync %lld", [msg getAlbumId]);
    [albumManager_ reportAlbumUpdateWithLong:[msg getAlbumId]];
}


- (void)HandleWithSLNotificationMessage_PhotosAdded:(SLNotificationMessage_PhotosAdded *)msg
{
    [albumManager_ reportAlbumUpdateWithLong:[msg getAlbumId]];
//    msg get
    
//    NSString * pushType = [[userInfo objectForKey:@"d"] objectForKey:@"type"];
//    long long int albumId = [[userInfo objectForKey:@"d"] objectForKey:@"album_id"];
//    if([pushType isEqualToString:@"photo_comment"]){
    
//    } else if([pushType isEqualToString:@"photos_added"]){
    
    
        
//    }
//    [msg isAccessibilityElement];
//    if(){}
    
    if([[ShotVibeAppDelegate sharedDelegate] appOpenedFromPush]){
    
        [[ShotVibeAppDelegate sharedDelegate] setPushAlbumId:[msg getAlbumId]];
//        [[ShotVibeAppDelegate sharedDelegate] setPhotoIdFromPush:[msg get]];
        //TODO Ask benny to add latest photo id to store it so we can scroll to it if we opened a push that he isnt the latest one.
        
//        [[ContainerViewController sharedInstance] transitToAlbumList:NO direction:UIPageViewControllerNavigationDirectionForward withAlbumId:[msg getAlbumId] completion:^{
//            
//        }];
        
    } else {
        
        LNNotification* notification = [LNNotification notificationWithMessage:[NSString stringWithFormat:@"%@ just add a new photo to the group @ %@",[msg getAuthorName],[msg getAlbumName]]];
        notification.title = @"New Photo";
        notification.soundName = @"push.mp3";
        notification.defaultAction = [LNNotificationAction actionWithTitle:@"Default Action" handler:^(LNNotificationAction *action) {

            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"pushWasPressed" object:self userInfo:@{@"msg":msg}];
                

            
            
        }];
        
        [[LNNotificationCenter defaultCenter] presentNotification:notification forApplicationIdentifier:@"glance_app"];
        
    }


}


- (void)HandleWithSLNotificationMessage_AddedToAlbum:(SLNotificationMessage_AddedToAlbum *)msg
{
    [albumManager_ reportAlbumUpdateWithLong:[msg getAlbumId]];

    NSString *message = [NSString stringWithFormat:@"%@ added you to %@", [msg getAdderName], [msg getAlbumName]];

//    showNotificationBanner(message);
    
//    [msg getAdderName];
    LNNotification* notification = [LNNotification notificationWithMessage:message];
    notification.title = [NSString stringWithFormat:@"You've been added!"];
    notification.soundName = @"push.mp3";
    
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager downloadImageWithURL:[NSURL URLWithString:[msg getAdderAvatarUrl]]
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
                                    
                                    
                                    
                                    [[NSNotificationCenter defaultCenter] postNotificationName:@"pushWasPressed" object:self userInfo:@{@"msg":msg}];
                                    
                                    
                                    //                                    NSUInteger childViewControllersCount = [[[[ContainerViewController sharedInstance] navigationController] childViewControllers] count];
                                    
                                    
                                    //                                    if(childViewControllersCount == 1){
                                    //
                                    //                                        [[GLSharedCamera sharedInstance] setCameraInFeed];
                                    //
                                    //                                        GLFeedViewController * feedView = [[GLFeedViewController alloc] init];
                                    //                                        feedView.albumId = [msg getAlbumId];
                                    //                                        feedView.scrollToComment = YES;
                                    //                                        feedView.photoToScrollToCommentsId = [msg getPhotoId];
                                    //                                        feedView.prevAlbumId = [msg getAlbumId];
                                    //                                        feedView.startImidiatly = NO;
                                    //                                        GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
                                    //                                        glcamera.imageForOutSideUpload = nil;
                                    //                                        [[[ContainerViewController sharedInstance] navigationController] pushViewController:feedView animated:YES];
                                    //                                        [[ContainerViewController sharedInstance] lockScrolling:YES];
                                    //
                                    //                                    } else if (childViewControllersCount == 2){
                                    //
                                    //                                        GLFeedViewController * glfeed = [[[[ContainerViewController sharedInstance] navigationController] childViewControllers] objectAtIndex:1];
                                    //                                        self.delegate = glfeed;
                                    //                                        [self.delegate commentPushPressed:msg];
                                    //
                                    //                                    }
                                    
                                    //                                    GLFeedViewController * glfeed = [[[[ContainerViewController sharedInstance] navigationController] childViewControllers] objectAtIndex:1];
                                    //                                    self.delegate = glfeed;
                                    //                                    [self.delegate commentPushPressed:msg];
                                    
                                }];
                                
                                [[LNNotificationCenter defaultCenter] presentNotification:notification forApplicationIdentifier:@"glance_app"];
                                
                                // do something with image
                            }
                        }];
    
    
}

- (void)HandleWithSLNotificationMessage_PhotoComment:(SLNotificationMessage_PhotoComment *)msg {

    [albumManager_ reportAlbumUpdateWithLong:[msg getAlbumId]];
    
    
//    showNotificationBanner([msg getCommentAuthorNickname]);
    
//    [msg get]
    
    
    if([[ShotVibeAppDelegate sharedDelegate] appOpenedFromPush]){
        
        [[ShotVibeAppDelegate sharedDelegate] setPushAlbumId:[msg getAlbumId]];
        
        
        [[ShotVibeAppDelegate sharedDelegate] setPhotoIdFromPush:[msg getPhotoId]];
        //TODO Ask benny to add latest photo id to store it so we can scroll to it if we opened a push that he isnt the latest one.
        
        //        [[ContainerViewController sharedInstance] transitToAlbumList:NO direction:UIPageViewControllerNavigationDirectionForward withAlbumId:[msg getAlbumId] completion:^{
        //
        //        }];
        
    } else {
    
        NSString * firstName = [[[msg getCommentAuthorNickname] componentsSeparatedByString:@" "] objectAtIndex:0];
        
    LNNotification* notification = [LNNotification notificationWithMessage:[NSString stringWithFormat:@"%@ commented on a photo @ %@",[msg getCommentAuthorNickname],[msg getAlbumName]]];
    notification.title = [NSString stringWithFormat:@"%@: %@",firstName,[msg getCommentText]];
    notification.soundName = @"push.mp3";
    
//        [[YYWebImageManager sharedManager] ]
        
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

                                    
                                    [[NSNotificationCenter defaultCenter] postNotificationName:@"pushWasPressed" object:self userInfo:@{@"msg":msg}];
                                    

                                    
                                }];
                                
                                [[LNNotificationCenter defaultCenter] presentNotification:notification forApplicationIdentifier:@"glance_app"];
                                
                                // do something with image
                            }
                        }];
    
    
    }
    
}

- (void)HandleWithSLNotificationMessage_PhotoGlanceScoreDelta:(SLNotificationMessage_PhotoGlanceScoreDelta *)msg {
 
    [albumManager_ reportAlbumUpdateWithLong:[msg getAlbumId]];
    
    
    //    showNotificationBanner([msg getCommentAuthorNickname]);
    
    //    [msg get]
    NSString * pushText = @"";
    NSString * pushTitle = @"";
    
    if([msg getScoreDelta] > 0){
        pushText = [NSString stringWithFormat:@"%@ glanced your image. You just won 3 points to your score. Keep glancing!",[msg getGlanceAuthorNickname]];
        pushTitle = @"You've got Glanced";
    } else if([msg getScoreDelta] < 0){
        pushText = [NSString stringWithFormat:@"%@ unglanced your image. You just lost 3 points to your score. Better glancing next time...",[msg getGlanceAuthorNickname]];
        pushTitle = @"You've got UnGlanced";
    }
    LNNotification* notification = [LNNotification notificationWithMessage:pushText];
    
    
    
    notification.title = pushTitle;
    notification.soundName = @"push.mp3";
    
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager downloadImageWithURL:[NSURL URLWithString:[msg getGlanceAuthorAvatarUrl]]
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
                                    
                                    
                                    [[NSNotificationCenter defaultCenter] postNotificationName:@"pushWasPressed" object:self userInfo:@{@"msg":msg}];
                                    
//                                    [self.delegate youGotGlanced:msg];
//                                    [self.delegate commentPushPressed:nil];
                                    
                                }];
                                
                                [[LNNotificationCenter defaultCenter] presentNotification:notification forApplicationIdentifier:@"glance_app"];
                                
                                // do something with image
                            }
                        }];
    
    
}

- (void)HandleWithSLNotificationMessage_UserGlanceScoreUpdate:(SLNotificationMessage_UserGlanceScoreUpdate *)msg {

     int score = [msg getUserGlanceScore];
    [[[GLSharedCamera sharedInstance] userScore] updateScoreFromPush:score];
}


- (void)HandleWithSLNotificationMessage_PhotoGlance:(SLNotificationMessage_PhotoGlance *)msg
{
    // Ignore. Photo Glances have been removed
}


@end
