//
//  GLShareVideoPLayer.h
//  shotvibe
//
//  Created by Tsah Kashkash on 03/12/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface GLSharedVideoPlayer : NSObject


+ (GLSharedVideoPlayer *)sharedInstance;
- (void)resetPlayer;
- (BOOL)isAttachedTo:(NSString *)targetPhotoId;
- (void)attachToView:(UIView *)parentView withPhotoId:(NSString *)targetPhotoId withVideoUrl:(NSString *)videoUrl;
- (void)pause;
- (void)play;

@end
