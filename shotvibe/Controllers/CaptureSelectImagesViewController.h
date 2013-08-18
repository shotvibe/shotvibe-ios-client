//
//  CaptureSelectImagesViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 5/1/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <UIKit/UIKit.h>
#import "CaptureViewfinderController.h"

@class OldAlbum;

@interface CaptureSelectImagesViewController : UIViewController

@property (nonatomic, strong) NSArray *takenPhotos;// Set only one of this options
@property (nonatomic, strong) NSArray *libraryPhotos;
@property (nonatomic, strong) OldAlbum *selectedAlbum;
@property (nonatomic, strong) ALAssetsGroup *selectedGroup;

@property (nonatomic) id <CaptureViewfinderDelegate> delegate;

@end
