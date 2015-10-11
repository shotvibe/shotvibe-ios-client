//
//  MainCameraViewController.h
//  GlanceCamera
//
//  Created by Tsah Kashkash on 20/09/2015.
//  Copyright © 2015 Tsah Kashkash. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "GPUImage.h"
#import "GLCamera.h"
#import "iCarousel.h"
#import "RJTextView.h"
#include <AssetsLibrary/AssetsLibrary.h>
//#import "ResizeableView.h"
#import "GLResizeableView.h"
//@import Photos;
#import <Photos/Photos.h>


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

@protocol MainCameraViewControllerDelegate <NSObject>

- (void)imageSelected:(UIImage*)image;

@end




@interface MainCameraViewController : UIViewController <iCarouselDataSource, iCarouselDelegate,UIScrollViewDelegate,UIGestureRecognizerDelegate, UIImagePickerControllerDelegate, RJTextViewDelegate,GLResizeableViewDelegate>


- (void)viewIsResizing:(CGRect)bounds gesture:(UIPanGestureRecognizer*)gesture;
@property (nonatomic, assign) id<MainCameraViewControllerDelegate> delegate;
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

@property(nonatomic, strong) UIScrollView * recentPhotosSlider;

@property(nonatomic, retain) GLResizeableView * resizeAbleView;
//@pro
//@property (nonatomic, strong) NSMutableArray * finalScrollViewImagesArray;

@end
