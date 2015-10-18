//
//  GLFilterView.m
//  GlanceCamera
//
//  Created by Tsah Kashkash on 20/09/2015.
//  Copyright © 2015 Tsah Kashkash. All rights reserved.
//



#import "GLFilterView.h"
//#import "GLCamera.h"





@implementation GLFilterView {
    CGPoint startLocation;
    float sineVolXY;
    float sinePitchXY;
    UIView * touchPointCircle;
   
}
//@synthesize filter,filterType;

-(void)dealloc {
    
    NSString *strClass = NSStringFromClass([self class]);
    NSLog(@"%@ deallocated",strClass);
    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
}

- (instancetype)initWithType:(GPUImageShowcaseFilterType)typeIs {
    
    self = [super init];
    if(self){
        
        NSString *strClass = NSStringFromClass([self class]);
        NSLog(@"%@ inited",strClass);
        
        self.filterType = typeIs;
        
        CGRect screenRect = kScreenBounds;
        CGFloat filterViewWidth = screenRect.size.width;
        CGFloat filterViewHeight = screenRect.size.width;
        
        self.title = [[UILabel alloc] initWithFrame:CGRectMake((filterViewWidth/2)-((filterViewWidth/2)/2), 0, filterViewWidth/2, filterViewWidth/6)];
        self.title.textAlignment = NSTextAlignmentCenter;
        [self setupFilterByType];
        
        //Setup Container
        self.container = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0,filterViewWidth , filterViewHeight)];
        self.container.bounces = NO;
        self.container.delegate = self;
        [self.container setContentSize:CGSizeMake(filterViewWidth, filterViewHeight)];
        
        //Setup Output View
        
        
        
        self.outputView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, filterViewWidth, filterViewHeight)];
        self.outputView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
        self.outputViewCasted = (GPUImageView*)self.outputView;
        [self.container addSubview:self.outputViewCasted];
        
        [self.filter addTarget:self.outputViewCasted];
        
        
//        self.outputViewAfterCapture = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, filterViewWidth, filterViewHeight)];
//        self.outputView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
//        [self.container addSubview:self.outputViewAfterCapture];
        
        
        self.sliderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];
//        self.sliderView.backgroundColor = [UIColor redColor];
        [self.container addSubview:self.sliderView];
        
        UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(sineXYPad:)];
            pan.delegate = self;
            [self.container addGestureRecognizer:pan];
        
        self.filterSettingsSlider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];
        self.filterSettingsSlider.continuous = YES;
        [self.filterSettingsSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        [self.filterSettingsSlider setHidden:YES];
        [self.container addSubview:self.filterSettingsSlider];
        
        
        
//        touchPointCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
//        
//        UIImage * image = [UIImage imageNamed:@"CameraFocusIcon"];
//        UIImageView * iv = [[UIImageView alloc] initWithFrame:touchPointCircle.frame];
//        iv.image = image;
//        [touchPointCircle addSubview:iv];
//        
//        
//        touchPointCircle.backgroundColor = [UIColor clearColor];
////        touchPointCircle.layer.cornerRadius = 30;
//        touchPointCircle.alpha = 0;
        
        UITapGestureRecognizer *focusGest = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(focusCameraToTOuchPoint:)];
        
        self.focusLayer = [[UIView alloc] initWithFrame:self.container.frame];
        self.focusLayer.backgroundColor = [UIColor clearColor];
        [self.focusLayer addGestureRecognizer:focusGest];
        
//        [self.focusLayer addSubview:touchPointCircle];
        [self.container addSubview:self.focusLayer];
        
        
//        self.title.text = @"test";
        self.title.font = [UIFont fontWithName:@"Helvetica-Light" size:24];
        self.title.textColor = [UIColor whiteColor];
        self.title.backgroundColor = [UIColor clearColor];
//        filterName.text = nsstringfrom;
        [self.container addSubview:self.title];
        
        
        
        
    }
    return  self;
}

-(void) backToCamera {

//    [self.filter removeAllTargets];
////    [self.filter removeTarget:self.sourcePicture];
//    
////    [self.sourcePicture removeOutputFramebuffer];
    [self.sourcePicture removeAllTargets];
//    self.sourcePicture = nil;
//    [self.outputViewCasted remove];
//    [self.outputView removea];
//    self.sourcePicture = nil;
//    [self.sourcePicture addTarget:self.filter];
    
//    self.
//    [self.filter removeAllTargets];

}

-(void) setImageCapturedUnderFilter:(UIImage*)cpaturedImaged {

    [UIView animateWithDuration:0.1 animations:^{
        self.outputViewCasted.alpha = 0;
    } completion:^(BOOL finished) {
    
        
        
//        [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
//        [self.filter removeAllTargets];
//
//        [self.sourcePicture processImage];
//        [self.sourcePicture removeAllTargets];
//        self.sourcePicture = nil;
    
    if(self.filterType == GPUIMAGE_AMATORKA){
        self.filter = [[GPUImageAmatorkaFilter alloc] init];
        self.sourcePicture = nil;
    }
    if(self.filterType == GPUIMAGE_MISSETIKATE){
        self.filter = [[GPUImageMissEtikateFilter alloc] init];
        self.sourcePicture = nil;
    }
    if(self.filterType == GPUIMAGE_SOFTELEGANCE){
        self.filter = [[GPUImageSoftEleganceFilter alloc] init];
        self.sourcePicture = nil;
    }
        
        self.sourcePicture = [[GPUImagePicture alloc] initWithImage:cpaturedImaged];
//        [self.sourcePicture processImage];
//        [self.filter forceProcessingAtSize:self.outputViewCasted.sizeInPixels]; // This is now needed to make the filter run at the smaller output size
        //
        //
        
        [self.sourcePicture addTarget:self.filter];
        [self.filter addTarget:self.outputViewCasted];
        [self.sourcePicture processImage];
        
        
//        [self.sourcePicture processImage];
    
    
    
//        [self.sourcePicture set];
        
        [UIView animateWithDuration:0.1 animations:^{
            self.outputViewCasted.alpha = 1;
        } completion:^(BOOL finished) {
//            [self.sourcePicture processImage];
        }];
    }];

    
    

    


}

-(void)focusCameraToTOuchPoint:(UITapGestureRecognizer*)tgr {
    [self.delegate focusCameraToPoint:tgr location:[tgr locationInView:self.focusLayer]];
}

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)panGestureRecognizer {
    CGPoint velocity = [panGestureRecognizer velocityInView:self.sliderView];
    return fabs(velocity.y) < fabs(velocity.x);
    
}

-(IBAction)sineXYPad:(UIPanGestureRecognizer *)trigger
{
    float sinepadHeight = trigger.view.bounds.size.height;
    float sinepadWidth = trigger.view.bounds.size.width;
    CGPoint location = [trigger locationInView:trigger.view];
    
    if ((location.y >= 0) && (location.y < sinepadHeight) && (location.x >= 0) && (location.x < sinepadWidth))
    {
         sinePitchXY = ((location.x) / sinepadWidth);
    }
//    NSLog(@"%f - %u",sineVolXY,self.filterType);
    self.filterSettingsSlider.value = sinePitchXY;
    [self.filterSettingsSlider sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)setupFilterByType {


    switch (self.filterType)
    {
            
        
        case GPUIMAGE_NOFILTER:
        {
            self.title.text = @"Default (NONE)";
            self.filterSettingsSlider.hidden = YES;
            
            [self.filterSettingsSlider setValue:1.0];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            
            self.filter = [[GPUImageSaturationFilter alloc] init];
        }; break;
            
        case GPUIMAGE_SATURATION:
        {
            self.title.text = @"Saturation";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:1.0];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            
            self.filter = [[GPUImageSaturationFilter alloc] init];
        }; break;
            
        case GPUIMAGE_CONTRAST:
        {
            self.title.text = @"Contrast";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:4.0];
            [self.filterSettingsSlider setValue:1.0];
            
            self.filter = [[GPUImageContrastFilter alloc] init];
        }; break;
        case GPUIMAGE_BRIGHTNESS:
        {
            self.title.text = @"Brightness";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-1.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.0];
            
            self.filter = [[GPUImageBrightnessFilter alloc] init];
        }; break;
        case GPUIMAGE_LEVELS:
        {
            self.title.text = @"Levels";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.0];
            
            self.filter = [[GPUImageLevelsFilter alloc] init];
        }; break;
        case GPUIMAGE_RGB:
        {
            self.title.text = @"RGB";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            [self.filterSettingsSlider setValue:1.0];
            
            self.filter = [[GPUImageRGBFilter alloc] init];
        }; break;
        case GPUIMAGE_EXPOSURE:
        {
            self.title.text = @"Exposure";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-4.0];
            [self.filterSettingsSlider setMaximumValue:4.0];
            [self.filterSettingsSlider setValue:0.0];
            
            self.filter = [[GPUImageExposureFilter alloc] init];
        }; break;
        case GPUIMAGE_WHITEBALANCE:
        {
            self.title.text = @"White Balance";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:2500.0];
            [self.filterSettingsSlider setMaximumValue:7500.0];
            [self.filterSettingsSlider setValue:5000.0];
            
            self.filter = [[GPUImageWhiteBalanceFilter alloc] init];
        }; break;
        case GPUIMAGE_GAMMA:
        {
            self.title.text = @"Gamma";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:3.0];
            [self.filterSettingsSlider setValue:1.0];
            
            self.filter = [[GPUImageGammaFilter alloc] init];
        }; break;
        case GPUIMAGE_HAZE:
        {
            self.title.text = @"Haze / UV";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-0.2];
            [self.filterSettingsSlider setMaximumValue:0.2];
            [self.filterSettingsSlider setValue:0.2];
            
            self.filter = [[GPUImageHazeFilter alloc] init];
        }; break;
        case GPUIMAGE_AMATORKA:
        {
            self.title.text = @"Amatorka (Lookup)";
            self.filterSettingsSlider.hidden = YES;
            
            self.filter = [[GPUImageAmatorkaFilter alloc] init];
        }; break;
        case GPUIMAGE_GAUSSIAN_SELECTIVE:
        {
            self.title.text = @"Selective Blur";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:.75f];
            [self.filterSettingsSlider setValue:40.0/320.0];
            
            self.filter = [[GPUImageGaussianSelectiveBlurFilter alloc] init];
            [(GPUImageGaussianSelectiveBlurFilter*)self.filter setExcludeCircleRadius:40.0/320.0];
        }; break;
        case GPUIMAGE_SEPIA:
        {
            self.title.text = @"Sepia Tone";
//            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:1.0];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            
            self.filter = [[GPUImageSepiaFilter alloc] init];
        }; break;
        case GPUIMAGE_POLKADOT:
        {
            self.title.text = @"Polka Dot";
//            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:0.05];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:0.3];
            
            self.filter = [[GPUImagePolkaDotFilter alloc] init];
        }; break;
        
        case GPUIMAGE_GRAYSCALE:
        {
            self.title.text = @"Grayscale";
//            self.filterSettingsSlider.hidden = YES;
            
            self.filter = [[GPUImageGrayscaleFilter alloc] init];
        }; break;
        case GPUIMAGE_SOFTELEGANCE:
        {
            self.title.text = @"Soft Elegance (Lookup)";
//            self.filterSettingsSlider.hidden = YES;
            
            self.filter = [[GPUImageSoftEleganceFilter alloc] init];
        }; break;
        case GPUIMAGE_MISSETIKATE:
        {
            self.title.text = @"Miss Etikate (Lookup)";
//            self.filterSettingsSlider.hidden = YES;
            
            self.filter = [[GPUImageMissEtikateFilter alloc] init];
        }; break;

            



        case GPUIMAGE_SHARPEN:
        {
            self.title.text = @"Sharpen";
//            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-1.0];
            [self.filterSettingsSlider setMaximumValue:4.0];
            [self.filterSettingsSlider setValue:0.0];
            
            self.filter = [[GPUImageSharpenFilter alloc] init];
        }; break;
        case GPUIMAGE_UNSHARPMASK:
        {
            self.title.text = @"Unsharp Mask";
//            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:5.0];
            [self.filterSettingsSlider setValue:1.0];
            
            self.filter = [[GPUImageUnsharpMaskFilter alloc] init];
            
            [(GPUImageUnsharpMaskFilter *)self.filter setIntensity:3.0];
        }; break;






        case GPUIMAGE_SKETCH:
        {
            self.title.text = @"Sketch";
//            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.25];
            
            self.filter = [[GPUImageSketchFilter alloc] init];
        }; break;

        case GPUIMAGE_TOON:
        {
            self.title.text = @"Toon";
//            self.filterSettingsSlider.hidden = YES;
            
            self.filter = [[GPUImageToonFilter alloc] init];
        }; break;

       

        
        case GPUIMAGE_EMBOSS:
        {
            self.title.text = @"Emboss";
//            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:5.0];
            [self.filterSettingsSlider setValue:1.0];
            
            self.filter = [[GPUImageEmbossFilter alloc] init];
        }; break;

        case GPUIMAGE_POSTERIZE:
        {
            self.title.text = @"Posterize";
//            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:1.0];
            [self.filterSettingsSlider setMaximumValue:20.0];
            [self.filterSettingsSlider setValue:10.0];
            
            self.filter = [[GPUImagePosterizeFilter alloc] init];
        }; break;





        case GPUIMAGE_VIGNETTE:
        {
            self.title.text = @"Vignette";
//            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.5];
            [self.filterSettingsSlider setMaximumValue:0.9];
            [self.filterSettingsSlider setValue:0.75];
            
            self.filter = [[GPUImageVignetteFilter alloc] init];
        }; break;

            
        default: self.filter = [[GPUImageSepiaFilter alloc] init]; break;
    }
    
    switch(self.filterType){
            
            
        case GPUIMAGE_NOFILTER: [(GPUImageSaturationFilter *)self.filter setSaturation:[self sliderValueMultiplier:0.0 max:2.0 value:0.6]]; break;
    
        case GPUIMAGE_SATURATION: [(GPUImageSaturationFilter *)self.filter setSaturation:[self sliderValueMultiplier:0.0 max:2.0 value:1]]; break;
            
        case GPUIMAGE_CONTRAST: [(GPUImageContrastFilter *)self.filter setContrast:[self sliderValueMultiplier:0.0 max:4.0 value:1]]; break;
            
//        case GPUIMAGE_BRIGHTNESS: [(GPUImageBrightnessFilter *)filter setBrightness:[self sliderValueMultiplier:-1 max:1 value:0]]; break;
            
        case GPUIMAGE_LEVELS: {
            float value = [self sliderValueMultiplier:0 max:1 value:0];
            [(GPUImageLevelsFilter *)self.filter setRedMin:value gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
            [(GPUImageLevelsFilter *)self.filter setGreenMin:value gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
            [(GPUImageLevelsFilter *)self.filter setBlueMin:value gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
        }; break;
            
        case GPUIMAGE_SEPIA: [(GPUImageSepiaFilter *)self.filter setIntensity:[self sliderValueMultiplier:0 max:1 value:1]]; break;
            
        case GPUIMAGE_EXPOSURE: [(GPUImageExposureFilter *)self.filter setExposure:[self sliderValueMultiplier:-4 max:4 value:-2]]; break;
            
        case GPUIMAGE_RGB: [(GPUImageRGBFilter *)self.filter setGreen:[self sliderValueMultiplier:0 max:2 value:1]]; break;
            
        case GPUIMAGE_WHITEBALANCE: [(GPUImageWhiteBalanceFilter *)self.filter setTemperature:[self sliderValueMultiplier:2500 max:7500 value:5000]]; break;
            
        case GPUIMAGE_SHARPEN: [(GPUImageSharpenFilter *)self.filter setSharpness:[self sliderValueMultiplier:-1 max:4 value:0]]; break;
            
        case GPUIMAGE_UNSHARPMASK: [(GPUImageUnsharpMaskFilter *)self.filter setIntensity:[self sliderValueMultiplier:0 max:5 value:1]]; break;
            
        case GPUIMAGE_GAMMA: [(GPUImageGammaFilter *)self.filter setGamma:[self sliderValueMultiplier:0 max:3 value:1]]; break;
            
        case GPUIMAGE_HAZE: [(GPUImageHazeFilter *)self.filter setDistance:[self sliderValueMultiplier:-0.2 max:0.2 value:0.2]]; break;
            
        case GPUIMAGE_GAUSSIAN_SELECTIVE: [(GPUImageGaussianSelectiveBlurFilter *)self.filter setExcludeCircleRadius:[self sliderValueMultiplier:0.0 max:.75f value:40.0/320.0]]; break;
            
        case GPUIMAGE_POLKADOT: [(GPUImagePolkaDotFilter *)self.filter setFractionalWidthOfAPixel:[self sliderValueMultiplier:0.0 max:0.3 value:0.05]]; break;
            
        case GPUIMAGE_POSTERIZE: [(GPUImagePosterizeFilter *)self.filter setColorLevels:round([self sliderValueMultiplier:1 max:20 value:10])]; break;
            
        case GPUIMAGE_SKETCH:
            [(GPUImageSketchFilter *)self.filter setEdgeStrength:[self sliderValueMultiplier:0 max:1 value:0.25]];
            break;
            
        case GPUIMAGE_EMBOSS: [(GPUImageEmbossFilter *)self.filter setIntensity:[self sliderValueMultiplier:0 max:5 value:1]]; break;
            
        case GPUIMAGE_VIGNETTE: [(GPUImageVignetteFilter *)self.filter setVignetteEnd:[self sliderValueMultiplier:0.5 max:0.9 value:0.75]]; break;
            default: break;
    }
    [self.sourcePicture processImage];

}

- (float)sliderValueMultiplier:(float)min max:(float)max value:(float)value {

    return (max-min) * value+min;
}

- (void)sliderValueChanged:(id)sender

{
    switch(self.filterType)
    {
        case GPUIMAGE_SATURATION: [(GPUImageSaturationFilter *)self.filter setSaturation:[self sliderValueMultiplier:0.0 max:2.0 value:[(UISlider *)sender value]]]; break;
            
        case GPUIMAGE_CONTRAST: [(GPUImageContrastFilter *)self.filter setContrast:[self sliderValueMultiplier:0.0 max:4.0 value:[(UISlider *)sender value]]]; break;
            
        case GPUIMAGE_BRIGHTNESS: [(GPUImageBrightnessFilter *)self.filter setBrightness:[self sliderValueMultiplier:-1 max:1 value:[(UISlider *)sender value]]]; break;
            
        case GPUIMAGE_LEVELS: {
            float value = [self sliderValueMultiplier:0 max:1 value:[(UISlider *)sender value]];
            [(GPUImageLevelsFilter *)self.filter setRedMin:value gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
            [(GPUImageLevelsFilter *)self.filter setGreenMin:value gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
            [(GPUImageLevelsFilter *)self.filter setBlueMin:value gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
        }; break;
            
        case GPUIMAGE_SEPIA: [(GPUImageSepiaFilter *)self.filter setIntensity:[self sliderValueMultiplier:0 max:1 value:[(UISlider *)sender value]]]; break;
            
        case GPUIMAGE_EXPOSURE: [(GPUImageExposureFilter *)self.filter setExposure:[self sliderValueMultiplier:-4 max:4 value:[(UISlider *)sender value]]]; break;
            
        case GPUIMAGE_RGB: [(GPUImageRGBFilter *)self.filter setGreen:[self sliderValueMultiplier:0 max:2 value:[(UISlider *)sender value]]]; break;
            
        case GPUIMAGE_WHITEBALANCE: [(GPUImageWhiteBalanceFilter *)self.filter setTemperature:[self sliderValueMultiplier:2500 max:7500 value:[(UISlider *)sender value]]]; break;
            
        case GPUIMAGE_SHARPEN: [(GPUImageSharpenFilter *)self.filter setSharpness:[self sliderValueMultiplier:-1 max:4 value:[(UISlider *)sender value]]]; break;
            
        case GPUIMAGE_UNSHARPMASK: [(GPUImageUnsharpMaskFilter *)self.filter setIntensity:[self sliderValueMultiplier:0 max:5 value:[(UISlider *)sender value]]]; break;
            
        case GPUIMAGE_GAMMA: [(GPUImageGammaFilter *)self.filter setGamma:[self sliderValueMultiplier:0 max:3 value:[(UISlider *)sender value]]]; break;
            
        case GPUIMAGE_HAZE: [(GPUImageHazeFilter *)self.filter setDistance:[self sliderValueMultiplier:-0.2 max:0.2 value:[(UISlider *)sender value]]]; break;
            
        case GPUIMAGE_GAUSSIAN_SELECTIVE: [(GPUImageGaussianSelectiveBlurFilter *)self.filter setExcludeCircleRadius:[self sliderValueMultiplier:0.0 max:.75f value:[(UISlider *)sender value]]]; break;
            
        case GPUIMAGE_POLKADOT: [(GPUImagePolkaDotFilter *)self.filter setFractionalWidthOfAPixel:[self sliderValueMultiplier:0.0 max:0.3 value:[(UISlider *)sender value]]]; break;
            
        case GPUIMAGE_POSTERIZE: [(GPUImagePosterizeFilter *)self.filter setColorLevels:round([self sliderValueMultiplier:1 max:20 value:[(UISlider *)sender value]])]; break;
            
        case GPUIMAGE_SKETCH:
            [(GPUImageSketchFilter *)self.filter setEdgeStrength:[self sliderValueMultiplier:0 max:1 value:[(UISlider *)sender value]]];
            break;
            
        case GPUIMAGE_EMBOSS: [(GPUImageEmbossFilter *)self.filter setIntensity:[self sliderValueMultiplier:0 max:5 value:[(UISlider *)sender value]]]; break;
            
        case GPUIMAGE_VIGNETTE: [(GPUImageVignetteFilter *)self.filter setVignetteEnd:[self sliderValueMultiplier:0.5 max:0.9 value:[(UISlider *)sender value]]]; break;
        default: break;
    }
    
    [self.sourcePicture processImage];
    
}


@end
