//
//  SVSidebarMenuViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 2/15/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SVAlbumGridViewController;
@class OldAlbum;

@interface SVSidebarAlbumMemberViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

#pragma mark - Properties

@property (strong, nonatomic) SVAlbumGridViewController *parentController;
@property (nonatomic, strong) AlbumContents *albumContents;

@end
