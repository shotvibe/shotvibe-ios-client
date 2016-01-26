//
//  GLShareVideoPLayer.m
//  shotvibe
//
//  Created by Tsah Kashkash on 03/12/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import "GLSharedVideoPlayer.h"
#import "SL/AlbumPhoto.h"
#import "SL/MediaType.h"


@interface GLSharedVideoPlayer ()

- (void)initMoviePlayer;

@end

@implementation GLSharedVideoPlayer
{
    
    MPMoviePlayerController *moviePlayer;
    BOOL playBackStarted;
    NSTimer * videoStartedTimer;
    UIImageView * tempBluredVideoFrame;
    BOOL putOnHold;
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
                                                 selector:@selector(menuStateEventOccurred:)
                                                     name:MFSideMenuStateNotificationEvent
                                                   object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackStateChanged:)
                                                     name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
        

        
    }
    return  self;
}

- (void)menuStateEventOccurred:(NSNotification *)notification {
    MFSideMenuStateEvent event = [[[notification userInfo] objectForKey:@"eventType"] intValue];
    if(event == MFSideMenuStateEventMenuDidOpen){
        
        putOnHold = YES;
        [self pause];
        
    } else if(event == MFSideMenuStateEventMenuDidClose){

        putOnHold = NO;
        [self play];
//        [[GLSharedCamera sharedInstance] check]
        
    }
}

- (void)initMoviePlayer
{
    
//    self.isFromPublic = NO;
    playBackStarted = NO;
    putOnHold = NO;
    moviePlayer = [[MPMoviePlayerController alloc] init];
    moviePlayer.view.clipsToBounds = YES;
    moviePlayer.scalingMode = MPMovieScalingModeAspectFill;
    moviePlayer.controlStyle = MPMovieControlStyleNone;
    moviePlayer.shouldAutoplay = NO;
    moviePlayer.repeatMode = MPMovieRepeatModeOne;
    moviePlayer.useApplicationAudioSession = NO;
    self.currentCell = nil;
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


- (void)longPressDetected:(UILongPressGestureRecognizer*)gest {
    
    
    if(gest.state == UIGestureRecognizerStateBegan){
        
        NSLog(@"hold on post image began");
        [UIView animateWithDuration:0.2 animations:^{
            self.currentCell.postPannelWrapper.alpha = 0;
        }];
        
    }
    
    if(gest.state == UIGestureRecognizerStateEnded){
        NSLog(@"hold on post image ended");
        [UIView animateWithDuration:0.2 animations:^{
            self.currentCell.postPannelWrapper.alpha = 1;
        }];
    }
    
    
    
}

- (void)attachToView:(UIView *)parentView withPhotoId:(NSString *)targetPhotoId withVideoUrl:(NSString *)videoUrl videoThumbNail:(UIImage*)thumbNail tableCell:(GLFeedTableCell*)cell postsArray:(NSArray *)posts
{
    if (![targetPhotoId isEqualToString:self.photoId]) {
        [self resetPlayer];
    }

    if (moviePlayer.view.superview == parentView) {
        [self play];
        return;
    }
    
    [moviePlayer.view removeFromSuperview];
    [moviePlayer.view setFrame:parentView.bounds];
    [parentView addSubview:moviePlayer.view];
    
    
    
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressDetected:)];
    longPressRecognizer.cancelsTouchesInView = NO;
    longPressRecognizer.minimumPressDuration = 0.25f;
    longPressRecognizer.numberOfTouchesRequired = 1;
    self.postsArray = [NSArray arrayWithArray:posts];
    self.currentCell = cell;
    longPressRecognizer.delegate = self;
    moviePlayer.view.userInteractionEnabled = YES;
    [moviePlayer.view addGestureRecognizer:longPressRecognizer];
    NSLog(@"GLSharedVideoPlayer URL: %@", videoUrl);
    
    [moviePlayer setContentURL:[NSURL URLWithString:videoUrl]];
    
    
//    cell.isVisible;
    
//    AVURLAsset * asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:videoUrl] options:nil];
//    NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
//    
//    // Mute all the audio tracks
//    NSMutableArray * allAudioParams = [NSMutableArray array];
//    for (AVAssetTrack *track in audioTracks) {
//        AVMutableAudioMixInputParameters *audioInputParams =[AVMutableAudioMixInputParameters audioMixInputParameters];
//        [audioInputParams setVolume:0.0 atTime:kCMTimeZero ];
//        [audioInputParams setTrackID:[track trackID]];
//        [allAudioParams addObject:audioInputParams];
//    }
//    AVMutableAudioMix * audioZeroMix = [AVMutableAudioMix audioMix];
//    [audioZeroMix setInputParameters:allAudioParams];
//    
//    // Create a player item
//    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
//    [playerItem setAudioMix:audioZeroMix]; // Mute the player item
//    
//    // Create a new Player, and set the player to use the player item
//    // with the muted audio mix
//    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
//    
//    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:_player];    layer.frame = self.frame;    layer.backgroundColor = [UIColor clearColor].CGColor;    [layer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
//    
    
    self.photoId = targetPhotoId;
    [self play];
    
    
    
}


-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return true;
    
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return true;
    
}

- (void)play
{
    NSLog(@"GLSharedVideoPlayer play");
//    if(moviePlayer.playbackState == MPMoviePlaybackStateStopped || moviePlayer.playbackState ==  MPMoviePlaybackStatePaused){
    
//    NSLog(@"%f",self.currentCell.frame.origin.y);
    
//    NSLog(@"the current cell index by pixels is %f",self.currentCell.frame.origin.y/self.currentCell.frame.size.height);
    UITableView * tableview = self.currentCell.tableView;
    
//    NSLog(@"the table current page is: %f",floorf(tableview.contentOffset.y/self.currentCell.frame.size.height));
    
    CGFloat cellPage = self.currentCell.frame.origin.y/self.currentCell.frame.size.height;
    CGFloat tablePage = tableview.contentOffset.y/self.currentCell.bounds.size.height;
    
    NSLog(@"%f - %f",cellPage,tablePage);
//    [tableview indexPathForCell:self.currentCell];
//    NSIndexPath * path = [nsind]
    SLAlbumPhoto *photo;
    NSArray * data;
    if(self.postsArray.count > 0){
        data = [self.postsArray objectAtIndex:floor(tablePage+0.5)];

    } else {
        data = [self.postsArray objectAtIndex:0];
    }
        photo = [data objectAtIndex:1];
//    if(){
    if(!putOnHold && ![[GLSharedCamera sharedInstance] cameraIsShown] && self.currentCell.isVisible && ([[photo getServerPhoto] getMediaType] == [SLMediaTypeEnum VIDEO])  /*&& self.currentCell.photoId == self.photoId*/){
        [moviePlayer play];
        
    } else if(self.isFromPublic){
        [moviePlayer play];
        self.isFromPublic = NO;
    }
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
