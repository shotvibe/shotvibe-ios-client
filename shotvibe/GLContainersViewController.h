//
//  GLContainersViewController.h
//  shotvibe
//
//  Created by Tsah Kashkash on 28/12/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLFeedViewController.h"
#import "SVAddFriendsViewController.h"
#import "GLPublicFeedViewController.h"
#import "SVAlbumListViewController.h"
#import "SVNavigationController.h"
#import "UIViewController+index.h"

@interface GLContainersViewController : UIViewController <UIPageViewControllerDataSource,UIPageViewControllerDelegate>

@property (strong, nonatomic) UIPageViewController *pageController;
@property (strong, nonatomic) GLFeedViewController *feedViewController;
@property (strong, nonatomic) SVAlbumListViewController *albumListViewController;
@property (strong, nonatomic) SVAddFriendsViewController *friendsViewController;
@property (strong, nonatomic) GLPublicFeedViewController *publicFeedViewController;
@property (strong, nonatomic) SVNavigationController * navigationController;

@end
