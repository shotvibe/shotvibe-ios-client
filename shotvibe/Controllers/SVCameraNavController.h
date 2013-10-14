//
//  CaptureNavigationController.h
//  shotvibe
//
//  Created by John Gabelmann on 4/22/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVCameraPickerDelegate.h"
#import "SVCameraPickerController.h"
#import "AlbumSummary.h"

@interface SVCameraNavController : NSObject <SVCameraPickerDelegate> {
	
	SVCameraPickerController *cameraController;
}

@property (nonatomic, retain) id<SVCameraPickerDelegate> cameraDelegate;
@property (nonatomic, strong) UINavigationController *nav;
@property (nonatomic) BOOL oneImagePicker;
@property (nonatomic) BOOL imageWasTaken;

@property (nonatomic, assign) int64_t albumId;
@property (nonatomic, strong) AlbumManager *albumManager;

@property (nonatomic, strong) NSArray *albums;
@property (nonatomic, strong) AlbumSummary *selectedAlbum;

@end
