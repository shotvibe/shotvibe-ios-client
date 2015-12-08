//
//  SVAlbumListViewController.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#import <AddressBook/AddressBook.h>
#import "SVAlbumListViewController.h"
#import "SVSettingsViewController.h"
#import "SVProfileViewController.h"
#import "UIImageView+WebCache.h"
#import "SVDefines.h"

#import "SVCameraNavController.h"
#import "SVPickerController.h"

#import "SVImagePickerListViewController.h"
#import "NSDate+Formatting.h"
#import "MFSideMenu.h"
#import "MBProgressHUD.h"
#import "SVNavigationController.h"
#import "NetworkLogViewController.h"

#import "SL/AlbumUser.h"
#import "SL/AlbumSummary.h"
#import "SL/AlbumContents.h"
#import "SL/AlbumPhoto.h"
#import "SL/AlbumServerPhoto.h"
#import "SL/ArrayList.h"
#import "SL/DateTime.h"
#import "SL/ShotVibeAPI.h"
#import "SL/APIException.h"
#import "ShotVibeAppDelegate.h"
#import "UserSettings.h"

#import "AlbumMember.h"
#import "SL/AlbumServerVideo.h"

#import "SVMultiplePicturesViewController.h"
#import "SVNonRotatingNavigationControllerViewController.h"

//#import "MainCameraViewController.h"
#import "ShotVibeAppDelegate.h"
#import "GLSharedCamera.h"

#import "STXFeedViewController.h"
#import <CoreData/CoreData.h>


#import "GLFeedViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "ContainerViewController.h"
#import "Common.h"
//#import "MPMoviePlayerController.h"

CGFloat kResizeThumbSize = 45.0f;

@interface SVAlbumListViewController ()
{
    BOOL searchShowing;
	BOOL creatingAlbum;
	BOOL refreshManualy;
    NSMutableArray *albumList;
	NSArray *allAlbums;
    NSMutableDictionary *thumbnailCache;
	UIView *sectionView;
	NSIndexPath *tappedCell;
	SVCameraNavController *cameraNavController;
	int table_content_offset_y;
	int total_header_h;
	int status_bar_h;
	int dropdown_origin_y;
    
    BOOL networkOnline_;
    
    BOOL cameraShown;
    
    
    BOOL isResizingLR;
    BOOL isResizingUL;
    BOOL isResizingUR;
    BOOL isResizingLL;
    CGPoint touchStart;
    
    
}

@property (nonatomic, strong) IBOutlet UIView *sectionHeader;
@property (nonatomic, strong) IBOutlet UIView *tableOverlayView;
@property (nonatomic, strong) IBOutlet UIView *dropDownContainer;
@property (nonatomic, strong) IBOutlet UIView *noPhotosView;
@property (nonatomic, strong) IBOutlet UITextField *albumField;
@property (nonatomic, strong) IBOutlet UISearchBar *searchbar;
@property (nonatomic, strong) IBOutlet UIButton *butAlbum;
@property (nonatomic, strong) IBOutlet UIButton *butTakePicture;

@property (nonatomic, strong) UINavigationController *pickerController;

@property (nonatomic, strong) UIView *refreshLoadingView;
@property (nonatomic, strong) UIView *refreshColorView;
@property (nonatomic, strong) UIImageView *compass_background;
@property (nonatomic, strong) UIImageView *compass_spinner;
@property (assign) BOOL isRefreshIconsOverlap;
@property (assign) BOOL isRefreshAnimating;

- (IBAction)newAlbumPressed:(id)sender;
- (IBAction)newAlbumClosed:(id)sender;
- (IBAction)newAlbumDone:(id)sender;
- (IBAction)takePicturePressed:(id)sender;

@end


@implementation SVAlbumListViewController
{
    SLAlbumManager *albumManager_;
    PhotoFilesManager *photoFilesManager_;
    AVPlayer *_player;
    AVPlayerLayer * _playerLayer;
    AVAsset * _asset;
    AVPlayerItem * _playerItem;
}


#pragma mark - Controller lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
 
//    self.view.la.userInteractionEnabled = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    cameraShown = NO;
    self.tableView.delegate = self;
    

    photoFilesManager_ = [ShotVibeAppDelegate sharedDelegate].photoFilesManager;

    albumManager_ = [ShotVibeAppDelegate sharedDelegate].albumManager;
    [self setAlbumList:[albumManager_ addAlbumListListenerWithSLAlbumManager_AlbumListListener:self].array];
    
//    SLArrayList * cachedalbums = [albumManager_ getCachedAlbums];

//    RCLog(@"##### Initial albumList: %@", albumList);

    table_content_offset_y = IS_IOS7 ? 0 : 0;
    total_header_h = IS_IOS7 ? 0 : 0;
    status_bar_h = IS_IOS7 ? 0 : 0;
    dropdown_origin_y = 0;//IS_IOS7 ? (45 + 44) : (45 + 44);

    //self.tableView.contentInset = UIEdgeInsetsMake(44, 0, 0, 0);
//    self.tableView.contentOffset = CGPointMake(0, 44);

    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.butTakePicture.enabled = NO;
    }

    thumbnailCache = [[NSMutableDictionary alloc] init];
    self.searchbar.placeholder = NSLocalizedString(@"Search album", nil);
    self.dropDownContainer.frame = CGRectMake(8, -134, self.dropDownContainer.frame.size.width, 134);

    // Setup titleview
//    UIImageView *titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
//    UIView *titleContainer = [[UIView alloc] initWithFrame:titleView.frame];
//    [titleContainer addSubview:titleView];
//    titleContainer.backgroundColor = [UIColor clearColor];
//    titleView.frame = CGRectMake(0, -1, titleView.frame.size.width, titleView.frame.size.height);
//    self.navigationItem.titleView = titleContainer;

    // Setup menu button

    UIImage *profileImg = [UIImage imageNamed:@"IconProfile.png"];

    if ([profileImg respondsToSelector:@selector(imageWithRenderingMode:)]) {
        profileImg = [profileImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }

    UIBarButtonItem *butProfile = [[UIBarButtonItem alloc] initWithImage:profileImg
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(profilePressed)];
    self.navigationItem.leftBarButtonItem = butProfile;
    
//    UIView * refreshWrapper = [[UIView alloc] initWithFrame:CGRectMake(0, 400, self.view.frame.size.width, 60)];
//    refreshWrapper.backgroundColor = [UIColor redColor];
    

    self.refreshControl = [[UIRefreshControl alloc] init];
    
    
    // Setup the loading view, which will hold the moving graphics
    self.refreshLoadingView = [[UIView alloc] initWithFrame:self.refreshControl.bounds];
    self.refreshLoadingView.backgroundColor = [UIColor clearColor];
    
    // Setup the color view, which will display the rainbowed background
    self.refreshColorView = [[UIView alloc] initWithFrame:self.refreshControl.bounds];
    self.refreshColorView.backgroundColor = [UIColor clearColor];
    self.refreshColorView.alpha = 0.30;
    
    // Create the graphic image views
    self.compass_background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"compass_background.png"]];
    self.compass_spinner = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"compass_spinner.png"]];
    
    // Add the graphics to the loading view
    [self.refreshLoadingView addSubview:self.compass_background];
    [self.refreshLoadingView addSubview:self.compass_spinner];
    
    // Clip so the graphics don't stick out
    self.refreshLoadingView.clipsToBounds = YES;
    
    // Hide the original spinner icon
    self.refreshControl.tintColor = [UIColor clearColor];
    
    // Add the loading and colors views to our refresh control
    [self.refreshControl addSubview:self.refreshColorView];
    [self.refreshControl addSubview:self.refreshLoadingView];
    
    // Initalize flags
    self.isRefreshIconsOverlap = NO;
    self.isRefreshAnimating = NO;
    
//    [refreshWrapper addSubview:self.refreshControl];
//    [self.view addSubview:refreshWrapper];
    
    
//
    if (!IS_IOS7) {
        self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
    }
    [self.refreshControl addTarget:self action:@selector(onUserRefreshed) forControlEvents:UIControlEventValueChanged];

    [self updateEmptyState];

    // Set required taps and number of touches
    UITapGestureRecognizer *touchOnView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(releaseOverlay)];
    [touchOnView setNumberOfTapsRequired:1];
    [touchOnView setNumberOfTouchesRequired:1];
    [self.tableOverlayView addGestureRecognizer:touchOnView];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(somethingChangedInAlbumwithId:)
                                                 name:NOTIFICATIONCENTER_ALBUM_CHANGED
                                               object:nil];

    ShotVibeAppDelegate *app = (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];
    networkOnline_ = [app.networkStatusManager registerListenerWithSLNetworkStatusManager_Listener:self];
    [self updateNetworkStatusNavBar];

    RCLogTimestamp();

    if (IS_IOS7) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
    
    
//    [[ShotVibeAppDelegate sharedDelegate] setUserScore:[[[ShotVibeAppDelegate sharedDelegate].albumManager getShotVibeAPI] getUserGlanceScoreWithLong:[[[[ShotVibeAppDelegate sharedDelegate].albumManager getShotVibeAPI] getAuthData] getUserId]]];
    
    
//    int score = [[albumManager_ getShotVibeAPI] getUserGlanceScoreWithLong:[[[albumManager_ getShotVibeAPI] getAuthData] getUserId]];
    
    
//    NSString  *fileNamePath = [[NSBundle mainBundle] pathForResource:@"welcome" ofType:@"mov"];
//    _asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:fileNamePath]];
//    _playerItem =[[AVPlayerItem alloc]initWithAsset:_asset];
//    _player = [[AVPlayer alloc]initWithPlayerItem:_playerItem];
//    _playerLayer =[AVPlayerLayer playerLayerWithPlayer:_player];
//    [_playerLayer setFrame:CGRectMake(0, 0, app.window.frame.size.width, app.window.frame.size.height)];
//    [_playerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
//    [app.window.layer addSublayer:_playerLayer];
//    [_player seekToTime:kCMTimeZero];
//    [_player play];
//    self.de


    
    
    
}


-(void)scrollViewDidScroll:(UIScrollView *)scrollView {


    // Get the current size of the refresh controller
    CGRect refreshBounds = self.refreshControl.bounds;
    
    // Distance the table has been pulled >= 0
    CGFloat pullDistance = MAX(0.0, -self.refreshControl.frame.origin.y);
    
    // Half the width of the table
    CGFloat midX = self.tableView.frame.size.width / 2.0;
    
    // Calculate the width and height of our graphics
    CGFloat compassHeight = self.compass_background.bounds.size.height;
    CGFloat compassHeightHalf = compassHeight / 2.0;
    
    CGFloat compassWidth = self.compass_background.bounds.size.width;
    CGFloat compassWidthHalf = compassWidth / 2.0;
    
    CGFloat spinnerHeight = self.compass_spinner.bounds.size.height;
    CGFloat spinnerHeightHalf = spinnerHeight / 2.0;
    
    CGFloat spinnerWidth = self.compass_spinner.bounds.size.width;
    CGFloat spinnerWidthHalf = spinnerWidth / 2.0;
    
    // Calculate the pull ratio, between 0.0-1.0
    CGFloat pullRatio = MIN( MAX(pullDistance, 0.0), 100.0) / 100.0;
    
    // Set the Y coord of the graphics, based on pull distance
    CGFloat compassY = pullDistance / 2.0 - compassHeightHalf;
    CGFloat spinnerY = pullDistance / 2.0 - spinnerHeightHalf;
    
    // Calculate the X coord of the graphics, adjust based on pull ratio
    CGFloat compassX = (midX + compassWidthHalf) - (compassWidth * pullRatio);
    CGFloat spinnerX = (midX - spinnerWidth - spinnerWidthHalf) + (spinnerWidth * pullRatio);
    
    // When the compass and spinner overlap, keep them together
    if (fabsf(compassX - spinnerX) < 1.0) {
        self.isRefreshIconsOverlap = YES;
    }
    
    // If the graphics have overlapped or we are refreshing, keep them together
    if (self.isRefreshIconsOverlap || self.refreshControl.isRefreshing) {
        compassX = midX - compassWidthHalf;
        spinnerX = midX - spinnerWidthHalf;
    }
    
    // Set the graphic's frames
    CGRect compassFrame = self.compass_background.frame;
    compassFrame.origin.x = compassX;
    compassFrame.origin.y = compassY;
    
    CGRect spinnerFrame = self.compass_spinner.frame;
    spinnerFrame.origin.x = spinnerX;
    spinnerFrame.origin.y = spinnerY;
    
    self.compass_background.frame = compassFrame;
    self.compass_spinner.frame = spinnerFrame;
    
    // Set the encompassing view's frames
    refreshBounds.size.height = pullDistance;
    
    self.refreshColorView.frame = refreshBounds;
    self.refreshLoadingView.frame = refreshBounds;
    
    // If we're refreshing and the animation is not playing, then play the animation
    if (self.refreshControl.isRefreshing && !self.isRefreshAnimating) {
        [self animateRefreshView];
    }
    
    DLog(@"pullDistance: %.1f, pullRatio: %.1f, midX: %.1f, isRefreshing: %i", pullDistance, pullRatio, midX, self.refreshControl.isRefreshing);
}



- (void)animateRefreshView
{
    // Background color to loop through for our color view
    NSArray *colorArray = @[[UIColor redColor],[UIColor blueColor],[UIColor purpleColor],[UIColor cyanColor],[UIColor orangeColor],[UIColor magentaColor]];
    static int colorIndex = 0;
    
    // Flag that we are animating
    self.isRefreshAnimating = YES;
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         // Rotate the spinner by M_PI_2 = PI/2 = 90 degrees
                         [self.compass_spinner setTransform:CGAffineTransformRotate(self.compass_spinner.transform, M_PI_2)];
                         
                         // Change the background color
                         self.refreshColorView.backgroundColor = [colorArray objectAtIndex:colorIndex];
                         colorIndex = (colorIndex + 1) % colorArray.count;
                     }
                     completion:^(BOOL finished) {
                         // If still refreshing, keep spinning, else reset
                         if (self.refreshControl.isRefreshing) {
                             [self animateRefreshView];
                         }else{
                             [self resetAnimation];
                         }
                     }];
}

- (void)resetAnimation
{
    // Reset our flags and background color
    self.isRefreshAnimating = NO;
    self.isRefreshIconsOverlap = NO;
    self.refreshColorView.backgroundColor = [UIColor clearColor];
}




-(void)uploadImageAfterTransitionFromFriends {

}

- (void)goToAlbumId:(long long int)num startImidiatly:(BOOL)start addAlbumContents:(SLAlbumContents*)album {

//    SLAlbumSummary *album = [albumList objectAtIndex:indexPath.row];
    [[GLSharedCamera sharedInstance] setCameraInFeed];
//    [[GLSharedCamera sharedInstance] setInFeedMode:YES dmutNeedTransform:NO];
    
    [self.navigationController setNavigationBarHidden:YES];
    
    GLFeedViewController * feed = [[GLFeedViewController alloc] init];
    if(album != nil){
        feed.contentsFromOutside = album;
    }
    feed.albumId = num;
    if(start){
        feed.startImidiatly = YES;
    } else {
        feed.startImidiatly = NO;
    }
//    feed.
    [self.navigationController pushViewController:feed animated:YES];
    
    
}



//-(void)dmutTapped {
//
//    ShotVibeAppDelegate *appDelegate = (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];
//
//    
//    if(cameraShown){
//        
//        [UIView animateWithDuration:0.25 animations:^{
//            
//            //        [[[GLSharedCamera sharedInstance] view] setFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
//            dmut.frame = CGRectMake(27, ([UIScreen mainScreen].bounds.size.height/3)-90
//                                    , 320, 110);
//            cameraWrapper.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height/3);
//            
//        }];
//    
//    } else {
//        
//        [UIView animateWithDuration:0.25 animations:^{
//            
//            //        [[[GLSharedCamera sharedInstance] view] setFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
//            dmut.frame = CGRectMake(27, ([UIScreen mainScreen].bounds.size.height)-157, 320, 110);
//            cameraWrapper.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
//            
//        }];
//        
//    }
//    
//    
//    
//    
//    cameraShown = !cameraShown;
//
//
//}


- (void)updateNetworkStatusNavBar
{
    UIImage *managementButtonImg = [UIImage imageNamed:@"IconSettings.png"];
    
    if ([managementButtonImg respondsToSelector:@selector(imageWithRenderingMode:)]) {
        managementButtonImg = [managementButtonImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }

    UIBarButtonItem *managementButton = [[UIBarButtonItem alloc] initWithImage:managementButtonImg
                                                                         style:UIBarButtonItemStyleBordered
                                                                        target:self
                                                                        action:@selector(settingsPressed)];

    UIImage *networkButtonImg = [UIImage imageNamed:@"IconNotConnected.png"];

    if ([networkButtonImg respondsToSelector:@selector(imageWithRenderingMode:)]) {
        networkButtonImg = [networkButtonImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }

    if (networkOnline_) {
        self.navigationItem.rightBarButtonItems = [[NSArray alloc] initWithObjects:
                                                   managementButton,
                                                   nil];
    } else {
        UIBarButtonItem *notConnectedButton = [[UIBarButtonItem alloc] initWithImage:networkButtonImg
                                                                               style:UIBarButtonItemStyleBordered
                                                                              target:self
                                                                              action:@selector(notConnectedPressed)];

        self.navigationItem.rightBarButtonItems = [[NSArray alloc] initWithObjects:
                                                   managementButton,
                                                   notConnectedButton,
                                                   nil];
    }

    if (IS_IOS7) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
}


- (void)viewWillAppear:(BOOL)animated {
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[NSUserDefaults standardUserDefaults] setInteger:[[[ShotVibeAppDelegate sharedDelegate].albumManager getShotVibeAPI] getUserGlanceScoreWithLong:[[[[ShotVibeAppDelegate sharedDelegate].albumManager getShotVibeAPI] getAuthData] getUserId]] forKey:@"kUserScore"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[GLSharedCamera sharedInstance] score] setText:[NSString stringWithFormat:@"%ld",(long)[[NSUserDefaults standardUserDefaults] integerForKey:@"kUserScore"]]];
        });
    });
    
    
    
	
//    [[[GLSharedCamera sharedInstance]cameraViewBackground]setAlpha:0];
    [super viewWillAppear:animated];
    
    UIImageView * background = [[UIImageView alloc] initWithFrame:CGRectMake(0, 202, self.view.frame.size.width, 130)];
    background.image = [UIImage imageNamed:@"refrehBg"];
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.refreshControl addSubview:background];
//    [self.view bringSubviewToFront:self.tableView];
//    [[self.refreshControl.subviews objectAtIndex:0] setFrame:CGRectMake(30, 400, 20, 50)];
//    self.refreshControl.bounds = CGRectMake(self.refreshControl.bounds.origin.x,
//                                            802,
//                                            self.refreshControl.bounds.size.width,
//                                            self.refreshControl.bounds.size.height);
	
    [albumManager_ refreshAlbumListWithBoolean:NO];

	// Update the cell that was last tapped and maybe edited
	if (tappedCell != nil) {
		[self.tableView reloadRowsAtIndexPaths:@[tappedCell] withRowAnimation:UITableViewRowAnimationNone];
		tappedCell = nil;
	}
    if([[GLSharedCamera sharedInstance] isInFeedMode]){
        [[GLSharedCamera sharedInstance] setInFeedMode:NO dmutNeedTransform:NO];
    }
    GLSharedCamera * camera = [GLSharedCamera sharedInstance];
    camera.picYourGroup.alpha = 1;
    camera.cameraViewBackground.userInteractionEnabled = YES;
    camera.delegate = [ContainerViewController sharedInstance];
    
}

- (void)viewDidAppear:(BOOL)animated {
	
	[super viewDidAppear:animated];
	
	self.menuContainerViewController.panMode = MFSideMenuPanModeNone;
	cameraNavController = nil;

    [self promptNickChange];
    [albumManager_ refreshAlbumListWithBoolean:NO];
    
//    [self.refreshControl setFrame:CGRectMake(0, 400, 50, 50)];
    
}

- (void)openAppleImagePicker {
    
    
    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    //    glcamera.delegate = self;
    
    //    glcamera.delegate
    //     glcamera.imagePickerDelegate = picker.delegate;
    picker.delegate = self;
    
    
    //    fromImagePicker = YES;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:^{
        
        //        [appDelegate.window sendSubviewToBack:glcamera.view];
        
        [UIView animateWithDuration:0.3 animations:^{
            glcamera.view.alpha = 0;
            [glcamera hideForPicker:YES];
//            glcamera.
        }];
    }];
    
    
    
    
    
}
//-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
//    [[GLSharedCamera sharedInstance] retrievePhotoFromPicker:info[UIImagePickerControllerEditedImage]];
//}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
    
    [UIView animateWithDuration:0.3 animations:^{
        glcamera.view.alpha = 1;
        [glcamera hideForPicker:NO];
        //            glcamera.
    }];
    
}

- (void)viewWillDisappear:(BOOL)animated {
	
    [super viewWillDisappear:animated];
    
    [thumbnailCache removeAllObjects];
    
    if (self.albumField.isFirstResponder) {
        [self.albumField resignFirstResponder];
    }
    else if (self.searchbar.isFirstResponder) {
        [self.searchbar resignFirstResponder];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}


- (BOOL)shouldAutorotate
{
    return NO;
}


- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}


#pragma mark - Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [thumbnailCache removeAllObjects];
}


#pragma mark - Misc

+ (NSString *)getAlbumOrg:(SLAlbumBase *)album
{
    const unichar ZERO_WIDTH_SPACE = L'\u200B';

    // This is a hack we use to determine which albums are part of an organization.

    // If the album name starts with a sequence of the special invisible
    // character then it is part of the org whose number is the length of the
    // sequence

    int counter = 0;
    while ([album getName].length > counter && [[album getName] characterAtIndex:counter] == ZERO_WIDTH_SPACE) {
        counter++;
    }

    switch (counter) {
        case 0:
            return nil;

        case 1:
            return @"walla";

        case 2:
            return @"easyweb";

        case 3:
            return @"shvoong";

        case 4:
            return @"orange";
    }
    return nil;
}


#pragma mark - Actions


- (void)notConnectedPressed
{
    [NetworkLogViewController showNetworkErrorDialog:self];
}


- (void)profilePressed {
    [[Mixpanel sharedInstance] track:@"Profile Button Pressed"];

	tappedCell = nil;
	[self performSegueWithIdentifier:@"ProfileSegue" sender:nil];
}

- (void)settingsPressed {
    [[Mixpanel sharedInstance] track:@"Settings Button Pressed"];

	tappedCell = nil;
    [self performSegueWithIdentifier:@"SettingsSegue" sender:nil];
}

- (IBAction)newAlbumPressed:(id)sender {
    [[Mixpanel sharedInstance] track:@"New Album Button Pressed"];

    [self showDropDown];
	//	ShotVibeAppDelegate *app = [ShotVibeAppDelegate sharedDelegate];
	//	NSDictionary *dic = @{@"aps":@{@"alert":@"Just added few pics to your album"}};
	//	[app application:nil didReceiveRemoteNotification:dic];
}

- (IBAction)newAlbumClosed:(id)sender {
    [[Mixpanel sharedInstance] track:@"New Album Canceled"];

    [self hideDropDown];
}

- (IBAction)newAlbumDone:(id)sender {
    [[Mixpanel sharedInstance] track:@"New Album Done"];

	NSString *name = self.albumField.text.length == 0 ? self.albumField.placeholder : self.albumField.text;
    [self createNewAlbumWithTitle:name];
    [self hideDropDown];
}

- (IBAction)takePicturePressed:(id)sender
{
    [[Mixpanel sharedInstance] track:@"Take a Picture Pressed"];
//	int capacity = 8;
//	int i = 0;
//
//	NSMutableArray *albums = [[NSMutableArray alloc] initWithCapacity:capacity];
//
//	for (AlbumSummary *album in albumList) {
//		[albums addObject:album];
//		i++;
//		if (i>=capacity) {
//			break;
//		}
//	}

    SVPickerController *manager = [[SVPickerController alloc] init];
    SVNonRotatingNavigationControllerViewController *nc = [[SVNonRotatingNavigationControllerViewController alloc] initWithRootViewController:manager];
    [self presentViewController:nc animated:NO completion:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showAlbumSelector:) name:@"kSVPickAlbumToUpload" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelAlbumSelector:) name:@"kSVPickAlbumCancel" object:nil];

    self.pickerController = nc;
//    cameraNavController = [[SVCameraNavController alloc] init];
//	cameraNavController.cameraDelegate = self;
//	cameraNavController.albums = albums;
//	cameraNavController.albumManager = self.albumManager;
//    cameraNavController.nav = (SVNavigationController*)self.navigationController;// this is set last
}


- (void)cancelAlbumSelector:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showAlbumSelector:) name:@"kSVPickAlbumToUpload" object:nil];

    if (![self.pickerController presentingViewController]) {
        [self presentViewController:self.pickerController animated:NO completion:^{
            self.view.hidden = NO;
        }];
    }
}


- (void)showAlbumDetails:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"kSVShowAlbum" object:nil];

    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    SVAlbumGridViewController *controller = (SVAlbumGridViewController *)[mainStoryboard instantiateViewControllerWithIdentifier:@"SVAlbumGridViewController"];
    controller.albumId = [[notification userInfo][@"albumId"] integerValue];
    controller.scrollToTop = YES;
    [self.navigationController pushViewController:controller animated:YES];
}


- (void)showAlbumSelector:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"kSVPickAlbumToUpload" object:nil];

    NSArray *images = [notification userInfo][@"images"];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    SVMultiplePicturesViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"MultiplePicturesViewController"];
    controller.images = images;
    controller.albums = albumList;
    [self.navigationController pushViewController:controller animated:YES];
}


#pragma mark Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"AlbumGridViewSegue"]) {
        // Get the selected Album
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        SLAlbumSummary *album = [albumList objectAtIndex:indexPath.row];

        // Get the destination controller
        SVAlbumGridViewController *destinationController = segue.destinationViewController;
        destinationController.albumId = [album getId];
    } else if ([segue.identifier isEqualToString:@"SettingsSegue"]) {
        SVSettingsViewController *destinationController = segue.destinationViewController;
    } else if ([segue.identifier isEqualToString:@"ProfileSegue"]) {
        SVProfileViewController *destinationController = segue.destinationViewController;
    } else if ([segue.identifier isEqualToString:@"PromptNickChangeSegue"]) {
        SVProfileViewController *destinationController = segue.destinationViewController;
        destinationController.shouldPrompt = YES;
    } else if ([segue.identifier isEqualToString:@"AlbumsToImagePickerSegue"]) {
		
        SLAlbumSummary *album = (SLAlbumSummary *)sender;
		
        SVNavigationController *destinationNavigationController = (SVNavigationController *)segue.destinationViewController;
        SVImagePickerListViewController *destination = [destinationNavigationController.viewControllers objectAtIndex:0];
        destination.albumId = [album getId];
        destination.nav = self.navigationController;
    }
}


#pragma mark AlbumGrid delegate

- (void)somethingChangedInAlbumwithId:(NSNotification *)notification {
	
	RCLog(@"somethingChangedInAlbumwithId %@", notification.userInfo);
	NSDictionary *userInfo = notification.userInfo;
    int64_t albumId = [[userInfo objectForKey:@"albumId"] longLongValue];
	
	int i = 0;
    for (SLAlbumSummary *album in albumList) {
        RCLog(@"album.albumId == albumId %lli %lli", [album getId], albumId);
        if ([album getId] == albumId) {
			break;
		}
		i++;
	}
	
	if (i >= albumList.count) {
		RCLog(@"Fatal error, no album with the selected id was found. It might be 0 which means a bug in the code that sent the notification");
		return;
	}
	
    SLAlbumSummary *album = [albumList objectAtIndex:i];

    // TODO:
    SLDateTime *dummyDateCreated = [SLDateTime ParseISO8601WithNSString:@"2000-01-01T00:00:00Z"];

    SLAlbumSummary *newAlbum = [[SLAlbumSummary alloc] initWithLong:[album getId]
                                                       withNSString:[album getEtag]
                                                       withNSString:[album getName]
                                                    withSLAlbumUser:[album getCreator]
                                                     withSLDateTime:[album getDateCreated]
                                                     withSLDateTime:dummyDateCreated
                                                           withLong:[album getNumNewPhotos]
                                                     withSLDateTime:[album getLastAccess]
                                                    withSLArrayList:[album getLatestPhotos]];

	//album.dateUpdated = [NSDate date];
	[albumList removeObjectAtIndex:i];
	[albumList insertObject:newAlbum atIndex:0];
	
	[self.tableView beginUpdates];
	[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
	[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
	[self.tableView endUpdates];
}


#pragma mark Cell delegate

- (void)cameraButtonTapped:(UITableViewCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    SLAlbumSummary *album = [albumList objectAtIndex:indexPath.row];

    SVPickerController *manager = [[SVPickerController alloc] init];
    manager.albumId = [album getId];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showAlbumDetails:) name:@"kSVShowAlbum" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelAlbumSelector:) name:@"kSVPickAlbumCancel" object:nil];

    SVNonRotatingNavigationControllerViewController *nc = [[SVNonRotatingNavigationControllerViewController alloc] initWithRootViewController:manager];
    [self presentViewController:nc animated:NO completion:nil];

    //	cameraNavController = [[SVCameraNavController alloc] init];
    //	cameraNavController.cameraDelegate = self;
    //	cameraNavController.albumId = album.albumId;
    //	cameraNavController.albumManager = self.albumManager;
    //    cameraNavController.nav = (SVNavigationController*)self.navigationController;// this is set last
}


-(void)transitToAlbumWithId:(long long int)albumId animated:(BOOL)animated dmutScale:(BOOL)scale {
    
    if(albumId != 0){
        [[GLSharedCamera sharedInstance] setCameraInFeed];
//        [[GLSharedCamera sharedInstance] setInFeedMode:YES dmutNeedTransform:scale];
        [self.navigationController setNavigationBarHidden:YES];
        GLFeedViewController * feed = [[GLFeedViewController alloc] init];
        feed.albumId = albumId;
        [self.navigationController pushViewController:feed animated:animated];
        [[ContainerViewController sharedInstance] lockScrolling:YES];
    }
}

- (void)libraryButtonTapped:(UITableViewCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    SLAlbumSummary *album = [albumList objectAtIndex:indexPath.row];

    [self performSegueWithIdentifier:@"AlbumsToImagePickerSegue" sender:album];
}

- (void)selectCell:(SVAlbumListViewCell*)cell {
    
    self.tableView.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:0.2 animations:^{
       
//        cell.frontView.backgroundColor = [UIColor lightGrayColor];
        
        cell.frontView.backgroundColor = [UIColor blackColor];
                cell.author.textColor = [UIColor whiteColor];
                [cell.timestamp setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                cell.title.textColor = [UIColor whiteColor];
        
    } completion:^(BOOL finished) {
        
        [UIView animateWithDuration:0.2 animations:^{
           
//            cell.frontView.backgroundColor = [UIColor whiteColor];
//            cell.author.textColor = [UIColor blackColor];
//            [cell.timestamp setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//            cell.title.textColor = [UIColor blackColor];
            
        } completion:^(BOOL finished) {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            //        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
            
            
            SLAlbumSummary *album = [albumList objectAtIndex:indexPath.row];
            
            [self transitToAlbumWithId:[album getId] animated:YES dmutScale:YES];
            self.tableView.userInteractionEnabled = YES;
        }];
        
        
        
    }];
    
   
    
    
    
//    [[ContainerViewController sharedInstance] transitToFriendsList:YES direction:UIPageViewControllerNavigationDirectionForward completion:^{
//        NSLog(@"DONE");
//    }];
    
    
    
//    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"YES" forKey:@"lockScroll"];
//    [[NSNotificationCenter defaultCenter] postNotificationName: @"LockScrollingInContainerPages" object:nil userInfo:userInfo];
//    [[NSNotificationCenter defaultCenter]
//     postNotificationName:@"LockScrollingInContainerPages"
//     object:self];
    
//    NSMutableArray *leftBtns = [[NSMutableArray alloc] init];
//    
//    UIBarButtonItem *leftBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Icon-40"] style:UIBarButtonItemStylePlain target:self action:@selector(leftButtonPressed)];
//    
//    [leftBtns addObject:leftBtn];
    

//    UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Show" style:UIBarButtonItemStylePlain target:self action:@selector(refreshPropertyList:)];
    
    
//    UIButton * but = [];
    
//    UIButton * flipCameraButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-65, 10, 60, 60)];
//    UIImage *btnImage = [UIImage imageNamed:@"FlipCameraIcon"];
//    [flipCameraButton addTarget:self action:@selector(flipCamera) forControlEvents:UIControlEventTouchUpInside];
//    [flipCameraButton setImage:btnImage forState:UIControlStateNormal];
//    [self.navigationController.view addSubview:flipCameraButton];
    
    
//    ShotVibeAppDelegate *appDelegate = (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];

//    [UIView animateWithDuration:0.2 animations:^{
//        
////        UIColor * color = cell.backgroundColor;
//        cell.backgroundColor = [UIColor lightGrayColor];
////
//        
////        dmut.alpha = 0;
////        [[[GLSharedCamera sharedInstance] view] setAlpha:0];
//    }];
    
    
    
    
//    self.navigationItem.leftBarButtonItem = anotherButton;
//    [self.navigationController.navigationItem setRightBarButtonItem:anotherButton];
//    [self.navigationController.navigationItem setRightBarButtonItems:leftBtns animated:NO];
//    [self presentViewController:feedView animated:YES completion:nil];
    
    
    
//    [self performSegueWithIdentifier: @"AlbumGridViewSegue" sender: cell];
}

-(void)flipCamera {
    [[GLSharedCamera sharedInstance] showCamera];
}

#pragma mark camera delegate

- (void)cameraExit {
	RCLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> cameraExit");
	
}


- (void)cameraWasDismissedWithAlbum:(SLAlbumSummary *)selectedAlbum
{
    RCLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> cameraWasDismissedWithAlbum %@", [selectedAlbum getName]);
}



#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	self.sectionHeader.frame = CGRectMake(0, 0, self.view.frame.size.width, ([UIScreen mainScreen].bounds.size.height/3)-20);
	return self.sectionHeader;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return ([UIScreen mainScreen].bounds.size.height/3)-20;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return ([UIScreen mainScreen].bounds.size.height-([UIScreen mainScreen].bounds.size.height/3))/6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return albumList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    
    
    
    
    
    SVAlbumListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SVAlbumListCell"];
//	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.delegate = self;
	cell.parentTableView = self.tableView;
//    
//    cell.scrollView.frame = cell.frame;
//    cell.frontView.frame = cell.frame;
    
    cell.numberNotViewedIndicator.backgroundColor = UIColorFromRGB(0x3eb4b6);
    cell.numberNotViewedIndicator.layer.cornerRadius = cell.numberNotViewedIndicator.frame.size.width/2.1;
//    cell.numberNotViewedIndicator.layer.borderWidth = 1;
//    cell.numberNotViewedIndicator.layer.borderColor = UIColorFromRGB(0x000000).CGColor;
//    cell.textLabel.textColor = [UIColor whiteColor];
    SLAlbumSummary *album = [albumList objectAtIndex:indexPath.row];
    if ([album getNumNewPhotos] > 0) {
        NSString *title = [album getNumNewPhotos] > 99 ? @"99+" : [NSString stringWithFormat:@"%lld", [album getNumNewPhotos]];
        [cell.numberNotViewedIndicator setTitle:title forState:UIControlStateNormal];
        cell.numberNotViewedIndicator.hidden = NO;
    } else
        cell.numberNotViewedIndicator.hidden = YES;


    long long seconds = [[album getDateUpdated] getTimeStamp] / 1000000LL;
    NSDate *dateUpdated = [[NSDate alloc] initWithTimeIntervalSince1970:seconds];
    NSString *distanceOfTimeInWords = [dateUpdated distanceOfTimeInWords];

    cell.tag = indexPath.row;
    cell.title.text = [album getName];
    cell.author.text = @"";
    cell.timestamp.hidden = YES;

    [cell.networkImageView setImage:nil];
	// TODO: ltestPhotos might be nil if we insert an AlbumContents instead AlbumSummary
    if ([album getLatestPhotos].array.count > 0) {
        
//        [[albumManager_ getShotVibeAPI] get]
        
//        [[albumManager_ getShotVibeAPI] getAlbumContentsWithLong:album];
//        album get
        
        cell.networkImageView.layer.cornerRadius = cell.networkImageView.frame.size.width/2;
        SLAlbumPhoto *latestPhoto = [[album getLatestPhotos].array objectAtIndex:0];
        if ([latestPhoto getServerPhoto]) {
            
            cell.author.text = [NSString stringWithFormat:NSLocalizedString(@"Last added by %@", nil), [[[latestPhoto getServerPhoto] getAuthor] getMemberNickname]];

            
            if([[latestPhoto getServerPhoto] getMediaType] == [SLAlbumServerPhoto_MediaTypeEnum VIDEO]){
                
               
//                SDWebImageManager *manager = [SDWebImageManager sharedManager];
//                [manager downloadImageWithURL:[NSURL URLWithString:[[[latestPhoto getServerPhoto] getVideo] getVideoThumbnailUrl]] options:SDWebImageHighPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {} completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL)
//                 {
//                     
//                     if (image) {
//                          cell.networkImageView.image = image;
//                         
//                         //                [self.contentView bringSubviewToFront:self.moviePlayer.view];
//                         //                [self.moviePlayer.view setAlpha:1];
//                     }
//                     
//                 }];
                
                [cell.networkImageView.imageView_ sd_setImageWithURL:[NSURL URLWithString:[[[latestPhoto getServerPhoto] getVideo]getVideoThumbnailUrl]] placeholderImage:[UIImage imageNamed:@""]];
                
//                [cell.networkImageView setPhoto:[[latestPhoto getServerPhoto] getId] photoUrl:[[[latestPhoto getServerPhoto] getVideo]getVideoThumbnailUrl] photoSize:[PhotoSize Thumb75] manager:photoFilesManager_];
                
            } else {
                [cell.networkImageView setPhoto:[[latestPhoto getServerPhoto] getId]
                                   photoUrl:[[latestPhoto getServerPhoto] getUrl]
                                  photoSize:[PhotoSize Thumb75]
                                    manager:photoFilesManager_];
            }
            
            [cell.timestamp setTitle:distanceOfTimeInWords forState:UIControlStateNormal];
            cell.timestamp.hidden = NO;
        }
    }
	else {
		[cell.networkImageView setImage:[UIImage imageNamed:@"placeholderImage"]];
        cell.author.text = NSLocalizedString(@"Empty album", nil);
	}

    NSString *org = [SVAlbumListViewController getAlbumOrg:album];
    if (org) {
        cell.albumOrgOverlay.hidden = NO;
        cell.albumOrgOverlay.image = [UIImage imageNamed:[org stringByAppendingString:@"_ribbon_overlay"]];
    } else {
        cell.albumOrgOverlay.hidden = YES;
    }
    
//    if(!((indexPath.row/2)%2)){
        cell.frontView.backgroundColor = [UIColor whiteColor];
//    cell.frontView setba
        cell.author.textColor = [UIColor blackColor];
        [cell.timestamp setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        cell.title.textColor = [UIColor blackColor];
//    } else {
//        cell.frontView.backgroundColor = [UIColor blackColor];
//        cell.author.textColor = [UIColor whiteColor];
//        [cell.timestamp setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//        cell.title.textColor = [UIColor whiteColor];
//    }
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
//	cell.backgroundColor = [UIColor purpleColor];
    
//    BOOL t = ;
    

    if (creatingAlbum) // Navigate to the newly created album
        [self performSegueWithIdentifier: @"AlbumGridViewSegue" sender: cell];
}


#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.searchbar resignFirstResponder];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    tappedCell = [indexPath copy];
    // The rest of the actions are made through the segue in IB
}


#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	
	if (textField == self.albumField) {
		[self newAlbumDone:nil];
	}
    return YES;
}


#pragma mark - UISearchbarDelegate Methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
	
	[searchBar setShowsCancelButton:YES animated:YES];
	
//	[UIView animateWithDuration:0.4 animations:^{
//		self.tableView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-KEYBOARD_H-status_bar_h);
//	}];
	
	searchShowing = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:NO animated:YES];

//	self.tableView.frame = CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-total_header_h);

//    [self.tableView setContentOffset:CGPointMake(0, 44) animated:YES];

    searchShowing = NO;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self searchForAlbumWithTitle:searchBar.text];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    [self searchForAlbumWithTitle:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	[searchBar resignFirstResponder];
	searchBar.text = @"";
	[self searchForAlbumWithTitle:nil];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)bar {
    return YES;
}

- (void)searchForAlbumWithTitle:(NSString *)title
{
	albumList = [NSMutableArray arrayWithCapacity:[allAlbums count]];

    for (SLAlbumSummary *album in allAlbums) {
        if (title == nil || [title isEqualToString:@""] || [[[album getName] lowercaseString] rangeOfString:title].location != NSNotFound) {
			[albumList addObject:album];
		}
    }
    [self.tableView reloadData];
}





#pragma mark - Private Methods

- (void) updateEmptyState
{
	if (albumList.count == 0) {
    
        GLSharedCamera * cam =  [GLSharedCamera sharedInstance];
        
        
		self.noPhotosView.frame = CGRectMake(0,cam.cameraViewBackground.frame.size.height-20, self.view.frame.size.width, self.view.frame.size.height-cam.cameraViewBackground.frame.size.height-20);
		[self.view addSubview:self.noPhotosView];
		self.butTakePicture.enabled = NO;
	} else {
		[self.noPhotosView removeFromSuperview];
		self.butTakePicture.enabled = YES;
	}
}

- (void) releaseOverlay {
	
	if (searchShowing) {
		[self.searchbar resignFirstResponder];
		self.tableOverlayView.hidden = YES;
		self.tableOverlayView.alpha = 0;
	}
}


#pragma mark drop down stuffs

- (void)showDropDown
{
//	[self.tableView setContentOffset:CGPointMake(0,table_content_offset_y) animated:YES];
	[self.view addSubview:self.tableOverlayView];
	
	CGRect r = self.tableOverlayView.frame;
	r.origin.y = dropdown_origin_y;
	self.tableOverlayView.frame = r;
	self.tableOverlayView.alpha = 0;
    self.tableOverlayView.hidden = NO;
    self.dropDownContainer.hidden = NO;
	self.butAlbum.enabled = NO;
	self.butTakePicture.enabled = NO;
	self.tableView.scrollEnabled = NO;
    
    NSString *currentDateString = [NSDateFormatter localizedStringFromDate:[NSDate date]
																 dateStyle:NSDateFormatterLongStyle
																 timeStyle:NSDateFormatterNoStyle];
    self.albumField.text = @"";
	self.albumField.placeholder = currentDateString;
    
    [UIView animateWithDuration:0.5 animations:^{
        self.tableOverlayView.alpha = 1;
        self.dropDownContainer.frame = CGRectMake(8, -4, self.dropDownContainer.frame.size.width, 134);
    } completion:^(BOOL finished) {
        [self.albumField becomeFirstResponder];
    }];
}


- (void)hideDropDown
{
	[self.albumField resignFirstResponder];
	
	[UIView animateWithDuration:0.3 animations:^{
        self.tableOverlayView.alpha = 0.0;
        self.dropDownContainer.frame = CGRectMake(8, -134, self.dropDownContainer.frame.size.width, 134);
    } completion:^(BOOL finished) {
        self.tableOverlayView.hidden = YES;
        self.dropDownContainer.hidden = YES;
		self.butAlbum.enabled = YES;
		self.butTakePicture.enabled = YES;
		self.tableView.scrollEnabled = YES;
    }];
}


- (void)createNewAlbumWithTitle:(NSString *)title {
	
	RCLog(@"createNewAlbumWithTitle %@", title);
	[MBProgressHUD showHUDAddedTo:self.view animated:YES];
	
	// Write the album to server
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		
		creatingAlbum = YES;
        SLAlbumContents *albumContents = nil;
        SLAPIException *apiException = nil;
        @try {
            albumContents = [[albumManager_ getShotVibeAPI] createNewBlankAlbumWithNSString:title];
        } @catch (SLAPIException *exception) {
            apiException = exception;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (apiException) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Creating Album"
                                                                message:apiException.description
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            else {
                SLAlbumSummary *album = [[SLAlbumSummary alloc] initWithLong:[albumContents getId]
                                                                withNSString:[albumContents getEtag]
                                                                withNSString:[albumContents getName]
                                                             withSLAlbumUser:[albumContents getCreator]
                                                              withSLDateTime:[albumContents getDateCreated]
                                                              withSLDateTime:[albumContents getDateUpdated]
                                                                    withLong:[albumContents getNumNewPhotos]
                                                              withSLDateTime:[albumContents getLastAccess]
                                                             withSLArrayList:[[SLArrayList alloc] init]];

				[albumList insertObject:album atIndex:0];
				
				[self.tableView beginUpdates];
				[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
									  withRowAnimation:UITableViewRowAnimationAutomatic];
				[self.tableView endUpdates];
				[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
									  atScrollPosition:UITableViewScrollPositionTop
											  animated:YES];
				[self updateEmptyState];
            }
			[MBProgressHUD hideHUDForView:self.view animated:YES];
			creatingAlbum = NO;
        });
    });
}



- (void)setAlbumList:(NSArray *)albums {
	
	allAlbums = albums;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // Set all the album thumbnails to download at high priority
        for (SLAlbumSummary *a in albums) {
            if ([a getLatestPhotos].array.count > 0) {
                SLAlbumPhoto *p = [[a getLatestPhotos].array objectAtIndex:0];
                if ([p getServerPhoto]) {
                    [photoFilesManager_ queuePhotoDownload:[[p getServerPhoto] getId]
                                                  photoUrl:[[p getServerPhoto] getUrl]
                                                 photoSize:[PhotoSize Thumb75]
                                              highPriority:YES];
                }
            }
        }
    });

    [self searchForAlbumWithTitle:self.searchbar.text];
}

#pragma Prompt nickname change

// Check if the user has already set their nickname, and if not, prompt them to do this.
- (void)promptNickChange
{
    if ([UserSettings isNicknameSet]) {
        RCLog(@"Nickname was already set");
    } else {
        // TODO: Check with the server if the nickname really was not set yet, since now we will prompt also after a reinstall.
        if ([self.navigationController.viewControllers count] <= 1) {
            [self performSegueWithIdentifier:@"PromptNickChangeSegue" sender:nil];
        }
    }
}

#pragma mark UIRefreshView

- (void)onUserRefreshed
{
    [albumManager_ refreshAlbumListWithBoolean:YES];
}


- (void)showRefreshSpinner
{
    [self.refreshControl beginRefreshing];
    if (!IS_IOS7) {
        self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing albums..."];
    }
    // Need to call this whenever we scroll our table view programmatically
    [[NSNotificationCenter defaultCenter] postNotificationName:SVSwipeForOptionsCellEnclosingTableViewDidBeginScrollingNotification object:self.tableView];
}


- (void)hideRefreshSpinner
{
	[self.refreshControl endRefreshing];
	if (!IS_IOS7) self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
	//[self.tableView setContentOffset:CGPointMake(0,44) animated:YES];
}


- (void)onAlbumListBeginUserRefresh
{
    [self showRefreshSpinner];
}


- (void)onAlbumListNewContentWithSLArrayList:(SLArrayList *)albums
{
    NSLog(@"onAlbumListNewContents: size:%d", [albums size]);
	creatingAlbum = NO;
    [self setAlbumList:albums.array];
	[self updateEmptyState];
}

- (void)onAlbumListEndUserRefreshWithSLAPIException:(SLAPIException *)error
{
    [self hideRefreshSpinner];

    if (error) {
        // TODO Show error in "Toast"
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    // Need to do this to keep the view in a consistent state (layoutSubviews in the cell expects itself to be "closed")
    [[NSNotificationCenter defaultCenter] postNotificationName:SVSwipeForOptionsCellEnclosingTableViewDidBeginScrollingNotification object:self.tableView];
}


#pragma UIScrollViewDelegate Methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SVSwipeForOptionsCellEnclosingTableViewDidBeginScrollingNotification object:scrollView];
}

#pragma SLNetworkStatusManager_Listener Methods


- (void)networkStatusChangedWithBoolean:(BOOL)networkOnline
{
    dispatch_async(dispatch_get_main_queue(), ^{
        networkOnline_ = networkOnline;

        [self updateNetworkStatusNavBar];
    });
}


@end
