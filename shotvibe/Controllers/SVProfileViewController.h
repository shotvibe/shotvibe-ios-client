//
//  SVProfileViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 4/16/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AlbumManager.h"
#import "SVCameraPickerDelegate.h"
#import "SVCameraPickerController.h"


//#define OPTIONS [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ? (@"Camera", @"Photo Gallery") : @"Photo Gallery"
#define OPTIONS @"Camera", @"Photo Gallery"

@interface SVProfileViewController : UIViewController <UITextFieldDelegate, UIActionSheetDelegate, SVCameraPickerDelegate>

@property (nonatomic, strong) AlbumManager *albumManager;

@end
