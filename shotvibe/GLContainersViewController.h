//
//  GLContainersViewController.h
//  shotvibe
//
//  Created by Tsah Kashkash on 28/12/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShotVibeAPI.h"
#import "SL/AlbumContents.h"
#import "SL/ArrayList.h"
#import "ShotVibeAPITask.h"
#import "GLFeedViewController.h"
#import "SVAddFriendsViewController.h"
#import "SVSidebarMemberController.h"
#import "GLPublicFeedViewController.h"
#import "SVAlbumListViewController.h"
#import "SVNavigationController.h"
#import "UIViewController+index.h"
#import "MFSideMenuContainerViewController.h"
#import "SVSidebarMemberController.h"
#import "SVNotificationHandler.h"

typedef void(^pageTransitionCompleted)();

@interface GLContainersViewController : UIViewController <UINavigationControllerDelegate,UIImagePickerControllerDelegate,UIPageViewControllerDataSource,UIPageViewControllerDelegate>

@property (strong, nonatomic) UIPageViewController *pageController;
@property (strong, nonatomic) GLFeedViewController *feedViewController;
@property (strong, nonatomic) SVAlbumListViewController *albumListViewController;
@property (strong, nonatomic) SVAddFriendsViewController *friendsViewController;
@property (strong, nonatomic) GLPublicFeedViewController *publicFeedViewController;
@property (strong, nonatomic) SVNavigationController * navigationController;
@property (nonatomic, strong) MFSideMenuContainerViewController *membersSideMenu;
@property (nonatomic, strong) SVSidebarMemberController * membersViewController;


+ (GLContainersViewController *)sharedInstance;
-(void)disablePublicFeedPushAlerter;
- (void)goToPublicFeed:(BOOL)animated;
- (void)goToFriendsListViewAnimatedBeforeUploadingPhoto:(BOOL)animated completed:(pageTransitionCompleted)completed executeWhenFriendsDone:(BlockToExecuteWhenDone)friendsDoneBlock;
- (void)goToFeedViewAnimated:(BOOL)animated withAlbumId:(long long int)albumId;
- (void)goToFeedViewAnimated:(BOOL)animated withAlbumId:(long long int)albumId completed:(pageTransitionCompleted)completed;
- (void)goToFriendsListViewAnimatedBeforeAddingMembers:(BOOL)animated albumId:(long long int)albumId;
- (void)goToFriendsListViewAnimatedBeforeMovingPhoto:(BOOL)animated photoId:(NSString*)photoId;
- (void)goToFriendsListViewAnimatedBeforeMovingPhoto:(BOOL)animated photoId:(NSString*)photoId completed:(pageTransitionCompleted)completed fromPublic:(BOOL)fromPublic;
- (void)goToAlbumListViewController:(BOOL)animated;
- (void)resetFriendsView;
- (void)lockScrollingPages ;
- (void)unlockScrollingPages;
- (void)goBackToFeedAfterAddingMembersAnimated:(BOOL)animated;
- (void)disableSideMembers;
- (void)enableSideMembers;
- (void)openAppleImagePicker;

- (void)handleAddedPhotosPushPressed:(SLNotificationMessage_PhotosAdded *)data;
- (void)handleAddedToGroupPushPressed:(SLNotificationMessage_AddedToAlbum *)data;
- (void)handleCommentedPushPressed:(SLNotificationMessage_PhotoComment*)data;
- (void)handleGlancedPushPressed:(SLNotificationMessage_PhotoGlanceScoreDelta*)data;
@end
