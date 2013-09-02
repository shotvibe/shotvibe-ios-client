//
//  SVAlbumListViewController.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVDefines.h"
#import "AlbumSummary.h"
#import "AlbumMember.h"
#import "AlbumPhoto.h"
#import "CaptureNavigationController.h"
#import "SVCameraPickerController.h"
#import "SVAlbumListViewCell.h"
#import "SVAlbumGridViewController.h"
#import "NSDate+Formatting.h"
#import "AlbumListListener.h"
#import "AlbumManager.h"
#import "MFSideMenu.h"

@interface SVAlbumListViewController : UITableViewController <UITableViewDataSource,
																UITableViewDelegate,
																UITextFieldDelegate,
																UISearchBarDelegate,
																AlbumListListener,
																SVCameraPickerDelegate>
{
	
}

@property (nonatomic, strong) AlbumManager *albumManager;

@end
