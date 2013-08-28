//
//  SVAlbumDetailScrollViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 2/14/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVEntityStore.h"
#import "RCScrollView.h"
//#import "RCImageView.h"
#import "RCScrollImageView.h"
#import "SVLinkActivity.h"
#import "SVActivityViewController.h"
#import "AlbumContents.h"

@class OldAlbumPhoto;
@interface SVPhotoViewerController : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate, SVLinkActivityDelegate> {
	
	RCScrollView *photosScrollView;
}

#pragma mark - Properties

@property (nonatomic, strong) AlbumContents *albumContents;
@property (nonatomic, strong) NSMutableDictionary *cache;
@property (nonatomic) int index;

@end
