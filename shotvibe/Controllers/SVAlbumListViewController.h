//
//  SVAlbumListViewController.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCImageView.h"
#import "CaptureViewfinderController.h"
#import "CaptureNavigationController.h"
#import "SVDownloadManager.h"
#import "SVUploadManager.h"
#import "SVDefines.h"
#import "OldAlbum.h"
#import "OldMember.h"
#import "OldAlbumPhoto.h"
#import "SVAlbumListViewCell.h"
#import "SVAlbumGridViewController.h"
#import "SVOfflineStorageWS.h"
#import "SVEntityStore.h"
#import "NSDate+Formatting.h"
#import "SVBusinessDelegate.h"
#import "MagicalRecordShorthand.h"
#import "MagicalRecord+Actions.h"
#import "NSManagedObjectContext+MagicalRecord.h"
#import "AlbumListListener.h"
#import "AlbumManager.h"

@interface SVAlbumListViewController : UIViewController <UITableViewDataSource,
UITableViewDelegate,
UITextFieldDelegate,
UISearchBarDelegate,
AlbumListListener,
CaptureViewfinderDelegate,
RCImageViewDelegate> {
}

@property (nonatomic, strong) AlbumManager *albumManager;

@end
