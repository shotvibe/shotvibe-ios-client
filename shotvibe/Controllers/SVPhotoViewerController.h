//
//  SVAlbumDetailScrollViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 2/14/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AlbumContents.h"
#import "AlbumManager.h"
#import "AlbumContentsListener.h"
#import "SVActivityViewController.h"
#import "AFPhotoEditorController.h"

#define GAP_X 60


@interface SVPhotoViewerController : UIViewController <
UIScrollViewDelegate,
UIActionSheetDelegate,
SVActivityViewControllerDelegate,
AFPhotoEditorControllerDelegate>


#pragma mark - Properties

@property (nonatomic, strong) NSMutableArray *photos;// Ordered photos depending on the sortType chosen in 
@property (nonatomic, assign) int64_t albumId;
@property (nonatomic, assign) int index;

@end
