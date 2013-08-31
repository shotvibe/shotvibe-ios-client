//
//  SVSidebarManagementViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 3/29/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVSidebarAlbumManagementActivityCell.h"
#import "SVSidebarAlbumManagementSection.h"
#import "SVSidebarAlbumSection.h"
#import "MFSideMenu.h"
#import "UINavigationController+MFSideMenu.h"

@class SVAlbumGridViewController;

@interface SVSidebarAlbumManagementViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, SVSidebarAlbumManagementSectionDelegate, UIAlertViewDelegate>

#pragma mark - Properties

@property (strong, nonatomic) SVAlbumGridViewController *parentController;
@property (nonatomic) NSMutableArray *sectionInfoArray;
@property (nonatomic) NSInteger openSectionIndex;

@end
