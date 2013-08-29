//
//  SVAlbumListViewController.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCImageView.h"
#import "CaptureNavigationController.h"
#import "SVCameraPickerController.h"
#import "SVDefines.h"
#import "AlbumSummary.h"
#import "AlbumMember.h"
#import "AlbumPhoto.h"
#import "SVAlbumListViewCell.h"
#import "SVAlbumGridViewController.h"
#import "SVOfflineStorageWS.h"
#import "SVEntityStore.h"
#import "NSDate+Formatting.h"
#import "SVBusinessDelegate.h"
#import "AlbumListListener.h"
#import "AlbumManager.h"

@interface SVAlbumListViewController : UIViewController <UITableViewDataSource,
UITableViewDelegate,
UITextFieldDelegate,
UISearchBarDelegate,
AlbumListListener,
RCImageViewDelegate,
SVCameraPickerDelegate> {
}

@property (nonatomic, strong) AlbumManager *albumManager;

@end
