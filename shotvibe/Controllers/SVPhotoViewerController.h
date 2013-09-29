//
//  SVAlbumDetailScrollViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 2/14/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCScrollView.h"
#import "RCImageView.h"
#import "RCScrollImageView.h"
#import "RCTableImageViewCell.h"
#import "SVLinkActivity.h"
#import "SVActivityViewController.h"
#import "AlbumContents.h"
#import "AlbumManager.h"
#import "AFPhotoEditorController.h"
#import "AlbumContentsListener.h"

#define GAP_X 60


@interface SVPhotoViewerController : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate, RCTableImageViewCellDelegate, SVActivityViewControllerDelegate, AFPhotoEditorControllerDelegate, AlbumContentsListener>


#pragma mark - Properties

@property (nonatomic, strong) AlbumManager *albumManager;
@property (nonatomic, assign) int64_t albumId;
@property (nonatomic) int index;

@end
