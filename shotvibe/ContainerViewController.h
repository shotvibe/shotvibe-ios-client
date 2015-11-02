//
//  ContainerViewController.h
//  PageViewControllerExample
//
//  Created by Mani Shankar on 29/08/14.
//  Copyright (c) 2014 makemegeek. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLSharedCamera.h"
#import "SVAddFriendsViewController.h"
#import "SVAlbumListViewController.h"

//typedef enum ScrollDirection {
//    ScrollDirectionNone,
//    ScrollDirectionRight,
//    ScrollDirectionLeft,
//    ScrollDirectionUp,
//    ScrollDirectionDown,
//    ScrollDirectionCrazy,
//} ScrollDirection;



@interface ContainerViewController : UIViewController<UIPageViewControllerDataSource,UIScrollViewDelegate,UIPageViewControllerDelegate,GLSharedCameraDelegatte,AddFriendsDelegate,AlbumListDelegate>
@property (strong, nonatomic) UIPageViewController *pageController;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic) IBOutlet UIImageView *bluredImageView;
@property (nonatomic, assign) CGFloat lastContentOffset;
@property (nonatomic, assign) CGFloat containerlastContentOffset;
@end
