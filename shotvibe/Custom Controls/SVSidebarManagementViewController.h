//
//  SVSidebarManagementViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 3/29/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SVAlbumGridViewController;

@interface SVSidebarManagementViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

#pragma mark - Properties

@property (strong, nonatomic) SVAlbumGridViewController *parentController;

@end
