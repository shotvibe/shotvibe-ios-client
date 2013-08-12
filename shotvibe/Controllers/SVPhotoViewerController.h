//
//  SVAlbumDetailScrollViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 2/14/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NetworkPhotoAlbumViewController.h"
#import "SVEntityStore.h"

@class AlbumPhoto;
@interface SVPhotoViewerController : NetworkPhotoAlbumViewController <NIPhotoAlbumScrollViewDataSource, NIPhotoScrubberViewDataSource, NIOperationDelegate, UIActionSheetDelegate>

#pragma mark - Properties

@property (nonatomic, strong) NSArray *sortedPhotos;
@property (nonatomic, strong) AlbumPhoto *selectedPhoto;
@property (nonatomic) int index;

- (void)showImageAtIndex:(int)index;

@end
