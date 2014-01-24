//
//  SBPickerController.h
//  test
//
//  Created by Salvatore Balzano on 20/01/14.
//  Copyright (c) 2014 MobiApps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVPictureConfirmViewController.h"

@interface SVPickerController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, assign) int64_t albumId;
@property (nonatomic, strong) AlbumManager *albumManager;

@property (nonatomic, weak) SVPictureConfirmViewController *container;

@end
