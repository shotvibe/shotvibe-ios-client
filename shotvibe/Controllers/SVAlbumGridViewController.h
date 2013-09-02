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

@interface SVAlbumGridViewController : UIViewController <UIScrollViewDelegate, AlbumContentsListener, SVCameraPickerDelegate>

#pragma mark - Properties

@property (nonatomic, assign) int64_t albumId;
@property (nonatomic, strong) AlbumManager *albumManager;

@end
