//
//  SVProfilePicViewController.h
//  shotvibe
//
//  Created by Baluta Cristian on 17/09/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVImageCropViewController.h"
#import "SVImagePickerListViewController.h"
#import "SL/AlbumManager.h"

@interface SVProfilePicViewController : UIViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, SVCameraPickerDelegate> {
	
	IBOutlet UIImageView *imageView;
}

@property (nonatomic) id <SVImageCropDelegate> delegate;
@property (nonatomic, retain) UIImage *image;

@end
