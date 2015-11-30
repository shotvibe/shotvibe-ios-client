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
#import "GLProfilePageViewController.h"
#import "ShotVibeAPITask.h"
#import "ShotVibeAPI.h"
#import "GLPublicFeedViewController.h"
#import "AlbumPhoto.h"
#import "ArrayList.h"

#define kDefaultHeaderFrame CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)


@interface ContainerViewController ()
@property (nonatomic, strong) SVSidebarMemberController *sidebarRight;
@property (nonatomic, strong) SVSidebarManagementController *sidebarLeft;
@property (nonatomic, strong) MFSideMenuContainerViewController *sideMenu;
@property (nonatomic, strong) GLPublicFeedViewController *publicFeed;
@end

@implementation ContainerViewController {
//    NSMutableArray *viewControllers;
    int currentIndex;
    int _curIndex;
//    SVNavigationController *navigationController;
    SVAddFriendsViewController * freindsVc;
    ScrollDirection initialScrollDirection;
    int numberOfPixelsMoved;
    BOOL membersOpened;
    SVAlbumListViewController * albumlistvc;
}

static ContainerViewController *sharedInstance;

+ (ContainerViewController *)sharedInstance
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[ContainerViewController alloc] initWithNibName:@"ContainerViewController" bundle:nil];
    });
    return sharedInstance;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    
    
    if(sharedInstance) {
        // avoid creating more than one instance
//        [NSException raise:@"bug" format:@"tried to create more than one instance"];
        return self;
    }
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)startUploadAfterSourceSelect:(long long int)albumId withAlbumContents:(SLAlbumContents*)album {
    [albumlistvc goToAlbumId:albumId startImidiatly:YES addAlbumContents:album];
}

- (void)setFriendsForMove:(NSString*)photoId {
    if(photoId != nil){
        freindsVc.photoToMoveId = photoId;
    }
    freindsVc.fromMove = YES;
    freindsVc.state = SVAddFriendsFromMove;
}

- (void)setFriendsFromMain {
    freindsVc.fromCameraMainScreen = YES;
}

- (BOOL)shouldAutorotate
{
    return NO;
}
-(void)resetFriendsView {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    freindsVc = nil;
    freindsVc = [storyboard instantiateViewControllerWithIdentifier:@"InviteFriendsView"];
    freindsVc.delegate = self;
}

-(void)setFriendsFromMainWithPicture {
    freindsVc.friendsFromMainWithPicture = YES;
    freindsVc.state = SVAddFriendsMainWithImage;
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [[[GLSharedCamera sharedInstance] videoCamera] stopCameraCapture];
    [self dismissViewControllerAnimated:YES completion:^{
        [[GLSharedCamera sharedInstance] retrievePhotoFromPicker:info[UIImagePickerControllerOriginalImage]];
    }];
}

//
//-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
//    NSLog(@"");
//    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
//    
//    
//    [self dismissViewControllerAnimated:YES completion:^{
//        
//        [UIView animateWithDuration:0.3 animations:^{
////            glcamera.view.alpha = 1;
////            [glcamera hideForPicker:NO];
//            glcamera.picYourGroup.alpha = 0;
//            glcamera.picYourGroup.hidden = NO;
//        }];
//        
//    }];
////    glcamera.picYourGroup.alpha = 0;
//}

-(void)openAppleImagePicker {

    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
//    glcamera.delegate = self;
    
    //    glcamera.delegate
    //     glcamera.imagePickerDelegate = picker.delegate;
    picker.delegate = self;
    
    
    //    fromImagePicker = YES;
//    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:^{
        
        //        [appDelegate.window sendSubviewToBack:glcamera.view];
        
        [UIView animateWithDuration:0.3 animations:^{
//            glcamera.view.alpha = 0;
//            [glcamera hideForPicker:YES];
        }];
    }];

}

- (void)transitToAlbumList:(BOOL)animated direction:(UIPageViewControllerNavigationDirection)direction withAlbumId:(long long int)albumId completion:(pageTransitionCompleted)completion {

    
    if(albumId != 0){
//        albumlistvc.did
//        if(albumId == -1){
//            [self.navigationController popViewControllerAnimated:NO];
//        } else {
            [albumlistvc transitToAlbumWithId:albumId animated:animated dmutScale:NO];
//        }
        
    }
    
                [self.pageController setViewControllers:@[self.sideMenu]
                                              direction:direction
                                               animated:animated
                                             completion:^(BOOL done){
                                                 completion();
                                             }];
    
}

- (void)transitToFriendsList:(BOOL)animated direction:(UIPageViewControllerNavigationDirection)direction completion:(pageTransitionCompleted)completion {
    
    
    [self.pageController setViewControllers:@[freindsVc]
                                  direction:direction
                                   animated:animated
                                 completion:^(BOOL done){
                                     completion();
                                 }];
   
    
}

-(void)membersPressed {

    NSLog(@"test");
    
    membersOpened = !membersOpened;
    
    [self.navigationController.menuContainerViewController toggleRightSideMenuCompletion:^{
        
    }];
    
}

-(void)backPressed {

    if(membersOpened){
        
        membersOpened = !membersOpened;
        
        [self.sideMenu.navigationController.menuContainerViewController toggleRightSideMenuCompletion:^{
            
        }];
        
    }
    
    
    
    
    if([self.navigationController.visibleViewController class] == [GLProfilePageViewController class]){
        [[[GLSharedCamera sharedInstance]membersButton]setAlpha:1];
        [[[GLSharedCamera sharedInstance] dmut] setUserInteractionEnabled:YES];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            [[[GLSharedCamera sharedInstance]backButton]setAlpha:0];
            [[[GLSharedCamera sharedInstance]membersButton]setAlpha:0];
        }];
        [[GLSharedCamera sharedInstance] setCameraInMain];
        [self lockScrolling:NO];
        
    }
    
//    NSLog(@"",);
     [self.navigationController popViewControllerAnimated:YES];

}
-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
//    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
//    glcamera.delegate = nil;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    
    
    
    
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[[GLSharedCamera sharedInstance] score] setText:[NSString stringWithFormat:@"%ld",(long)[[NSUserDefaults standardUserDefaults] integerForKey:@"kUserScore"]]];
//    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
//    glcamera.delegate = nil;
//    glcamera.delegate = self;
    
//    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
//    glcamera.delegate = self;
    
 
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
//    SLShotVibeAPI *shotvibeAPI = [ getShotVibeAPI];
    SLAlbumManager * al = [ShotVibeAppDelegate sharedDelegate].albumManager;
    
    [ShotVibeAPITask runTask:self withAction:^id{
//        [[al getShotVibeAPI] getPublic];
        return [[al getShotVibeAPI] getPublicAlbumContents];
    } onTaskComplete:^(SLAlbumContents *album) {
//        NSLog(@"Public feed name: %@", [album getName]);
        
        self.publicFeed = [[GLPublicFeedViewController alloc] init];
        self.publicFeed.photosArray = [[NSMutableArray alloc] init];
        
        for(SLAlbumPhoto * photo in [album getPhotos]){
            [self.publicFeed.photosArray addObject:photo];
        }
        
        NSArray* reversedArray = [[self.publicFeed.photosArray reverseObjectEnumerator] allObjects];
        
        self.publicFeed.photosArray = [reversedArray copy];
        
//        self.publicFeed.albumId = [[al getShotVibeAPI] getPublicAlbumId];
        // TODO ...
    }];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    
    albumlistvc = [storyboard instantiateViewControllerWithIdentifier:@"SVAlbumListViewController"];
//    albumlistvc.delegate = self;
    
    self.navigationController = [[SVNavigationController alloc] initWithRootViewController:albumlistvc];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self.navigationController.view addSubview:[[GLSharedCamera sharedInstance] cameraViewBackground]];
    self.sidebarRight = [storyboard instantiateViewControllerWithIdentifier:@"SidebarMembersView"];
    self.sidebarLeft = [storyboard instantiateViewControllerWithIdentifier:@"SidebarManagementView"];
    self.sideMenu = [MFSideMenuContainerViewController containerWithCenterViewController:self.navigationController
                                                                  leftMenuViewController:nil
                                                                 rightMenuViewController:self.sidebarRight];
    self.sideMenu.panMode = MFSideMenuPanModeNone;
    
    freindsVc = [storyboard instantiateViewControllerWithIdentifier:@"InviteFriendsView"];
    freindsVc.delegate = self;
    NSLog(@"test");
    
    
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    
    self.pageController.dataSource = self;
    self.pageController.delegate = self;
    [[self.pageController view] setFrame:[[self view] bounds]];
    
    SVAddFriendsViewController *viewControllerObject = (SVAddFriendsViewController*)[self viewControllerAtIndex:1];
    
    NSArray *viewControllers = [NSArray arrayWithObject:viewControllerObject];
    
    
    [self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    
    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
    glcamera.delegate = self;
//    [self gotoPage:2];
    if([[ShotVibeAppDelegate sharedDelegate] appOpenedFromPush]){

        
        [self transitToAlbumList:NO direction:UIPageViewControllerNavigationDirectionReverse withAlbumId:[[ShotVibeAppDelegate sharedDelegate] pushAlbumId] completion:^{
            
            
            if(![[ShotVibeAppDelegate sharedDelegate] photoIdFromPush]){
                [[ShotVibeAppDelegate sharedDelegate] setAppOpenedFromPush:NO];
            }
            
//            [[[ShotVibeAppDelegate sharedDelegate] window] setAlpha:1];
            
        }];
//        [[ContainerViewController sharedInstance] transitToAlbumList:NO direction:UIPageViewControllerNavigationDirectionForward withAlbumId:5284 completion:^{
//            //
//        }];
    } else {
        
        
        [self transitToAlbumList:NO direction:UIPageViewControllerNavigationDirectionReverse withAlbumId:0 completion:^{
            
            
            
        }];
    }
    
    
    
    [self addChildViewController:self.pageController];
    [[self view] addSubview:[self.pageController view]];
    [self.pageController didMoveToParentViewController:self];
    
//    
//    for (UIView *view in self.pageController.view.subviews ) {
//        if ([view isKindOfClass:[UIScrollView class]]) {
//            UIScrollView *scroll = (UIScrollView *)view;
//            //                    scroll.delegate = self;
////                                scroll.pagingEnabled = YES;
////            scroll.scrollEnabled = !lock;
////                                scroll.alwaysBounceHorizontal = NO;
////                                scroll.bounces = NO;
//        }
//    }
    
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
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(LockScrollingInContainerPages:)
//                                                 name:@"LockScrollingInContainerPages"
//                                               object:nil];
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(ImageCapturedOnMainScreen:)
//                                                 name:@"ImageCapturedOnMainScreen"
//                                               object:nil];
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(ImageJustMoved:)
//                                                 name:@"ImageJustMoved"
//                                               object:nil];
}

- (void) ImageJustMoved:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:@"ImageJustMoved"]){

        
        NSDictionary *userInfo = notification.userInfo;
        NSString * photoToMoveId = [userInfo objectForKey:@"photoToMoveId"];
        //        UIImage *finalImage = [userInfo objectForKey:@"finalImage"];
        
        [self gotoPage:1];
        freindsVc.fromCameraMainScreen = NO;
        freindsVc.photoToMoveId = photoToMoveId;
//        self goToPage:1 andTransitToFeedAt:nil startUploadImidiatly:<#(BOOL)#>
        
    }
    
}

- (void) ImageCapturedOnMainScreen:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:@"ImageCapturedOnMainScreen"]){
        
        
        
//        UIStoryboard * sb = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
//        SVAddFriendsViewController * friendsvc = [sb instantiateViewControllerWithIdentifier:@"InviteFriendsView"];

        [self gotoPage:1];
        
//        NSDictionary *userInfo = notification.userInfo;
//        UIImage *finalImage = [userInfo objectForKey:@"finalImage"];
//        NSLog(@"");
//        [self presentViewController:friendsvc animated:YES completion:^{
//            
//        }];
//        [];
//        [self lockScrolling:[lock boolValue]];
//        NSLog (@"Successfully received the test notification!");
    }
}

- (void) LockScrollingInContainerPages:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:@"LockScrollingInContainerPages"]){
        
        NSDictionary *userInfo = notification.userInfo;
        NSString *lock = [userInfo objectForKey:@"lockScroll"];
        [self lockScrolling:[lock boolValue]];
        NSLog (@"Successfully received the test notification!");
    }
}

-(void)pageViewController:(UIPageViewController *)thePageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    
    
    if(completed) {
        
        
        if([[previousViewControllers objectAtIndex:0] class] == [MFSideMenuContainerViewController class]){
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
            [[[GLSharedCamera sharedInstance] videoCamera] stopCameraCapture];
        } else {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
            [[[GLSharedCamera sharedInstance] videoCamera] startCameraCapture];
        }
//        index = ((PageZoomViewController *)thePageViewController.viewControllers[0]).pageIndex;
//            NSUInteger index = thePageViewController
//        if(index == 1){
//            [[[GLSharedCamera sharedInstance] videoCamera] stopCameraCapture];
//            NSLog(@"stop camera");
//        } else if(index == 2){
//            [[[GLSharedCamera sharedInstance] videoCamera] startCameraCapture];
//            NSLog(@"start camera");
//        }
        
    }
}


//- (void)pageViewController:(UIPageViewController *)pvc didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
//{
//    // If the page did not turn
//    if (!completed)
//    {
//        // You do nothing because whatever page you thought
//        // the book was on before the gesture started is still the correct page
//        return;
//    }
//    
//    
////    if([[previousViewControllers objectAtIndex:0] class] == [SVAddFriendsViewController class]){
////        currentIndex = 1;
////    } else {
////        currentIndex = 0;
////    }
//    
//    // This is where you would know the page number changed and handle it appropriately
//    // [self sendPageChangeNotification:YES];
//    
//}

#pragma  - UIPageViewController Methods
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
//    if([viewController isKindOfClass:[SVAddFriendsViewController class]]){
//        return nil;
//    }
//    
//    if([viewController isKindOfClass:[MFSideMenuContainerViewController class]]){
//        return freindsVc;
//    }
    NSUInteger index = [(ViewController *)viewController indexNumber];
    
    if (index == 0 || index == 1) {
        return nil;
    }
    
    index--;
    
    return [self viewControllerAtIndex:index];
    
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    NSUInteger index = [(ViewController *)viewController indexNumber];
    
    
    index++;
    
    if (index == 4) {
        return nil;
    }
    
    return [self viewControllerAtIndex:index];
    
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index {
    
    
    if(index == 0){
//        freindsVc.indexNumber = index;
        
    } else if(index == 1){
        return freindsVc;
//        self.sideMenu.indexNumber = 1;
//        childViewController.indexNumber = index;
        
//        return self.sideMenu;
    } else if(index == 2){
        return  self.sideMenu;
    } else if(index == 3){
        return self.publicFeed;
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
    
//    self.st
    
    if(index == 2){
        _curIndex = 1;
        
    }
    
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
                
                SVAddFriendsViewController *viewController = (SVAddFriendsViewController*)[self viewControllerAtIndex:0];
                viewController.fromCameraMainScreen = YES;
//                viewController.
                
                [self.pageController setViewControllers:@[viewController]
                                                  direction:UIPageViewControllerNavigationDirectionForward
                                                   animated:NO
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

-(void)imageSelected:(UIImage *)image {

     GLFeedViewController * feed = (GLFeedViewController*)self.navigationController.visibleViewController;
    [feed imageSelected:image];

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

-(void)lockScrolling:(BOOL)lock {
    
    for (UIView *view in self.pageController.view.subviews ) {
                if ([view isKindOfClass:[UIScrollView class]]) {
                    UIScrollView *scroll = (UIScrollView *)view;
//                    scroll.delegate = self;
//                    scroll.pagingEnabled = YES;
                    scroll.scrollEnabled = !lock;
//                    scroll.alwaysBounceHorizontal = !lock;
//                    scroll.bounces = !lock;
                }
            }
}

- (void)goToPage:(int)num andTransitToFeedAt:(long long int)albumId startUploadImidiatly:(BOOL)start afterMove:(BOOL)afterMove{

//    GLFeedViewController * feed = [[self.sideMenu.navigationController.childViewControllers objectAtIndex:0] backPressed];
    
    [self gotoPage:num];
    [albumlistvc goToAlbumId:albumId startImidiatly:start addAlbumContents:nil];
    [self lockScrolling:YES];
    
    if(afterMove){
        [[GLSharedCamera sharedInstance]setInFeedMode:YES dmutNeedTransform:NO];
        [self.navigationController popViewControllerAnimated:NO];
    }
    
    
}

- (void)goToPage:(int)num {
        [self gotoPage:num];
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
