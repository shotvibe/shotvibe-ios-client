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
//#import "MainCameraViewController.h"
#import "SVPictureConfirmViewController.h"
#import "GLSharedCamera.h"
//#import "CameraViewController.h"

typedef enum {
	SortFeedAlike=0,
	SortByUser,
	SortByDate
}SortType;


@protocol SVAlbumGridViewControllerDelegate <NSObject>

@optional
- (void)pickerDone:(UIImage*)image;
//- (void)openAppleImagePicker;

@end

@interface SVAlbumGridViewController : UIViewController <SLAlbumManager_AlbumContentsListener, SVCameraPickerDelegate, UIAlertViewDelegate,GLSharedCameraDelegatte,UIImagePickerControllerDelegate,UINavigationControllerDelegate>//CameraViewControllerDelegate>

#pragma mark - Properties

@property (nonatomic, assign) id<SVAlbumGridViewControllerDelegate> delegate;

@property (nonatomic, assign) int64_t albumId;
@property (nonatomic, assign) BOOL scrollToBottom;
@property (nonatomic, assign) BOOL scrollToTop;
@property (nonatomic,retain) SVPictureConfirmViewController * container;

@end
