//
//  SVAlbumListViewController.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NINetworkImageView.h"
#import "CaptureViewfinderController.h"
#import "CaptureNavigationController.h"
#import "SVDownloadManager.h"
#import "SVUploadManager.h"
#import "SVDefines.h"
#import "Album.h"
#import "Member.h"
#import "AlbumPhoto.h"
#import "SVAlbumListViewCell.h"
#import "SVAlbumGridViewController.h"
#import "SVOfflineStorageWS.h"
#import "SVEntityStore.h"
#import "NSDate+Formatting.h"
#import "SVBusinessDelegate.h"
#import "MagicalRecordShorthand.h"
#import "MagicalRecord+Actions.h"
#import "NSManagedObjectContext+MagicalRecord.h"

@interface SVAlbumListViewController : UIViewController <UITableViewDataSource,
UITableViewDelegate,
UITextFieldDelegate,
UISearchBarDelegate,
NINetworkImageViewDelegate,
CaptureViewfinderDelegate> {
	
}

@end
