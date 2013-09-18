//
//  SVImagePickerListViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 5/2/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVCameraPickerDelegate.h"
#import "AlbumManager.h"

@class AlbumSummary;

@interface SVImagePickerListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) BOOL oneImagePicker;
@property (nonatomic, retain) id <SVCameraPickerDelegate> delegate;

@property (nonatomic, assign) int64_t albumId;
@property (nonatomic, strong) AlbumManager *albumManager;
@property (nonatomic, strong) AlbumSummary *selectedAlbum;

@end
