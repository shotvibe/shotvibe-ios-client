//
//  SVAboutViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 4/16/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "SVAboutViewController.h"
#import "SVDefines.h"

@interface SVAboutViewController ()
@property (nonatomic, strong) IBOutlet UITextView *aboutTextView;
@property (nonatomic, strong) IBOutlet UIButton *playButton;
@property (nonatomic, strong) IBOutlet UIView *movieContainer;
@property (nonatomic, strong) MPMoviePlayerController *movieController;

- (IBAction)playButtonPressed:(id)sender;
- (void)setupMoviePlayer;
- (void)movieFinished;

@end

@implementation SVAboutViewController

#pragma mark - Actions

- (IBAction)playButtonPressed:(id)sender
{
    self.playButton.hidden = YES;
    
    if (self.movieController) {
        [self.movieController play];
    }
}


#pragma mark - Initializers

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    if (!IS_IOS6_OR_GREATER) {
        self.aboutTextView.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:12];
        self.aboutTextView.textColor = [UIColor colorWithRed:0.46 green:0.50 blue:0.52 alpha:1.0];
    }
    
    // Enable this once we have a video file.
    //[self setupMoviePlayer];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Private Methods

- (void)setupMoviePlayer
{
    NSURL *movieURL = [NSURL fileURLWithPath:@"insertPathHere"];
    
    self.movieController = [[MPMoviePlayerController alloc] initWithContentURL:movieURL];
    self.movieController.view.frame = self.movieContainer.bounds;
    self.movieController.controlStyle = MPMovieControlModeHidden;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieFinished) name:MPMoviePlayerPlaybackDidFinishNotification object:self.movieController];
    
    [self.movieContainer addSubview:self.movieController.view];
    self.movieController.scalingMode = MPMovieScalingModeAspectFit;
    
    self.movieController.contentURL = movieURL;
}


- (void)movieFinished
{
    self.playButton.hidden = NO;
}

@end
