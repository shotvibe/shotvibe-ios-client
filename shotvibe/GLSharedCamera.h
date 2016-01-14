//
//  GLSharedCamera.h
//  shotvibe
//
//  Created by Tsah Kashkash on 15/10/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "iCarousel.h"
#import "RJTextView.h"
#include <AssetsLibrary/AssetsLibrary.h>
#import "GLResizeableView.h"
#import "GLFilterView.h"
#import <Photos/Photos.h>
#import "JTSlideShadowAnimation.h"
#import "GLUserScore.h"
#import "PECropViewController.h"

typedef enum {
    MGImageResizeCrop,	// analogous to UIViewContentModeScaleAspectFill, i.e. "best fit" with no space around.
    MGImageResizeCropStart,
    MGImageResizeCropEnd,
    MGImageResizeScale	// analogous to UIViewContentModeScaleAspectFit, i.e. scale down to fit, leaving space around if necessary.
} MGImageResizingMethod;

typedef enum ImageSource {
    ImageSourceNone,
    ImageSourceCamera,
    ImageSourceRecents,
    ImageSourceGallery
} ImageSource;

typedef enum ScrollDirection {
    ScrollDirectionNone,
    ScrollDirectionRight,
    ScrollDirectionLeft,
    ScrollDirectionUp,
    ScrollDirectionDown,
    ScrollDirectionCrazy,
} ScrollDirection;

@protocol GLSharedCameraDelegatte <NSObject>

@optional
- (void)videoSelected;
- (void)imageSelected:(UIImage*)image;
- (void)openAppleImagePicker;
- (void)backPressed;
- (void)membersPressed;

@end

@interface GLSharedCamera : NSObject <UITextFieldDelegate,iCarouselDataSource, iCarouselDelegate,UIScrollViewDelegate,UIGestureRecognizerDelegate, UIImagePickerControllerDelegate, RJTextViewDelegate,GLResizeableViewDelegate,GLFilterViewDelegate, UINavigationControllerDelegate,PECropViewControllerDelegate>

+ (GLSharedCamera *)sharedInstance;
- (UIImage *) imageWithView:(UIView *)view;
- (UIImage *) imageWithText:(UIView *)view;
- (UIImage *) resizeLabelImage:(UIImage*)image location:(CGPoint)location;
- (UIImage *)imageByCroppingImage:(UIImage *)image toSize:(CGSize)size;
- (void)retrievePhotoFromPicker:(UIImage*)image;
- (void)retrievePhotoFromLoginPicker:(UIImage *)image;
- (void)hideForPicker:(BOOL)no;
- (void) backToCameraFromEditPallette:(id)sender;
- (void)setInFeedMode:(BOOL)feed dmutNeedTransform:(BOOL)needTransform;
- (void)createMainScrollView;
- (void)showCamera;
- (void)setCameraIsBackView:(BOOL)isBackView;
- (void)hideCamera;
- (void) playCaptureSound;
- (void)toggleFlash;
- (void)hideGlCameraView;
- (void)showGlCameraView;
- (void)approveTextTapped;
- (void)setCameraInFeed;
- (void)setCameraInMain;
- (void)resetCameraAfterUploadingFromMain;
- (void)setCameraInFeedAfterGroupOpenedWithoutImage;
- (void)closeCameraViewWithSlideFromFeed;
- (void)closeCameraViewWithSlideFromMain;
- (void)flipCamera;
- (void)captureTapped;
- (void)finalProcessTapped;
- (void)fixAfterLogin;
- (void)resetCameraAfterBack;

@property (nonatomic) BOOL flashIsOn;
@property (nonatomic) BOOL inEditMode;
@property (nonatomic) BOOL isInFeedMode;
@property (nonatomic) BOOL afterLogin;
@property (nonatomic) BOOL cameraIsShown;
@property (nonatomic) BOOL captureStoppedByTimer;
@property (nonatomic) BOOL goneUploadAmovie;

@property (nonatomic, retain) NSTimer * videoCaptureTimer;
@property (nonatomic, strong) AVAudioPlayer *theAudio;
@property (nonatomic, retain) MPMoviePlayerController * previewPlayer;

@property (nonatomic, assign) CGFloat lastContentOffset;

@property (nonatomic, retain) UIView * view;
@property (nonatomic, strong) UIView * editPallette;
@property (nonatomic, strong) UIView * cameraViewBackground;
@property (nonatomic, retain) UIView * captureTimeLineWrapper;

@property (nonatomic, strong) UILabel * picYourGroup;
@property (nonatomic, strong) UILabel * score;

@property (nonatomic, retain) UIImage * imageForOutSideUpload;

@property (nonatomic, strong) UIButton *animatedView;
@property (nonatomic, retain) UIButton * backButton;
@property (nonatomic, retain) UIButton * membersButton;
@property (nonatomic, retain) UIButton * videoPreviewCloseButton;

@property (nonatomic, strong) UIImageView * editPalletteImageView;
@property (nonatomic, retain) UIImageView * dmut;

@property (nonatomic, retain) NSString * videoToUploadPath;

@property (nonatomic, retain) NSArray * colorArray;

@property (nonatomic, strong) NSMutableArray * arrayOfFilters;
@property (nonatomic, strong) NSMutableArray * latestImagesArray;
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, strong) NSMutableArray * colorViewsArray;

@property (nonatomic, strong) UIScrollView * mainScrollView;
@property (nonatomic, strong) UIScrollView * recentPhotosSlider;
@property (nonatomic, retain) UIScrollView * colors;

@property (nonatomic, retain) GLUserScore * userScore;

@property (nonatomic, assign) id<GLSharedCameraDelegatte> delegate;
@property (nonatomic, strong) GPUImageStillCamera * videoCamera;
@property (nonatomic, retain) GPUImageMovieWriter * movieWriter;
@property (nonatomic, strong) RJTextView *editTextViewObj;
@property (nonatomic, strong) IBOutlet iCarousel *carousel;
@property (nonatomic, retain) GLResizeableView * resizeAbleView;
@property (nonatomic, strong) JTSlideShadowAnimation *shadowAnimation;

@property (nonatomic, strong) PECropViewController * cropViewController;

@end