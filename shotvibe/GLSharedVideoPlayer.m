//
//  GLShareVideoPLayer.m
//  shotvibe
//
//  Created by Tsah Kashkash on 03/12/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import "GLSharedVideoPlayer.h"

@interface GLSharedVideoPlayer ()

- (void)initMoviePlayer;

@end

@implementation GLSharedVideoPlayer
{
    NSString *photoId;
    MPMoviePlayerController *moviePlayer;
}

+ (instancetype)sharedInstance {
    static GLSharedVideoPlayer *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[GLSharedVideoPlayer alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        photoId = nil;
        [self initMoviePlayer];
        
//        sharedMoviePlayer setContentURL:
        
        
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(playbackStateChanged:)
//                                                     name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
        

        
    }
    return  self;
}

- (void)initMoviePlayer
{
    moviePlayer = [[MPMoviePlayerController alloc] init];
    moviePlayer.scalingMode = MPMovieScalingModeAspectFill;
    moviePlayer.controlStyle = MPMovieControlStyleNone;
    moviePlayer.shouldAutoplay = NO;
    moviePlayer.repeatMode = MPMovieRepeatModeOne;
    
    // TODO Temporary:
    moviePlayer.controlStyle = MPMovieControlStyleEmbedded;
    
//    moviePlayer.view.backgroundColor = [UIColor yellowColor];
    
    moviePlayer.view.alpha = 1;
}


- (BOOL)isAttachedTo:(NSString *)targetPhotoId
{
    if (!photoId) {
        return NO;
    }

    return [photoId isEqualToString:targetPhotoId];
}

- (void)attachToView:(UIView *)parentView withPhotoId:(NSString *)targetPhotoId withVideoUrl:(NSString *)videoUrl
{
    if (![targetPhotoId isEqualToString:photoId]) {
        [self resetPlayer];
    }

    if (moviePlayer.view.superview == parentView) {
        return;
    }
    
    [moviePlayer.view removeFromSuperview];
    [moviePlayer.view setFrame:parentView.bounds];
    [parentView addSubview:moviePlayer.view];
    
    NSLog(@"GLSharedVideoPlayer URL: %@", videoUrl);
    [moviePlayer setContentURL:[NSURL URLWithString:videoUrl]];
    
    photoId = targetPhotoId;
}

- (void)play
{
    NSLog(@"GLSharedVideoPlayer play");
    [moviePlayer play];
}

- (void)pause
{
    NSLog(@"GLSharedVideoPlayer pause");
    [moviePlayer pause];
}

- (void)resetPlayer {
    [moviePlayer stop];
    [moviePlayer.view removeFromSuperview];

    photoId = nil;
    [self initMoviePlayer];
}

//-(void)playbackStateChanged:(MPMoviePlaybackState)state {
//    
//}

@end
