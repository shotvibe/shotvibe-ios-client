//
//  SVCameraPickerController.h
//  shotvibe
//
//  Created by Baluta Cristian on 22/08/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Album.h"
#import "CaptureSelectImagesViewController.h"
#import "SVCameraPickerDelegate.h"

@interface SVCameraPickerController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
	
	BOOL isShowingLandscapeView;
	NSMutableArray *selectedPhotos;
}

@property (nonatomic, strong) NSArray *albums;
@property (nonatomic) NSMutableArray *capturedImages;
@property (nonatomic, strong) Album *selectedAlbum;
@property (nonatomic, strong) id <SVCameraPickerDelegate> delegate;

@property (nonatomic, strong) IBOutlet UIView *topBarContainer;
@property (nonatomic, strong) IBOutlet UIScrollView *albumScrollView;
@property (nonatomic, strong) IBOutlet UIPageControl *albumPageControl;
@property (nonatomic, strong) IBOutlet UIImageView *albumPreviewImage;
@property (nonatomic, strong) IBOutlet UILabel *imagePileCounterLabel;

@property (nonatomic, weak) IBOutlet UIButton *butToggleCamera;
@property (nonatomic, weak) IBOutlet UIButton *butShutter;
@property (nonatomic, weak) IBOutlet UIButton *butFlash;
@property (nonatomic, weak) IBOutlet UIButton *butReady;
@property (nonatomic, weak) IBOutlet UIImageView *takeAnotherImage;
@property (nonatomic, weak) IBOutlet UISlider *sliderZoom;

@property (nonatomic) UIImagePickerController *imagePickerController;
@property (nonatomic) IBOutlet UIView *overlayView;

@property (nonatomic, strong) IBOutlet UICollectionView *gridView;

- (IBAction)toggleCamera:(id)sender;
- (IBAction)shooterPressed:(id)sender;
- (IBAction)exitButtonPressed:(id)sender;
- (IBAction)changeFlashModeButtonPressed:(id)sender;
- (IBAction)done:(id)sender;

@end
