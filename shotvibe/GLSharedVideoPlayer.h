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

@interface GLSharedVideoPlayer : NSObject 


+ (GLSharedVideoPlayer *)sharedInstance;
- (void)resetPlayer;
- (BOOL)isAttachedTo:(NSString *)targetPhotoId;
- (void)attachToView:(UIView *)parentView withPhotoId:(NSString *)targetPhotoId withVideoUrl:(NSString *)videoUrl videoThumbNail:(UIImage*)thumbNail;
- (void)pause;
- (void)play;
- (void)stop;
@property(nonatomic, retain) NSString *photoId;
@end
