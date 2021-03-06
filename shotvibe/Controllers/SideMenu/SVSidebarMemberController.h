//
//  SVSidebarMenuViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 2/15/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SVAlbumGridViewController;

@interface SVSidebarMemberController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UISearchBarDelegate>

#pragma mark - Public Properties

@property (strong, nonatomic) SVAlbumGridViewController *parentController;
@property (nonatomic, strong) SLAlbumContents *albumContents;

@end
