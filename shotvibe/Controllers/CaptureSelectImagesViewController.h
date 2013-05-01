//
//  CaptureSelectImagesViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 5/1/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Album;

@interface CaptureSelectImagesViewController : UIViewController

@property (nonatomic, strong) NSArray *takenPhotos;
@property (nonatomic, strong) Album *selectedAlbum;
@end
