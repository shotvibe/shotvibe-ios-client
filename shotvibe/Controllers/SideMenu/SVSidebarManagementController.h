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
#import "GLFeedViewController.h"

@class SVAlbumGridViewController;
@class SLAlbumContents;

@interface SVSidebarManagementController : UIViewController <UITableViewDataSource, UITableViewDelegate, SVSidebarAlbumManagementSectionDelegate, UIAlertViewDelegate>

#pragma mark - Properties

@property (strong, nonatomic) GLFeedViewController *parentController;
@property (nonatomic, strong) SLAlbumContents *albumContents;
@property (nonatomic) NSMutableArray *sectionInfoArray;
@property (nonatomic) NSInteger openSectionIndex;

@end
