//
//  MainCameraViewController.m
//  GlanceCamera
//
//  Created by Tsah Kashkash on 20/09/2015.
//  Copyright © 2015 Tsah Kashkash. All rights reserved.
//

#import "MainCameraViewController.h"



@class MainCameraViewController;
@interface MainCameraViewController ()

@end



@implementation MainCameraViewController {
    int currentFilterIndex;
    UIButton *flipCameraButton;
    BOOL backCameraOn;
    
    UIButton * flashButton;
    BOOL flashIsOn;
    
    UIButton * captureButton;
    
    UIButton * finalProcessButton;
    
    UIButton * backToCameraButton;
    UIButton * addTextButton;
    UIButton * trashTextButton;
    UIButton * approveTextButton;

//    ScrollDirection scrollDirection;
    
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

//    ResizeableView * resizeableView;
    
    PHFetchResult *fetchResult;
    
    UIView * mainOutPutFrame;
    
    BOOL cameraIsBackView;
    
    
    int indexOfImageFromCarousel;
    
    BOOL isEditing;
    BOOL stateEdit;
    BOOL fromImagePicker;
    
    int imageSource;
    
    UIImage * imageFromPicker;
    UIImage * cleanImageFromCamera;
    
    UIView * touchPointCircle;
}




-(void)dealloc {
    
    NSString *strClass = NSStringFromClass([self class]);
//    NSLog(@"%@ deallocated",strClass);
    
//    [mainOutPutFrame removeFromSuperview];
//        [self.mainScrollView removeFromSuperview];
//        [self.resizeAbleView removeFromSuperview];
//        [self.editTextViewObj removeFromSuperview];
    
    

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.videoCamera stopCameraCapture];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if(!fromImagePicker){
//        self.videoCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionBack];
//        self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
//        [self createFiltersViews];
//        [self.videoCamera startCameraCapture];
    }

}



- (void)viewDidLoad {
    [super viewDidLoad];
    
//    NSString *strClass = NSStringFromClass([self class]);
//    NSLog(@"%@ inited",strClass);
//    
//    imageSource = ImageSourceNone;
//    isEditing = NO;
//    stateEdit = NO;
//    fromImagePicker = NO;
//    cameraIsBackView = YES;
//    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
//                                                                          action:@selector(dismissKeyboard)];
////    tap.numberOfTapsRequired = 1;
////    tap.cancelsTouchesInView = NO;
////    tap.delegate = self;
//    [self.view addGestureRecognizer:tap];
//    
//    CGRect screenRect = kScreenBounds;
//    CGFloat screenWidth = screenRect.size.width;
//    CGFloat screenHeight = screenRect.size.height;
//    
//    mainOutPutFrame = [[UIView alloc] initWithFrame:CGRectMake(0, 20, screenWidth, screenWidth)];
//    mainOutPutFrame.backgroundColor = [UIColor clearColor];
//    [self.view addSubview:mainOutPutFrame];
//    
//    self.arrayOfFilters = [[NSMutableArray alloc] init];
//    self.latestImagesArray =[[NSMutableArray alloc] init];
//    
////    currentFilterIndex = 0;
//    
//    self.automaticallyAdjustsScrollViewInsets = NO;
//    
//    [self setupVideoCamera];
//    
//    int recentsLimit = 15;
//    
//    PHFetchOptions *fetchOptions = [PHFetchOptions new];
//    fetchOptions.includeAllBurstAssets = NO;
//    fetchOptions.includeHiddenAssets = NO;
////    fetchOptions.fetchLimit
////    fetchOptions.fetchLimit = 15;
////    [fetchOptions setFetchLimit:15];
//    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
////    fetchOptions.fetchLimit = 15;
//    fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];
//    
//    if([fetchResult count] < recentsLimit){
//        recentsLimit = (int)[fetchResult count];
//    }
//    
//    for(int r = 0; r < recentsLimit; r++){
//        [self.latestImagesArray addObject:[fetchResult objectAtIndex:r]];
//    }
////    for(PHAsset * asset in fetchResult){
////        [self.latestImagesArray addObject:asset];
////    }
//
//    self.carousel.type = iCarouselTypeLinear;
//    
//
//    
//    
//    UIView * bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, screenHeight-60, self.view.frame.size.width, 60)];
//    bottomBar.backgroundColor = [UIColor whiteColor];
//    
//    [self.view addSubview:bottomBar];
//    
//    
//    finalProcessButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0, 70, 70)];
//    UIImage *btnImage9 = [UIImage imageNamed:@"CaptureButton"];
//    [finalProcessButton setImage:btnImage9 forState:UIControlStateNormal];
//    
//    [finalProcessButton addTarget:self action:@selector(finalProcessTapped) forControlEvents:UIControlEventTouchUpInside];
//    
//    
//    [bottomBar addSubview:finalProcessButton];
//    
//    
//    self.carousel.parentView = self.view;
//    self.carousel.delegate = self;
//    self.carousel.dataSource = self;
//    self.carousel.backgroundColor = [UIColor blackColor];
////    self.carousel.itemWidth = 180;
//    //    self.carousel.backgroundColor = [UIColor blueColor];
//    
//    [self.view addSubview:self.carousel];
//    
//    
//    self.editPallette = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenWidth)];
//    
//    self.editPallette.backgroundColor = [UIColor clearColor];
//    
////    [mainOutPutFrame addSubview:self.editPallette];
//    
////    self.editPalletteImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenWidth)];
////    self.editPalletteImageView.userInteractionEnabled = YES;
////    self.editPalletteImageView.contentMode = UIViewContentModeScaleAspectFill;
////    self.editPallette.clipsToBounds = YES;
//////    self.editPalletteImageView.backgroundColor = [UIColor redColor];
////    [self.editPallette addSubview:self.editPalletteImageView];
//    
//    
////    self.resizeAbleView = [GLResizeableView];
//    
//    CGRect gripFrame = CGRectMake(0, 0, screenWidth/2, screenWidth/2);
//    self.resizeAbleView = [[GLResizeableView alloc] initWithFrame:gripFrame];
//    UIView *contentView = [[UIView alloc] initWithFrame:gripFrame];
//    [contentView setBackgroundColor:[UIColor clearColor]];
//    self.resizeAbleView.contentView = contentView;
//    self.resizeAbleView.delegate = self;
//    self.resizeAbleView.parentView = self.view;
////    [self.resizeAbleView hideEditingHandles];
//    
//    self.resizeAbleView.alpha = 0;
//    
//    
//    
////    resizeableView = [[ResizeableView alloc] initWithFrame:CGRectMake(60, 100, 200, 200)];
////    resizeableView.clipsToBounds = YES;
////    resizeableView.transform = CGAffineTransformMakeRotation(0.3);
////    resizeableView.center = CGPointMake(160, 200);
//////    resizeableView.instanceOfCustomObject = self;
////    
////    resizeableView.alpha = 0;
////    resizeableView.topLeft.alpha = 0;
////    resizeableView.topRight.alpha = 0;
////    resizeableView.bottomLeft.alpha = 0;
////    resizeableView.bottomRight.alpha = 0;
////    resizeableView.rotateHandle.alpha = 0;
//
//    
//    
//    CGFloat minWidth  = 100;
//    CGFloat minHeight = 50;
//    
//    UITapGestureRecognizer * tapOnWindow = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resizeableTapped:)];
//    [self.resizeAbleView addGestureRecognizer:tapOnWindow];
//    
//    
//    
//    
//    [self.resizeAbleView addGestureRecognizer:tapOnWindow];
////    [self.resizeAbleView addGestureRecognizer:resizepan];
//    
//    self.editTextViewObj = [[RJTextView alloc] initWithFrame:self.resizeAbleView.bounds
//                                                 defaultText:@"This is Hey from Glance!"
//                                                        font:[UIFont systemFontOfSize:14.f]
//                                                       color:[UIColor blackColor]
//                                                     minSize:CGSizeMake(minWidth, minHeight)];
//    self.editTextViewObj.userInteractionEnabled = NO;
//    self.editTextViewObj.delegate = self;
//    self.editTextViewObj.parentView = self.view;
//    [self.resizeAbleView addSubview:self.editTextViewObj];
//    
//    
//    [mainOutPutFrame addSubview:self.resizeAbleView];
//
////    self.editPallette.hidden = YES;
//    self.editPallette.alpha = 0;
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    captureButton = [[UIButton alloc] initWithFrame:CGRectMake((screenWidth/2)-35,self.view.frame.size.height * 0.6, 70, 70)];
//    UIImage *btnImage3 = [UIImage imageNamed:@"CaptureButton"];
//    [captureButton setImage:btnImage3 forState:UIControlStateNormal];
//    
//    [captureButton addTarget:self action:@selector(captureTapped) forControlEvents:UIControlEventTouchUpInside];
//
//    
//    [self.view addSubview:captureButton];
//    
//    
//    
//    backToCameraButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, 40, 30)];
//    backToCameraButton.userInteractionEnabled = YES;
//    [backToCameraButton addTarget:self action:@selector(backToCameraFromEditPallette:) forControlEvents:UIControlEventTouchUpInside];
//    UIImage *btnImage4 = [UIImage imageNamed:@"backToCameraIcon"];
//    
//    backToCameraButton.alpha = 0;
//    //    [flipCameraButton addTarget:self action:@selector(flipCamera) forControlEvents:UIControlEventTouchUpInside];
//    
//    [backToCameraButton setImage:btnImage4 forState:UIControlStateNormal];
//    [mainOutPutFrame addSubview:backToCameraButton];
//    
//    
//    
//    
//    addTextButton = [[UIButton alloc] initWithFrame:CGRectMake(screenWidth - 50, 10, 38, 38)];
////    addTextButton.backgroundColor = [UIColor blueColor];
//    UIImage *btnImage5 = [UIImage imageNamed:@"addTextIcon"];
//    addTextButton.alpha = 0;
//        [addTextButton addTarget:self action:@selector(addTextToImageTapped) forControlEvents:UIControlEventTouchUpInside];
//    [addTextButton setImage:btnImage5 forState:UIControlStateNormal];
//    [mainOutPutFrame addSubview:addTextButton];
//    
//    trashTextButton = [[UIButton alloc] initWithFrame:CGRectMake(screenWidth - 50, 10, 38, 38)];
//    //    addTextButton.backgroundColor = [UIColor blueColor];
//    UIImage *btnImage6 = [UIImage imageNamed:@"addTextTrashIcon"];
//    trashTextButton.alpha = 0;
//    [trashTextButton addTarget:self action:@selector(trashTheText) forControlEvents:UIControlEventTouchUpInside];
//    [trashTextButton setImage:btnImage6 forState:UIControlStateNormal];
//    [mainOutPutFrame addSubview:trashTextButton];
//    
//    
//    approveTextButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, 40, 30)];
//    approveTextButton.userInteractionEnabled = YES;
//    [approveTextButton addTarget:self action:@selector(approveTextTapped) forControlEvents:UIControlEventTouchUpInside];
//    UIImage *btnImage7 = [UIImage imageNamed:@"approveTextIcon"];
//    
//    approveTextButton.alpha = 0;
//    //    [flipCameraButton addTarget:self action:@selector(flipCamera) forControlEvents:UIControlEventTouchUpInside];
//    
//    [approveTextButton setImage:btnImage7 forState:UIControlStateNormal];
//    [mainOutPutFrame addSubview:approveTextButton];
//    
//    // Listen for keyboard appearances and disappearances
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(keyboardDidShow:)
//                                                 name:UIKeyboardWillShowNotification
//                                               object:nil];
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(keyboardDidHide:)
//                                                 name:UIKeyboardWillHideNotification
//                                               object:nil];
//    
//    touchPointCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
//    
//    UIImage * image = [UIImage imageNamed:@"CameraFocusIcon"];
//    UIImageView * iv = [[UIImageView alloc] initWithFrame:touchPointCircle.frame];
//    iv.image = image;
//    [touchPointCircle addSubview:iv];
//    
//    
//    touchPointCircle.backgroundColor = [UIColor clearColor];
//    //        touchPointCircle.layer.cornerRadius = 30;
//    touchPointCircle.alpha = 0;
//    
//    [mainOutPutFrame addSubview:touchPointCircle];
    
    
    
//    [self.videoCamera startCameraCapture];
    
    
//    [self.view addSubview:fontsScroller];
    
}

//- (void)keyboardDidShow: (NSNotification *) notif{
//    // Do something here
//    isEditing = YES;
////    [self.resizeAbleView showEditingHandles];
//}
//
//- (void)keyboardDidHide: (NSNotification *) notif{
//    // Do something here
//    isEditing = NO;
//    [self.resizeAbleView hideEditingHandles];
//}
//
////- (void)userResizableViewDidBeginEditing:(GLResizeableView *)userResizableView {
////    
////}
//
////-(void)resizeableDragged:(UIPanGestureRecognizer*)pan {
////    [self.editTextViewObj scaleTextView:pan];
////}
//
//-(void)resizeableTapped:(UITapGestureRecognizer*)tap {
//    
////    NSLog(@"test");
//    [self.editTextViewObj.textView becomeFirstResponder];
////    [self.resizeAbleView showEditingHandles];
//    
//}
//
//
//- (void)userResizableViewDidBeginEditing:(GLResizeableView *)userResizableView {
////    NSLog(@"userresized");
////    if(self.resizeAbleView){}
//    [self.resizeAbleView showEditingHandles];
////    currentlyEditingView = userResizableView;
//}
//
//- (void)userResizableViewDidEndEditing:(GLResizeableView *)userResizableView {
////    [self.resizeAbleView hideEditingHandles];
//    if(isEditing == NO){
//        [self.resizeAbleView hideEditingHandles];
//    }
//    
////    [self.editTextViewObj setFrame:CGRectMake(userResizableView.bounds.origin.x, userResizableView.bounds.origin.y, userResizableView.bounds.size.width, userResizableView.bounds.size.height)];
////    [self.editTextViewObj scaleTextView:];
//    
//}
//
//-(void)viewIsResizing:(CGRect)frame {
//    [self.editTextViewObj scaleTextViewByFrame:frame];
//}
//
//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
//    if ([self.resizeAbleView hitTest:[touch locationInView:self.resizeAbleView] withEvent:nil]) {
//        return NO;
//    }
//    return YES;
//}
//
//- (void)hideEditingHandles {
//    // We only want the gesture recognizer to end the editing session on the last
//    // edited view. We wouldn't want to dismiss an editing session in progress.
////    [self.resizeAbleView hideEditingHandles];
//}
//
//-(void)preserveMemory {
//    [[[GLCamera sharedInstance] videoCamera] stopCameraCapture];
//    for(GLFilterView * filter in self.arrayOfFilters){
//        [filter.filter removeAllTargets];
//        [filter.sourcePicture removeAllTargets];
//    }
//    
//}
//
//-(void)viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
//    
//    [self.videoCamera startCameraCapture];
////    [[[GLCamera sharedInstance] videoCamera]startCameraCapture];
////    [[[GLCamera sharedInstance] videoCamera]resumeCameraCapture];
////    [self backToCameraFromEditPallette:nil];
//}
//
//-(void)finalProcessTapped {
//    NSLog(@"final did tapped");
//    
//    
//
//
//    
//    PHImageRequestOptions *options = [[PHImageRequestOptions alloc]init];
//    options.synchronous  = YES;
//    options.resizeMode = PHImageRequestOptionsResizeModeExact;
//    options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
//    
//    [self.videoCamera startCameraCapture];
////    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
////    
////    for(GLFilterView * filterView in self.arrayOfFilters){
////        
////        [filterView backToCamera];
////        [[filterView filter] removeAllTargets];
////    }
////    self.videoCamera = nil;
//
//    
//    switch (imageSource) {
//        case ImageSourceCamera:
//        {
//            [self processSelectedImageWithFilterTextAndSize:cleanImageFromCamera];
//            
//        };
//            break;
//            
//        case ImageSourceRecents:
//        {
//            [[PHImageManager defaultManager]requestImageForAsset:[self.latestImagesArray objectAtIndex:indexOfImageFromCarousel] targetSize:CGSizeMake(1024, 1024) contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *image, NSDictionary *info){
//                
////                dispatch_async(dispatch_get_main_queue(), ^(){});
//                
//                [self processSelectedImageWithFilterTextAndSize:[self imageCroppedToFitSize:CGSizeMake(512, 512) image:image]];
//            }];
//        };
//            break;
//            
//        case ImageSourceGallery:
//        {
//            [self processSelectedImageWithFilterTextAndSize:imageFromPicker];
//        };
//            break;
//            
//        default:
//            break;
//    }
//    
//    
////    [self dismissViewControllerAnimated:YES completion:nil];
//    
//    
//}
//
//
//
//-(void)processSelectedImageWithFilterTextAndSize:(UIImage*)imageToFinal {
//
//    
////    @autoreleasepool {
//    
//    
//    UIImage * filteredImage = [self addFilterToImage:imageToFinal];
//    UIImage * textAsView = [self imageWithText:self.editTextViewObj.textView];
//    CGRect frame = [mainOutPutFrame convertRect:self.editTextViewObj.textView.frame fromView:self.editTextViewObj.textView];
//    UIImage * resizedTextAsImage = [[GLCamera sharedInstance] resizeLabelImage:textAsView location:CGPointZero];
//    UIImage * imageWithText = [[GLCamera sharedInstance] drawText:@"test" inImage:filteredImage atPoint:CGPointMake(frame.origin.x, frame.origin.y) viewToPast:resizedTextAsImage];
//    [self.delegate imageSelected:imageWithText];
//
//
//}
//
//- (UIImage *) imageWithText:(UIView *)view
//{
//    //    view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width*2, view.frame.size.height*2);
//    
//    
//    //    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
//    //    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
//    //    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
//    //    UIGraphicsEndImageContext();
//    
//    
//    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 1.0);
//    
//    
//    
//    
//    [view.layer renderInContext:UIGraphicsGetCurrentContext() ];
//    
//    
//    //    [ drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
//    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    
//    return image;
//}
//
//-(UIImage*)addFilterToImage:(UIImage*)inputImage {
//    
// 
//    
////    GPUImagePicture * sourcePicture = [[GPUImagePicture alloc] initWithImage:inputImage smoothlyScaleOutput:YES];
////    sourcePicture image
//    GLFilterView * currentFIlter = [self.arrayOfFilters objectAtIndex:currentFilterIndex];
//    UIImage * filteredImage = [currentFIlter.filter imageByFilteringImage:inputImage];
//    
//    return filteredImage;
//}
//
//#pragma mark - Camera Actions
//
//-(void) approveTextTapped {
//    
//    [self.editTextViewObj endEditing:YES];
//    [UIView animateWithDuration:0.5 animations:^{
////        resizeableView.alpha = 0;
////        resizeableView.topLeft.alpha = 0;
////        resizeableView.topRight.alpha = 0;
////        resizeableView.bottomLeft.alpha = 0;
////        resizeableView.bottomRight.alpha = 0;
////        resizeableView.rotateHandle.alpha = 0;
//        
//        trashTextButton.alpha = 0;
//        approveTextButton.alpha = 0;
//        
//        backToCameraButton.alpha = 1;
//        addTextButton.alpha = 1;
//        
//    }];
//}
//
//-(void) updateFiltersWithSelectedImage:(UIImage *)image {
//    
////    GLFilterView * currFilter = [self.arrayOfFilters objectAtIndex:currentFilterIndex];
////    UIImage * captured = [[GLCamera sharedInstance] imageWithView:currFilter.outputViewCasted];
//    
//    
//    
//    [UIView animateWithDuration:0.5 animations:^{
//        self.editPallette.alpha = 1;
//        flipCameraButton.alpha = 0;
//        backToCameraButton.alpha = 1;
//        flashButton.alpha = 0;
//        addTextButton.alpha = 1;
//        captureButton.alpha = 0;
//        
//        
//    }];
//    
////    croppedImage = nil;
//    
//    
//    
//    for(GLFilterView * filterView in self.arrayOfFilters){
//        [filterView setImageCapturedUnderFilter:image];
//    }
//}
//
//
//-(void) updateFiltersWithCapturedImage {
//    
//
//    
//    GLFilterView * t = [self.arrayOfFilters objectAtIndex:0];
//
//    
//    
//    UIImage * captured = [[GLCamera sharedInstance] imageWithView:t.outputViewCasted];
//    
//    
//    
//    for(GLFilterView * filterView in self.arrayOfFilters){
//        [filterView setImageCapturedUnderFilter:captured];
//    }
//}
//
//- (void) captureTapped {
//
////    [[GLCamera sharedInstance] setInEditMode:YES];
////    [[GLCamera sharedInstance] playCaptureSound];
//    
////    [self.videoCamera capturePhotoAsJPEGProcessedUpToFilter:[[self.arrayOfFilters objectAtIndex:0] filter] withCompletionHandler:^(NSData *processedJPEG, NSError *error) {
////        [self.videoCamera pauseCameraCapture];
////        
////        cleanImageFromCamera = [UIImage imageWithData:processedJPEG];
////        
////        [self updateFiltersWithCapturedImage];
////        
////        
//////        [];
////    }];
////    @autoreleasepool {
////        [[self.arrayOfFilters objectAtIndex:0] useNextFrameForImageCapture];
//    
//    CGRect screenRect = kScreenBounds;
//    CGFloat screenWidth = screenRect.size.width;
//
//    
//    [[[self.arrayOfFilters objectAtIndex:0] filter] useNextFrameForImageCapture];
//    //
//        UIImage * imageFromFilter = [[[self.arrayOfFilters objectAtIndex:0] filter] imageFromCurrentFramebuffer];
//    [self.videoCamera stopCameraCapture];
//        cleanImageFromCamera = [self imageCroppedToFitSize:CGSizeMake(512, 512) image:imageFromFilter];
//    
////    for(GLFilterView * filterView in self.arrayOfFilters){
////                        [filterView setImageCapturedUnderFilter:[self imageCroppedToFitSize:CGSizeMake(screenWidth, screenWidth) image:imageFromFilter]];
//////        [filterView.filter ]
////                    }
//    
//    
//
////        [self.videoCamera capturePhotoAsImageProcessedUpToFilter:[[self.arrayOfFilters objectAtIndex:0] filter] withCompletionHandler:^(UIImage *processedImage, NSError *error) {
////            
////            [self.videoCamera pauseCameraCapture];
////            
////            cleanImageFromCamera = [self imageCroppedToFitSize:CGSizeMake(512, 512) image:processedImage];
////
////            
////            for(GLFilterView * filterView in self.arrayOfFilters){
////                [filterView setImageCapturedUnderFilter:[self imageCroppedToFitSize:CGSizeMake(screenWidth, screenWidth) image:processedImage]];
////            }
////        }];
//
//    imageSource = ImageSourceCamera;
//    
//    
////    [UIView animateWithDuration:0.5 animations:^{
////        self.editPallette.alpha = 1;
////        flipCameraButton.alpha = 0;
////        backToCameraButton.alpha = 1;
////        flashButton.alpha = 0;
////        addTextButton.alpha = 1;
////        captureButton.alpha = 0;
////        
////        
////    }];
//    
//    
//    
////    UIImageWriteToSavedPhotosAlbum(captured,
////                                   nil,
////                                   @selector(savedone),
////                                   nil);
////    
////    [self sendImageToEdit:captured];
//    
//    
//    
////    GLFilterView * t = [self.arrayOfFilters objectAtIndex:0];
//////    GPUImageSepiaFilter * defFilter = [[GPUImageSepiaFilter alloc] init];
////    [(GPUImageSaturationFilter *)t.filter setSaturation:1];
//////    [self.videoCamera pauseCameraCapture];
////    
////    self.videoCamera.jpegCompressionQuality = 0.01;
////    [self.videoCamera capturePhotoAsJPEGProcessedUpToFilter:t.filter withCompletionHandler:^(NSData *processedJPEG, NSError *error) {
////        
////        UIImage *image=[UIImage imageWithData:processedJPEG];
////        UIImage * l = [self imageByCroppingImage:image toSize:CGSizeMake(image.size.width, image.size.width)];
//    
//    
//    
////        [[self.arrayOfFilters objectAtIndex:0] setImageCapturedUnderFilter:captured];
////        [[self.arrayOfFilters objectAtIndex:1] setImageCapturedUnderFilter:captured];
////        [[self.arrayOfFilters objectAtIndex:2] setImageCapturedUnderFilter:captured];
////        [[self.arrayOfFilters objectAtIndex:3] setImageCapturedUnderFilter:captured];
////        [[self.arrayOfFilters objectAtIndex:4] setImageCapturedUnderFilter:captured];
////        [[self.arrayOfFilters objectAtIndex:5] setImageCapturedUnderFilter:captured];
////        image = nil;
////        l = nil;
//        
////    }];
//    
////    [self.videoCamera capturePhotoAsImageProcessedUpToFilter:t.filter withCompletionHandler:^(UIImage *captureImage, NSError *error){
////        
//////        NSData *imgData= UIImageJPEGRepresentation(captureImage,0.3 /*compressionQuality*/);
//////        UIImage *image=[UIImage imageWithData:imgData];
////        
////        
////        UIImage * l = [self imageByCroppingImage:captureImage toSize:CGSizeMake(captureImage.size.width, captureImage.size.width)];
////        
////        
////        [[self.arrayOfFilters objectAtIndex:0] setImageCapturedUnderFilter:l];
//////        [[self.arrayOfFilters objectAtIndex:1] setImageCapturedUnderFilter:l];
//////        [[self.arrayOfFilters objectAtIndex:2] setImageCapturedUnderFilter:l];
////        
//////        for(GLFilterView * filterView in self.arrayOfFilters){
//////            
//////            [filterView setImageCapturedUnderFilter:l];
//////            
//////        }
////        
//////        UIImageView * tt = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, t.outputViewCasted.frame.size.width, t.outputViewCasted.frame.size.width)];
//////        tt.image = l;
//////        [t.outputViewCasted addSubview:tt];
////        
//////        if (error) {
//////            NSLog(@"ERROR: Could not capture!");
//////        }
//////        else {
//////            // save file
//////            
//////            NSLog(@"PHOTO SAVED - ??");
//////            
//////            // save photo to album
////////            UIImageWriteToSavedPhotosAlbum(captureImage, nil, nil, nil);
//////        }
//////        
//////        runOnMainQueueWithoutDeadlocking(^{
//////            
//////            // Start video camera capture again
////////            [self.videoCamera resumeCameraCapture];
//////            
//////            
//////        });
////        
////    }];
//    
//    
////    GLFilterView * t = [self.arrayOfFilters objectAtIndex:0];
////    
////    [self.videoCamera pauseCameraCapture];
////    UIImage *capturedImage = [self.videoCamera imageFromCurrentlyProcessedOutput];
////    UIImageWriteToSavedPhotosAlbum(capturedImage, nil, nil, nil);
////    [self.videoCamera resumeCameraCapture];
//    
//    
////    [self.videoCamera capturePhotoAsImageProcessedUpToFilter:nil withCompletionHandler:^(UIImage *processedJPEG, NSError *error){
////        
////        
////            UIImageWriteToSavedPhotosAlbum(processedJPEG,
////                                           nil,
////                                           @selector(savedone),
////                                           nil);
//    
////        // Save to assets library
////        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
////        
////        [library writeImageDataToSavedPhotosAlbum:processedJPEG metadata:self.videoCamera.currentCaptureMetadata completionBlock:^(NSURL *assetURL, NSError *error2)
////         {
////             if (error2) {
////                 NSLog(@"ERROR: the image failed to be written");
////             }
////             else {
////                 NSLog(@"PHOTO SAVED - assetURL: %@", assetURL);
////             }
////             
////             runOnMainQueueWithoutDeadlocking(^{
////                 //                 [photoCaptureButton setEnabled:YES];
////                 
////             });
////         }];
////    }];
//    
//    [UIView animateWithDuration:1.5 animations:^{
//        self.view.alpha = 0;
//    }];
//}
//
//-(void)savedone {
//
//}
//
//-(void) trashTheText {
//    [UIView animateWithDuration:0.5 animations:^{
//
//        self.resizeAbleView.alpha = 0;
////        resizeableView.alpha = 0;
////        resizeableView.topLeft.alpha = 0;
////        resizeableView.topRight.alpha = 0;
////        resizeableView.bottomLeft.alpha = 0;
////        resizeableView.bottomRight.alpha = 0;
////        resizeableView.rotateHandle.alpha = 0;
//        
//        addTextButton.alpha = 1;
//        trashTextButton.alpha = 0;
//        
//        approveTextButton.alpha = 0;
//        backToCameraButton.alpha = 1;
//    }];
//}
//
//
//-(void) addTextToImageTapped {
//    
//    [UIView animateWithDuration:0.5 animations:^{
//        addTextButton.alpha = 0;
//        backToCameraButton.alpha = 0;
//        trashTextButton.alpha = 1;
//        approveTextButton.alpha = 1;
//
//        self.resizeAbleView.alpha = 1;
//        
////        resizeableView.alpha = 1;
////        resizeableView.topLeft.alpha = 1;
////        resizeableView.topRight.alpha = 1;
////        resizeableView.bottomLeft.alpha = 1;
////        resizeableView.bottomRight.alpha = 1;
////        resizeableView.rotateHandle.alpha = 1;
//    }];
//}
//
//-(void) sendImageToEdit:(UIImage *)image {
//    
//    
//    self.editPalletteImageView.image = image;
//    [UIView animateWithDuration:0.5 animations:^{
//        self.editPallette.alpha = 1;
//        flipCameraButton.alpha = 0;
//        backToCameraButton.alpha = 1;
//        flashButton.alpha = 0;
//        addTextButton.alpha = 1;
//        captureButton.alpha = 0;
//        
//        
//    }];
//    
//
//}
//
//-(void) backToCameraFromEditPallette:(id)sender {
//    [self.editTextViewObj endEditing:YES];
//    imageSource = ImageSourceNone;
//    
////    self.resizeAbleView.alpha = 
//    
////    [[GLCamera sharedInstance] setInEditMode:NO];
//    
//    for(GLFilterView * filterView in self.arrayOfFilters){
//        [filterView backToCamera];
//    }
//    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
//    [self.videoCamera resumeCameraCapture];
//    
//    
//    
//    [UIView animateWithDuration:0.5 animations:^{
//        self.resizeAbleView.alpha = 0;
//        self.editPallette.alpha = 0;
//        flipCameraButton.alpha = 1;
//        backToCameraButton.alpha = 0;
//        flashButton.alpha = 1;
//        addTextButton.alpha = 0;
//        captureButton.alpha = 1;
//    }];
//}
//
//
//-(void)flipCamera {
//
//    
//    [self.videoCamera rotateCamera];
//    
//    if(cameraIsBackView){
//        if([[GLCamera sharedInstance] flashIsOn]){
//            [[GLCamera sharedInstance] toggleFlash];
//        }
//        [UIView animateWithDuration:0.2 animations:^{
//            [flashButton setAlpha:0];
//        }];
//    } else {
//        [UIView animateWithDuration:0.2 animations:^{
//            [flashButton setAlpha:1];
//        }];
//    }
//    cameraIsBackView = !cameraIsBackView;
//    
//}
//
//-(void)toggleFlash {
//    
//    [[GLCamera sharedInstance] toggleFlash];
//}
//
//
//#pragma mark - initiators
//
//- (void)createMainScrollView {
//    
//    CGRect screenRect = [[UIScreen mainScreen] bounds];
//    CGFloat filterViewWidth = screenRect.size.width;
//    CGFloat filterViewHeight = screenRect.size.width;
//    
//    self.mainScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, filterViewWidth, filterViewHeight)];
//    self.mainScrollView.tag = ScrollerTypeFilterScroller;
//    self.mainScrollView.delegate = self;
//    self.mainScrollView.bounces = NO;
//    self.mainScrollView.pagingEnabled = YES;
//    NSInteger numberOfViews = [self.arrayOfFilters count];
//    for (int i = 0; i < numberOfViews; i++) {
//        CGFloat yOrigin = i * filterViewHeight;
//        GLFilterView * tempFilt = [self.arrayOfFilters objectAtIndex:i];
//        [tempFilt.container setFrame:CGRectMake(0, yOrigin, filterViewWidth, filterViewHeight)];
//        tempFilt.container.backgroundColor = [UIColor blackColor];
//        
//        [self.mainScrollView addSubview:tempFilt.container];
//        
//    }
//    self.mainScrollView.contentSize = CGSizeMake(filterViewWidth, (filterViewHeight* numberOfViews));
//    
//    //    [self.mainScrollView setContentOffset:CGPointMake(0, 20)];
//    //    [self.mainScrollView scrollsToTop];
//    
//    [mainOutPutFrame addSubview:self.mainScrollView];
//    
//    UIView * buttonBg1 = [[UIView alloc] initWithFrame:CGRectMake(10, 0, 60, 60)];
//    buttonBg1.backgroundColor = [UIColor blackColor];
//    buttonBg1.layer.cornerRadius = 60;
//    
//    
//    flipCameraButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 20, 60, 60)];
//    UIImage *btnImage = [UIImage imageNamed:@"FlipCameraIcon"];
//    [flipCameraButton addTarget:self action:@selector(flipCamera) forControlEvents:UIControlEventTouchUpInside];
//    [flipCameraButton setImage:btnImage forState:UIControlStateNormal];
//    [self.view addSubview:flipCameraButton];
//    
//    backCameraOn = YES;
//    
//    flashButton = [[UIButton alloc] initWithFrame:CGRectMake(filterViewWidth - 50, 30, 40, 40)];
//    UIImage *btnImage2 = [UIImage imageNamed:@"FlashIcon"];
//    [flashButton addTarget:self action:@selector(toggleFlash) forControlEvents:UIControlEventTouchUpInside];
//    [flashButton setImage:btnImage2 forState:UIControlStateNormal];
//    [self.view addSubview:flashButton];
//    
//    flashIsOn = NO;
//    
//    
////    self.recentPhotosSlider = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, filterViewWidth, filterViewHeight)];
////    self.mainScrollView.tag = ScrollerTypeFilterScroller;
////    self.mainScrollView.delegate = self;
////    self.mainScrollView.pagingEnabled = YES;
//    
//}
//
//- (void)setupVideoCamera {
//
////    self.videoCamera = [[GLCamera sharedInstance] videoCamera];
//    self.videoCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionBack];
//    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
//    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
//    self.videoCamera.horizontallyMirrorRearFacingCamera = NO;
//    
//    [self createFiltersViews];
//    [self createMainScrollView];
//    
////    [self.videoCamera startCameraCapture];
//    
//}
//
//-(void)focusCameraToPoint:(UITapGestureRecognizer *)tgr location:(CGPoint)location {
//
//    if (tgr.state == UIGestureRecognizerStateRecognized) {
////        CGPoint location = [tgr locationInView:self.focusLayer];
//        
//        AVCaptureDevice *device = [self.videoCamera inputCamera];
//        CGPoint pointOfInterest = CGPointMake(.5f, .5f);
//        //            NSLog(@"taplocation x = %f y = %f", location.x, location.y);
//        
//        touchPointCircle.frame = CGRectMake(location.x-30, location.y-30, 60, 60);
//        touchPointCircle.alpha = 1;
//        [UIView animateWithDuration:0.5 animations:^{
//            touchPointCircle.transform = CGAffineTransformScale(touchPointCircle.transform, 0.7, 0.7);
//            touchPointCircle.alpha = 0;
//        }];
//        touchPointCircle.transform = CGAffineTransformIdentity;
//        
//        CGSize frameSize = self.view.frame.size;
//        
//        if ([[[GLCamera sharedInstance] videoCamera] cameraPosition] == AVCaptureDevicePositionFront) {
//            location.x = frameSize.width - location.x;
//        }
//        
//        pointOfInterest = CGPointMake(location.y / frameSize.height, 1.f - (location.x / frameSize.width));
//        
//        
//        if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
//            NSError *error;
//            if ([device lockForConfiguration:&error]) {
//                [device setFocusPointOfInterest:pointOfInterest];
//                
//                [device setFocusMode:AVCaptureFocusModeAutoFocus];
//                
//                if([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
//                {
//                    [device setExposurePointOfInterest:pointOfInterest];
//                    [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
//                }
//                
//                [device unlockForConfiguration];
//                
//                //                    NSLog(@"FOCUS OK");
//            } else {
//                //                    NSLog(@"ERROR = %@", error);
//            }
//        }
//    }
//    
//
//
//
//}
//
//- (void)createFiltersViews {
//
//    
//    
//    defaultFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_NOFILTER];
//    defaultFilter.delegate = self;
//    [self.videoCamera addTarget:defaultFilter.filter];
//    [self.arrayOfFilters addObject:defaultFilter];
//    
//    contrastFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_CONTRAST];
//    contrastFilter.delegate = self;
//    [self.videoCamera addTarget:contrastFilter.filter];
//    [self.arrayOfFilters addObject:contrastFilter];
//
//    brightnessFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_BRIGHTNESS];
//    brightnessFilter.delegate = self;
//    [self.videoCamera addTarget:brightnessFilter.filter];
//    [self.arrayOfFilters addObject:brightnessFilter];
//    
//    levelsFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_LEVELS];
//    levelsFilter.delegate = self;
////    [self.videoCamera addTarget:levelsFilter.filter];
//    [self.arrayOfFilters addObject:levelsFilter];
//    
//    exposureFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_EXPOSURE];
//    exposureFilter.delegate = self;
////    [self.videoCamera addTarget:exposureFilter.filter];
//    [self.arrayOfFilters addObject:exposureFilter];
//    
//    saturationFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_SATURATION];
//    saturationFilter.delegate = self;
////    [self.videoCamera addTarget:saturationFilter.filter];
//    [self.arrayOfFilters addObject:saturationFilter];
//    
//    sharpenFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_SHARPEN];
//    sharpenFilter.delegate = self;
////    [self.videoCamera addTarget:sharpenFilter.filter];
//    [self.arrayOfFilters addObject:sharpenFilter];
//    
//    gammaFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_GAMMA];
//    gammaFilter.delegate = self;
////    [self.videoCamera addTarget:gammaFilter.filter];
//    [self.arrayOfFilters addObject:gammaFilter];
//    
//    hazeFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_HAZE];
//    hazeFilter.delegate = self;
////    [self.videoCamera addTarget:hazeFilter.filter];
//    [self.arrayOfFilters addObject:hazeFilter];
//    
//    sepiaFIlter = [[GLFilterView alloc] initWithType:GPUIMAGE_SEPIA];
//    sepiaFIlter.delegate = self;
////    [self.videoCamera addTarget:sepiaFIlter.filter];
//    [self.arrayOfFilters addObject:sepiaFIlter];
//    
//    amatorkaFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_AMATORKA];
//    amatorkaFilter.delegate = self;
////    [self.videoCamera addTarget:amatorkaFilter.filter];
//    [self.arrayOfFilters addObject:amatorkaFilter];
//    
//    missEtikateFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_MISSETIKATE];
//    missEtikateFilter.delegate = self;
////    [self.videoCamera addTarget:missEtikateFilter.filter];
//    [self.arrayOfFilters addObject:missEtikateFilter];
//    
//    softEleganceFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_SOFTELEGANCE];
//    softEleganceFilter.delegate = self;
////    [self.videoCamera addTarget:softEleganceFilter.filter];
//    [self.arrayOfFilters addObject:softEleganceFilter];
//    
//    grayScaleFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_GRAYSCALE];
//    grayScaleFilter.delegate = self;
////    [self.videoCamera addTarget:grayScaleFilter.filter];
//    [self.arrayOfFilters addObject:grayScaleFilter];
//    
//    sketchFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_SKETCH];
//    sketchFilter.delegate = self;
////    [self.videoCamera addTarget:sketchFilter.filter];
//    [self.arrayOfFilters addObject:sketchFilter];
//    
//    embossFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_EMBOSS];
//    embossFilter.delegate = self;
////    [self.videoCamera addTarget:embossFilter.filter];
//    [self.arrayOfFilters addObject:embossFilter];
//    
//    vignetteFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_VIGNETTE];
//    vignetteFilter.delegate = self;
////    [self.videoCamera addTarget:vignetteFilter.filter];
//    [self.arrayOfFilters addObject:vignetteFilter];
//    
//    selectiveBlurFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_GAUSSIAN_SELECTIVE];
//    selectiveBlurFilter.delegate = self;
////    [self.videoCamera addTarget:selectiveBlurFilter.filter];
//    [self.arrayOfFilters addObject:selectiveBlurFilter];
//    
//    toonFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_TOON];
//    toonFilter.delegate = self;
////    [self.videoCamera addTarget:toonFilter.filter];
//    [self.arrayOfFilters addObject:toonFilter];
//
//    
//    
//}
//
//#pragma mark - FitlersScrollViewMethods
//
//- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    
//    
//    if (self.lastContentOffset > scrollView.contentOffset.y)
//        scrollDirection = ScrollDirectionUp;
//    else if (self.lastContentOffset < scrollView.contentOffset.y)
//        scrollDirection = ScrollDirectionDown;
//    
//    self.lastContentOffset = scrollView.contentOffset.y;
//    
//    
//    
//    if(scrollView.tag == ScrollerTypeFontsScroller){
//        
//    }
//    
//    
//    if(scrollView.tag == ScrollerTypeFilterScroller){
//    
//    
//    
//    CGFloat offsetY = scrollView.contentOffset.y;
//    
//    
//
//    [defaultFilter.container setContentOffset:CGPointMake(0, -offsetY)];
//    defaultFilter.sliderView.frame = CGRectMake(0, -offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//    
//    [contrastFilter.container setContentOffset:CGPointMake(0, (contrastFilter.container.frame.size.height)-offsetY)];
//    contrastFilter.sliderView.frame = CGRectMake(0, (contrastFilter.container.frame.size.height)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//    
//    [brightnessFilter.container setContentOffset:CGPointMake(0, (brightnessFilter.container.frame.size.height*2) -offsetY)];
//    brightnessFilter.sliderView.frame = CGRectMake(0, (brightnessFilter.container.frame.size.height*2)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//    
//    [levelsFilter.container setContentOffset:CGPointMake(0, (levelsFilter.container.frame.size.height*3)-offsetY)];
//    levelsFilter.sliderView.frame = CGRectMake(0, (levelsFilter.container.frame.size.height*3)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//    
//    [exposureFilter.container setContentOffset:CGPointMake(0, (exposureFilter.container.frame.size.height*4)-offsetY)];
//    exposureFilter.sliderView.frame = CGRectMake(0, (exposureFilter.container.frame.size.height*4)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//    
//    [saturationFilter.container setContentOffset:CGPointMake(0, (saturationFilter.container.frame.size.height*5)-offsetY)];
//    saturationFilter.sliderView.frame = CGRectMake(0, (saturationFilter.container.frame.size.height*5)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//        
//        [sharpenFilter.container setContentOffset:CGPointMake(0, (sharpenFilter.container.frame.size.height*6)-offsetY)];
//        sharpenFilter.sliderView.frame = CGRectMake(0, (sharpenFilter.container.frame.size.height*6)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//    
//    
//    [gammaFilter.container setContentOffset:CGPointMake(0, (gammaFilter.container.frame.size.height*7)-offsetY)];
//    gammaFilter.sliderView.frame = CGRectMake(0, (gammaFilter.container.frame.size.height*7)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//    
//    [hazeFilter.container setContentOffset:CGPointMake(0, (hazeFilter.container.frame.size.height*8)-offsetY)];
//    hazeFilter.sliderView.frame = CGRectMake(0, (hazeFilter.container.frame.size.height*8)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//    
//    [sepiaFIlter.container setContentOffset:CGPointMake(0, (sepiaFIlter.container.frame.size.height*9)-offsetY)];
//    sepiaFIlter.sliderView.frame = CGRectMake(0, (sepiaFIlter.container.frame.size.height*9)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//    
//    [amatorkaFilter.container setContentOffset:CGPointMake(0, (amatorkaFilter.container.frame.size.height*10)-offsetY)];
//    amatorkaFilter.sliderView.frame = CGRectMake(0, (amatorkaFilter.container.frame.size.height*10)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//    
//    [missEtikateFilter.container setContentOffset:CGPointMake(0, (missEtikateFilter.container.frame.size.height*11)-offsetY)];
//    missEtikateFilter.sliderView.frame = CGRectMake(0, (missEtikateFilter.container.frame.size.height*11)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//    
//    [softEleganceFilter.container setContentOffset:CGPointMake(0, (softEleganceFilter.container.frame.size.height*12)-offsetY)];
//    softEleganceFilter.sliderView.frame = CGRectMake(0, (softEleganceFilter.container.frame.size.height*12)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//    
//    [grayScaleFilter.container setContentOffset:CGPointMake(0, (grayScaleFilter.container.frame.size.height*13)-offsetY)];
//    grayScaleFilter.sliderView.frame = CGRectMake(0, (grayScaleFilter.container.frame.size.height*13)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//    
//    
//    [sketchFilter.container setContentOffset:CGPointMake(0, (sketchFilter.container.frame.size.height*14)-offsetY)];
//    sketchFilter.sliderView.frame = CGRectMake(0, (sketchFilter.container.frame.size.height*14)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//
//    
//    [embossFilter.container setContentOffset:CGPointMake(0, (embossFilter.container.frame.size.height*15)-offsetY)];
//    embossFilter.sliderView.frame = CGRectMake(0, (embossFilter.container.frame.size.height*15)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//
//    [vignetteFilter.container setContentOffset:CGPointMake(0, (vignetteFilter.container.frame.size.height*16)-offsetY)];
//    vignetteFilter.sliderView.frame = CGRectMake(0, (vignetteFilter.container.frame.size.height*16)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//    
//    [selectiveBlurFilter.container setContentOffset:CGPointMake(0, (selectiveBlurFilter.container.frame.size.height*17)-offsetY)];
//    selectiveBlurFilter.sliderView.frame = CGRectMake(0, (selectiveBlurFilter.container.frame.size.height*17)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//
//    [toonFilter.container setContentOffset:CGPointMake(0, (toonFilter.container.frame.size.height*18)-offsetY)];
//    toonFilter.sliderView.frame = CGRectMake(0, (toonFilter.container.frame.size.height*18)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//
//        
//    }
//    static NSInteger previousPage = 0;
//    CGFloat pageHeight = scrollView.frame.size.height;
//    float fractionalPage = scrollView.contentOffset.y / pageHeight;
//    NSInteger page = lround(fractionalPage);
//    NSLog(@"%d",page);
//    if (previousPage != page) {
//        previousPage = page;
//        currentFilterIndex = page;
//        
//        if(scrollDirection == ScrollDirectionDown){
//            //
//                        if(page >= 2){
//                            GLFilterView * prevFilter = [self.arrayOfFilters objectAtIndex:page-2];
//                            if(prevFilter.filterType != GPUIMAGE_NOFILTER){
//                                [self.videoCamera removeTarget:prevFilter.filter];
//                            }
//                        }
//            
//                        if(page < [self.arrayOfFilters count]-2){
//                            GLFilterView * nextFilter = [self.arrayOfFilters objectAtIndex:page+2];
//                            if(nextFilter.filterType != GPUIMAGE_NOFILTER){
//                                [self.videoCamera addTarget:nextFilter.filter];
//                            }
//            
//                            //            if(stateEdit){
//                            //                [[self.arrayOfFilters objectAtIndex:currentFilterIndex+1] setImageCapturedUnderFilter:cleanImageFromCamera];
//                            //
//                            //            }
//                        }
//            
//            
//            
//            
//                    } else if(scrollDirection == ScrollDirectionUp){
//            
//                        if(page >= 2){
//                            GLFilterView * prevFilter = [self.arrayOfFilters objectAtIndex:page-2];
//                            if(prevFilter.filterType != GPUIMAGE_NOFILTER){
//                                [self.videoCamera addTarget:prevFilter.filter];
//                            }
//                        }
//            
//                        if(page < [self.arrayOfFilters count]-2){
//                            
//                            GLFilterView * nextFilter = [self.arrayOfFilters objectAtIndex:page+2];
//                            if(nextFilter.filterType != GPUIMAGE_NOFILTER){
//                                [self.videoCamera removeTarget:nextFilter.filter];
//                            }
//                            
//                        }
//                        
//                    }
//        
//        
//        /* Page did change */
//    }
//    
//}
//
//- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
//    
//    scrollView.userInteractionEnabled = YES;
//    
////    if(scrollView.tag == ScrollerTypeFilterScroller){
////        
////        int page = scrollView.contentOffset.y / scrollView.frame.size.height;
////        currentFilterIndex = page;
////        NSLog(@"%d - %d",page,currentFilterIndex);
////        
////        
////        if(scrollDirection == ScrollDirectionDown){
////            
////            if(page >= 2){
////                GLFilterView * prevFilter = [self.arrayOfFilters objectAtIndex:page-2];
////                if(prevFilter.filterType != GPUIMAGE_NOFILTER){
////                    [self.videoCamera removeTarget:prevFilter.filter];
////                }
////            }
////            
////            if(page < [self.arrayOfFilters count]-2){
////                GLFilterView * nextFilter = [self.arrayOfFilters objectAtIndex:page+2];
////                if(nextFilter.filterType != GPUIMAGE_NOFILTER){
////                    [self.videoCamera addTarget:nextFilter.filter];
////                }
////                
////                //            if(stateEdit){
////                //                [[self.arrayOfFilters objectAtIndex:currentFilterIndex+1] setImageCapturedUnderFilter:cleanImageFromCamera];
////                //
////                //            }
////            }
////            
////            
////            
////            
////        } else if(scrollDirection == ScrollDirectionUp){
////            
////            if(page >= 2){
////                GLFilterView * prevFilter = [self.arrayOfFilters objectAtIndex:page-2];
////                if(prevFilter.filterType != GPUIMAGE_NOFILTER){
////                    [self.videoCamera addTarget:prevFilter.filter];
////                }
////            }
////            
////            if(page < [self.arrayOfFilters count]-2){
////                
////                GLFilterView * nextFilter = [self.arrayOfFilters objectAtIndex:page+2];
////                if(nextFilter.filterType != GPUIMAGE_NOFILTER){
////                    [self.videoCamera removeTarget:nextFilter.filter];
////                }
////                
////            }
////            
////        }
////        
////    }
//    
//    
//    
////    NSLog(@"%d",page);
//}
//
//- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
//    
//    
//    scrollView.userInteractionEnabled = NO;
//    
//    
//    
////    int page = scrollView.contentOffset.y / scrollView.frame.size.height;
//    
////    if(currentFilterIndex < [self.arrayOfFilters count]-1){
//    
////    }
//   
//    
////    if(currentFilterIndex > [self.arrayOfFilters count]-1){
////        NSLog(@"im bigger and im gone crash");
////        currentFilterIndex = page-1;
////    }
//    
////    NSLog(@"%d - %d",page,currentFilterIndex);
////    
////    
////    if(scrollView.tag == ScrollerTypeFontsScroller){
////        
////    }
////    
////    
////    if(scrollView.tag == ScrollerTypeFilterScroller){
////    
//////        if(scrollView.tag == ScrollerTypeFilterScroller){
//////            currentFilterIndex = page;
////        
//////        }
////        
////    
////        
////        
////        
////    }
//    
//    
//}
//
//#pragma mark - iCarouselMethods
//
//- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index locationInView:(CGPoint)location {
//    
//    indexOfImageFromCarousel = (int)index;
//    
//    
//    if(index == [self.latestImagesArray count]){ // Set the last item in carousel to a button which opens image picker.
////        NSLog(@"test");
//        [self.videoCamera stopCameraCapture];
//        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
//        picker.delegate = self;
//        fromImagePicker = YES;
//        picker.allowsEditing = YES;
//        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
//        
//        [self presentViewController:picker animated:YES completion:NULL];
//    } else {
//        
//        PHImageRequestOptions *options = [[PHImageRequestOptions alloc]init];
//        options.synchronous  = YES;
//        options.resizeMode = PHImageRequestOptionsResizeModeExact;
////        options.normalizedCropRect = CGRectMake(0, 0, 200, 200);
//        options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
//        
////        [[GLCamera sharedInstance] setInEditMode:YES];
//        
////        [[[GLCamera sharedInstance] videoCamera] pauseCameraCapture];
//        [self.videoCamera stopCameraCapture];
//        
//        [[PHImageManager defaultManager]requestImageForAsset:[self.latestImagesArray objectAtIndex:index] targetSize:CGSizeMake(self.view.frame.size.width*2, self.view.frame.size.width*2) contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *result, NSDictionary *info){
//            
//////            [self sendImageToEdit:result];
////            CGImageRef cgRef = result.CGImage;
////            UIImage * ttimage = [self normalizedImage:result];
//            
//            UIImage * croppedImage = [self imageCroppedToFitSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.width) image:result];
//            
//            
//            [self updateFiltersWithSelectedImage:croppedImage];
////            ttimage = nil;
//            imageSource = ImageSourceRecents;
//            
//            
////            [[PHImageManager defaultManager] dealloc];
//            //            UIImageView * thumbImage = [[UIImageView alloc] initWithImage:result];//
//            //            thumbImage.frame = CGRectMake(98, self.view.frame.size.height-256, 180, 180);
//            //
//            //
//            //
//            //
//            //            [self.view addSubview:thumbImage];
//            //            NSLog(@"%f",self.carousel.contentOffset.width);
//            //            [UIView animateWithDuration:0.25 animations:^{
//            //                thumbImage.frame = CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.width);
//            //            }];
//            
//        }];
//    }
//    
//}
//
//- (UIImage *)normalizedImage:(UIImage*)image {
//    if (image.imageOrientation == UIImageOrientationUp) return image;
//    
//    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
//    [image drawInRect:(CGRect){0, 0, image.size}];
//    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    return normalizedImage;
//}
//
//- (NSInteger)numberOfItemsInCarousel:(iCarousel *)carousel
//{
//    //return the total number of items in the carousel
//    return [self.latestImagesArray count]+1;
//}
//
//- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
//{
//    
//    view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 180.0f, 180.0f)];
//    //        ((UIImageView *)view).image = [UIImage imageNamed:@"page.png"];
//    view.contentMode = UIViewContentModeScaleAspectFill;
//    view.clipsToBounds = YES;
//    
//    if(index == [self.latestImagesArray count]){
//        //        view.backgroundColor = [UIColor purpleColor];
//        //        UIImage * i = [[UIImage alloc] ];
//        UIImage * image = [UIImage imageNamed:@"GiCon"];
//        UIImageView * iv = [[UIImageView alloc] initWithFrame:CGRectMake(45, 45, 90.0f, 90.0f)];
//        iv.image = image;
//        [view addSubview:iv];
//        //        ((UIImageView *)view).image = image;
//    } else {
//        [[PHImageManager defaultManager]requestImageForAsset:[self.latestImagesArray objectAtIndex:index] targetSize:CGSizeMake(180.0f, 180.0f) contentMode:PHImageContentModeDefault options:nil resultHandler:^(UIImage *result, NSDictionary *info){
//            ((UIImageView *)view).image = result;
//            //            UIImageView * thumbImage = [[UIImageView alloc] initWithImage:result];//
//            //            thumbImage.frame = CGRectMake(0, 0, 180, 180);
//            //
//            //            [view addSubview:thumbImage];
//            
//        }];
//    }
//    
//    
//    
//    return view;
//}
//
//- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
//{
//    if (option == iCarouselOptionSpacing)
//    {
//        return value * 1.1;
//    }
//    return value;
//}
//
////- (CGFloat)carouselItemWidth:(iCarousel *)carousel {
////
////    CGFloat w = 180;
////
////    return  w;
////
////}
//
//#pragma mark - otherDelegateMethods
//
//- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
//    
//    fromImagePicker = NO;
//    
////    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
////    [self sendImageToEdit:chosenImage];
////   ;
//    
//    [self updateFiltersWithSelectedImage:[self imageCroppedToFitSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.width) image:info[UIImagePickerControllerEditedImage]]];
//    //    self.imageView.image = chosenImage;
//    
//    //
//    [picker dismissViewControllerAnimated:YES completion:NULL];
//    imageSource = ImageSourceGallery;
//    imageFromPicker = [self imageCroppedToFitSize:CGSizeMake(512, 512) image:info[UIImagePickerControllerEditedImage]];
//    //
//}
//
//-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
//    [picker dismissViewControllerAnimated:YES completion:NULL];
//    [self.videoCamera stopCameraCapture];
//    fromImagePicker = NO;
//    imageSource = ImageSourceGallery;
//    imageFromPicker = nil;
//    picker = nil;
//}
////- (void)viewIsResizing:(CGRect)bounds gesture:(UIPanGestureRecognizer*)gesture {
//////    [self.editTextViewObj setFrame:CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height)];
//////    [self.editTextViewObj scaleTextView:gesture location:nil];
////}
//
//#pragma mark - TextField Delegate methods
//
//- (void)focusOnTextField {
//    
////    [self.resizeAbleView showEditingHandles];
//    
//    [UIView animateWithDuration:0.5 animations:^{
//        
////
//        
//        addTextButton.alpha = 0;
//        backToCameraButton.alpha = 0;
//        trashTextButton.alpha = 1;
//        approveTextButton.alpha = 1;
//
//        self.resizeAbleView.alpha = 1;
////        resizeableView.alpha = 1;
////        resizeableView.topLeft.alpha = 1;
////        resizeableView.topRight.alpha = 1;
////        resizeableView.bottomLeft.alpha = 1;
////        resizeableView.bottomRight.alpha = 1;
////        resizeableView.rotateHandle.alpha = 1;
//    }];
//}
//
//
//- (void)focusOutTextField {
//
//    [UIView animateWithDuration:0.5 animations:^{
//        //        resizeableView.alpha = 0;
////        resizeableView.topLeft.alpha = 0;
////        resizeableView.topRight.alpha = 0;
////        resizeableView.bottomLeft.alpha = 0;
////        resizeableView.bottomRight.alpha = 0;
////        resizeableView.rotateHandle.alpha = 0;
//        
////        [self.resizeAbleView hideEditingHandles];
//        
//        trashTextButton.alpha = 0;
//        approveTextButton.alpha = 0;
//        
//        backToCameraButton.alpha = 1;
//        addTextButton.alpha = 1;
//        
//    }];
//
//}
//
//-(void)dismissKeyboard {
//    [self.editTextViewObj endEditing:TRUE];
//}
//
//- (UIImage *)imageToFitSize:(CGSize)fitSize method:(MGImageResizingMethod)resizeMethod image:(UIImage*) imageToResize
//{
//    float imageScaleFactor = 1.0;
//#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
//    if ([self respondsToSelector:@selector(scale)]) {
//        imageScaleFactor = [imageToResize scale];
//    }
//#endif
//    
//    float sourceWidth = [imageToResize size].width * imageScaleFactor;
//    float sourceHeight = [imageToResize size].height * imageScaleFactor;
//    float targetWidth = fitSize.width;
//    float targetHeight = fitSize.height;
//    BOOL cropping = !(resizeMethod == MGImageResizeScale);
//    
//    // Calculate aspect ratios
//    float sourceRatio = sourceWidth / sourceHeight;
//    float targetRatio = targetWidth / targetHeight;
//    
//    // Determine what side of the source image to use for proportional scaling
//    BOOL scaleWidth = (sourceRatio <= targetRatio);
//    // Deal with the case of just scaling proportionally to fit, without cropping
//    scaleWidth = (cropping) ? scaleWidth : !scaleWidth;
//    
//    // Proportionally scale source image
//    float scalingFactor, scaledWidth, scaledHeight;
//    if (scaleWidth) {
//        scalingFactor = 1.0 / sourceRatio;
//        scaledWidth = targetWidth;
//        scaledHeight = round(targetWidth * scalingFactor);
//    } else {
//        scalingFactor = sourceRatio;
//        scaledWidth = round(targetHeight * scalingFactor);
//        scaledHeight = targetHeight;
//    }
//    float scaleFactor = scaledHeight / sourceHeight;
//    
//    // Calculate compositing rectangles
//    CGRect sourceRect, destRect;
//    if (cropping) {
//        destRect = CGRectMake(0, 0, targetWidth, targetHeight);
//        float destX, destY;
//        if (resizeMethod == MGImageResizeCrop) {
//            // Crop center
//            destX = round((scaledWidth - targetWidth) / 2.0);
//            destY = round((scaledHeight - targetHeight) / 2.0);
//        } else if (resizeMethod == MGImageResizeCropStart) {
//            // Crop top or left (prefer top)
//            if (scaleWidth) {
//                // Crop top
//                destX = 0.0;
//                destY = 0.0;
//            } else {
//                // Crop left
//                destX = 0.0;
//                destY = round((scaledHeight - targetHeight) / 2.0);
//            }
//        } else {
//            // Crop bottom or right
//            if (scaleWidth) {
//                // Crop bottom
//                destX = round((scaledWidth - targetWidth) / 2.0);
//                destY = round(scaledHeight - targetHeight);
//            } else {
//                // Crop right
//                destX = round(scaledWidth - targetWidth);
//                destY = round((scaledHeight - targetHeight) / 2.0);
//            }
//        }
//        sourceRect = CGRectMake(destX / scaleFactor, destY / scaleFactor,
//                                targetWidth / scaleFactor, targetHeight / scaleFactor);
//    } else {
//        sourceRect = CGRectMake(0, 0, sourceWidth, sourceHeight);
//        destRect = CGRectMake(0, 0, scaledWidth, scaledHeight);
//    }
//    
//    // Create appropriately modified image.
//    UIImage *image = nil;
//#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
//    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 4.0) {
//        UIGraphicsBeginImageContextWithOptions(destRect.size, NO, 0.0); // 0.0 for scale means "correct scale for device's main screen".
//        CGImageRef sourceImg = CGImageCreateWithImageInRect([imageToResize CGImage], sourceRect); // cropping happens here.
//        image = [UIImage imageWithCGImage:sourceImg scale:0.0 orientation:imageToResize.imageOrientation]; // create cropped UIImage.
//        [image drawInRect:destRect]; // the actual scaling happens here, and orientation is taken care of automatically.
//        CGImageRelease(sourceImg);
//        image = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
//    }
//#endif
//    if (!image) {
//        // Try older method.
//        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//        CGContextRef context = CGBitmapContextCreate(NULL, fitSize.width, fitSize.height, 8, (fitSize.width * 4),
//                                                     colorSpace, kCGImageAlphaPremultipliedLast);
//        CGImageRef sourceImg = CGImageCreateWithImageInRect([imageToResize CGImage], sourceRect);
//        CGContextDrawImage(context, destRect, sourceImg);
//        CGImageRelease(sourceImg);
//        CGImageRef finalImage = CGBitmapContextCreateImage(context);
//        CGContextRelease(context);
//        CGColorSpaceRelease(colorSpace);
//        image = [UIImage imageWithCGImage:finalImage];
//        CGImageRelease(finalImage);
//    }
//    
//    return image;
//}
//
//
//- (UIImage *)imageCroppedToFitSize:(CGSize)fitSize image:(UIImage*)image
//{
//    return [self imageToFitSize:fitSize method:MGImageResizeCrop image:image];
//}
//
//
//- (UIImage *)imageScaledToFitSize:(CGSize)fitSize image:(UIImage*)image
//{
//    return [self imageToFitSize:fitSize method:MGImageResizeScale image:image];
//}
//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//    
//    [self.editTextViewObj endEditing:TRUE];
//    
//}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
