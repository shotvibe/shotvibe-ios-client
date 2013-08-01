//
//  CaptureViewfinderController.h
//  sartorii
//
//  Created by John Gabelmann on 4/23/12.
//  Copyright (c) 2012 Reticent Media. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <IMageIO/CGImageProperties.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreFoundation/CoreFoundation.h>
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "Album.h"

@class AVCamCaptureManager, AVCamPreviewView, AVCaptureVideoPreviewLayer;

@protocol CaptureViewfinderDelegate <NSObject>

@required
- (void)cameraWasDismissedWithAlbum:(Album*)selectedAlbum;
@optional
- (void)didSelectPhoto:(UIImage *)thePhoto;

@end

@interface CaptureViewfinderController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate>


#pragma mark - Properties

@property (nonatomic, strong) AVCamCaptureManager *captureManager;
@property (nonatomic, weak) IBOutlet UIView *videoPreviewView;
@property (nonatomic, weak) IBOutlet UIImageView *vignetteView;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic, weak) IBOutlet UIButton *cameraToggleButton;
@property (nonatomic, weak) IBOutlet UIButton *stillButton;
@property (nonatomic, weak) IBOutlet UIButton *flashButtonAuto;
@property (nonatomic, weak) IBOutlet UIButton *flashButtonOn;
@property (nonatomic, weak) IBOutlet UIButton *flashButtonOff;
@property (nonatomic, strong) NSArray *albums;
@property (nonatomic, strong) Album *selectedAlbum;

@property (nonatomic) id <CaptureViewfinderDelegate> delegate;
@property (nonatomic) BOOL isFinishedSelectingPhotoEarly;

#pragma mark - Actions

- (IBAction)toggleCamera:(id)sender;
- (IBAction)captureStillImage:(id)sender;
- (IBAction)exitButtonPressed:(id)sender;
- (IBAction)pickFromLibraryButtonPressed:(id)sender;
- (IBAction)changeFlashModeButtonPressed:(id)sender;

@end
