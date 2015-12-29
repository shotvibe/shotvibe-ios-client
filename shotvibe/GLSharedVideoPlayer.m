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
    
    MPMoviePlayerController *moviePlayer;
    BOOL playBackStarted;
    NSTimer * videoStartedTimer;
    UIImageView * tempBluredVideoFrame;
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
        self.photoId = nil;
        [self initMoviePlayer];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackStateChanged:)
                                                     name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
        

        
    }
    return  self;
}

- (void)initMoviePlayer
{
    
    playBackStarted = NO;
    
    moviePlayer = [[MPMoviePlayerController alloc] init];
    moviePlayer.view.clipsToBounds = YES;
    moviePlayer.scalingMode = MPMovieScalingModeAspectFill;
    moviePlayer.controlStyle = MPMovieControlStyleNone;
    moviePlayer.shouldAutoplay = NO;
    moviePlayer.repeatMode = MPMovieRepeatModeOne;
    
    // TODO Temporary:
//    moviePlayer.controlStyle = MPMovieControlStyleEmbedded;
    
    moviePlayer.view.alpha = 0;
    
    
    tempBluredVideoFrame = [UIImageView alloc];
    
    
    
}

- (void)videoDidStartedPlaying {
    
//    [self.activityIndicator startAnimating];
    
    if(moviePlayer.currentPlaybackTime > 0.0){
        
        [moviePlayer.view setHidden:NO];
        [UIView animateWithDuration:0.2 animations:^{
//            [self.activityIndicator stopAnimating];
            moviePlayer.view.alpha = 1;
            //            [self.contentView bringSubviewToFront:self.moviePlayer.view];
        } completion:^(BOOL finished) {
            [videoStartedTimer invalidate];
        }];
        
    }
    
}


- (BOOL)isAttachedTo:(NSString *)targetPhotoId
{
    if (!self.photoId) {
        return NO;
    }

    return [self.photoId isEqualToString:targetPhotoId];
}

- (void)attachToView:(UIView *)parentView withPhotoId:(NSString *)targetPhotoId withVideoUrl:(NSString *)videoUrl videoThumbNail:(UIImage*)thumbNail
{
    if (![targetPhotoId isEqualToString:self.photoId]) {
        [self resetPlayer];
    }

    if (moviePlayer.view.superview == parentView) {
        [moviePlayer play];
        return;
    }
    
    [moviePlayer.view removeFromSuperview];
    [moviePlayer.view setFrame:parentView.bounds];
    [parentView addSubview:moviePlayer.view];
    
    NSLog(@"GLSharedVideoPlayer URL: %@", videoUrl);
    [moviePlayer setContentURL:[NSURL URLWithString:videoUrl]];
    
    [moviePlayer play];
    
    self.photoId = targetPhotoId;
}

- (void)play
{
//    NSLog(@"GLSharedVideoPlayer play");
//    if(moviePlayer.playbackState == MPMoviePlaybackStateStopped || moviePlayer.playbackState ==  MPMoviePlaybackStatePaused){
//        [moviePlayer play];
//    }
    
}

- (void)pause
{
    NSLog(@"GLSharedVideoPlayer pause");
    [moviePlayer pause];
}

- (void)resetPlayer {
    [moviePlayer stop];
    [moviePlayer.view removeFromSuperview];

    self.photoId = nil;
    [self initMoviePlayer];
}

-(void)playbackStateChanged:(MPMoviePlaybackState)state {
    
    if(moviePlayer.playbackState == MPMoviePlaybackStateStopped){
        NSLog(@"MPMoviePlaybackStateStopped");
        playBackStarted = NO;
        [videoStartedTimer invalidate];
    }
    if(moviePlayer.playbackState == MPMoviePlaybackStatePlaying){
        NSLog(@"MPMoviePlaybackStatePlaying");
        if(playBackStarted){//Means it continues to play after buffering we should remove the indicator blur view
            
            [self removeTemporaryBlurBuffering];
        
        } else {
//            [self createTemporaryBlureWhenBuffering];
            playBackStarted = YES;
            videoStartedTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                                 target:self
                                                               selector:@selector(videoDidStartedPlaying)
                                                               userInfo:nil
                                                                repeats:YES];
        }
        
        
        
//        [UIView animateWithDuration:0.2 animations:^{
//            moviePlayer.view.alpha = 1;
//        }];
    }
    if(moviePlayer.playbackState == MPMoviePlaybackStatePaused){
        NSLog(@"MPMoviePlaybackStatePaused");
        if(playBackStarted){//Means its buffering we should display inidcator.
            
            [self createTemporaryBlureWhenBuffering];
        
        }
    }
    if(moviePlayer.playbackState == MPMoviePlaybackStateInterrupted){
        NSLog(@"MPMoviePlaybackStateInterrupted");
    }

    
    
    
}

- (UIImage *)screenShotOfView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(moviePlayer.view.frame.size, YES, 0.0);
    [moviePlayer.view drawViewHierarchyInRect:moviePlayer.view.frame afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)createTemporaryBlureWhenBuffering
{
    UIImage *screenShot =  [moviePlayer thumbnailImageAtTime:moviePlayer.currentPlaybackTime timeOption:MPMovieTimeOptionExact];
    
    tempBluredVideoFrame = [[UIImageView alloc] initWithFrame:moviePlayer.view.frame];
    tempBluredVideoFrame.contentMode = UIViewContentModeScaleAspectFill;
    tempBluredVideoFrame.image = screenShot;
    tempBluredVideoFrame.alpha = 0;
    screenShot = [tempBluredVideoFrame.image applyBlurWithRadius:5 tintColor:[UIColor colorWithWhite:0.6 alpha:0.2] saturationDeltaFactor:1.0 maskImage:nil];
    tempBluredVideoFrame.image = screenShot;
    
    [moviePlayer.view addSubview:tempBluredVideoFrame];
    
    
    UIActivityIndicatorView * activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    CGRect viewBounds = moviePlayer.view.bounds;
    viewBounds.size.height = viewBounds.size.height/1.5;
    activityIndicator.center = CGPointMake(CGRectGetMidX(viewBounds), CGRectGetMidY(viewBounds));
    
    [tempBluredVideoFrame addSubview:activityIndicator];
    
    [activityIndicator startAnimating];
    
    [UIView animateWithDuration:0.2 animations:^{
        tempBluredVideoFrame.alpha = 1;
    }];
    
    
//    self.bluredImageView.image = screenShot;
}

- (void)removeTemporaryBlurBuffering {
    [UIView animateWithDuration:0.2 animations:^{
        tempBluredVideoFrame.alpha = 0;
    } completion:^(BOOL finished) {
        [tempBluredVideoFrame removeFromSuperview];
        tempBluredVideoFrame.image = nil;
        tempBluredVideoFrame = nil;
    }];
}

@end