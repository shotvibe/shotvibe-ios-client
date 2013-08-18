//
//  SVAlbumGridViewController.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/13/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SVSidebarAlbumMemberViewController;
@class SVSidebarAlbumManagementViewController;

@class OldAlbum;

@interface SVAlbumGridViewController : UIViewController <UIScrollViewDelegate>

#pragma mark - Properties

@property (nonatomic, strong) OldAlbum *selectedAlbum;
@property (nonatomic, strong) SVSidebarAlbumMemberViewController *sidebarRight;
@property (nonatomic, strong) SVSidebarAlbumManagementViewController *sidebarLeft;


@end
