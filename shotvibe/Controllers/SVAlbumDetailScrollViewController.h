//
//  SVAlbumDetailScrollViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 2/14/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NetworkPhotoAlbumViewController.h"

@class Photo;
@interface SVAlbumDetailScrollViewController : NetworkPhotoAlbumViewController <NIPhotoAlbumScrollViewDataSource, NIPhotoScrubberViewDataSource, NIOperationDelegate, UIActionSheetDelegate>

#pragma mark - Properties

@property (nonatomic, strong) Photo *selectedPhoto;

@end
