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

-(void)resetFriendsView {
    self.friendsViewController = nil;
    self.friendsViewController = [[SVAddFriendsViewController alloc] init];
    self.friendsViewController.indexNumber = 0;
}


- (void)goBackToFeedAfterAddingMembersAnimated:(BOOL)animated {
    [self.pageController setViewControllers:@[self.membersSideMenu] direction:UIPageViewControllerNavigationDirectionForward animated:animated completion:^(BOOL finished) {
//        completed();
        //        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    }];
}

- (void)goToFeedViewAnimated:(BOOL)animated withAlbumId:(long long int)albumId completed:(pageTransitionCompleted)completed {
    
    [self lockScrollingPages];
    [[GLSharedCamera sharedInstance] setCameraInFeed];
    GLFeedViewController * feed = [[GLFeedViewController alloc] init];
    feed.albumId = albumId;
    [self.navigationController pushViewController:feed animated:animated];
    [self.pageController setViewControllers:@[self.membersSideMenu] direction:UIPageViewControllerNavigationDirectionForward animated:animated completion:^(BOOL finished) {
        completed();
//        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    }];
    
    
    
}

- (void)goToFeedViewAnimated:(BOOL)animated withAlbumId:(long long int)albumId {
    
    [self lockScrollingPages];
    [[GLSharedCamera sharedInstance] setCameraInFeed];
    GLFeedViewController * feed = [[GLFeedViewController alloc] init];
    feed.albumId = albumId;
    [self.navigationController pushViewController:feed animated:animated];
    [self.pageController setViewControllers:@[self.membersSideMenu] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL finished) {
        
    }];
    
    
    
}

- (void)goToAlbumListViewController:(BOOL)animated {
    
    [self unlockScrollingPages];
    [self.pageController setViewControllers:@[self.membersSideMenu] direction:UIPageViewControllerNavigationDirectionForward animated:animated completion:^(BOOL finished) {
        
    }];
    
}

- (void)goToFriendsListViewAnimatedBeforeAddingMembers:(BOOL)animated albumId:(long long int)albumId {

    [self lockScrollingPages];
    if(albumId){
        self.friendsViewController.albumId = albumId;
    }
    self.friendsViewController.state = SVAddFriendsFromAddFriendButton;
    
    [self.pageController setViewControllers:@[self.friendsViewController] direction:UIPageViewControllerNavigationDirectionReverse animated:animated completion:^(BOOL finished) {
        
    }];
    
}

- (void)goToFriendsListViewAnimatedBeforeUploadingPhoto:(BOOL)animated completed:(pageTransitionCompleted)completed {
    
    self.friendsViewController.state = SVAddFriendsMainWithImage;
    self.friendsViewController.friendsFromMainWithPicture = YES;
    
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

    [self.pageController setViewControllers:@[self.friendsViewController] direction:UIPageViewControllerNavigationDirectionReverse animated:animated completion:^(BOOL finished) {
        
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
//    self.friendsViewController.delegate = self;
    self.membersViewController = [[SVSidebarMemberController alloc] init];
    self.membersSideMenu = [[MFSideMenuContainerViewController alloc] init];
    
    self.membersSideMenu.panMode = MFSideMenuPanModeNone;
    
    
    self.navigationController = [[SVNavigationController alloc] initWithRootViewController:self.albumListViewController];
    self.friendsViewController.indexNumber = 0;
    self.navigationController.indexNumber = 1;
    self.publicFeedViewController.indexNumber = 2;
    [self.navigationController setNavigationBarHidden:YES];
    
    
    
    self.membersSideMenu = [MFSideMenuContainerViewController containerWithCenterViewController:self.navigationController
                                                                  leftMenuViewController:nil
                                                                 rightMenuViewController:self.membersViewController];
    self.membersSideMenu.view.clipsToBounds = YES;
    self.membersSideMenu.indexNumber = 1;
    
    
    [self.pageController setViewControllers:@[self.membersSideMenu] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
    }];
    
    
    
    SLAlbumManager * al = [ShotVibeAppDelegate sharedDelegate].albumManager;
    
    [ShotVibeAPITask runTask:self withAction:^id{
        //        [[al getShotVibeAPI] getPublic];
        return [[al getShotVibeAPI] getPublicAlbumContents];
    } onTaskComplete:^(SLAlbumContents *album) {
        //        NSLog(@"Public feed name: %@", [album getName]);
        
        //        self.publicFeed = [[GLPublicFeedViewController alloc] init];
        NSMutableArray * photosArray = [[NSMutableArray alloc] init];
        
        for(SLAlbumPhoto * photo in [album getPhotos]){
            [photosArray addObject:photo];
        }
        
        NSArray* reversedArray = [[photosArray reverseObjectEnumerator] allObjects];
        
        self.publicFeedViewController.photosArray = [reversedArray copy];
        [self.publicFeedViewController.collectionView reloadData];
        
        //        self.publicFeed.albumId = [[al getShotVibeAPI] getPublicAlbumId];
        // TODO ...
    } onTaskFailure:^(id success) {
        
        //        [];
        
    } withLoaderIndicator:NO];

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


@end
