//
//  SVAlbumGridViewController.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/13/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AlbumContentsListener.h"
#import "AlbumManager.h"

@class SVSidebarAlbumMemberViewController;
@class SVSidebarAlbumManagementViewController;

@class OldAlbum;

@interface SVAlbumGridViewController : UIViewController <UIScrollViewDelegate, AlbumContentsListener>

#pragma mark - Properties

@property (nonatomic, strong) SVSidebarAlbumMemberViewController *sidebarRight;
@property (nonatomic, strong) SVSidebarAlbumManagementViewController *sidebarLeft;

@property (nonatomic, assign) int64_t albumId;
@property (nonatomic, strong) AlbumManager *albumManager;

@end
