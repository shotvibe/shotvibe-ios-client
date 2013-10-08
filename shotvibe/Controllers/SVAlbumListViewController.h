//
//  SVAlbumListViewController.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AlbumManager.h"
#import "AlbumListListener.h"
#import "SVCameraPickerController.h"
#import "SVAlbumListViewCell.h"


@interface SVAlbumListViewController : UITableViewController <UITableViewDataSource,
																UITableViewDelegate,
																UITextFieldDelegate,
																UISearchBarDelegate,
																AlbumListListener,
																SVCameraPickerDelegate,
																SVAlbumListViewCellDelegate>

@property (nonatomic, strong) AlbumManager *albumManager;

@end
