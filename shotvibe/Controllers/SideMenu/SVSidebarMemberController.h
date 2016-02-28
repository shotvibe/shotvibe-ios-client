//
//  SVSidebarMenuViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 2/15/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLFeedViewController.h"
#import "GLPubNubManager.h"

@class SVAlbumGridViewController;

@interface SVSidebarMemberController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UILabel *groupTitle;
#pragma mark - Public Properties

@property (strong, nonatomic) GLFeedViewController *parentController;
@property (nonatomic, strong) SLAlbumContents *albumContents;
@property (nonatomic) long long int albumId;
@property (weak, nonatomic) IBOutlet UIImageView *addPlusButton;

@end
