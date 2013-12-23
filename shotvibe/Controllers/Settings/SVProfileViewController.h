//
//  SVProfileViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 4/16/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AlbumManager.h"
#import "SVProfilePicViewController.h"


@interface SVProfileViewController : UIViewController <UITextFieldDelegate, SVImageCropDelegate>

@property (nonatomic, strong) AlbumManager *albumManager;

@end
