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
    NSMutableArray * latestImagesArray;
    NSMutableArray *items;
    
    UIImage * imageToServe;
    
    PHFetchResult *fetchResult;
    
    ScrollDirection scrollDirection;
    
    CGFloat lastContentOffset;
    CGFloat screenWidth;
    
    int currentFilterIndex;
    int indexOfImageFromCarousel;
    int imageSource;
    
    
    
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
    imageSource = ImageSourceNone;
    imageToServe = [[UIImage alloc] init];
    arrayOfFilters = [[NSMutableArray alloc] init];
    latestImagesArray = [[NSMutableArray alloc] init];
    
    stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionBack];
    stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
//    filter = [[GPUImageSketchFilter alloc] init];
//    [stillCamera addTarget:filter];

//    [filter addTarget:self.cameraOutPutView];

    

//    self.cameraOutPutView.alpha = 0;
    
    
    self.mainScrollView.tag = ScrollerTypeFilterScroller;
//    self.mainScrollView.delegate = self;
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
    
    int recentsLimit = 15;
    
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.includeAllBurstAssets = NO;
    fetchOptions.includeHiddenAssets = NO;
    //    fetchOptions.fetchLimit
    //    fetchOptions.fetchLimit = 15;
    //    [fetchOptions setFetchLimit:15];
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    //    fetchOptions.fetchLimit = 15;
    fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];
    
    if([fetchResult count] < recentsLimit){
        recentsLimit = (int)[fetchResult count];
    }
    
    for(int r = 0; r < recentsLimit; r++){
        [latestImagesArray addObject:[fetchResult objectAtIndex:r]];
    }
    
    self.carousel.type = iCarouselTypeLinear;
    self.carousel.backgroundColor = [UIColor blackColor];
    [self.carousel reloadData];
    
    [stillCamera startCameraCapture];
    // Do any additional setup after loading the view from its nib.
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    
    stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionBack];
    stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    [self createFiltersViews];
    [stillCamera startCameraCapture];
//    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
//    stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionBack];
//    stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
//    
//    defaultFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_NOFILTER];
//    [stillCamera addTarget:defaultFilter.filter];
//    [stillCamera startCameraCapture];
//    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];


    
    

    
    
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
//     [stillCamera stopCameraCapture];
//    [stillCamera resumeCameraCapture];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
//    [UIView animateWithDuration:0.25 animations:^{
//        self.cameraOutPutView.alpha = 1;
    
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
    defaultFilter.delegate = self;
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


#pragma mark - iCarouselMethods

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index locationInView:(CGPoint)location {
    
    indexOfImageFromCarousel = (int)index;
    
    
    if(index == [latestImagesArray count]){ // Set the last item in carousel to a button which opens image picker.
        //        NSLog(@"test");
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
        [self presentViewController:picker animated:YES completion:^{
            [stillCamera pauseCameraCapture];
        }];
    } else {
        
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc]init];
        options.synchronous  = YES;
        options.resizeMode = PHImageRequestOptionsResizeModeExact;
        //        options.normalizedCropRect = CGRectMake(0, 0, 200, 200);
        options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;

        
        [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
        
        [stillCamera stopCameraCapture];
        
        [[PHImageManager defaultManager]requestImageForAsset:[latestImagesArray objectAtIndex:index] targetSize:CGSizeMake(1024, 1024) contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *result, NSDictionary *info){
            
            NSLog(@"");
            
            
            

            for(GLFilterView * filterView in arrayOfFilters){
                [filterView setImageCapturedUnderFilter:[self imageCroppedToFitSize:CGSizeMake(screenWidth, screenWidth) image:result]];
            }
            imageSource = ImageSourceRecents;
//            [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
            
            
            ////            [self sendImageToEdit:result];
            //            CGImageRef cgRef = result.CGImage;
//            UIImage * ttimage = [self normalizedImage:result];
//            
//            //            UIImage * croppedImage = ;
//            
//            
//            [self updateFiltersWithSelectedImage:[[GLCamera sharedInstance] imageByCroppingImage:ttimage toSize:CGSizeMake(ttimage.size.width, ttimage.size.width)]];
//            ttimage = nil;
//            imageSource = ImageSourceRecents;
            
            
            //            [[PHImageManager defaultManager] dealloc];
            //            UIImageView * thumbImage = [[UIImageView alloc] initWithImage:result];//
            //            thumbImage.frame = CGRectMake(98, self.view.frame.size.height-256, 180, 180);
            //
            //
            //
            //
            //            [self.view addSubview:thumbImage];
            //            NSLog(@"%f",self.carousel.contentOffset.width);
            //            [UIView animateWithDuration:0.25 animations:^{
            //                thumbImage.frame = CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.width);
            //            }];
            
        }];
    }
    
}

- (NSInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    //return the total number of items in the carousel
    return [latestImagesArray count]+1;
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    
    view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 180.0f, 180.0f)];
    //        ((UIImageView *)view).image = [UIImage imageNamed:@"page.png"];
    view.contentMode = UIViewContentModeScaleAspectFill;
    view.clipsToBounds = YES;
    
    if(index == [latestImagesArray count]){
        //        view.backgroundColor = [UIColor purpleColor];
        //        UIImage * i = [[UIImage alloc] ];
//        UIImage * image = [UIImage imageNamed:@"GiCon"];
//        UIImageView * iv = [[UIImageView alloc] initWithFrame:CGRectMake(45, 45, 90.0f, 90.0f)];
//        iv.image = image;
//        [view addSubview:iv];
        view.backgroundColor = [UIColor purpleColor];
        //        ((UIImageView *)view).image = image;
    } else {
        [[PHImageManager defaultManager]requestImageForAsset:[latestImagesArray objectAtIndex:index] targetSize:CGSizeMake(180.0f, 180.0f) contentMode:PHImageContentModeDefault options:nil resultHandler:^(UIImage *result, NSDictionary *info){
            ((UIImageView *)view).image = result;
            //            UIImageView * thumbImage = [[UIImageView alloc] initWithImage:result];//
            //            thumbImage.frame = CGRectMake(0, 0, 180, 180);
            //
            //            [view addSubview:thumbImage];
            
        }];
    }
    
    
    
    return view;
}

- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    if (option == iCarouselOptionSpacing)
    {
        return value * 1.1;
    }
    return value;
}

//-(void)image

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    
    
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
    for(GLFilterView * filterView in arrayOfFilters){
        [filterView setImageCapturedUnderFilter:[self imageCroppedToFitSize:CGSizeMake(screenWidth, screenWidth) image:chosenImage]];
    }
    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
    [picker dismissViewControllerAnimated:YES completion:NULL];
    imageSource = ImageSourceGallery;
    imageToServe = chosenImage;
    //
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

    imageSource = ImageSourceCamera;
    
    __block UIView * mask = [[UIView alloc] initWithFrame:CGRectMake(0, 20, screenWidth, screenWidth)];
    mask.backgroundColor = [UIColor blackColor];
    mask.alpha = 0;
    [self.view addSubview:mask];
    
    [UIView animateWithDuration:0.2 animations:^{
        mask.alpha = 1;
    }];
    
//    
//    [stillCamera pauseCameraCapture];
    [stillCamera capturePhotoAsImageProcessedUpToFilter:[[arrayOfFilters objectAtIndex:0] filter] withCompletionHandler:^(UIImage *processedImage, NSError *error) {
        

        
        [stillCamera pauseCameraCapture];
        
         imageToServe = [self imageCroppedToFitSize:CGSizeMake(512, 512) image:processedImage];
        
        
            for(GLFilterView * filterView in arrayOfFilters){
                            [filterView setImageCapturedUnderFilter:imageToServe];
                        }
            [stillCamera removeAllTargets];
            [stillCamera removeInputsAndOutputs];
        
             [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [UIView animateWithDuration:0.1 animations:^{
        
//                    }];
//    
//                });
                        dispatch_async(dispatch_get_main_queue(), ^{

        [UIView animateWithDuration:0.2 animations:^{
            mask.alpha = 0;
        }];
                            });
    }];

    
//    [[[arrayOfFilters objectAtIndex:currentFilterIndex] filter] useNextFrameForImageCapture];
//   
//    imageToServe = [[[arrayOfFilters objectAtIndex:currentFilterIndex] filter] imageFromCurrentFramebuffer];
//   
//    imageToServe = [self imageCroppedToFitSize:CGSizeMake(512, 512) image:imageToServe];
//    [stillCamera pauseCameraCapture];
//    
//    for(GLFilterView * filterView in arrayOfFilters){
//                    [filterView setImageCapturedUnderFilter:imageToServe];
//                }
//    [stillCamera removeAllTargets];
//    [stillCamera removeInputsAndOutputs];
//    
//     [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
     NSLog(@"");
//    [stillCamera capturePhotoAsJPEGProcessedUpToFilter:[[arrayOfFilters objectAtIndex:0] filter] withCompletionHandler:^(NSData *processedJPEG, NSError *error){
////        [stillCamera stopCameraCapture];
//        
//        
////        [[[arrayOfFilters objectAtIndex:currentFilterIndex] filter] removeAllTargets];
//        
//        imageToServe = [self imageCroppedToFitSize:CGSizeMake(1024, 1024) image:[UIImage imageWithData:processedJPEG]];
//
//        for(GLFilterView * filterView in arrayOfFilters){
//            [filterView setImageCapturedUnderFilter:[self imageCroppedToFitSize:CGSizeMake(screenWidth, screenWidth) image:[UIImage imageWithData:processedJPEG]]];
//        }
//        [stillCamera removeAllTargets];
//        [stillCamera removeInputsAndOutputs];
////
//        [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
////        [stillCamera pauseCameraCapture];
//        
//    }];
    
}

-(UIImage *)processImagedBeforeServing {
    
    return [[[arrayOfFilters objectAtIndex:currentFilterIndex] filter] imageByFilteringImage:imageToServe];

}

- (IBAction)exitPressed:(id)sender {

    [stillCamera stopCameraCapture];
    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
    
    for(GLFilterView * filterView in arrayOfFilters){
        
        [filterView backToCamera];
        [[filterView filter] removeAllTargets];
//        __strong filterView = nil;
//        [[filterView filter] remove];
//        [filterView setImageCapturedUnderFilter:nil];
    }
    stillCamera = nil;
    
//    [self dismissViewControllerAnimated:YES completion:nil];
    
    if(imageSource == ImageSourceCamera){
//
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [self saveFiles];
        
//        imageToServe = ;
        [self.delegate imageSelected:[self processImagedBeforeServing]];
        imageToServe = nil;
//        });
//
//        
//        
    }
//
//    if(imageSource == ImageSourceRecents){
//        
//        PHImageRequestOptions *options = [[PHImageRequestOptions alloc]init];
//        options.synchronous  = YES;
//        options.resizeMode = PHImageRequestOptionsResizeModeExact;
//        options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
//        
//        [[PHImageManager defaultManager]requestImageForAsset:[latestImagesArray objectAtIndex:indexOfImageFromCarousel] targetSize:CGSizeMake(1024, 1024) contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *image, NSDictionary *info){
//            
//            imageToServe = image;
//            [self saveFiles];
////            [self.delegate imageSelected:nil];
//            imageToServe = nil;
//        }];
//    }
//    
//    if(imageSource == ImageSourceGallery){
//        [self saveFiles];
////        [self.delegate imageSelected:nil];
//        imageToServe = nil;
////        imageToServe = nil;
//    }
//    
//    
//    
////    [self.delegate imageSelected:[self processImagedBeforeServing]];
////    ;
//    
//    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
//    [stillCamera stopCameraCapture];
//    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
//    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
//    [self dismissViewControllerAnimated:YES completion:^{
////        [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
////        [[NSNotificationCenter defaultCenter] postNotificationName:@"ImageIsReadyToUpload" object:self];
//    }];
    
    
}

//-(void)foc

-(void)saveFiles {

    // Take as many pictures as you want. Save the path and the thumb and the picture
     NSString *filePath = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/Library/Caches/Photo%i.jpg", 0]];
     NSString *thumbPath = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/Library/Caches/Photo%i_thumb.jpg", 0]];
    
    //    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // Save large image
    
    imageToServe = [self processImagedBeforeServing];
    
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    

        
        dispatch_async(queue, ^(void) {
            
            
             [UIImageJPEGRepresentation(imageToServe, 1.0) writeToFile:filePath atomically:NO];
            CGSize newSize = CGSizeMake(200, 200);
            float oldWidth = imageToServe.size.width;
            float scaleFactor = newSize.width / oldWidth;
            float newHeight = imageToServe.size.height * scaleFactor;
            float newWidth = oldWidth * scaleFactor;
            
            UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
            [imageToServe drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
            UIImage * thumbImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            // Save thumb image
            [UIImageJPEGRepresentation(thumbImage, 0.5) writeToFile:thumbPath atomically:YES];
           
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"FINISH to write image");
                
            });
            
        });
    
    
   

    

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
        } else {
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
