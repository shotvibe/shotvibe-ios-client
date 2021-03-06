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


@interface SVAlbumListViewController : UITableViewController <UITableViewDataSource,
																UITableViewDelegate,
																UITextFieldDelegate,
																UISearchBarDelegate,
                                                              SLAlbumManager_AlbumListListener,
																SVCameraPickerDelegate,
                                                              SVAlbumListViewCellDelegate,
                                                              SLNetworkStatusManager_Listener>

// This function is a temporary hack
// Returns nil if not an org
+ (NSString *)getAlbumOrg:(SLAlbumBase *)album;

@end
