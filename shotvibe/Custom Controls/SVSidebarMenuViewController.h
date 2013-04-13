//
//  SVSidebarMenuViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 2/15/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SVAlbumGridViewController;
@class Album;

@interface SVSidebarMenuViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

#pragma mark - Properties

@property (strong, nonatomic) SVAlbumGridViewController *parentController;
@property (strong, nonatomic) Album *selectedAlbum;


#pragma mark - Instance Methods

- (void)refreshMembers;

@end
