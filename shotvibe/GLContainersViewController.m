//
//  GLContainersViewController.m
//  shotvibe
//
//  Created by Tsah Kashkash on 28/12/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import "GLContainersViewController.h"

@interface GLContainersViewController ()

@end

static GLContainersViewController *sharedInstance;
@implementation GLContainersViewController

+ (GLContainersViewController *)sharedInstance
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[GLContainersViewController alloc] initWithNibName:@"GLContainersViewController" bundle:nil];
    });
    return sharedInstance;
}

- (void)enableSideMembers {
    self.membersSideMenu.panMode = MFSideMenuPanModeDefault;
}

- (void)disableSideMembers {
    self.membersSideMenu.panMode = MFSideMenuPanModeNone;
}

-(void)resetFriendsView {
    self.friendsViewController = nil;
    self.friendsViewController = [[SVAddFriendsViewController alloc] init];
//    self.friendsViewController.view.frame = CGRectMake(20, 100, 400, 400);
    self.friendsViewController.indexNumber = 0;
}


- (void)goBackToFeedAfterAddingMembersAnimated:(BOOL)animated {
    [self.pageController setViewControllers:@[self.membersSideMenu] direction:UIPageViewControllerNavigationDirectionForward animated:animated completion:^(BOOL finished) {
//        completed();
//        [self resetFriendsView];
        //        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    }];
}

- (void)goToFeedViewAnimated:(BOOL)animated withAlbumId:(long long int)albumId completed:(pageTransitionCompleted)completed {
    
    [self lockScrollingPages];
//    [[GLSharedCamera sharedInstance] setCameraInFeed];
    GLFeedViewController * feed = [[GLFeedViewController alloc] init];
    feed.albumId = albumId;
    [self.navigationController pushViewController:feed animated:animated];
    [self.pageController setViewControllers:@[self.membersSideMenu] direction:UIPageViewControllerNavigationDirectionForward animated:animated completion:^(BOOL finished) {
        completed();
//        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    }];
    
    
    
}

- (void)goToFeedViewAnimated:(BOOL)animated withAlbumId:(long long int)albumId  {
    
    [self lockScrollingPages];
//    [[GLSharedCamera sharedInstance] setCameraInFeed];
    GLFeedViewController * feed = [[GLFeedViewController alloc] init];
    feed.albumId = albumId;
    [self.navigationController pushViewController:feed animated:animated];
    [self.pageController setViewControllers:@[self.membersSideMenu] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL finished) {
        
    }];
    
    
    
}

- (void)goToAlbumListViewController:(BOOL)animated {
    
    [self unlockScrollingPages];
    
    __block GLContainersViewController * weakSelf = self;
    [self.pageController setViewControllers:@[self.membersSideMenu] direction:UIPageViewControllerNavigationDirectionForward animated:animated completion:^(BOOL finished) {
//        [weakSelf resetFriendsView];
    }];
    
}

- (void)goToFriendsListViewAnimatedBeforeAddingMembers:(BOOL)animated albumId:(long long int)albumId {

    [self lockScrollingPages];
    
    [[GLContainersViewController sharedInstance] resetFriendsView];
    
    if(albumId){
        self.friendsViewController.albumId = albumId;
    }
    self.friendsViewController.state = SVAddFriendsFromAddFriendButton;
    
    [self.pageController setViewControllers:@[self.friendsViewController] direction:UIPageViewControllerNavigationDirectionReverse animated:animated completion:^(BOOL finished) {
        
    }];
    
}

- (void)goToFriendsListViewAnimatedBeforeUploadingPhoto:(BOOL)animated completed:(pageTransitionCompleted)completed executeWhenFriendsDone:(BlockToExecuteWhenDone)friendsDoneBlock {
    
    self.friendsViewController.state = SVAddFriendsMainWithImage;
    self.friendsViewController.friendsFromMainWithPicture = YES;
    self.friendsViewController.friendsDoneBlock = friendsDoneBlock;
    
    [self.pageController setViewControllers:@[self.friendsViewController] direction:UIPageViewControllerNavigationDirectionReverse animated:animated completion:^(BOOL finished) {
        completed();
        
        
        
    }];
    
}

- (void)goToFriendsListViewAnimatedBeforeMovingPhoto:(BOOL)animated photoId:(NSString*)photoId  {
//    self.pageController tra
    
    [self lockScrollingPages];
    
    if(photoId != nil){
        self.friendsViewController.photoToMoveId = photoId;
    }
    self.friendsViewController.fromMove = YES;
    self.friendsViewController.state = SVAddFriendsFromMove;
    self.friendsViewController.fromPublicFeed = NO;

    [self.pageController setViewControllers:@[self.friendsViewController] direction:UIPageViewControllerNavigationDirectionReverse animated:animated completion:^(BOOL finished) {
        
    }];
    
}

- (void)goToFriendsListViewAnimatedBeforeMovingPhoto:(BOOL)animated photoId:(NSString*)photoId completed:(pageTransitionCompleted)completed {
    //    self.pageController tra
    
    [self lockScrollingPages];
    
    if(photoId != nil){
        self.friendsViewController.photoToMoveId = photoId;
    }
    self.friendsViewController.fromMove = YES;
    self.friendsViewController.state = SVAddFriendsFromMove;
    self.friendsViewController.fromPublicFeed = YES;
    
//    __weak GLContainersViewController * weakSelf = self;
    [self.pageController setViewControllers:@[self.friendsViewController] direction:UIPageViewControllerNavigationDirectionReverse animated:animated completion:^(BOOL finished) {
//        if(completed){
//            weakSelf.friendsViewController.friendsDoneBlock = ^{
//                completed();
//            };
//        }
    }];
    
}

- (void)pageViewController:(UIPageViewController *)pvc didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    // If the page did not turn
    if (!completed)
    {
        // You do nothing because whatever page you thought
        // the book was on before the gesture started is still the correct page
        return;
    }
    // This is where you would know the page number changed and handle it appropriately
//    KVNProgressConfiguration * conf = [[KVNProgressConfiguration alloc] init];
//    conf.successColor = UIColorFromRGB(0x40b4b5);
//    conf.errorColor = UIColorFromRGB(0xf07480);
//    [KVNProgress setConfiguration:conf];
//    [KVNProgress showSuccessWithStatus:@"scroll finished" completion:^{
//                [KVNProgress showErrorWithStatus:@"scroll finished"];
//    }];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
//    MPVolumeView * volumeView = [[MPVolumeView alloc]initWithFrame:CGRectZero];
//    [volumeView setShowsVolumeSlider:YES];
//    [volumeView setShowsRouteButton:NO];
//    
//    // control must be VISIBLE if you want to prevent default OS volume display
//    // from appearing when you change the volume level
//    [volumeView setHidden:NO];
//    volumeView.alpha = 0.1f;
//    volumeView.userInteractionEnabled = NO;
//    
//    // to hide from view just insert behind all other views
//    [self.view insertSubview:volumeView atIndex:0];
//    [[MPMusicPlayerController applicationMusicPlayer] setVolume:0.0];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    // Do any additional setup after loading the view from its nib.
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    
    self.pageController.dataSource = self;
    self.pageController.delegate = self;
//    self.pageController.scr
    [[self.pageController view] setFrame:[[self view] bounds]];
    
    [self addChildViewController:self.pageController];
    [[self view] addSubview:[self.pageController view]];
    [self.pageController didMoveToParentViewController:self];
    
    self.publicFeedViewController = [[GLPublicFeedViewController alloc] init];
    self.albumListViewController = [[SVAlbumListViewController alloc] init];
    self.friendsViewController = [[SVAddFriendsViewController alloc] init];
    self.membersViewController = [[SVSidebarMemberController alloc] init];
    self.membersSideMenu = [[MFSideMenuContainerViewController alloc] init];
    self.navigationController = [[SVNavigationController alloc] initWithRootViewController:self.albumListViewController];
    self.membersSideMenu = [MFSideMenuContainerViewController containerWithCenterViewController:self.navigationController
                                                                         leftMenuViewController:nil
                                                                        rightMenuViewController:self.membersViewController];
    
    self.friendsViewController.indexNumber = 0;
    self.navigationController.indexNumber = 1;
    self.publicFeedViewController.indexNumber = 2;
    [self.navigationController setNavigationBarHidden:YES];
    self.membersSideMenu.view.clipsToBounds = YES;
    self.membersSideMenu.indexNumber = 1;
    self.membersSideMenu.panMode = MFSideMenuPanModeDefault;    

    
    
//    [self.pageController setViewControllers:@[self.friendsViewController] direction:UIPageViewControllerNavigationDirectionReverse animated:NO completion:^(BOOL finished) {
    
        [self.pageController setViewControllers:@[self.membersSideMenu] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
        }];
        
//    }];
    
    
    
    
    
//    SLAlbumManager * al = [ShotVibeAppDelegate sharedDelegate].albumManager;
//    
//    [ShotVibeAPITask runTask:self withAction:^id{
//        //        [[al getShotVibeAPI] getPublic];
//        return [[al getShotVibeAPI] getPublicAlbumContents];
//    } onTaskComplete:^(SLAlbumContents *album) {
//        //        NSLog(@"Public feed name: %@", [album getName]);
//        
//        //        self.publicFeed = [[GLPublicFeedViewController alloc] init];
//        NSMutableArray * photosArray = [[NSMutableArray alloc] init];
//        
//        for(SLAlbumPhoto * photo in [album getPhotos]){
//            [photosArray addObject:photo];
//        }
//        
//        NSArray* reversedArray = [[photosArray reverseObjectEnumerator] allObjects];
//        
//        self.publicFeedViewController.photosArray = [reversedArray copy];
//        [self.publicFeedViewController.collectionView reloadData];
//        
//        //        self.publicFeed.albumId = [[al getShotVibeAPI] getPublicAlbumId];
//        // TODO ...
//    } onTaskFailure:^(id success) {
//        
//        //        [];
//        
//    } withLoaderIndicator:NO];

}



- (void)lockScrollingPages {
    for (UIScrollView *view in self.pageController.view.subviews) {
        
        if ([view isKindOfClass:[UIScrollView class]]) {
            
            view.scrollEnabled = NO;
        }
    }
}

- (void)unlockScrollingPages {
    for (UIScrollView *view in self.pageController.view.subviews) {
        
        if ([view isKindOfClass:[UIScrollView class]]) {
            
            view.scrollEnabled = YES;
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma  - UIPageViewController Methods
#define MAX_PAGES 3

// Factory method
- (UIViewController *)viewControllerAtIndex:(int)i {
    // Asking for a page that is out of bounds??
    if (i<0) {
        return nil;
    }
    if (i>=MAX_PAGES) {
        return nil;
    }

    if(i == 0){
        NSLog(@"requested page 0");
        
        return self.friendsViewController;
    } else if(i == 1){
        NSLog(@"requested page 1");

        return self.membersSideMenu;
    } else if (i == 2){
        NSLog(@"requested page 2");
        
        return self.publicFeedViewController;
    }
//    self.pageController setpa
    
}



- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    int index = [(UIViewController *)viewController indexNumber];
    index--;
    
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    int index = [viewController indexNumber];
    index++;

    return [self viewControllerAtIndex:index];
}



- (void)openAppleImagePicker {
    
    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:^{
        
    }];
    
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [[[GLSharedCamera sharedInstance] videoCamera] stopCameraCapture];
    [self dismissViewControllerAnimated:YES completion:^{
        [[GLSharedCamera sharedInstance] retrievePhotoFromPicker:info[UIImagePickerControllerOriginalImage]];
    }];
}


@end
