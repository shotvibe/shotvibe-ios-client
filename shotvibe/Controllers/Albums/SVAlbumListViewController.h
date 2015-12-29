//
//  SVAlbumListViewController.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SL/AlbumManager.h"
#import "SVCameraPickerController.h"
#import "SVAlbumListViewCell.h"
#import "SVAlbumGridViewController.h"
#import "SL/NetworkStatusManager.h"
#import "SVNotificationHandler.h"
#import "ShotVibeAppDelegate.h"
//#import "SVAddFriendsViewController.h"


@protocol AlbumListDelegate <NSObject>

//- (void)goToAlbumId:(long long int)num;

@end

@interface SVAlbumListViewController : UITableViewController <UITableViewDataSource,
                                                                NotificationManagerDelegate,
																UITableViewDelegate,
																UITextFieldDelegate,
																UISearchBarDelegate,
                                                              SLAlbumManager_AlbumListListener,
																SVCameraPickerDelegate,
                                                              SVAlbumListViewCellDelegate,
                                                              SLNetworkStatusManager_Listener,
                                                                GLSharedCameraDelegatte,
                                                                UIImagePickerControllerDelegate,
                                                                UINavigationControllerDelegate>

// This function is a temporary hack
// Returns nil if not an org
+ (NSString *)getAlbumOrg:(SLAlbumBase *)album;
- (void)transitToAlbumWithId:(long long int)num animated:(BOOL)animated dmutScale:(BOOL)scale;
- (void)goToAlbumId:(long long int)num startImidiatly:(BOOL)start addAlbumContents:(SLAlbumContents*)album;
- (void)goToAlbumId:(long long int)num startImidiatly:(BOOL)start addAlbumContents:(SLAlbumContents*)album isVideo:(BOOL)isVideo;

@property (nonatomic, assign) id<AlbumListDelegate> delegate;
//@property (assign, nonatomic) NSInteger indexNumber;

@end
