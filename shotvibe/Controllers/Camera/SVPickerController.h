//
//  SBPickerController.h
//  shotvibe
//
//  Created by Salvatore Balzano on 20/01/14.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVPictureConfirmViewController.h"

@interface SVPickerController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, assign) int64_t albumId;

@property (nonatomic, weak) SVPictureConfirmViewController *container;

@end
