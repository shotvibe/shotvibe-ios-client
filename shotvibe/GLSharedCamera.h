//
//  GLSharedCamera.h
//  shotvibe
//
//  Created by Tsah Kashkash on 15/10/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>
//#import "GLCamera.h"
#import "iCarousel.h"
#import "RJTextView.h"
#include <AssetsLibrary/AssetsLibrary.h>
#import "GLResizeableView.h"
#import "GLFilterView.h"
#import <Photos/Photos.h>
//#import "JPSVolumeButtonHandler.h"


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
- (void)imageSelected:(UIImage*)image;
- (void)openAppleImagePicker;
- (void)backPressed;
- (void)membersPressed;

@end

@interface GLSharedCamera : NSObject <iCarouselDataSource, iCarouselDelegate,UIScrollViewDelegate,UIGestureRecognizerDelegate, UIImagePickerControllerDelegate, RJTextViewDelegate,GLResizeableViewDelegate,GLFilterViewDelegate, UINavigationControllerDelegate>

+ (GLSharedCamera *)sharedInstance;

-(void)showCamera;
-(void)hideCamera;
- (void) playCaptureSound;
- (UIImage *) imageWithView:(UIView *)view;
- (UIImage *) imageWithText:(UIView *)view;
- (UIImage *) resizeLabelImage:(UIImage*)image location:(CGPoint)location;
- (UIImage *)imageByCroppingImage:(UIImage *)image toSize:(CGSize)size;
- (void)toggleFlash;
-(void)setInFeedMode;
-(void)retrievePhotoFromPicker:(UIImage*)image;
-(void)hideForPicker:(BOOL)no;
-(void)hideGlCameraView;
-(void)showGlCameraView;

@property(nonatomic) BOOL flashIsOn;
@property(nonatomic) BOOL inEditMode;
@property(nonatomic,retain) UIView * view;
@property (nonatomic, assign) id<GLSharedCameraDelegatte> delegate;
@property(nonatomic, strong) GPUImageStillCamera * videoCamera;
@property(nonatomic, strong) NSMutableArray * arrayOfFilters;
@property(nonatomic, strong) UIScrollView * mainScrollView;
@property (nonatomic, assign) CGFloat lastContentOffset;
@property (nonatomic, strong) RJTextView *editTextViewObj;
@property (nonatomic, strong) IBOutlet iCarousel *carousel;
@property (nonatomic, strong) NSMutableArray * latestImagesArray;
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, strong) UIView * editPallette;
@property (nonatomic, strong) UIImageView * editPalletteImageView;

@property (nonatomic,strong) UIView * cameraViewBackground;

@property(nonatomic, strong) UIScrollView * recentPhotosSlider;

@property(nonatomic, retain) GLResizeableView * resizeAbleView;

@property(nonatomic) BOOL isInFeedMode;

@property(nonatomic, retain) UIButton * backButton;
@property(nonatomic, retain) UIButton * membersButton;

@end
