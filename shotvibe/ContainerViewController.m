//
//  ContainerViewController.m
//  PageViewControllerExample
//
//  Created by Mani Shankar on 29/08/14.
//  Copyright (c) 2014 makemegeek. All rights reserved.
//

#import "UIImage+ImageEffects.h"
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>


#import "ContainerViewController.h"
#import "ViewController.h"
#import "SVAddFriendsViewController.h"
#import "SVAlbumListViewController.h"
#import "MFSideMenuContainerViewController.h"
#import "SVSidebarMemberController.h"
#import "SVSidebarManagementController.h"
#import "SVNavigationController.h"
#import "SVRegistrationViewController.h"

#define kDefaultHeaderFrame CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)


@interface ContainerViewController ()
@property (nonatomic, strong) SVSidebarMemberController *sidebarRight;
@property (nonatomic, strong) SVSidebarManagementController *sidebarLeft;
@property (nonatomic, strong) MFSideMenuContainerViewController *sideMenu;
@end

@implementation ContainerViewController {
//    NSMutableArray *viewControllers;
    int currentIndex;
    int _curIndex;
    SVNavigationController *navigationController;
    SVAddFriendsViewController * freindsVc;
    ScrollDirection initialScrollDirection;
    int numberOfPixelsMoved;
    BOOL membersOpened;
    SVAlbumListViewController * albumlistvc;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

-(void)membersPressed {

    NSLog(@"test");
    
    membersOpened = !membersOpened;
    
    [navigationController.menuContainerViewController toggleRightSideMenuCompletion:^{
        
    }];
    
}
-(void)backPressed {

    if(membersOpened){
        
        membersOpened = !membersOpened;
        
        [navigationController.menuContainerViewController toggleRightSideMenuCompletion:^{
            
        }];
        
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        [[[GLSharedCamera sharedInstance]backButton]setAlpha:0];
        [[[GLSharedCamera sharedInstance]membersButton]setAlpha:0];
    }];
    
    [navigationController popViewControllerAnimated:YES];

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    
    
    albumlistvc = [storyboard instantiateViewControllerWithIdentifier:@"SVAlbumListViewController"];
//    albumlistvc.delegate = self;
    
    navigationController = [[SVNavigationController alloc] initWithRootViewController:albumlistvc];
    [navigationController.view addSubview:[[GLSharedCamera sharedInstance] cameraViewBackground]];
    self.sidebarRight = [storyboard instantiateViewControllerWithIdentifier:@"SidebarMembersView"];
    self.sidebarLeft = [storyboard instantiateViewControllerWithIdentifier:@"SidebarManagementView"];
    self.sideMenu = [MFSideMenuContainerViewController containerWithCenterViewController:navigationController
                                                                  leftMenuViewController:nil
                                                                 rightMenuViewController:self.sidebarRight];
    self.sideMenu.panMode = MFSideMenuPanModeNone;
    
    freindsVc = [storyboard instantiateViewControllerWithIdentifier:@"InviteFriendsView"];
    freindsVc.delegate = self;
    NSLog(@"test");
    
    
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    
    self.pageController.dataSource = self;
    [[self.pageController view] setFrame:[[self view] bounds]];
    
    SVAddFriendsViewController *viewControllerObject = (SVAddFriendsViewController*)[self viewControllerAtIndex:0];
    
    NSArray *viewControllers = [NSArray arrayWithObject:viewControllerObject];
    
    [self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    [self addChildViewController:self.pageController];
    [[self view] addSubview:[self.pageController view]];
    [self.pageController didMoveToParentViewController:self];
    
    [self gotoPage:2];
    
//    numberOfPixelsMoved = 0;
//    membersOpened = NO;
//    ShotVibeAppDelegate *appDelegate = (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];
//    // Do any additional setup after loading the view from its nib.
//    initialScrollDirection = ScrollDirectionLeft;
//    currentIndex = 1;
//    
//    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
////    self.pageController setnum
//    
//    self.pageController.dataSource = self;
//    self.pageController.delegate = self;
////    self.pageController.view.sc
////    self.pageController.
//    [[self.pageController view] setFrame:[[self view] bounds]];
//    
//    
////    UIStoryboard * sb = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
////    SVAddFriendsViewController * friendsvc = [sb instantiateViewControllerWithIdentifier:@"InviteFriendsView"];
////    SVAlbumListViewController * albumlistvc = [sb instantiateViewControllerWithIdentifier:@"SVAlbumListViewController"];
//    
//    
//    
//    
//    
//    
//    //    UIPageViewController * pagesViewController = [[UIPageViewController alloc] init];
//    //    pagesViewController.ch
//    
//    // Initialize the sidebar menu
    
//    freindsVc.delegate = self;
   
//
//    
//    
//    
//    
//    
//    MFSideMenuContainerViewController *viewControllerObject = self.sideMenu;
//
//    viewControllers = [NSMutableArray arrayWithObject:viewControllerObject];
////    [viewControllers addObject:albumlistvc];
////    [viewControllers addObject:friendsvc];
//    
//    [self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
//    
//    [self addChildViewController:self.pageController];
//    [[self view] addSubview:[self.pageController view]];
//    [self.pageController didMoveToParentViewController:self];
////    [self scrollToNext];
//    
//    for (UIView *view in self.pageController.view.subviews ) {
//        if ([view isKindOfClass:[UIScrollView class]]) {
//            UIScrollView *scroll = (UIScrollView *)view;
//            scroll.delegate = self;
//            scroll.pagingEnabled = YES;
////            scroll.alwaysBounceHorizontal = NO;
////            scroll.bounces = NO;
//        }
//    }
//    
////    [self gotoPage:2];
//    
//    UIImageView *imageView = [[UIImageView alloc] initWithFrame:appDelegate.window.frame];
//    imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
//    imageView.contentMode = UIViewContentModeScaleAspectFill;
////    imageView.image = self.headerImage;
//    self.imageView = imageView;
//    
//    self.bluredImageView = [[UIImageView alloc] initWithFrame:appDelegate.window.frame];
//    self.bluredImageView.autoresizingMask = self.imageView.autoresizingMask;
//    self.bluredImageView.alpha = 0.0f;
    
//    [[[GLSharedCamera sharedInstance] cameraViewBackground]addSubview:self.bluredImageView];
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
//    if([[previousViewControllers objectAtIndex:0] class] == [SVAddFriendsViewController class]){
//        currentIndex = 1;
//    } else {
//        currentIndex = 0;
//    }
    
    // This is where you would know the page number changed and handle it appropriately
    // [self sendPageChangeNotification:YES];
    
}

#pragma  - UIPageViewController Methods
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    NSUInteger index = [(ViewController *)viewController indexNumber];
    
    if (index == 0) {
        return nil;
    }
    
    index--;
    
    return [self viewControllerAtIndex:index];
    
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    NSUInteger index = [(ViewController *)viewController indexNumber];
    
    
    index++;
    
    if (index == 2) {
        return nil;
    }
    
    return [self viewControllerAtIndex:index];
    
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index {
    
    
    if(index == 0){
        freindsVc.indexNumber = index;
        return (SVAddFriendsViewController*)freindsVc;
    } else if(index == 1 || index == 2){
    
        self.sideMenu.indexNumber = 1;
//        childViewController.indexNumber = index;
        
        return self.sideMenu;
    }
    
    
}


//#pragma  - UIPageViewController Methods
//- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
//    
//    NSUInteger index = [(ViewController *)viewController indexNumber];
//    
//    if (index == 0) {
//        return nil;
//    }
//    
////    currentIndex--;
//    index--;
//    
//    return freindsVc;
//    
//}
//
//- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
//    
//    NSUInteger index = [(ViewController *)viewController indexNumber];
//    
////    currentIndex++;
//    index++;
//    
//    if (index == 2) {
//        return nil;
//    }
//    
//    return [self viewControllerAtIndex:index];
//    
//}
//
//- (MFSideMenuContainerViewController *)viewControllerAtIndex:(NSUInteger)index {
//
//    self.sideMenu.indexNumber = index;
//    return self.sideMenu;
//    
//}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)gotoPage:(int)index{
    
    
    MFSideMenuContainerViewController *viewController = (MFSideMenuContainerViewController*)[self viewControllerAtIndex:index];
    
    UIPageViewControllerNavigationDirection direction;
    if(_curIndex <= index){
        direction = UIPageViewControllerNavigationDirectionForward;
    }
    else
    {
        direction = UIPageViewControllerNavigationDirectionReverse;
    }
    
    
    if(_curIndex < index)
    {
        for (int i = 0; i <= index; i++)
        {
            if (i == index) {
                [self.pageController setViewControllers:@[viewController]
                                                  direction:direction
                                                   animated:YES
                                                 completion:nil];
            }
            else
            {
                [self.pageController setViewControllers:@[[self viewControllerAtIndex:i]]
                                                  direction:direction
                                                   animated:NO
                                                 completion:nil];
                
            }
        }
    }
    else
    {
        for (int i = _curIndex; i >= index; i--)
        {
            if (i == index) {
                [self.pageController setViewControllers:@[viewController]
                                                  direction:direction
                                                   animated:YES
                                                 completion:nil];
            }
            else
            {
                [self.pageController setViewControllers:@[[self viewControllerAtIndex:i]]
                                                  direction:direction
                                                   animated:NO
                                                 completion:nil];
                
            }
        }
    }
    
    _curIndex = index;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
//    if (!isPageToBounce) {
//    if([[GLSharedCamera sharedInstance] isInFeedMode]){
//        *targetContentOffset = CGPointMake(scrollView.bounds.size.width, 0);
//        self.bluredImageView.image = nil;
//    }
//    
//        if (0 == currentIndex && scrollView.contentOffset.x <= scrollView.bounds.size.width) {
//            *targetContentOffset = CGPointMake(scrollView.bounds.size.width, 0);
//        }
//        if (currentIndex == 1 && scrollView.contentOffset.x >= scrollView.bounds.size.width) {
//            *targetContentOffset = CGPointMake(scrollView.bounds.size.width, 0);
//        }
//    }
}

//- (void)goToAlbumId:(long long)num {
//    [albumlistvc goToAlbumId:1];
//}


- (void)goToPage:(int)num {
    [self gotoPage:2];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
//    NSLog(@"scrolled x %f",scrollView.contentOffset.x);
//    if(numberOfPixelsMoved == 0){
//        numberOfPixelsMoved = 1;
//    }
//    if(numberOfPixelsMoved == 1){
//        [self refreshBlurViewForNewImage];
//        numberOfPixelsMoved = 2;
//    }
    
//    if([[GLSharedCamera sharedInstance] isInFeedMode]){
//        self.bluredImageView.image = nil;
//        scrollView.contentOffset = CGPointMake(scrollView.bounds.size.width, 0);
//    }
//    
//    if (currentIndex == 0 && scrollView.contentOffset.x < scrollView.bounds.size.width) {
//        scrollView.contentOffset = CGPointMake(scrollView.bounds.size.width, 0);
//    }
//    if (currentIndex == 1 && scrollView.contentOffset.x > scrollView.bounds.size.width) {
//        scrollView.contentOffset = CGPointMake(scrollView.bounds.size.width, 0);
//    }
    
    
    
    
//        ScrollDirection scrollDirection;
//        if (self.lastContentOffset > scrollView.contentOffset.x)
//        {
//            scrollDirection = ScrollDirectionRight;
//            self.bluredImageView.alpha = (1 - (1 / self.view.frame.size.width * scrollView.contentOffset.x))*2;
//        }
//        else {
//            scrollDirection = ScrollDirectionLeft;
//            
//            NSLog(@"m %f",((2*(self.view.frame.size.width / scrollView.contentOffset.x))-1)*2);
//            
//            self.bluredImageView.alpha = ((2*(self.view.frame.size.width / scrollView.contentOffset.x))-1)*2;
//        }
//    
//        self.lastContentOffset = scrollView.contentOffset.x;
    
    
    //    if(scrollView.contentOffset.x != 375 && scrollDirection == ScrollDirectionRight){
    //
    //
    //    GLSharedCamera * sharedCamera = [GLSharedCamera sharedInstance];
    //        sharedCamera.cameraViewBackground.center = CGPointMake(-scrollView.contentOffset.x+1.5*(sharedCamera.cameraViewBackground.frame.size.width), sharedCamera.cameraViewBackground.center.y);
    ////
    ////        self.bluredImageView.center = CGPointMake(-scrollView.contentOffset.x+1.5*(sharedCamera.cameraViewBackground.frame.size.width), sharedCamera.cameraViewBackground.center.y);
    //
    //
    //
    //    } else if(scrollView.contentOffset.x != 375 && scrollDirection == ScrollDirectionLeft){
    //        GLSharedCamera * sharedCamera = [GLSharedCamera sharedInstance];
    //        sharedCamera.cameraViewBackground.center = CGPointMake(self.view.frame.size.width + (-scrollView.contentOffset.x+1.5*(sharedCamera.cameraViewBackground.frame.size.width)), sharedCamera.cameraViewBackground.center.y);
    //    }

}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers {
    
//    if(![[GLSharedCamera sharedInstance] isInFeedMode]){
//    if(currentIndex ==0){
//        
//        [[[GLSharedCamera sharedInstance] videoCamera] resumeCameraCapture];
//    } else {
//        [[[GLSharedCamera sharedInstance] videoCamera] pauseCameraCapture];
//        [self refreshBlurViewForNewImage];
//    }
//    }
    
}


- (UIImage *)screenShotOfView:(UIView *)view
{
    ShotVibeAppDelegate *appDelegate = (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    UIGraphicsBeginImageContextWithOptions(appDelegate.window.frame.size, YES, 0.0);
    [appDelegate.window drawViewHierarchyInRect:appDelegate.window.frame afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)refreshBlurViewForNewImage
{
    
    
    ShotVibeAppDelegate *appDelegate = (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];
    UIImage *screenShot = [self screenShotOfView:appDelegate.window];
    screenShot = [screenShot applyBlurWithRadius:5 tintColor:[UIColor colorWithWhite:0.6 alpha:0.2] saturationDeltaFactor:1.0 maskImage:nil];
    self.bluredImageView.image = screenShot;
}

//- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
//    return 3;
//}

//- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
//    return 1;
//}

@end
