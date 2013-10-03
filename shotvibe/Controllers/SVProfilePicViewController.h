//
//  SVProfilePicViewController.h
//  shotvibe
//
//  Created by Baluta Cristian on 17/09/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVImageCropViewController.h"
#import "AlbumManager.h"

@interface SVProfilePicViewController : UIViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate> {
	
	IBOutlet UIImageView *imageView;
}

@property (nonatomic) id <SVImageCropDelegate> delegate;
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, strong) AlbumManager *albumManager;

@end
