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
#import "OldAlbum.h"

@interface CaptureNavigationController : NSObject <SVCameraPickerDelegate> {
	
	SVCameraPickerController *cameraController;
}

@property (nonatomic, retain) id<SVCameraPickerDelegate> cameraDelegate;
@property (nonatomic, strong) NSArray *albums;
@property (nonatomic, strong) OldAlbum *selectedAlbum;
@property (nonatomic, strong) UINavigationController *nav;

@end
