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

@interface SVAlbumListViewController : UIViewController <UITableViewDataSource,
UITableViewDelegate,
UITextFieldDelegate,
UISearchBarDelegate,
NINetworkImageViewDelegate,
CaptureViewfinderDelegate>

@end
