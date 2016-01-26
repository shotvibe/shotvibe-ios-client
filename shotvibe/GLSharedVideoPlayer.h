//
//  GLShareVideoPLayer.h
//  shotvibe
//
//  Created by Tsah Kashkash on 03/12/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "UIImage+ImageEffects.h"
#import "MFSideMenu.h"
#import "ShotVibeAppDelegate.h"
#import "GLFeedTableCell.h"
#import "GLSharedCamera.h"
#import "UILongPressGestureRecognizer+LongPressWithGLFeedTableCell.h"

@interface GLSharedVideoPlayer : NSObject <UIGestureRecognizerDelegate>


+ (GLSharedVideoPlayer *)sharedInstance;
- (void)resetPlayer;
- (BOOL)isAttachedTo:(NSString *)targetPhotoId;
- (void)attachToView:(UIView *)parentView withPhotoId:(NSString *)targetPhotoId withVideoUrl:(NSString *)videoUrl videoThumbNail:(UIImage*)thumbNail tableCell:(GLFeedTableCell*)cell postsArray:(NSArray*)posts;

- (void)pause;
- (void)play;
- (void)stop;
@property(nonatomic, retain) NSString *photoId;
@property(nonatomic, retain) GLFeedTableCell *currentCell;
@property(nonatomic) BOOL isFromPublic;
@property(nonatomic, retain) NSArray * postsArray;
@end
