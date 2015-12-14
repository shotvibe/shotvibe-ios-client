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
#import "SVNavigationController.h"

typedef void(^pageTransitionCompleted)();

//typedef enum ScrollDirection {
//    ScrollDirectionNone,
//    ScrollDirectionRight,
//    ScrollDirectionLeft,
//    ScrollDirectionUp,
//    ScrollDirectionDown,
//    ScrollDirectionCrazy,
//} ScrollDirection;



@interface ContainerViewController : UIViewController<UIPageViewControllerDataSource,UIScrollViewDelegate,UIPageViewControllerDelegate,GLSharedCameraDelegatte,AddFriendsDelegate,AlbumListDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
+ (ContainerViewController *)sharedInstance;

- (void)transitToAlbumList:(BOOL)animated direction:(UIPageViewControllerNavigationDirection)direction withAlbumId:(long long int)albumId completion:(pageTransitionCompleted)completion;
- (void)transitToFriendsList:(BOOL)animated direction:(UIPageViewControllerNavigationDirection)direction completion:(pageTransitionCompleted)completion;
- (void)startVideoUploadAfterSourceSelect:(long long int)albumId withAlbumContents:(SLAlbumContents*)album;
-(void)lockScrolling:(BOOL)lock;
- (void)resetFriendsView;
- (void)startUploadAfterSourceSelect:(long long int)albumId withAlbumContents:(SLAlbumContents*)album;
- (void)setFriendsFromMain;
- (void)setFriendsFromMainWithPicture;
- (void)setFriendsForMove:(NSString*)photoId;
//- (void)attachAlbumContent:(SLAlbumContents*)album;



@property (strong, nonatomic) UIPageViewController *pageController;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic) IBOutlet UIImageView *bluredImageView;
@property (nonatomic, assign) CGFloat lastContentOffset;
@property (nonatomic, assign) CGFloat containerlastContentOffset;
@property(nonatomic, retain) SVNavigationController *navigationController;
@end
