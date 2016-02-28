//
//  GLShareVideoPLayer.m
//  shotvibe
//
//  Created by Tsah Kashkash on 03/12/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import "GLSharedYouTubePlayer.h"
#import "SL/AlbumPhoto.h"
#import "SL/MediaType.h"


@interface GLSharedYouTubePlayer ()

- (void)initMoviePlayer;

@end

@implementation GLSharedYouTubePlayer
{
    
//    XCDYouTubeVideoPlayerViewController * youTubePlayerController;
    XCDYouTubeVideoPlayerViewController *moviePlayer;
    BOOL playBackStarted;
    NSTimer * videoStartedTimer;
    UIImageView * tempBluredVideoFrame;
    BOOL putOnHold;
}

+ (instancetype)sharedInstance {
    static GLSharedYouTubePlayer *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[GLSharedYouTubePlayer alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.photoId = nil;
        
        [self initMoviePlayer];
//
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(menuStateEventOccurred:)
                                                     name:MFSideMenuStateNotificationEvent
                                                   object:nil];
//
//        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackStateChanged:)
                                                     name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
        
        
       
        

        
    }
    return  self;
}

- (BOOL)checkIfYouTubeExists:(NSString *)videoId {
    
    XCDYouTubeVideoPlayerViewController * moviePlayer2 = [[XCDYouTubeVideoPlayerViewController alloc] initWithVideoIdentifier:videoId];
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(videoPlayerViewControllerDidReceiveVideo:) name:XCDYouTubeVideoPlayerViewControllerDidReceiveVideoNotification object:moviePlayer2];
//    return <#expression#>
    return NO;
}

- (void) videoPlayerViewControllerDidReceiveVideo:(NSNotification *)notification
{
    XCDYouTubeVideo *video = notification.userInfo[XCDYouTubeVideoUserInfoKey];
    NSLog(@"");
//    self.titleLabel.text = video.title;
//    UILabel * title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];
//    title.text = video.title;
//    [self.currentCell.contentView addSubview:title];
    
//    NSURL *thumbnailURL = video.mediumThumbnailURL ?: video.smallThumbnailURL;
//    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:thumbnailURL] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
//     {
//         self.currentCell.postImage.image = [UIImage imageWithData:data];
         [self play];

//     }];
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
    moviePlayer = [[XCDYouTubeVideoPlayerViewController alloc] init];
    moviePlayer.moviePlayer.view.backgroundColor = [UIColor redColor];
    moviePlayer.moviePlayer.view.clipsToBounds = YES;
    moviePlayer.moviePlayer.scalingMode = MPMovieScalingModeAspectFill;
    moviePlayer.moviePlayer.controlStyle = MPMovieControlStyleEmbedded;
    moviePlayer.moviePlayer.shouldAutoplay = NO;
    moviePlayer.moviePlayer.repeatMode = MPMovieRepeatModeOne;
//    moviePlayer.useApplicationAudioSession = NO;
    self.currentCell = nil;
    moviePlayer.view.alpha = 0;
    tempBluredVideoFrame = [UIImageView alloc];
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(videoPlayerViewControllerDidReceiveVideo:) name:XCDYouTubeVideoPlayerViewControllerDidReceiveVideoNotification object:moviePlayer];

}

- (void)videoDidStartedPlaying {
    
//    [self.activityIndicator startAnimating];
    
    if(moviePlayer.moviePlayer.currentPlaybackTime > 0.0){
        
        [moviePlayer.moviePlayer.view setHidden:NO];
        [UIView animateWithDuration:0.2 animations:^{
//            [self.activityIndicator stopAnimating];
            moviePlayer.moviePlayer.view.alpha = 1;
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

- (void)attachToView:(UIView *)parentView withPhotoId:(NSString *)targetPhotoId withYouTubeId:(NSString *)youTubeId videoThumbNail:(UIImage*)thumbNail tableCell:(GLFeedTableCell*)cell postsArray:(NSArray *)posts
{
    if (![targetPhotoId isEqualToString:self.photoId]) {
        [self resetPlayer];
    }

    if (moviePlayer.moviePlayer.view.superview == parentView) {
        [self play];
        return;
    }
    
    [moviePlayer.moviePlayer.view removeFromSuperview];
    [moviePlayer.moviePlayer.view setFrame:parentView.bounds];
    [parentView addSubview:moviePlayer.moviePlayer.view];
    
    
    
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressDetected:)];
    longPressRecognizer.cancelsTouchesInView = NO;
    longPressRecognizer.minimumPressDuration = 0.25f;
    longPressRecognizer.numberOfTouchesRequired = 1;
    self.postsArray = [NSArray arrayWithArray:posts];
    self.currentCell = cell;
    longPressRecognizer.delegate = self;
//    moviePlayer.view.userInteractionEnabled = YES;
    [moviePlayer.moviePlayer.view addGestureRecognizer:longPressRecognizer];
//    NSLog(@"GLSharedVideoPlayer URL: %@", videoUrl);
//    [moviePlayer.moviePlayer set];
//    [moviePlayer setContentURL:[NSURL URLWithString:videoUrl]];
    
    NSString *category = AVAudioSessionCategoryPlayback;
    //    NSString *category = [[NSUserDefaults standardUserDefaults] objectForKey:@"AudioSessionCategory"];
    if (category)
    {
        NSError *error = nil;
        BOOL success = [[AVAudioSession sharedInstance] setCategory:category error:&error];
        if (!success)
            NSLog(@"Audio Session Category error: %@", error);
    }
    
//    moviePlayer = [[XCDYouTubeVideoPlayerViewController alloc] initWithVideoIdentifier:youTubeId];
    [moviePlayer setVideoIdentifier:youTubeId];
    moviePlayer.moviePlayer.backgroundPlaybackEnabled = YES;
    moviePlayer.moviePlayer.shouldAutoplay = NO;
    
    
//
//    
    self.photoId = targetPhotoId;
//    [self play];
    
    
    
    
    
//
//
//    parentView.backgroundColor = [UIColor redColor];
//    parentView.alpha = 1;
//    parentView.hidden = NO;
//    [youTubePlayerController presentInView:parentView];
//    [youTubePlayerController.moviePlayer play];
    
    
    
    
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
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
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
    if((!putOnHold && ![[GLSharedCamera sharedInstance] cameraIsShown] && self.currentCell.isVisible && ([[photo getServerPhoto] getMediaType] == [SLMediaTypeEnum VIDEO])) || (!putOnHold && ![[GLSharedCamera sharedInstance] cameraIsShown] && self.currentCell.isVisible && ([[photo getServerPhoto] getMediaType] == [SLMediaTypeEnum YOUTUBE])) ){
        [moviePlayer.moviePlayer play];
        
    } else if(self.isFromPublic){
        [moviePlayer.moviePlayer play];
        self.isFromPublic = NO;
    }
//    }
    
}

- (void)pause
{
    NSLog(@"GLSharedVideoPlayer pause");
    [moviePlayer.moviePlayer pause];
}

- (void)resetPlayer {
    [moviePlayer.moviePlayer stop];
    [moviePlayer.moviePlayer.view removeFromSuperview];
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver:self name:XCDYouTubeVideoPlayerViewControllerDidReceiveVideoNotification object:moviePlayer];
    self.photoId = nil;
    [self initMoviePlayer];
}

-(void)playbackStateChanged:(MPMoviePlaybackState)state {
    
    if(moviePlayer.moviePlayer.playbackState == MPMoviePlaybackStateStopped){
        NSLog(@"MPMoviePlaybackStateStopped");
        playBackStarted = NO;
        [videoStartedTimer invalidate];
    }
    if(moviePlayer.moviePlayer.playbackState == MPMoviePlaybackStatePlaying){
        
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
    if(moviePlayer.moviePlayer.playbackState == MPMoviePlaybackStatePaused){
        NSLog(@"MPMoviePlaybackStatePaused");
        if(playBackStarted){//Means its buffering we should display inidcator.
            
            [self createTemporaryBlureWhenBuffering];
        
        }
    }
    if(moviePlayer.moviePlayer.playbackState == MPMoviePlaybackStateInterrupted){
        NSLog(@"MPMoviePlaybackStateInterrupted");
    }

    
    
    
}

- (UIImage *)screenShotOfView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(moviePlayer.moviePlayer.view.frame.size, YES, 0.0);
    [moviePlayer.moviePlayer.view drawViewHierarchyInRect:moviePlayer.moviePlayer.view.frame afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)createTemporaryBlureWhenBuffering
{
    UIImage *screenShot =  [moviePlayer.moviePlayer thumbnailImageAtTime:moviePlayer.moviePlayer.currentPlaybackTime timeOption:MPMovieTimeOptionExact];
    
    tempBluredVideoFrame = [[UIImageView alloc] initWithFrame:moviePlayer.moviePlayer.view.frame];
    tempBluredVideoFrame.contentMode = UIViewContentModeScaleAspectFill;
    tempBluredVideoFrame.image = screenShot;
    tempBluredVideoFrame.alpha = 0;
    screenShot = [tempBluredVideoFrame.image applyBlurWithRadius:5 tintColor:[UIColor colorWithWhite:0.6 alpha:0.2] saturationDeltaFactor:1.0 maskImage:nil];
    tempBluredVideoFrame.image = screenShot;
    
    [moviePlayer.moviePlayer.view addSubview:tempBluredVideoFrame];
    
    
    UIActivityIndicatorView * activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    CGRect viewBounds = moviePlayer.moviePlayer.view.bounds;
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
