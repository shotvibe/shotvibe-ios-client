//
//  SVAlbumGridViewController.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/13/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVCameraPickerDelegate.h"
#import "SL/AlbumManager.h"

typedef enum {
	SortFeedAlike=0,
	SortByUser,
	SortByDate
}SortType;


@interface SVAlbumGridViewController : UIViewController <SLAlbumManager_AlbumContentsListener, SVCameraPickerDelegate, UIAlertViewDelegate>

#pragma mark - Properties

@property (nonatomic, assign) int64_t albumId;
@property (nonatomic, assign) BOOL scrollToBottom;
@property (nonatomic, assign) BOOL scrollToTop;

@end
