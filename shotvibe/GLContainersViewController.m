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
    
    if([[ShotVibeAppDelegate sharedDelegate] platformTypeIsIphone5]){
        self.friendsViewController = [[SVAddFriendsViewController alloc] initWithNibName:@"SVAddFriendsViewController5" bundle:[NSBundle mainBundle]];
        
    } else if([[ShotVibeAppDelegate sharedDelegate] platformTypeIsIphone6plus]){
        self.friendsViewController = [[SVAddFriendsViewController alloc] initWithNibName:@"SVAddFriendsViewController6p" bundle:[NSBundle mainBundle]];
    } else {
        self.friendsViewController = [[SVAddFriendsViewController alloc] initWithNibName:@"SVAddFriendsViewController" bundle:[NSBundle mainBundle]];
    }
//    self.friendsViewController = [[SVAddFriendsViewController alloc] init];
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

- (void)goToPublicFeed:(BOOL)animated {
    
//    [self unlockScrollingPages];
    
    __block GLContainersViewController * weakSelf = self;
    [self.pageController setViewControllers:@[self.publicFeedViewController] direction:UIPageViewControllerNavigationDirectionForward animated:animated completion:^(BOOL finished) {
        //        [weakSelf resetFriendsView];
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
    __block GLContainersViewController * weakSelf = self;
    if(albumId){
        self.friendsViewController.albumId = albumId;
    }
    self.friendsViewController.state = SVAddFriendsFromAddFriendButton;
    self.friendsViewController.friendsDoneBlock = ^{
//        [[GLContainersViewController sharedInstance] resetFriendsView];
    };
    
    [self.pageController setViewControllers:@[self.friendsViewController] direction:UIPageViewControllerNavigationDirectionReverse animated:animated completion:^(BOOL finished) {
//        weakSelf.friendsViewController.friendsDoneBlock();
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

- (void)goToFriendsListViewAnimatedBeforeMovingPhoto:(BOOL)animated photoId:(NSString*)photoId completed:(pageTransitionCompleted)completed fromPublic:(BOOL)fromPublic {
    //    self.pageController tra
    
    [self lockScrollingPages];
    
    if(photoId != nil){
        self.friendsViewController.photoToMoveId = photoId;
    }
    self.friendsViewController.fromMove = YES;
    self.friendsViewController.state = SVAddFriendsFromMove;
    self.friendsViewController.fromPublicFeed = fromPublic;
    
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
    
    if([[ShotVibeAppDelegate sharedDelegate] platformTypeIsIphone5]){
        self.publicFeedViewController = [[GLPublicFeedViewController alloc] initWithNibName:@"GLPublicFeedViewController5" bundle:[NSBundle mainBundle]];
        self.friendsViewController = [[SVAddFriendsViewController alloc] initWithNibName:@"SVAddFriendsViewController5" bundle:[NSBundle mainBundle]];
        self.membersViewController = [[SVSidebarMemberController alloc] initWithNibName:@"SVSidebarMemberController5" bundle:[NSBundle mainBundle]];
    } else if([[ShotVibeAppDelegate sharedDelegate] platformTypeIsIphone6plus]){
        self.membersViewController = [[SVSidebarMemberController alloc] initWithNibName:@"SVSidebarMemberController6p" bundle:[NSBundle mainBundle]];
        self.publicFeedViewController = [[GLPublicFeedViewController alloc] initWithNibName:@"GLPublicFeedViewController6p" bundle:[NSBundle mainBundle]];
        self.friendsViewController = [[SVAddFriendsViewController alloc] initWithNibName:@"SVAddFriendsViewController6p" bundle:[NSBundle mainBundle]];
    } else {
        
        
        self.membersViewController = [[SVSidebarMemberController alloc] initWithNibName:@"SVSidebarMemberController" bundle:[NSBundle mainBundle]];
        self.publicFeedViewController = [[GLPublicFeedViewController alloc] initWithNibName:@"GLPublicFeedViewController" bundle:[NSBundle mainBundle]];
        self.friendsViewController = [[SVAddFriendsViewController alloc] initWithNibName:@"SVAddFriendsViewController" bundle:[NSBundle mainBundle]];
    }
    
    
    self.albumListViewController = [[SVAlbumListViewController alloc] init];
    
    
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
    
//    [[[[ShotVibeAppDelegate sharedDelegate] pushNotificationsManager] notificationHandler_] setDelegate:self];
    
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
//    
//    ShotVibeAppDelegate *appDelegate = (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];
//    appDelegate.pushNotificationsManager.notificationHandler_.delegate = self;

    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pushNotficationDidPressed:)
                                                 name:@"pushWasPressed"
                                               object:nil];
    
}

-(BOOL)inFeed {
    return [[self.navigationController.viewControllers lastObject] isKindOfClass:[GLFeedViewController class]];
}

- (void)pushNotficationDidPressed:(NSNotification*)notification {


    if([[notification.userInfo valueForKey:@"msg"] isKindOfClass:[SLNotificationMessage_PhotoGlanceScoreDelta class]]){
        [self handleGlancedPushPressed:[notification.userInfo valueForKey:@"msg"]];
    }
    
    if([[notification.userInfo valueForKey:@"msg"] isKindOfClass:[SLNotificationMessage_PhotoComment class]]){
        [self handleCommentedPushPressed:[notification.userInfo valueForKey:@"msg"]];
    }
    
    
    
    if([[notification.userInfo valueForKey:@"msg"] isKindOfClass:[SLNotificationMessage_AddedToAlbum class]]){
        [self handleAddedToGroupPushPressed:[notification.userInfo valueForKey:@"msg"]];
    }
    
    if([[notification.userInfo valueForKey:@"msg"] isKindOfClass:[SLNotificationMessage_PhotosAdded class]]){
        [self handleAddedPhotosPushPressed:[notification.userInfo valueForKey:@"msg"]];
    }
    
    
    
    
    
    
}

-(void)disablePublicFeedPushAlerter {
    [self.albumListViewController disablePublicFeedAlerterTimer];
}

- (void)handleAddedPhotosPushPressed:(SLNotificationMessage_PhotosAdded *)data {
    
    
    if([self inFeed]){
        
        GLFeedViewController * currentFeed = [self.navigationController.viewControllers lastObject];
        if(currentFeed.albumId == [data getAlbumId]){
            GLFeedTableCell * cell = [currentFeed ShowSpecificCell:[data getPhotoId]];
            [cell highLightLastCommentInPost];
        } else {
            
            GLFeedViewController * feed = [[GLFeedViewController alloc] init];
            feed.albumId = [data getAlbumId];
            [self.navigationController pushViewController:feed animated:NO];
            //            [self.pageController setViewControllers:@[self.membersSideMenu] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
            feed.feedDidAppearBlock = ^(GLFeedViewController * feedInstance){
                GLFeedTableCell * cell = [feedInstance ShowSpecificCell:[data getPhotoId]];
//                [cell highLightLastCommentInPost];
            };
            
            
        }
        
        
        
    } else {
        
//        UIAlertView * al = [[UIAlertView alloc] initWithTitle:[data getAlbumName] message:[data getAuthorName] delegate:nil cancelButtonTitle:[data getAuthorAvatarUrl] otherButtonTitles:[data getPhotoId],[NSString stringWithFormat:@"%lld",[data getAlbumId]],[NSString stringWithFormat:@"%d",[data getNumPhotos]], nil];
//        UIAlertView * al = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%lld",[data getAlbumId]] message:@"" delegate:nil cancelButtonTitle:@"" otherButtonTitles:@"", nil];
//        
//        [al show];
        
        [[GLSharedCamera sharedInstance] setCameraInFeedAfterGroupOpenedWithoutImage];
        [self lockScrollingPages];
        GLFeedViewController * feed = [[GLFeedViewController alloc] init];
        feed.albumId = [data getAlbumId];
        [self.navigationController pushViewController:feed animated:NO];
        [self.pageController setViewControllers:@[self.membersSideMenu] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
        feed.feedDidAppearBlock = ^(GLFeedViewController * feedInstance){
            GLFeedTableCell * cell = [feedInstance ShowSpecificCell:[data getPhotoId]];
//            [cell highLightLastCommentInPost];
        };
        
    }
    
}

//- (void)handleAddedPhotosPushPressed:(SLNotificationMessage_PhotosAdded *)data {
//    
//    
//    NSString * photoId = [data getPhotoId];
//    
//    if([self inFeed]){
//        
//        GLFeedViewController * feed = [[GLFeedViewController alloc] init];
//        feed.albumId = [data getAlbumId];
//        [self.navigationController pushViewController:feed animated:NO];
//        
//        
//    } else {
//        
//        [[GLSharedCamera sharedInstance] setCameraInFeedAfterGroupOpenedWithoutImage];
//        [self lockScrollingPages];
//        GLFeedViewController * feed = [[GLFeedViewController alloc] init];
//        feed.albumId = [data getAlbumId];
//        [self.navigationController pushViewController:feed animated:NO];
//        [self.pageController setViewControllers:@[self.membersSideMenu] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
//    }
//    
//}

- (void)handleAddedToGroupPushPressed:(SLNotificationMessage_AddedToAlbum *)data {

    if([self inFeed]){
        
            GLFeedViewController * feed = [[GLFeedViewController alloc] init];
            feed.albumId = [data getAlbumId];
            [self.navigationController pushViewController:feed animated:NO];
        
        
    } else {
        
        [[GLSharedCamera sharedInstance] setCameraInFeedAfterGroupOpenedWithoutImage];
        [self lockScrollingPages];
        GLFeedViewController * feed = [[GLFeedViewController alloc] init];
        feed.albumId = [data getAlbumId];
        [self.navigationController pushViewController:feed animated:NO];
        [self.pageController setViewControllers:@[self.membersSideMenu] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    }
}

- (void)handleCommentedPushPressed:(SLNotificationMessage_PhotoComment*)data {
    
    if([self inFeed]){
        
        GLFeedViewController * currentFeed = [self.navigationController.viewControllers lastObject];
        if(currentFeed.albumId == [data getAlbumId]){
            GLFeedTableCell * cell = [currentFeed ShowSpecificCell:[data getPhotoId]];
            [cell highLightLastCommentInPost];
        } else {
            
            GLFeedViewController * feed = [[GLFeedViewController alloc] init];
            feed.albumId = [data getAlbumId];
            [self.navigationController pushViewController:feed animated:NO];
//            [self.pageController setViewControllers:@[self.membersSideMenu] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
            feed.feedDidAppearBlock = ^(GLFeedViewController * feedInstance){
                GLFeedTableCell * cell = [feedInstance ShowSpecificCell:[data getPhotoId]];
                [cell highLightLastCommentInPost];
            };

            
        }
        
        
        
    } else {
        
        [[GLSharedCamera sharedInstance] setCameraInFeedAfterGroupOpenedWithoutImage];
        [self lockScrollingPages];
        GLFeedViewController * feed = [[GLFeedViewController alloc] init];
        feed.albumId = [data getAlbumId];
        [self.navigationController pushViewController:feed animated:NO];
        [self.pageController setViewControllers:@[self.membersSideMenu] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
        feed.feedDidAppearBlock = ^(GLFeedViewController * feedInstance){
            GLFeedTableCell * cell = [feedInstance ShowSpecificCell:[data getPhotoId]];
            [cell highLightLastCommentInPost];
        };
        
    }
    
}


- (void)handleGlancedPushPressed:(SLNotificationMessage_PhotoGlanceScoreDelta*)data {
    
    if([self inFeed]){
        
        GLFeedViewController * currentFeed = [self.navigationController.viewControllers lastObject];
        if(currentFeed.albumId == [data getAlbumId]){
            GLFeedTableCell * cell = [currentFeed ShowSpecificCell:[data getPhotoId]];
//            [cell highLightLastCommentInPost];
        } else {
            
            GLFeedViewController * feed = [[GLFeedViewController alloc] init];
            feed.albumId = [data getAlbumId];
            [self.navigationController pushViewController:feed animated:NO];
            //            [self.pageController setViewControllers:@[self.membersSideMenu] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
            feed.feedDidAppearBlock = ^(GLFeedViewController * feedInstance){
                GLFeedTableCell * cell = [feedInstance ShowSpecificCell:[data getPhotoId]];
//                [cell highLightLastCommentInPost];
            };
            
            
        }
        
    } else {
        
        [[GLSharedCamera sharedInstance] setCameraInFeedAfterGroupOpenedWithoutImage];
        [self lockScrollingPages];
        GLFeedViewController * feed = [[GLFeedViewController alloc] init];
        feed.albumId = [data getAlbumId];
            [self.navigationController pushViewController:feed animated:NO];
            [self.pageController setViewControllers:@[self.membersSideMenu] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
        feed.feedDidAppearBlock = ^(GLFeedViewController * feedInstance){
            GLFeedTableCell * cell = [feedInstance ShowSpecificCell:[data getPhotoId]];
//            [cell highLightLastCommentInPost];
        };
        
    }
    
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
//[];


- (void)openAppleImagePicker {
    
    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
//    picker.allowsEditing = YES;
//    picker.disa
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
//    picker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie,(NSString *)kUTTypeImage, nil];
    [self presentViewController:picker animated:YES completion:^{
        
    }];
    
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [[[GLSharedCamera sharedInstance] videoCamera] stopCameraCapture];
    [self dismissViewControllerAnimated:YES completion:^{
        [[GLSharedCamera sharedInstance] retrievePhotoFromPicker:info[UIImagePickerControllerOriginalImage]];
    }];
}


- (void)youGotGlanced:(SLNotificationMessage_PhotoGlanceScoreDelta *)msg {

    NSLog(@"");

}


@end
