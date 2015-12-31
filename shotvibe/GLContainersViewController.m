//
//  GLContainersViewController.m
//  shotvibe
//
//  Created by Tsah Kashkash on 28/12/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import "GLContainersViewController.h"

@interface GLContainersViewController () {
    int currentPageIndex;
}

@end

@implementation GLContainersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    // Do any additional setup after loading the view from its nib.
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    
    self.pageController.dataSource = self;
    self.pageController.delegate = self;
    [[self.pageController view] setFrame:[[self view] bounds]];
//    self.pageController.pag
    
    
    [self addChildViewController:self.pageController];
    [[self view] addSubview:[self.pageController view]];
    [self.pageController didMoveToParentViewController:self];
    
//    [self.view addSubview:self.pageController.view];
    
    
//    UIStoryboard * storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    
    self.publicFeedViewController = [[GLPublicFeedViewController alloc] init];
    self.publicFeedViewController.indexNumber = 2;
    self.albumListViewController = [[SVAlbumListViewController alloc] init];
    
    
    self.navigationController = [[SVNavigationController alloc] initWithRootViewController:self.albumListViewController];
    self.navigationController.indexNumber = 1;
    [self.navigationController setNavigationBarHidden:YES];
    [self.pageController setViewControllers:@[self.navigationController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
    }];
    
    
//    [[[GLSharedCamera sharedInstance] cameraViewBackground]removeFromSuperview];
    
//    currentPageIndex = 1;
//    [self.pageController setViewControllers:@[self.albumListViewController]
//                                  direction:UIPageViewControllerNavigationDirectionForward
//                                   animated:NO
//                                 completion:^(BOOL done){
////                                     completion();
//                                 }];
    
    

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
        return self.navigationController;
    } else if (i == 2){
        NSLog(@"requested page 2");
        return self.publicFeedViewController;
    } else if (i == 3){
        NSLog(@"requested page 3");
    }
    
    
    // Assuming you have SomePageViewController.xib
//    SomePageViewController *newController = [[SomePageViewController alloc] initWithNibName:@"SomePageViewController" bundle:nil];
//    newController.idx = i;
//    return [self viewControllerAtIndex:<#(int)#>];
}


//- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
////    SomePageViewController *p = (SomePageViewController *)viewController;
//    int index = [viewController indexNumber];
//    
//    return [self viewControllerAtIndex:index-1];
////    return [self viewControllerAtIndex:(p.idx - 1)];
//}
//
//- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
////    SomePageViewController *p = (SomePageViewController *)viewController;
////    return [self viewControllerAtIndex:(p.idx + 1)];
//    int index = [viewController indexNumber];
//    return [self viewControllerAtIndex:index];
//}


- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
//        if([viewController isKindOfClass:[SVAddFriendsViewController class]]){
//            return nil;
//        }
//    
//        if([viewController isKindOfClass:[MFSideMenuContainerViewController class]]){
//            return freindsVc;
//        }
    int index = [(UIViewController *)viewController indexNumber];
    
    if (index == 0 || index == 1) {
        return nil;
    }
//    if (index > 0){
        index--;
//    }
    
    return [self viewControllerAtIndex:index];
    
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    int index = [viewController indexNumber];
    
    
    index++;
    
    if (index == 4) {
        return nil;
    }
    
    return [self viewControllerAtIndex:index];
    
}
//
//- (UIViewController *)viewControllerAtIndex:(NSUInteger)index {
//    
//    
//    if(index == 0){
//        //        freindsVc.indexNumber = index;
//        return self.friendsViewController;
//        
//    } else if(index == 1){
//        return self.albumListViewController;
//        //        self.sideMenu.indexNumber = 1;
//        //        childViewController.indexNumber = index;
//        
//        //        return self.sideMenu;
//    } else if(index == 2){
//        return self.publicFeedViewController;
////        return  self.sideMenu;
//    } else if(index == 3){
////        return self.publicFeed;
//    }
//    
//    
//}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
