//
//  CameraViewController.h
//  shotvibe
//
//  Created by Tsah Kashkash on 12/10/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
//#import <Foundation/Foundation.h>
//#import <UIKit/UIKit.h>
#import <GPUImage/GPUImage.h>
#import "GLFilterView.h"
#import "iCarousel.h"
//#import "UIImage+ProportionalFill.h"
//#import "UIImage+Tint.h"

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

typedef enum ScrollerType {
    ScrollerTypeFilterScroller,
    ScrollerTypeRecentsPhotosScroller,
    ScrollerTypeFontsScroller,
    ScrollerTypeColorsScroller
} ScrollerType;

@protocol CameraViewControllerDelegate <NSObject>

- (void)imageSelected:(UIImage*)image;

@end

@interface CameraViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, GLFilterViewDelegate>



//@property (weak, nonatomic) IBOutlet GPUImageView *cameraOutPutView;
@property (weak, nonatomic) IBOutlet UIScrollView *mainScrollView;
@property (weak, nonatomic) IBOutlet iCarousel *carousel;
@property (nonatomic, assign) id<CameraViewControllerDelegate> delegate;

- (IBAction)exitPressed:(id)sender;
- (IBAction)captureTapped:(id)sender;

@end
