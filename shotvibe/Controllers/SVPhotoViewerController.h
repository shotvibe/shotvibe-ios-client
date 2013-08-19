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
#import "RCImageView.h"
#import "AlbumPhoto.h"
#import "SVLinkActivity.h"

@class AlbumPhoto;
@interface SVPhotoViewerController : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate, SVLinkActivityDelegate> {
	
	RCScrollView *photosScrollView;
}

#pragma mark - Properties

@property (nonatomic, strong) NSMutableArray *sortedPhotos;
@property (nonatomic, strong) NSMutableDictionary *cache;
@property (nonatomic, strong) AlbumPhoto *selectedPhoto;
@property (nonatomic) int index;

@end
