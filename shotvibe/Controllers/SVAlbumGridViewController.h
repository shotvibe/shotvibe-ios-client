//
//  SVAlbumGridViewController.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/13/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVCameraPickerDelegate.h"

#import "AlbumContentsListener.h"
#import "AlbumManager.h"

@class SVSidebarAlbumMemberViewController;
@class SVSidebarAlbumManagementViewController;

@class AlbumSummary;

@interface SVAlbumGridViewController : UIViewController <UIScrollViewDelegate, AlbumContentsListener, SVCameraPickerDelegate>

#pragma mark - Properties

@property (nonatomic, strong) SVSidebarAlbumMemberViewController *sidebarRight;
@property (nonatomic, strong) SVSidebarAlbumManagementViewController *sidebarLeft;

@property (nonatomic, assign) int64_t albumId;
@property (nonatomic, strong) AlbumManager *albumManager;

@end
