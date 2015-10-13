//
//  CameraViewController.m
//  shotvibe
//
//  Created by Tsah Kashkash on 12/10/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import "CameraViewController.h"



@interface CameraViewController () {
    
    GLFilterView * defaultFilter;
    
    GLFilterView * saturationFilter;
    GLFilterView * contrastFilter;
    GLFilterView * brightnessFilter;
    GLFilterView * levelsFilter;
    GLFilterView * exposureFilter;
    GLFilterView * rgbFilter;
    GLFilterView * whiteBalance;
    GLFilterView * sharpenFilter;
    GLFilterView * unsharpFilter;
    GLFilterView * gammaFilter;
    GLFilterView * hazeFilter;
    GLFilterView * sepiaFIlter;
    GLFilterView * amatorkaFilter;
    GLFilterView * missEtikateFilter;
    GLFilterView * softEleganceFilter;
    GLFilterView * grayScaleFilter;
    GLFilterView * polkaDotFIlter;
    GLFilterView * sketchFilter;
    GLFilterView * posterizeFilter;
    GLFilterView * embossFilter;
    GLFilterView * vignetteFilter;
    GLFilterView * selectiveBlurFilter;
    GLFilterView * toonFilter;
    
    GPUImageStillCamera *stillCamera;
    GPUImageOutput<GPUImageInput> *filter;
    UISlider *filterSettingsSlider;
    UIButton *photoCaptureButton;
    
    NSMutableArray * arrayOfFilters;
    
    ScrollDirection scrollDirection;
    
    CGFloat lastContentOffset;
    CGFloat screenWidth;
    
    int currentFilterIndex;
    
    
}

@end

@implementation CameraViewController

-(void)dealloc {
    NSString * className = NSStringFromClass([self class]);
    NSLog(@"%@ Deallocated",className);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    screenWidth = screenRect.size.width;
//    CGFloat filterViewHeight = screenRect.size.width;
    
    arrayOfFilters = [[NSMutableArray alloc] init];
    
    stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetInputPriority cameraPosition:AVCaptureDevicePositionBack];
    stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
//    filter = [[GPUImageSketchFilter alloc] init];
//    [stillCamera addTarget:filter];

//    [filter addTarget:self.cameraOutPutView];

    

//    self.cameraOutPutView.alpha = 0;
    
    
    self.mainScrollView.tag = ScrollerTypeFilterScroller;
    self.mainScrollView.delegate = self;
    self.mainScrollView.pagingEnabled = YES;
    
    [self createFiltersViews];
    
    NSInteger numberOfViews = [arrayOfFilters count];
    for (int i = 0; i < numberOfViews; i++) {
        CGFloat yOrigin = i * screenWidth;
        GLFilterView * tempFilt = [arrayOfFilters objectAtIndex:i];
        [tempFilt.container setFrame:CGRectMake(0, yOrigin, screenWidth, screenWidth)];
        tempFilt.container.backgroundColor = [UIColor blackColor];
        
        [self.mainScrollView addSubview:tempFilt.container];
        
    }
    self.mainScrollView.contentSize = CGSizeMake(screenWidth, (screenWidth* numberOfViews)-20);
    
    // Do any additional setup after loading the view from its nib.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
//    [UIView animateWithDuration:0.25 animations:^{
//        self.cameraOutPutView.alpha = 1;
        [stillCamera startCameraCapture];
//    } completion:^(BOOL done){
//        
//    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)createFiltersViews {
    
    
    
    defaultFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_NOFILTER];
    [stillCamera addTarget:defaultFilter.filter];
    [arrayOfFilters addObject:defaultFilter];
    
    contrastFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_CONTRAST];
    [stillCamera addTarget:contrastFilter.filter];
    [arrayOfFilters addObject:contrastFilter];
    
    brightnessFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_BRIGHTNESS];
    [stillCamera addTarget:brightnessFilter.filter];
    [arrayOfFilters addObject:brightnessFilter];
    
    levelsFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_LEVELS];
    //    [self.videoCamera addTarget:levelsFilter.filter];
    [arrayOfFilters addObject:levelsFilter];
    
    exposureFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_EXPOSURE];
    //    [self.videoCamera addTarget:exposureFilter.filter];
    [arrayOfFilters addObject:exposureFilter];
    
    saturationFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_SATURATION];
    //    [self.videoCamera addTarget:saturationFilter.filter];
    [arrayOfFilters addObject:saturationFilter];
    
    sharpenFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_SHARPEN];
    //    [self.videoCamera addTarget:sharpenFilter.filter];
    [arrayOfFilters addObject:sharpenFilter];
    
    gammaFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_GAMMA];
    //    [self.videoCamera addTarget:gammaFilter.filter];
    [arrayOfFilters addObject:gammaFilter];
    
    hazeFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_HAZE];
    //    [self.videoCamera addTarget:hazeFilter.filter];
    [arrayOfFilters addObject:hazeFilter];
    
    sepiaFIlter = [[GLFilterView alloc] initWithType:GPUIMAGE_SEPIA];
    //    [self.videoCamera addTarget:sepiaFIlter.filter];
    [arrayOfFilters addObject:sepiaFIlter];
    
    amatorkaFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_AMATORKA];
    //    [self.videoCamera addTarget:amatorkaFilter.filter];
    [arrayOfFilters addObject:amatorkaFilter];
    
    missEtikateFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_MISSETIKATE];
    //    [self.videoCamera addTarget:missEtikateFilter.filter];
    [arrayOfFilters addObject:missEtikateFilter];
    
    softEleganceFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_SOFTELEGANCE];
    //    [self.videoCamera addTarget:softEleganceFilter.filter];
    [arrayOfFilters addObject:softEleganceFilter];
    
    grayScaleFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_GRAYSCALE];
    //    [self.videoCamera addTarget:grayScaleFilter.filter];
    [arrayOfFilters addObject:grayScaleFilter];
    
    sketchFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_SKETCH];
    //    [self.videoCamera addTarget:sketchFilter.filter];
    [arrayOfFilters addObject:sketchFilter];
    
    embossFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_EMBOSS];
    //    [self.videoCamera addTarget:embossFilter.filter];
    [arrayOfFilters addObject:embossFilter];
    
    vignetteFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_VIGNETTE];
    //    [self.videoCamera addTarget:vignetteFilter.filter];
    [arrayOfFilters addObject:vignetteFilter];
    
    selectiveBlurFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_GAUSSIAN_SELECTIVE];
    //    [self.videoCamera addTarget:selectiveBlurFilter.filter];
    [arrayOfFilters addObject:selectiveBlurFilter];
    
    toonFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_TOON];
    //    [self.videoCamera addTarget:toonFilter.filter];
    [arrayOfFilters addObject:toonFilter];
    
    
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    
    if (lastContentOffset > scrollView.contentOffset.y)
        scrollDirection = ScrollDirectionUp;
    else if (lastContentOffset < scrollView.contentOffset.y)
        scrollDirection = ScrollDirectionDown;
    
    lastContentOffset = scrollView.contentOffset.y;
    
    
    
    if(scrollView.tag == ScrollerTypeFontsScroller){
        
    }
    
    
    if(scrollView.tag == ScrollerTypeFilterScroller){
        
        
        
        CGFloat offsetY = scrollView.contentOffset.y;
        
        
        
        [defaultFilter.container setContentOffset:CGPointMake(0, -offsetY)];
        defaultFilter.sliderView.frame = CGRectMake(0, -offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [contrastFilter.container setContentOffset:CGPointMake(0, (contrastFilter.container.frame.size.height)-offsetY)];
        contrastFilter.sliderView.frame = CGRectMake(0, (contrastFilter.container.frame.size.height)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [brightnessFilter.container setContentOffset:CGPointMake(0, (brightnessFilter.container.frame.size.height*2) -offsetY)];
        brightnessFilter.sliderView.frame = CGRectMake(0, (brightnessFilter.container.frame.size.height*2)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [levelsFilter.container setContentOffset:CGPointMake(0, (levelsFilter.container.frame.size.height*3)-offsetY)];
        levelsFilter.sliderView.frame = CGRectMake(0, (levelsFilter.container.frame.size.height*3)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [exposureFilter.container setContentOffset:CGPointMake(0, (exposureFilter.container.frame.size.height*4)-offsetY)];
        exposureFilter.sliderView.frame = CGRectMake(0, (exposureFilter.container.frame.size.height*4)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [saturationFilter.container setContentOffset:CGPointMake(0, (saturationFilter.container.frame.size.height*5)-offsetY)];
        saturationFilter.sliderView.frame = CGRectMake(0, (saturationFilter.container.frame.size.height*5)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [sharpenFilter.container setContentOffset:CGPointMake(0, (sharpenFilter.container.frame.size.height*6)-offsetY)];
        sharpenFilter.sliderView.frame = CGRectMake(0, (sharpenFilter.container.frame.size.height*6)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        
        [gammaFilter.container setContentOffset:CGPointMake(0, (gammaFilter.container.frame.size.height*7)-offsetY)];
        gammaFilter.sliderView.frame = CGRectMake(0, (gammaFilter.container.frame.size.height*7)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [hazeFilter.container setContentOffset:CGPointMake(0, (hazeFilter.container.frame.size.height*8)-offsetY)];
        hazeFilter.sliderView.frame = CGRectMake(0, (hazeFilter.container.frame.size.height*8)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [sepiaFIlter.container setContentOffset:CGPointMake(0, (sepiaFIlter.container.frame.size.height*9)-offsetY)];
        sepiaFIlter.sliderView.frame = CGRectMake(0, (sepiaFIlter.container.frame.size.height*9)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [amatorkaFilter.container setContentOffset:CGPointMake(0, (amatorkaFilter.container.frame.size.height*10)-offsetY)];
        amatorkaFilter.sliderView.frame = CGRectMake(0, (amatorkaFilter.container.frame.size.height*10)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [missEtikateFilter.container setContentOffset:CGPointMake(0, (missEtikateFilter.container.frame.size.height*11)-offsetY)];
        missEtikateFilter.sliderView.frame = CGRectMake(0, (missEtikateFilter.container.frame.size.height*11)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [softEleganceFilter.container setContentOffset:CGPointMake(0, (softEleganceFilter.container.frame.size.height*12)-offsetY)];
        softEleganceFilter.sliderView.frame = CGRectMake(0, (softEleganceFilter.container.frame.size.height*12)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [grayScaleFilter.container setContentOffset:CGPointMake(0, (grayScaleFilter.container.frame.size.height*13)-offsetY)];
        grayScaleFilter.sliderView.frame = CGRectMake(0, (grayScaleFilter.container.frame.size.height*13)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        
        [sketchFilter.container setContentOffset:CGPointMake(0, (sketchFilter.container.frame.size.height*14)-offsetY)];
        sketchFilter.sliderView.frame = CGRectMake(0, (sketchFilter.container.frame.size.height*14)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        
        [embossFilter.container setContentOffset:CGPointMake(0, (embossFilter.container.frame.size.height*15)-offsetY)];
        embossFilter.sliderView.frame = CGRectMake(0, (embossFilter.container.frame.size.height*15)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [vignetteFilter.container setContentOffset:CGPointMake(0, (vignetteFilter.container.frame.size.height*16)-offsetY)];
        vignetteFilter.sliderView.frame = CGRectMake(0, (vignetteFilter.container.frame.size.height*16)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [selectiveBlurFilter.container setContentOffset:CGPointMake(0, (selectiveBlurFilter.container.frame.size.height*17)-offsetY)];
        selectiveBlurFilter.sliderView.frame = CGRectMake(0, (selectiveBlurFilter.container.frame.size.height*17)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [toonFilter.container setContentOffset:CGPointMake(0, (toonFilter.container.frame.size.height*18)-offsetY)];
        toonFilter.sliderView.frame = CGRectMake(0, (toonFilter.container.frame.size.height*18)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        
    }
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    int page = scrollView.contentOffset.y / scrollView.frame.size.height;
    
    if(scrollView.tag == ScrollerTypeFontsScroller){
        
    }
    
    
    if(scrollView.tag == ScrollerTypeFilterScroller){
        currentFilterIndex = page;
    }
    
    //    NSLog(@"%d",page);
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    
    
    
    int page = scrollView.contentOffset.y / scrollView.frame.size.height;
    //    currentFilterIndex = page+1;
    
    //    NSLog(@"%d",page);\
    
    
    if(scrollView.tag == ScrollerTypeFontsScroller){
        
    }
    
    
    if(scrollView.tag == ScrollerTypeFilterScroller){
        
        if(scrollDirection == ScrollDirectionDown){
            
            if(page >= 2){
                GLFilterView * prevFilter = [arrayOfFilters objectAtIndex:page-2];
                if(prevFilter.filterType != GPUIMAGE_NOFILTER){
                    [stillCamera removeTarget:prevFilter.filter];
                }
            }
            
            if(page < [arrayOfFilters count]-2){
                GLFilterView * nextFilter = [arrayOfFilters objectAtIndex:page+2];
                if(nextFilter.filterType != GPUIMAGE_NOFILTER){
                    [stillCamera addTarget:nextFilter.filter];
                }
            }
            
            
        } else if(scrollDirection == ScrollDirectionUp){
            
            if(page >= 2){
                GLFilterView * prevFilter = [arrayOfFilters objectAtIndex:page-2];
                if(prevFilter.filterType != GPUIMAGE_NOFILTER){
                    [stillCamera addTarget:prevFilter.filter];
                }
            }
            
            if(page < [arrayOfFilters count]-2){
                
                GLFilterView * nextFilter = [arrayOfFilters objectAtIndex:page+2];
                if(nextFilter.filterType != GPUIMAGE_NOFILTER){
                    [stillCamera removeTarget:nextFilter.filter];
                }
                
            }
            
        }
    }
    
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/



- (IBAction)captureTapped:(id)sender {
    
//    CGRect screenRect = [[UIScreen mainScreen] bounds];
//    CGFloat screenWidth = screenRect.size.width;
//    CGFloat screenHeight = screenRect.size.height;
//    UIImage * image = nil;

    [stillCamera capturePhotoAsJPEGProcessedUpToFilter:[[arrayOfFilters objectAtIndex:0] filter] withCompletionHandler:^(NSData *processedJPEG, NSError *error){
        [stillCamera stopCameraCapture];
        UIImage * image = [UIImage imageWithData:processedJPEG];
        image = [self imageCroppedToFitSize:CGSizeMake(screenWidth, screenWidth) image:image];
        for(GLFilterView * filterView in arrayOfFilters){
            [filterView setImageCapturedUnderFilter:image];
        }
        [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
    }];

    
}
- (IBAction)exitPressed:(id)sender {
//    [stillCamera resumeCameraCapture];
//    [stillCamera stopCameraCapture];
//    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (UIImage *)imageToFitSize:(CGSize)fitSize method:(MGImageResizingMethod)resizeMethod image:(UIImage*) imageToResize
{
    float imageScaleFactor = 1.0;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
    if ([self respondsToSelector:@selector(scale)]) {
        imageScaleFactor = [imageToResize scale];
    }
#endif
    
    float sourceWidth = [imageToResize size].width * imageScaleFactor;
    float sourceHeight = [imageToResize size].height * imageScaleFactor;
    float targetWidth = fitSize.width;
    float targetHeight = fitSize.height;
    BOOL cropping = !(resizeMethod == MGImageResizeScale);
    
    // Calculate aspect ratios
    float sourceRatio = sourceWidth / sourceHeight;
    float targetRatio = targetWidth / targetHeight;
    
    // Determine what side of the source image to use for proportional scaling
    BOOL scaleWidth = (sourceRatio <= targetRatio);
    // Deal with the case of just scaling proportionally to fit, without cropping
    scaleWidth = (cropping) ? scaleWidth : !scaleWidth;
    
    // Proportionally scale source image
    float scalingFactor, scaledWidth, scaledHeight;
    if (scaleWidth) {
        scalingFactor = 1.0 / sourceRatio;
        scaledWidth = targetWidth;
        scaledHeight = round(targetWidth * scalingFactor);
    } else {
        scalingFactor = sourceRatio;
        scaledWidth = round(targetHeight * scalingFactor);
        scaledHeight = targetHeight;
    }
    float scaleFactor = scaledHeight / sourceHeight;
    
    // Calculate compositing rectangles
    CGRect sourceRect, destRect;
    if (cropping) {
        destRect = CGRectMake(0, 0, targetWidth, targetHeight);
        float destX, destY;
        if (resizeMethod == MGImageResizeCrop) {
            // Crop center
            destX = round((scaledWidth - targetWidth) / 2.0);
            destY = round((scaledHeight - targetHeight) / 2.0);
        } else if (resizeMethod == MGImageResizeCropStart) {
            // Crop top or left (prefer top)
            if (scaleWidth) {
                // Crop top
                destX = 0.0;
                destY = 0.0;
            } else {
                // Crop left
                destX = 0.0;
                destY = round((scaledHeight - targetHeight) / 2.0);
            }
        } else if (resizeMethod == MGImageResizeCropEnd) {
            // Crop bottom or right
            if (scaleWidth) {
                // Crop bottom
                destX = round((scaledWidth - targetWidth) / 2.0);
                destY = round(scaledHeight - targetHeight);
            } else {
                // Crop right
                destX = round(scaledWidth - targetWidth);
                destY = round((scaledHeight - targetHeight) / 2.0);
            }
        }
        sourceRect = CGRectMake(destX / scaleFactor, destY / scaleFactor,
                                targetWidth / scaleFactor, targetHeight / scaleFactor);
    } else {
        sourceRect = CGRectMake(0, 0, sourceWidth, sourceHeight);
        destRect = CGRectMake(0, 0, scaledWidth, scaledHeight);
    }
    
    // Create appropriately modified image.
    UIImage *image = nil;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 4.0) {
        UIGraphicsBeginImageContextWithOptions(destRect.size, NO, 0.0); // 0.0 for scale means "correct scale for device's main screen".
        CGImageRef sourceImg = CGImageCreateWithImageInRect([imageToResize CGImage], sourceRect); // cropping happens here.
        image = [UIImage imageWithCGImage:sourceImg scale:0.0 orientation:imageToResize.imageOrientation]; // create cropped UIImage.
        [image drawInRect:destRect]; // the actual scaling happens here, and orientation is taken care of automatically.
        CGImageRelease(sourceImg);
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
#endif
    if (!image) {
        // Try older method.
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL, fitSize.width, fitSize.height, 8, (fitSize.width * 4),
                                                     colorSpace, kCGImageAlphaPremultipliedLast);
        CGImageRef sourceImg = CGImageCreateWithImageInRect([imageToResize CGImage], sourceRect);
        CGContextDrawImage(context, destRect, sourceImg);
        CGImageRelease(sourceImg);
        CGImageRef finalImage = CGBitmapContextCreateImage(context);
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
        image = [UIImage imageWithCGImage:finalImage];
        CGImageRelease(finalImage);
    }
    
    return image;
}


- (UIImage *)imageCroppedToFitSize:(CGSize)fitSize image:(UIImage*)image
{
    return [self imageToFitSize:fitSize method:MGImageResizeCrop image:image];
}


- (UIImage *)imageScaledToFitSize:(CGSize)fitSize image:(UIImage*)image
{
    return [self imageToFitSize:fitSize method:MGImageResizeScale image:image];
}

@end
