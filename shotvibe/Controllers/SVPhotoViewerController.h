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

#define GAP_X 60

typedef enum {
	PhotoViewerTypeTableView,
	PhotoViewerTypeScrollView
} PhotoViewerType;

@interface SVPhotoViewerController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UIActionSheetDelegate, RCTableImageViewCellDelegate, SVActivityViewControllerDelegate, AFPhotoEditorControllerDelegate> {
	
	UITableView *photosTableView;
	RCScrollView *photosScrollView;
	PhotoViewerType viewerType;
	NSMutableArray *photos;
	NSMutableArray *cache;
	SVActivityViewController* activity;
	BOOL toolVisible;
	AlbumContents *albumContents;
}

#pragma mark - Properties

@property (nonatomic, strong) AlbumManager *albumManager;
@property (nonatomic, assign) int64_t albumId;
@property (nonatomic) int index;

@end
