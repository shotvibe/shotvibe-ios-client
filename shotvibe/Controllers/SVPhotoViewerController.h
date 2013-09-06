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

#define GAP_X 60

typedef enum {
	PhotoViewerTypeTableView,
	PhotoViewerTypeScrollView
} PhotoViewerType;

@interface SVPhotoViewerController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UIActionSheetDelegate, RCTableImageViewCellDelegate, SVActivityViewControllerDelegate> {
	
	UITableView *photosTableView;
	RCScrollView *photosScrollView;
	PhotoViewerType viewerType;
	NSMutableArray *photos;
	NSMutableDictionary *cache;
	SVActivityViewController* activity;
}

#pragma mark - Properties

@property (nonatomic, strong) AlbumContents *albumContents;
@property (nonatomic) int index;

@end
