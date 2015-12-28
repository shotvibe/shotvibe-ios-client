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

@implementation GLContainersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    
    self.pageController.dataSource = self;
    self.pageController.delegate = self;
    [[self.pageController view] setFrame:[[self view] bounds]];
    
    
    [self addChildViewController:self.pageController];
    [[self view] addSubview:[self.pageController view]];
    [self.pageController didMoveToParentViewController:self];
    
//    [self.view addSubview:self.pageController.view];
    
    
    UIStoryboard * storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    ////    SVAddFriendsViewController * friendsvc = [sb instantiateViewControllerWithIdentifier:@"InviteFriendsView"];
    ////    SVAlbumListViewController * albumlistvc = [sb instantiateViewControllerWithIdentifier:@"SVAlbumListViewController"];
    
    self.albumListViewController = [storyBoard instantiateViewControllerWithIdentifier:@"SVAlbumListViewController"];//[[SVAlbumListViewController alloc] init];
//    self.albumListViewController.view.frame = [[self view] bounds];
    
//    self.navigationController = [[SVNavigationController alloc] initWithRootViewController:self.albumListViewController];
    
    [self.pageController setViewControllers:@[self.albumListViewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
        
    }];
    
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma  - UIPageViewController Methods
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
//        if([viewController isKindOfClass:[SVAddFriendsViewController class]]){
//            return nil;
//        }
//    
//        if([viewController isKindOfClass:[MFSideMenuContainerViewController class]]){
//            return freindsVc;
//        }
    NSUInteger index = [(UIViewController *)viewController indexNumber];
    
    if (index == 0 || index == 1) {
        return nil;
    }
    
    index--;
    
    return [self viewControllerAtIndex:index];
    
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    NSUInteger index = [(UIViewController *)viewController indexNumber];
    
    
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
        return self.albumListViewController;
        //        self.sideMenu.indexNumber = 1;
        //        childViewController.indexNumber = index;
        
        //        return self.sideMenu;
    } else if(index == 2){
//        return  self.sideMenu;
    } else if(index == 3){
//        return self.publicFeed;
    }
    
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
