//
//  SVAlbumDetailScrollViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 2/14/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NetworkPhotoAlbumViewController.h"

@class AlbumPhoto;
@interface SVAlbumDetailScrollViewController : NetworkPhotoAlbumViewController <NIPhotoAlbumScrollViewDataSource, NIPhotoScrubberViewDataSource, NIOperationDelegate, UIActionSheetDelegate>

#pragma mark - Properties

@property (nonatomic, strong) AlbumPhoto *selectedPhoto;

@end
