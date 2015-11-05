//
//  GLSharedCamera.m
//  shotvibe
//
//  Created by Tsah Kashkash on 15/10/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import "GLSharedCamera.h"
#import "RBVolumeButtons.h"
#import "SVAddFriendsViewController.h"
#import "ContainerViewController.h"
#import "UIImage+ImageEffects.h"



@implementation GLSharedCamera {
    ScrollDirection scrollDirection;
    int currentFilterIndex;
    int indexOfImageFromCarousel;
    int imageSource;
    BOOL backCameraOn;
    BOOL cameraIsBackView;
    BOOL isEditing;
    BOOL stateEdit;
    BOOL fromImagePicker;
    BOOL flashIsOn;
    BOOL firstTime;
    BOOL addText;
    
    UIView * mainOutPutFrame;
    UIView * touchPointCircle;
    UIImage * imageFromPicker;
    UIImage * cleanImageFromCamera;
    UIButton * flashButton;
    UIButton *flipCameraButton;
    UIButton * captureButton;
    UIButton * finalProcessButton;
    UIButton * backToCameraButton;
    UIButton * addTextButton;
    UIButton * trashTextButton;
    UIButton * approveTextButton;
    UIButton * abortUploadButton;
    
    GLFilterView * defaultFilter;
    GLFilterView * amatorkaFilter;
    GLFilterView * softEleganceFilter;
    GLFilterView * missEtikateFilter;
    
    GLFilterView * softElegance2Filter;
    GLFilterView * lateSunsetFilter;
    GLFilterView * foggyNightFilter;
    
    
    
    GLFilterView * grayScaleFilter;
    GLFilterView * sepiaFIlter;
    GLFilterView * exposureFilter;
    GLFilterView * saturationFilter;
    GLFilterView * selectiveBlurFilter;
    GLFilterView * vignetteFilter;
//    
//    GLFilterView * contrastFilter;
//    GLFilterView * brightnessFilter;
//    GLFilterView * levelsFilter;
//    
//    GLFilterView * rgbFilter;
//    GLFilterView * whiteBalance;
//    GLFilterView * sharpenFilter;
//    GLFilterView * unsharpFilter;
//    GLFilterView * gammaFilter;
//    GLFilterView * hazeFilter;
//    GLFilterView * polkaDotFIlter;
//    GLFilterView * sketchFilter;
//    GLFilterView * posterizeFilter;
//    GLFilterView * embossFilter;
//    GLFilterView * toonFilter;
    
    
    PHFetchResult *fetchResult;
    
    
    
    BOOL yes;
    
    UIImageView * dmut;
    UIView * cameraWrapper;
    
    CGFloat cameraSlideTopLimit;
    
    CGFloat firstX;
    CGFloat firstY;
    
    BOOL cameraVisble;
    
    UIVisualEffectView *effectView;
    
    CGAffineTransform dmutScaleOriginal;
    UIView * scoreBg;
//    JPSVolumeButtonHandler * volumeButtonHandler;
    RBVolumeButtons *buttonStealer;
    
    CGFloat draggedLength;
    
    
    UIImageView * glanceLogo;
}

+ (instancetype)sharedInstance {
    static GLSharedCamera *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[GLSharedCamera alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
        buttonStealer = [[RBVolumeButtons alloc] init];
//        [buttonStealer startStealingVolumeButtonEvents];
//        buttonStealer.upBlock = ^{
//            NSLog(@"vol up");
//            [self captureTapped];
//        };
//        buttonStealer.downBlock = ^{
//            NSLog(@"vol down");
//        };
        

        
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        self.isInFeedMode = NO;
        cameraVisble = NO;
        yes = YES;
        addText = NO;
        firstTime = YES;
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat width = screenRect.size.width;
        CGFloat heigth = screenRect.size.height;
        self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, heigth)];
        self.view.clipsToBounds = YES;
        self.view.backgroundColor = [UIColor whiteColor];
        
        NSString *strClass = NSStringFromClass([self class]);
        NSLog(@"%@ inited",strClass);
        
        imageSource = ImageSourceNone;
        isEditing = NO;
//        self.flashIsOn = NO;
//        self.inEditMode = NO;
        stateEdit = NO;
        fromImagePicker = NO;
        cameraIsBackView = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(dismissKeyboard)];
        //    tap.numberOfTapsRequired = 1;
        //    tap.cancelsTouchesInView = NO;
        //    tap.delegate = self;
        [self.view addGestureRecognizer:tap];
        
//        CGRect screenRect = kScreenBounds;
        CGFloat screenWidth = screenRect.size.width;
        CGFloat screenHeight = screenRect.size.height;
        
        mainOutPutFrame = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight*0.75)];
        mainOutPutFrame.backgroundColor = [UIColor blackColor];
        [self.view addSubview:mainOutPutFrame];
        
        self.arrayOfFilters = [[NSMutableArray alloc] init];
        self.latestImagesArray =[[NSMutableArray alloc] init];
        
//        currentFilterIndex = 0;
        
//        self.view.automaticallyAdjustsScrollViewInsets = NO;
        
        [self setupVideoCamera];
        
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
            [self.latestImagesArray addObject:[fetchResult objectAtIndex:r]];
        }
        //    for(PHAsset * asset in fetchResult){
        //        [self.latestImagesArray addObject:asset];
        //    }
        
        self.carousel = [[iCarousel alloc] initWithFrame:CGRectMake(0, mainOutPutFrame.frame.size.height, screenWidth, self.view.frame.size.height/5.4)];
//        self.carousel.backgroundColor = [UIColor redColor];
        self.carousel.type = iCarouselTypeLinear;
        [self.view addSubview:self.carousel];
        
        
        
        
        UIView * bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, screenHeight-self.carousel.frame.size.height, self.view.frame.size.width, self.carousel.frame.size.height)];
        
        UIView * gap = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 13)];
        gap.backgroundColor = [UIColor whiteColor];
        [bottomBar addSubview:gap];
        
        bottomBar.backgroundColor = [UIColor whiteColor];
        
        [self.view addSubview:bottomBar];
        
        
        finalProcessButton = [[UIButton alloc] initWithFrame:CGRectMake(65,40,self.view.frame.size.width*0.66 , 70)];
        finalProcessButton.alpha = 0;
        UIImage *btnImage9 = [UIImage imageNamed:@"glancePostImageIconLogo"];
        [finalProcessButton setImage:btnImage9 forState:UIControlStateNormal];
        
//        [finalProcessButton addTarget:self action:@selector(finalProcessTapped) forControlEvents:UIControlEventTouchUpInside];
        
        
        [bottomBar addSubview:finalProcessButton];
        
        
        abortUploadButton = [[UIButton alloc] initWithFrame:finalProcessButton.frame];
        abortUploadButton.alpha = 1;
        UIImage *btnImage10 = [UIImage imageNamed:@"abortImageUploadIcon"];
        [abortUploadButton setImage:btnImage10 forState:UIControlStateNormal];
        
        [abortUploadButton addTarget:self action:@selector(abortUploadButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        
        
//        [bottomBar addSubview:abortUploadButton];
        
        
        self.carousel.parentView = self.view;
        self.carousel.delegate = self;
        self.carousel.dataSource = self;
        self.carousel.backgroundColor = [UIColor clearColor];
        [self.carousel scrollByNumberOfItems:1 duration:0.3];
        
        
        
        //    self.carousel.itemWidth = 180;
        //    self.carousel.backgroundColor = [UIColor blueColor];
        UIImageView * bricksBg = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.mainScrollView.frame.size.height
                                                                               , [[UIScreen mainScreen] bounds].size.width, self.view.frame.size.height-self.mainScrollView.frame.size.height)];
        
        UIImage * i = [UIImage imageNamed:@"Bricks"];
//        bricksBg.image = [i imageNamed:@"Bricks"];
        UIImage * screenShot = [i applyBlurWithRadius:0 tintColor:[UIColor colorWithWhite:0.6 alpha:0.2] saturationDeltaFactor:1.0 maskImage:nil];
        bricksBg.image = screenShot;
        
//        UIBlurEffect *blurV = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        
        // add effect to an effect view
//        UIVisualEffectView * brikcsBlur = [[UIVisualEffectView alloc]initWithEffect:blurV];
//        brikcsBlur.frame = bricksBg.frame;
//        effectView.alpha = 0;
        
        [self.view addSubview:bricksBg];
//        [self.view addSubview:brikcsBlur];
        [self.view addSubview:self.carousel];
        
        
        UIView * bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.mainScrollView.frame.size.height+self.carousel.frame.size.height, self.view.frame.size.width, self.view.frame.size.height-(self.mainScrollView.frame.size.height+self.carousel.frame.size.height))];

        bottomLine.backgroundColor = [UIColor clearColor];
        [self.view addSubview:bottomLine];
        
//        bottomLine
        self.animatedView = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-100, 0, 100, 50)];
        [self.animatedView addTarget:self action:@selector(finalProcessTapped) forControlEvents:UIControlEventTouchUpInside];
//        self.animatedView.backgroundColor = [UIColor blackColor];
        self.animatedView.titleLabel.font = [UIFont fontWithName:@"GothamRounded-Bold" size:55];
//        self.animatedView.frame = CGRectMake(0, 0, 100, 50);
        [self.animatedView setTitle:@">>" forState:UIControlStateNormal];
//        self.
//        [self.animatedView setTitle: @"Click to start or stop the animation" forState:UIControlStateNormal];
        [self.animatedView setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        self.shadowAnimation = [JTSlideShadowAnimation new];
        self.shadowAnimation.animatedView = self.animatedView;
        self.shadowAnimation.shadowWidth = 20.;
        self.animatedView.alpha = 0;
        [bottomLine addSubview:self.animatedView];
        //[self.shadowAnimation start];
        
        
        
        
        
//        self.editPallette = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenWidth)];
//        
//        self.editPallette.backgroundColor = [UIColor clearColor];
        
        //    [mainOutPutFrame addSubview:self.editPallette];
        
        //    self.editPalletteImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenWidth)];
        //    self.editPalletteImageView.userInteractionEnabled = YES;
        //    self.editPalletteImageView.contentMode = UIViewContentModeScaleAspectFill;
        //    self.editPallette.clipsToBounds = YES;
        ////    self.editPalletteImageView.backgroundColor = [UIColor redColor];
        //    [self.editPallette addSubview:self.editPalletteImageView];
        
        
        //    self.resizeAbleView = [GLResizeableView];
        
        [self createResizableTextView];
        
        
        
        
        
        
        
        
        
        
        captureButton = [[UIButton alloc] initWithFrame:CGRectMake(10,self.mainScrollView.frame.size.height-80, 70, 70)];
        UIImage *btnImage3 = [UIImage imageNamed:@"CaptureButton"];
        [captureButton setImage:btnImage3 forState:UIControlStateNormal];
        
        [captureButton addTarget:self action:@selector(captureTapped) forControlEvents:UIControlEventTouchUpInside];
        
        
        [self.view addSubview:captureButton];
        
        
        
        backToCameraButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 32, 40, 30)];
        backToCameraButton.userInteractionEnabled = YES;
        [backToCameraButton addTarget:self action:@selector(backToCameraFromEditPallette:) forControlEvents:UIControlEventTouchUpInside];
        UIImage *btnImage4 = [UIImage imageNamed:@"backToCameraIcon"];
        
        backToCameraButton.alpha = 0;
        //    [flipCameraButton addTarget:self action:@selector(flipCamera) forControlEvents:UIControlEventTouchUpInside];
        
        [backToCameraButton setImage:btnImage4 forState:UIControlStateNormal];
        [mainOutPutFrame addSubview:backToCameraButton];
        
        
        
        
        addTextButton = [[UIButton alloc] initWithFrame:CGRectMake(screenWidth - 50, 25, 38, 38)];
        //    addTextButton.backgroundColor = [UIColor blueColor];
        UIImage *btnImage5 = [UIImage imageNamed:@"addTextIcon"];
        addTextButton.alpha = 0;
        [addTextButton addTarget:self action:@selector(addTextToImageTapped) forControlEvents:UIControlEventTouchUpInside];
        [addTextButton setImage:btnImage5 forState:UIControlStateNormal];
        [mainOutPutFrame addSubview:addTextButton];
        
        trashTextButton = [[UIButton alloc] initWithFrame:CGRectMake(screenWidth - 50, 25, 38, 38)];
        //    addTextButton.backgroundColor = [UIColor blueColor];
        UIImage *btnImage6 = [UIImage imageNamed:@"addTextTrashIcon"];
        trashTextButton.alpha = 0;
        [trashTextButton addTarget:self action:@selector(trashTheText) forControlEvents:UIControlEventTouchUpInside];
        [trashTextButton setImage:btnImage6 forState:UIControlStateNormal];
        [mainOutPutFrame addSubview:trashTextButton];
        
        
        approveTextButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 25, 40, 30)];
        approveTextButton.userInteractionEnabled = YES;
        [approveTextButton addTarget:self action:@selector(approveTextTapped) forControlEvents:UIControlEventTouchUpInside];
        UIImage *btnImage7 = [UIImage imageNamed:@"approveTextIcon"];
        
        approveTextButton.alpha = 0;
        //    [flipCameraButton addTarget:self action:@selector(flipCamera) forControlEvents:UIControlEventTouchUpInside];
        
        [approveTextButton setImage:btnImage7 forState:UIControlStateNormal];
        [mainOutPutFrame addSubview:approveTextButton];
        
//         Listen for keyboard appearances and disappearances
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
        
        touchPointCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        
        UIImage * image = [UIImage imageNamed:@"CameraFocusIcon"];
        UIImageView * iv = [[UIImageView alloc] initWithFrame:touchPointCircle.frame];
        iv.image = image;
        [touchPointCircle addSubview:iv];
        
        
        touchPointCircle.backgroundColor = [UIColor clearColor];
        //        touchPointCircle.layer.cornerRadius = 30;
        touchPointCircle.alpha = 0;
        
        [mainOutPutFrame addSubview:touchPointCircle];

        
        [self.videoCamera startCameraCapture];
        
        for(GLFilterView * filter in self.arrayOfFilters){
            filter.title.alpha = 0 ;
        }
        
        self.view.userInteractionEnabled = YES;
//        [self.videoCamera rotateCamera];
        
        
        
        ShotVibeAppDelegate *appDelegate = (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        
        
        
        self.cameraViewBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, (self.view.frame.size.height/3))];
        
        
//            cameraViewBackground.backgroundColor = [UIColor orangeColor];
        //    cameraViewBackground.userInteractionEnabled = NO;
        
        //    [self.view addSubview:cameraViewBackground];
        
        cameraWrapper = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height/3)];
        cameraWrapper.clipsToBounds = YES;
        //    cameraWrapper.backgroundColor = [UIColor orangeColor];
        
//        GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
        //    glcamera.view.clipsToBounds = NO;
        //    glcamera.view.alpha = 0;
        [cameraWrapper addSubview:self.view];
        [self.cameraViewBackground addSubview:cameraWrapper];
//        [appDelegate.window addSubview:self.cameraViewBackground];
        
        
        
      
        
        
        dmut = [[UIImageView alloc] initWithFrame:CGRectMake(60, ([UIScreen mainScreen].bounds.size.height/3)-86, 256, 104)];
        dmut.userInteractionEnabled = YES;
        dmut.image = [UIImage imageNamed:@"Dmut"];
        [self.cameraViewBackground addSubview:dmut];
        dmutScaleOriginal = dmut.transform;
        
        UIPanGestureRecognizer * gest = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dmutDragged:)];
        
        [dmut addGestureRecognizer:gest];
        
        cameraSlideTopLimit = [dmut center].y;
        
        UITapGestureRecognizer * scoreTapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scoreTapped:)];
        
        scoreBg = [[UIView alloc] initWithFrame:CGRectMake(20, 40, 40, 40)];
        scoreBg.backgroundColor = [UIColor whiteColor];
        scoreBg.layer.cornerRadius = 20;
        
        [scoreBg addGestureRecognizer:scoreTapped];
        
        UILabel * score = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        score.text = @"156";
        score.textAlignment = NSTextAlignmentCenter;
        score.textColor = [UIColor blackColor];
        [scoreBg addSubview:score];
        
//        [cameraViewBackground addSubview:scoreBg];
        
        self.picYourGroup = [[UILabel alloc] initWithFrame:CGRectMake(20, 35, self.view.frame.size.width, 40)];
        self.picYourGroup.text = @"pic your group";
        self.picYourGroup.textColor = [UIColor whiteColor];
        self.picYourGroup.font = [UIFont fontWithName:@"GothamRounded-Bold" size:24];
        
        glanceLogo = [[UIImageView alloc] initWithFrame:CGRectMake((self.picYourGroup.frame.size.width)-self.view.frame.size.width*0.3, 35, self.view.frame.size.width*0.25, 40)];
        glanceLogo.image = [UIImage imageNamed:@"glanceMainLogo"];
        

        [self.cameraViewBackground addSubview:self.picYourGroup];
        [self.cameraViewBackground addSubview:glanceLogo];
        
        
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        
        // add effect to an effect view
        effectView = [[UIVisualEffectView alloc]initWithEffect:blur];
        effectView.frame = CGRectMake(0, 0, self.view.frame.size.width, 80);
        effectView.alpha = 0;
        
        
        self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(13, 20, 40, 70)];
        
        //13, 30, 20, 30
        
        self.backButton.alpha = 0;
        [self.backButton setImage:[UIImage imageNamed:@"feedBackIcon"] forState:UIControlStateNormal];
        self.backButton.imageEdgeInsets = UIEdgeInsetsMake(-10, -5, 0, 0);
        
        //        [backButton targetForAction:@selector(backButton) withSender:nil];
        [self.backButton addTarget:self action:@selector(backButtonPressed)
                  forControlEvents:UIControlEventTouchUpInside];
        
        self.membersButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-43, 30, 30, 30)];
        self.membersButton.alpha = 0;
        //        [backButton targetForAction:@selector(membersButton) withSender:nil];
        [self.membersButton addTarget:self action:@selector(membersButtonPressed)
                     forControlEvents:UIControlEventTouchUpInside];
        
        [self.membersButton setBackgroundImage:[UIImage imageNamed:@"feedMembersIcon"] forState:UIControlStateNormal];
        
        [effectView addSubview:self.backButton];
        [effectView addSubview:self.membersButton];
        [self.cameraViewBackground addSubview:effectView];
        
//        cameraViewBackground.backgroundColor = [UIColor purpleColor];
        
        
        
        
    }
    return self;
}

-(void)showGlCameraView {

    [UIView animateWithDuration:0.2 animations:^{
        self.cameraViewBackground.alpha = 1;
    }];
    
}

-(void)hideGlCameraView {

    [UIView animateWithDuration:0.2 animations:^{
        self.cameraViewBackground.alpha = 0;
    }];
    
    
    

}

//-(void)scoreTapped:(UITapGestureRecognizer*)gest {
//    
//    ShotVibeAppDelegate *appDelegate = (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];
//
//    UIWebView * webview = [[UIWebView alloc] initWithFrame:CGRectMake(0, -self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
//    [appDelegate.window addSubview:webview];
//    webview.backgroundColor = [UIColor purpleColor];
//    [webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://matthew.wagerfield.com/parallax/"]]];
//    
//    [UIView animateWithDuration:0.2 animations:^{
//        webview.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
//    }];
//    
//
//
//}

-(void)dmutDragged:(UIPanGestureRecognizer*)gest {
    
    
    CGPoint location = [gest translationInView:self.view];
    
    if(gest.state == UIGestureRecognizerStateBegan){
        //
        
//        draggedLength = 0;
        
        firstX = [[gest view] center].x;
        firstY = [[gest view] center].y;
        
        //
    } else if(gest.state == UIGestureRecognizerStateChanged){
        
        
        
        
        if(firstY+location.y > cameraSlideTopLimit ){
            
            if(firstY+location.y < self.view.frame.size.height - dmut.frame.size.height){
                
                [cameraWrapper setFrame:CGRectMake(0, 0, cameraWrapper.frame.size.width, firstY+location.y+35)];
                [self.cameraViewBackground setFrame:CGRectMake(0, 0, self.cameraViewBackground.frame.size.width, firstY+location.y+35)];
                
                //        dmut.frame = CGRectMake(27, firstY+location.y
                //                                , 320, 110);
                dmut.center = CGPointMake(firstX, firstY+location.y);
                
            } else {
                
                [cameraWrapper setFrame:CGRectMake(0, 0, cameraWrapper.frame.size.width, firstY+location.y+35)];
                [self.cameraViewBackground setFrame:CGRectMake(0, 0, self.cameraViewBackground.frame.size.width, firstY+location.y+35)];
                
            }
            
            
            
        }
        
        
        //
        //
    } else if(gest.state == UIGestureRecognizerStateEnded){
        
        
        dmut.userInteractionEnabled = NO;
        
        CGPoint velocity = [gest velocityInView:self.view];
        
        if (velocity.y < 0)   // panning down
        {
            
            
            [UIView animateWithDuration:0.3 animations:^(){
                
                
                self.picYourGroup.alpha = 1;
                glanceLogo.alpha = 1;
                
                if(self.isInFeedMode){
                
//                    [[self videoCamera] stopCameraCapture];
                    [cameraWrapper setFrame:CGRectMake(0, 0, cameraWrapper.frame.size.width, 60)];
                    effectView.alpha = 1;
                    dmut.center = CGPointMake(firstX, 60);
                    [self.cameraViewBackground setFrame:CGRectMake(0, 0, self.cameraViewBackground.frame.size.width, 60)];
                    self.backButton.alpha=1;
                    self.membersButton.alpha=1;
                    
                } else {
                    
                    
//                    [[self videoCamera] startCameraCapture];
                    [cameraWrapper setFrame:CGRectMake(0, 0, cameraWrapper.frame.size.width, self.view.frame.size.height/3)];
                    dmut.center = CGPointMake(firstX, cameraSlideTopLimit);
                    [self.cameraViewBackground setFrame:CGRectMake(0, 0, self.cameraViewBackground.frame.size.width, self.view.frame.size.height/3)];
                }
                
                
                
//                draggedLength = firstY+location.y;
              
//                if(firstY+location.y >self.view.frame.size.height/2){
                
//                if(draggedLength > self.view.frame.size.height*0.65){
                
//                    [self toggleCamera];
                
//                }
                
                
                
                
                
                
//                }
                if(!self.isInFeedMode){
                    dmut.transform = CGAffineTransformIdentity;
                }
                
                
            } completion:^(BOOL finished) {
                if(self.isInFeedMode){
                    [[self videoCamera] stopCameraCapture];
                }
                
                NSLog(@"animation completed1");
//                [UIView animateWithDuration:0.2 animations:^{
//                    if(!self.isInFeedMode){
//                        dmut.transform = CGAffineTransformIdentity;
//                    }
                }];
                [self toggleCamera:YES];
                [[ContainerViewController sharedInstance] lockScrolling:NO];
                dmut.userInteractionEnabled = YES;
                
//            }];
            //            self.brightness = self.brightness -.02;
            //     NSLog (@"Decreasing brigntness in pan");
        }
        else                // panning up
        {
            
            [UIView animateWithDuration:0.3 animations:^(){
                
                self.picYourGroup.alpha = 0;
                glanceLogo.alpha = 0;
                
                [cameraWrapper setFrame:CGRectMake(0, 0, cameraWrapper.frame.size.width, self.view.frame.size.height)];
                
                [self.cameraViewBackground setFrame:CGRectMake(0, 0, self.cameraViewBackground.frame.size.width, self.view.frame.size.height)];
                
                if(self.isInFeedMode){
                    self.backButton.alpha=0;
                    self.membersButton.alpha=0;
                    effectView.alpha = 0;
                    dmut.center = CGPointMake(firstX, self.view.frame.size.height-187.5);
                } else {
                    dmut.center = CGPointMake(firstX, self.view.frame.size.height-187.5);
                }
                
                
//                if(firstY+location.y >self.view.frame.size.height/2){
//                if(draggedLength > self.view.frame.size.height*0.65){
                
//                    [self toggleCamera];
                
//                }
                
//                }
                if(!self.isInFeedMode){
                    CGFloat xScale = dmut.transform.a;
//                    CGFloat yScale = dmut.transform.d;
                    
                    
                    if(xScale == 1){
                        dmut.transform = CGAffineTransformScale(dmut.transform, 0.6, 0.6);
                    }
                    
                }
            } completion:^(BOOL finished) {
                [[self videoCamera] startCameraCapture];
                
                [UIView animateWithDuration:0.2 animations:^{
//                    dmut.transform = CGAffineTransformScale(dmut.transform, 0.6, 0.6);
                }];
                NSLog(@"animation completed2");
                [[ContainerViewController sharedInstance] lockScrolling:YES];
                [self toggleCamera:NO];
                dmut.userInteractionEnabled = YES;
            }];
            
            //            self.brightness = self.brightness +.02;
            //  NSLog (@"Increasing brigntness in pan");
            
        }
        
        
        
    }
    
}

-(void)setCameraInMain {
    self.isInFeedMode = NO;
    flipCameraButton.alpha = 0;
    flashButton.alpha = 0;
    glanceLogo.alpha = 1;
    self.picYourGroup.alpha = 1;
    [self toggleCamera:YES];
    
    
    [[self videoCamera] startCameraCapture];
    [UIView animateWithDuration:0.2 animations:^{
        dmut.transform = CGAffineTransformIdentity;
        effectView.alpha = 0;
        
        self.cameraViewBackground.frame = CGRectMake(0, 0, self.view.frame.size.width, (self.view.frame.size.height/3));
        cameraWrapper.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height/3);
        dmut.frame = CGRectMake(60, ([UIScreen mainScreen].bounds.size.height/3)-86, 256, 104);
    }];
    
}

- (void)setCameraInFeed {

    self.isInFeedMode = YES;
    [[self videoCamera] stopCameraCapture];
    [UIView animateWithDuration:0.2 animations:^{
        
                            effectView.alpha = 1;
                            self.backButton.alpha = 1;
                            self.membersButton.alpha = 1;
        
        
        dmut.frame = CGRectMake(dmut.frame.origin.x, 20, dmut.frame.size.width, dmut.frame.size.height);
        effectView.alpha = 1;
        [self.cameraViewBackground bringSubviewToFront:effectView];
        
        //        if(!dmutScaleOriginal){
        //            dmutScaleOriginal = dmut.transform;
        //        }
        
        //                    if(needTransform)
        //                    {
        dmut.transform = CGAffineTransformScale(dmut.transform, 0.60, 0.60);
        dmut.center = CGPointMake(dmut.center.x, dmut.center.y-12.5);
        //                    } else {
        ////                        dmut.transform = CGAffineTransformScale(dmut.transform, 0.60, 0.60);
        //                        dmut.center = CGPointMake(dmut.center.x, dmut.center.y+8);
        //                    }
        ////                    dmut.transform = CGAffineTransformScale(dmut.transform, 0.60, 0.60);
        //                    dmut.center = CGPointMake(dmut.center.x, dmut.center.y+8);
        
        cameraWrapper.frame = CGRectMake(0, 0, cameraWrapper.frame.size.width, 80);
        self.cameraViewBackground.frame = CGRectMake(0, 0, self.cameraViewBackground.frame.size.width, 80);
        
        
        [self.cameraViewBackground bringSubviewToFront:dmut];
    }];

}

-(void)setInFeedMode:(BOOL)feed dmutNeedTransform:(BOOL)needTransform {
    
    if(feed){
    
        [[self videoCamera] stopCameraCapture];
                // create effect
        
        
        
        
        
                [UIView animateWithDuration:0.2 animations:^{
        
//                    effectView.alpha = 1;
//                    self.backButton.alpha = 1;
//                    self.membersButton.alpha = 1;
        
        
                    dmut.frame = CGRectMake(dmut.frame.origin.x, 20, dmut.frame.size.width, dmut.frame.size.height);
                    effectView.alpha = 1;
        
        //        if(!dmutScaleOriginal){
        //            dmutScaleOriginal = dmut.transform;
        //        }
        
//                    if(needTransform)
//                    {
                        dmut.transform = CGAffineTransformScale(dmut.transform, 0.60, 0.60);
                        dmut.center = CGPointMake(dmut.center.x, dmut.center.y-12.5);
//                    } else {
////                        dmut.transform = CGAffineTransformScale(dmut.transform, 0.60, 0.60);
//                        dmut.center = CGPointMake(dmut.center.x, dmut.center.y+8);
//                    }
////                    dmut.transform = CGAffineTransformScale(dmut.transform, 0.60, 0.60);
//                    dmut.center = CGPointMake(dmut.center.x, dmut.center.y+8);
        
                    cameraWrapper.frame = CGRectMake(0, 0, cameraWrapper.frame.size.width, 80);
                    self.cameraViewBackground.frame = CGRectMake(0, 0, self.cameraViewBackground.frame.size.width, 80);
                
                
                    [self.cameraViewBackground bringSubviewToFront:dmut];
                
            }];
        
    } else {
        
        [[self videoCamera] startCameraCapture];
                [UIView animateWithDuration:0.2 animations:^{
                    dmut.transform = CGAffineTransformIdentity;
                    effectView.alpha = 0;
        
                    self.cameraViewBackground.frame = CGRectMake(0, 0, self.view.frame.size.width, (self.view.frame.size.height/3));
                    cameraWrapper.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height/3);
                    dmut.frame = CGRectMake(60, ([UIScreen mainScreen].bounds.size.height/3)-86, 256, 104);
                }];
        
    }
    self.isInFeedMode = feed;
    
//    if(self.isInFeedMode){
//    
//        [[self videoCamera] startCameraCapture];
//        [UIView animateWithDuration:0.2 animations:^{
//            dmut.transform = CGAffineTransformIdentity;
//            effectView.alpha = 0;
//            
//            self.cameraViewBackground.frame = CGRectMake(0, 0, self.view.frame.size.width, (self.view.frame.size.height/3)+20);
//            cameraWrapper.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height/3);
//            dmut.frame = CGRectMake(60, ([UIScreen mainScreen].bounds.size.height/3)-86, 256, 104);
//        }];
//        
//    } else {
//        
//        [[self videoCamera] stopCameraCapture];
//        // create effect
//        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
//    
//        // add effect to an effect view
//        effectView = [[UIVisualEffectView alloc]initWithEffect:blur];
//        effectView.frame = CGRectMake(0, 0, self.view.frame.size.width, 80);
//        effectView.alpha = 0;
//        [self.cameraViewBackground addSubview:effectView];
//        
//        self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(13, 30, 20, 30)];
//        [self.backButton setBackgroundImage:[UIImage imageNamed:@"feedBackIcon"] forState:UIControlStateNormal];
////        [backButton targetForAction:@selector(backButton) withSender:nil];
//        [self.backButton addTarget:self action:@selector(backButtonPressed)
//              forControlEvents:UIControlEventTouchUpInside];
//        
//        self.membersButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-43, 30, 30, 30)];
////        [backButton targetForAction:@selector(membersButton) withSender:nil];
//        [self.membersButton addTarget:self action:@selector(membersButtonPressed)
//             forControlEvents:UIControlEventTouchUpInside];
//        
//        [self.membersButton setBackgroundImage:[UIImage imageNamed:@"feedMembersIcon"] forState:UIControlStateNormal];
//        
//        [self.cameraViewBackground addSubview:self.backButton];
//        [self.cameraViewBackground addSubview:self.membersButton];
//
//    
//        [UIView animateWithDuration:0.2 animations:^{
//        
//        
//       
//        
//            dmut.frame = CGRectMake(dmut.frame.origin.x, 20, dmut.frame.size.width, dmut.frame.size.height);
//            effectView.alpha = 1;
//        
////        if(!dmutScaleOriginal){
////            dmutScaleOriginal = dmut.transform;
////        }
//        
//            dmut.transform = CGAffineTransformScale(dmut.transform, 0.60, 0.60);
//            dmut.center = CGPointMake(dmut.center.x, dmut.center.y-12.5);
//        
//            cameraWrapper.frame = CGRectMake(0, 0, cameraWrapper.frame.size.width, 80);
//            self.cameraViewBackground.frame = CGRectMake(0, 0, self.cameraViewBackground.frame.size.width, 80);
//        
//        
//            [self.cameraViewBackground bringSubviewToFront:dmut];
//        
//    }];
//    }
//    
//    self.isInFeedMode = !self.isInFeedMode;

}

-(void)membersButtonPressed {
    

    [self.delegate membersPressed];
    
//    [UIView animateWithDuration:0.2 animations:^{
//        self.backButton.alpha=0;
//        self.membersButton.alpha=0;
//        effectView.alpha = 0;
//        glanceLogo.alpha = 1;
//        picYourGroup.alpha = 1;
//    }];
}

-(void)backButtonPressed {
    [self.delegate backPressed];
}

-(void)toggleCamera:(BOOL)on {

    [UIView animateWithDuration:0.2 animations:^{
        
        if(on){
            for(GLFilterView * filterView in self.arrayOfFilters){
                filterView.title.alpha = 0;
            }
            flipCameraButton.alpha = 0;
            flashButton.alpha = 0;
            scoreBg.alpha = 1;
        } else {
            for(GLFilterView * filterView in self.arrayOfFilters){
                filterView.title.alpha = 1;
            }
            flipCameraButton.alpha = 1;
            flashButton.alpha = 1;
            scoreBg.alpha = 0;
        }
        
    }];
    
    
//    cameraVisble = !cameraVisble;
}

-(void)abortUploadButtonTapped {
    [self hideCamera];
}

- (void)setupVideoCamera {
    
    self.videoCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionBack];
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    self.videoCamera.horizontallyMirrorRearFacingCamera = NO;
    
    [self createFiltersViews];
    [self createMainScrollView];
  
    
    
}

-(void)focusCameraToPoint:(UITapGestureRecognizer *)tgr location:(CGPoint)location {
    
    if(!isEditing){
    if (tgr.state == UIGestureRecognizerStateRecognized) {
        //        CGPoint location = [tgr locationInView:self.focusLayer];
        
        AVCaptureDevice *device = [self.videoCamera inputCamera];
        CGPoint pointOfInterest = CGPointMake(.5f, .5f);
        //            NSLog(@"taplocation x = %f y = %f", location.x, location.y);
        
        touchPointCircle.frame = CGRectMake(location.x-30, location.y-30, 60, 60);
        touchPointCircle.alpha = 1;
        [UIView animateWithDuration:0.5 animations:^{
            touchPointCircle.transform = CGAffineTransformScale(touchPointCircle.transform, 0.7, 0.7);
            touchPointCircle.alpha = 0;
        }];
        touchPointCircle.transform = CGAffineTransformIdentity;
        
        CGSize frameSize = self.view.frame.size;
        
        if (self.videoCamera.cameraPosition == AVCaptureDevicePositionFront) {
            location.x = frameSize.width - location.x;
        }
        
        pointOfInterest = CGPointMake(location.y / frameSize.height, 1.f - (location.x / frameSize.width));
        
        
        if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            NSError *error;
            if ([device lockForConfiguration:&error]) {
                [device setFocusPointOfInterest:pointOfInterest];
                
                [device setFocusMode:AVCaptureFocusModeAutoFocus];
                
                if([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
                {
                    [device setExposurePointOfInterest:pointOfInterest];
                    [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
                }
                
                [device unlockForConfiguration];
                
                //                    NSLog(@"FOCUS OK");
            } else {
                //                    NSLog(@"ERROR = %@", error);
            }
        }
    }
    }
    
    
    
}

-(void)createResizableTextView {

    CGRect screenRect = kScreenBounds;
    CGFloat screenWidth = screenRect.size.width;
//    CGFloat screenHeight = screenRect.size.height;
    
    CGRect gripFrame = CGRectMake(0, 0, screenWidth/2, screenWidth/2);
    self.resizeAbleView = [[GLResizeableView alloc] initWithFrame:gripFrame];
    UIView *contentView = [[UIView alloc] initWithFrame:gripFrame];
    [contentView setBackgroundColor:[UIColor clearColor]];
    self.resizeAbleView.contentView = contentView;
    self.resizeAbleView.delegate = self;
    self.resizeAbleView.parentView = self.view;
    //    [self.resizeAbleView hideEditingHandles];
    
    self.resizeAbleView.alpha = 0;
    
    
    CGFloat minWidth  = 100;
    CGFloat minHeight = 50;
    
    UITapGestureRecognizer * tapOnWindow = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resizeableTapped:)];
    [self.resizeAbleView addGestureRecognizer:tapOnWindow];
    
    
    
    
//    [self.resizeAbleView addGestureRecognizer:tapOnWindow];
    //    [self.resizeAbleView addGestureRecognizer:resizepan];
    
    self.editTextViewObj = [[RJTextView alloc] initWithFrame:self.resizeAbleView.bounds
                                                 defaultText:@"This is Hey from Glance!"
                                                        font:[UIFont systemFontOfSize:14.f]
                                                       color:[UIColor blackColor]
                                                     minSize:CGSizeMake(minWidth, minHeight)];
    self.editTextViewObj.userInteractionEnabled = NO;
    self.editTextViewObj.delegate = self;
    self.editTextViewObj.parentView = self.view;
    [self.resizeAbleView addSubview:self.editTextViewObj];
    
    
    [mainOutPutFrame addSubview:self.resizeAbleView];
    
    //    self.editPallette.hidden = YES;
    self.editPallette.alpha = 0;

    

}

- (void)createFiltersViews {
    
    
    
    defaultFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_NOFILTER];
    defaultFilter.delegate = self;
    [self.videoCamera addTarget:defaultFilter.filter];
    [self.arrayOfFilters addObject:defaultFilter];
    
    amatorkaFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_AMATORKA];
    amatorkaFilter.delegate = self;
        [self.videoCamera addTarget:amatorkaFilter.filter];
    [self.arrayOfFilters addObject:amatorkaFilter];
    
    softEleganceFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_SOFTELEGANCE];
    softEleganceFilter.delegate = self;
        [self.videoCamera addTarget:softEleganceFilter.filter];
    [self.arrayOfFilters addObject:softEleganceFilter];
    
    missEtikateFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_MISSETIKATE];
    missEtikateFilter.delegate = self;
    //    [self.videoCamera addTarget:missEtikateFilter.filter];
    [self.arrayOfFilters addObject:missEtikateFilter];
    
    foggyNightFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_FOGGYNIGHT];
    foggyNightFilter.delegate = self;
    //    [self.videoCamera addTarget:softEleganceFilter.filter];
    [self.arrayOfFilters addObject:foggyNightFilter];
    
    lateSunsetFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_LATESUNSET];
    lateSunsetFilter.delegate = self;
    //    [self.videoCamera addTarget:softEleganceFilter.filter];
    [self.arrayOfFilters addObject:lateSunsetFilter];
    
    sepiaFIlter = [[GLFilterView alloc] initWithType:GPUIMAGE_SEPIA];
    sepiaFIlter.delegate = self;
    //    [self.videoCamera addTarget:sepiaFIlter.filter];
    [self.arrayOfFilters addObject:sepiaFIlter];
    
    grayScaleFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_GRAYSCALE];
    grayScaleFilter.delegate = self;
    //    [self.videoCamera addTarget:grayScaleFilter.filter];
    [self.arrayOfFilters addObject:grayScaleFilter];
    
    exposureFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_EXPOSURE];
    exposureFilter.delegate = self;
//    [self.videoCamera addTarget:exposureFilter.filter];
    [self.arrayOfFilters addObject:exposureFilter];
    
    saturationFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_SATURATION];
    saturationFilter.delegate = self;
//    [self.videoCamera addTarget:saturationFilter.filter];
    [self.arrayOfFilters addObject:saturationFilter];
    
    selectiveBlurFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_GAUSSIAN_SELECTIVE];
    selectiveBlurFilter.delegate = self;
    //    [self.videoCamera addTarget:selectiveBlurFilter.filter];
    [self.arrayOfFilters addObject:selectiveBlurFilter];
    
    vignetteFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_VIGNETTE];
    vignetteFilter.delegate = self;
    //    [self.videoCamera addTarget:vignetteFilter.filter];
    [self.arrayOfFilters addObject:vignetteFilter];
    
//    softElegance2Filter = [[GLFilterView alloc] initWithType:GPUIMAGE_SOFTELEGANCE2];
//    softElegance2Filter.delegate = self;
//    //    [self.videoCamera addTarget:softEleganceFilter.filter];
//    [self.arrayOfFilters addObject:softElegance2Filter];
    
    
    
    
    
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
//    //    [self.videoCamera addTarget:levelsFilter.filter];
//    [self.arrayOfFilters addObject:levelsFilter];
    
    
    
    
    
//    sharpenFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_SHARPEN];
//    sharpenFilter.delegate = self;
//    //    [self.videoCamera addTarget:sharpenFilter.filter];
//    [self.arrayOfFilters addObject:sharpenFilter];
//    
//    gammaFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_GAMMA];
//    gammaFilter.delegate = self;
//    //    [self.videoCamera addTarget:gammaFilter.filter];
//    [self.arrayOfFilters addObject:gammaFilter];
//    
//    hazeFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_HAZE];
//    hazeFilter.delegate = self;
//    //    [self.videoCamera addTarget:hazeFilter.filter];
//    [self.arrayOfFilters addObject:hazeFilter];
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
//    sketchFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_SKETCH];
//    sketchFilter.delegate = self;
//    //    [self.videoCamera addTarget:sketchFilter.filter];
//    [self.arrayOfFilters addObject:sketchFilter];
//    
//    embossFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_EMBOSS];
//    embossFilter.delegate = self;
//    //    [self.videoCamera addTarget:embossFilter.filter];
//    [self.arrayOfFilters addObject:embossFilter];
    
    
    
    
//    toonFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_TOON];
//    toonFilter.delegate = self;
//    //    [self.videoCamera addTarget:toonFilter.filter];
//    [self.arrayOfFilters addObject:toonFilter];
    
    
    
}

#pragma mark - FitlersScrollViewMethods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    
    if (self.lastContentOffset > scrollView.contentOffset.y)
        scrollDirection = ScrollDirectionUp;
    else if (self.lastContentOffset < scrollView.contentOffset.y)
        scrollDirection = ScrollDirectionDown;
    
    self.lastContentOffset = scrollView.contentOffset.y;
    
    
    
    if(scrollView.tag == ScrollerTypeFontsScroller){
        
    }
    
    
    if(scrollView.tag == ScrollerTypeFilterScroller){
        
        
        
        CGFloat offsetY = scrollView.contentOffset.y;
        
        
        
        [defaultFilter.container setContentOffset:CGPointMake(0, -offsetY)];
        defaultFilter.sliderView.frame = CGRectMake(0, -offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [amatorkaFilter.container setContentOffset:CGPointMake(0, (amatorkaFilter.container.frame.size.height*1)-offsetY)];
        amatorkaFilter.sliderView.frame = CGRectMake(0, (amatorkaFilter.container.frame.size.height*1)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [softEleganceFilter.container setContentOffset:CGPointMake(0, (softEleganceFilter.container.frame.size.height*2)-offsetY)];
        softEleganceFilter.sliderView.frame = CGRectMake(0, (softEleganceFilter.container.frame.size.height*2)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [missEtikateFilter.container setContentOffset:CGPointMake(0, (missEtikateFilter.container.frame.size.height*3)-offsetY)];
        missEtikateFilter.sliderView.frame = CGRectMake(0, (missEtikateFilter.container.frame.size.height*3)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [foggyNightFilter.container setContentOffset:CGPointMake(0, (foggyNightFilter.container.frame.size.height*4)-offsetY)];
        foggyNightFilter.sliderView.frame = CGRectMake(0, (foggyNightFilter.container.frame.size.height*4)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [lateSunsetFilter.container setContentOffset:CGPointMake(0, (lateSunsetFilter.container.frame.size.height*5)-offsetY)];
        lateSunsetFilter.sliderView.frame = CGRectMake(0, (lateSunsetFilter.container.frame.size.height*5)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [sepiaFIlter.container setContentOffset:CGPointMake(0, (sepiaFIlter.container.frame.size.height*6)-offsetY)];
        sepiaFIlter.sliderView.frame = CGRectMake(0, (sepiaFIlter.container.frame.size.height*6)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [grayScaleFilter.container setContentOffset:CGPointMake(0, (grayScaleFilter.container.frame.size.height*7)-offsetY)];
        grayScaleFilter.sliderView.frame = CGRectMake(0, (grayScaleFilter.container.frame.size.height*7)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [exposureFilter.container setContentOffset:CGPointMake(0, (exposureFilter.container.frame.size.height*8)-offsetY)];
        exposureFilter.sliderView.frame = CGRectMake(0, (exposureFilter.container.frame.size.height*8)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [saturationFilter.container setContentOffset:CGPointMake(0, (saturationFilter.container.frame.size.height*9)-offsetY)];
        saturationFilter.sliderView.frame = CGRectMake(0, (saturationFilter.container.frame.size.height*9)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [selectiveBlurFilter.container setContentOffset:CGPointMake(0, (selectiveBlurFilter.container.frame.size.height*10)-offsetY)];
        selectiveBlurFilter.sliderView.frame = CGRectMake(0, (selectiveBlurFilter.container.frame.size.height*10)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [vignetteFilter.container setContentOffset:CGPointMake(0, (vignetteFilter.container.frame.size.height*11)-offsetY)];
        vignetteFilter.sliderView.frame = CGRectMake(0, (vignetteFilter.container.frame.size.height*11)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
//        [softElegance2Filter.container setContentOffset:CGPointMake(0, (softElegance2Filter.container.frame.size.height*10)-offsetY)];
//        softElegance2Filter.sliderView.frame = CGRectMake(0, (softElegance2Filter.container.frame.size.height*10)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        
        
        
        
        
//        [contrastFilter.container setContentOffset:CGPointMake(0, (contrastFilter.container.frame.size.height)-offsetY)];
//        contrastFilter.sliderView.frame = CGRectMake(0, (contrastFilter.container.frame.size.height)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//        
//        [brightnessFilter.container setContentOffset:CGPointMake(0, (brightnessFilter.container.frame.size.height*2) -offsetY)];
//        brightnessFilter.sliderView.frame = CGRectMake(0, (brightnessFilter.container.frame.size.height*2)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//        
//        [levelsFilter.container setContentOffset:CGPointMake(0, (levelsFilter.container.frame.size.height*3)-offsetY)];
//        levelsFilter.sliderView.frame = CGRectMake(0, (levelsFilter.container.frame.size.height*3)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
//        [sharpenFilter.container setContentOffset:CGPointMake(0, (sharpenFilter.container.frame.size.height*6)-offsetY)];
//        sharpenFilter.sliderView.frame = CGRectMake(0, (sharpenFilter.container.frame.size.height*6)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//        
//        
//        [gammaFilter.container setContentOffset:CGPointMake(0, (gammaFilter.container.frame.size.height*7)-offsetY)];
//        gammaFilter.sliderView.frame = CGRectMake(0, (gammaFilter.container.frame.size.height*7)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//        
//        [hazeFilter.container setContentOffset:CGPointMake(0, (hazeFilter.container.frame.size.height*8)-offsetY)];
//        hazeFilter.sliderView.frame = CGRectMake(0, (hazeFilter.container.frame.size.height*8)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
//        [sketchFilter.container setContentOffset:CGPointMake(0, (sketchFilter.container.frame.size.height*14)-offsetY)];
//        sketchFilter.sliderView.frame = CGRectMake(0, (sketchFilter.container.frame.size.height*14)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//        
//        
//        [embossFilter.container setContentOffset:CGPointMake(0, (embossFilter.container.frame.size.height*15)-offsetY)];
//        embossFilter.sliderView.frame = CGRectMake(0, (embossFilter.container.frame.size.height*15)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
//        [toonFilter.container setContentOffset:CGPointMake(0, (toonFilter.container.frame.size.height*18)-offsetY)];
//        toonFilter.sliderView.frame = CGRectMake(0, (toonFilter.container.frame.size.height*18)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
//        
        
    }
//    static NSInteger previousPage = 0;
//    CGFloat pageHeight = scrollView.frame.size.height;
//    float fractionalPage = scrollView.contentOffset.y / pageHeight;
//    NSInteger page = lround(fractionalPage);
//    NSLog(@"%d",page);
////    if (previousPage != page) {
////        previousPage = page;
//
//        if(scrollDirection == ScrollDirectionDown){
//            //
//            if(page >= 2){
//                GLFilterView * prevFilter = [self.arrayOfFilters objectAtIndex:page-2];
//                if(prevFilter.filterType != GPUIMAGE_NOFILTER){
//                    [self.videoCamera removeTarget:prevFilter.filter];
//                }
//            }
//            
//            if(page < [self.arrayOfFilters count]-2){
//                GLFilterView * nextFilter = [self.arrayOfFilters objectAtIndex:page+2];
//                if(nextFilter.filterType != GPUIMAGE_NOFILTER){
//                    [self.videoCamera addTarget:nextFilter.filter];
//                }
//                
//                //            if(stateEdit){
//                //                [[self.arrayOfFilters objectAtIndex:currentFilterIndex+1] setImageCapturedUnderFilter:cleanImageFromCamera];
//                //
//                //            }
//            }
//            
//            
//            
//            
//        } else if(scrollDirection == ScrollDirectionUp){
//            
//            if(page >= 2){
//                GLFilterView * prevFilter = [self.arrayOfFilters objectAtIndex:page-2];
//                if(prevFilter.filterType != GPUIMAGE_NOFILTER){
//                    [self.videoCamera addTarget:prevFilter.filter];
//                }
//            }
//            
//            if(page < [self.arrayOfFilters count]-2){
//                
//                GLFilterView * nextFilter = [self.arrayOfFilters objectAtIndex:page+2];
//                if(nextFilter.filterType != GPUIMAGE_NOFILTER){
//                    [self.videoCamera removeTarget:nextFilter.filter];
//                }
//                
//            }
//            
//        }
//        
//        previousPage = page;
//        currentFilterIndex = page;
//        
//        
//        /* Page did change */
//    }
    
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self stoppedScrolling];
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self stoppedScrolling];
    }
}

- (void)stoppedScrolling
{
    // done, do whatever
    self.mainScrollView.userInteractionEnabled = YES;
    int page = self.mainScrollView.contentOffset.y / self.mainScrollView.frame.size.height;
    
    NSLog(@"%d",page);
    currentFilterIndex = page;
    
    
    if(scrollDirection == ScrollDirectionDown){
        
                if(page >= 2){
                    GLFilterView * prevFilter = [self.arrayOfFilters objectAtIndex:page-2];
                    if(prevFilter.filterType != GPUIMAGE_NOFILTER){
                        [self.videoCamera removeTarget:prevFilter.filter];
                    }
                }
        
                if(page < [self.arrayOfFilters count]-2){
                    GLFilterView * nextFilter = [self.arrayOfFilters objectAtIndex:page+2];
                    if(nextFilter.filterType != GPUIMAGE_NOFILTER){
                        [self.videoCamera addTarget:nextFilter.filter];
                    }
                }
        
        
    } else if(scrollDirection == ScrollDirectionUp){
        
                if(page >= 2){
                    GLFilterView * prevFilter = [self.arrayOfFilters objectAtIndex:page-2];
                    if(prevFilter.filterType != GPUIMAGE_NOFILTER){
                        [self.videoCamera addTarget:prevFilter.filter];
                    }
                }
        
                if(page < [self.arrayOfFilters count]-2){
        
                    GLFilterView * nextFilter = [self.arrayOfFilters objectAtIndex:page+2];
                    if(nextFilter.filterType != GPUIMAGE_NOFILTER){
                        [self.videoCamera removeTarget:nextFilter.filter];
                    }
                    
                }
                
    }

    
}


//- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
//    
//    
//    
////    static NSInteger previousPage = 0;
////    CGFloat pageHeight = scrollView.frame.size.height;
////    float fractionalPage = scrollView.contentOffset.y / pageHeight;
////    NSInteger page = lround(fractionalPage);
////   
////        if (previousPage != page) {
////            previousPage = page;
////            
////            currentFilterIndex = page;
////            
////            
////            NSLog(@"page - %d    currentFilterIndex - %d",page,currentFilterIndex);
////            
////            
////            if(scrollView.tag == ScrollerTypeFilterScroller){
////                //
//////                            int page = scrollView.contentOffset.y / scrollView.frame.size.height;
//////                            currentFilterIndex = page;
//////                            NSLog(@"%d - %d",page,currentFilterIndex);
//////                
//////                
////                            if(scrollDirection == ScrollDirectionDown){
////                
////                                if(page >= 2){
////                                    GLFilterView * prevFilter = [self.arrayOfFilters objectAtIndex:page-2];
////                                    if(prevFilter.filterType != GPUIMAGE_NOFILTER){
////                                        [self.videoCamera removeTarget:prevFilter.filter];
////                                    }
////                                }
////                
////                                if(page < [self.arrayOfFilters count]-2){
////                                    GLFilterView * nextFilter = [self.arrayOfFilters objectAtIndex:page+2];
////                                    if(nextFilter.filterType != GPUIMAGE_NOFILTER){
////                                        [self.videoCamera addTarget:nextFilter.filter];
////                                    }
////                                }
////                
////                
////                
////                
////                            } else if(scrollDirection == ScrollDirectionUp){
////                
////                                if(page >= 2){
////                                    GLFilterView * prevFilter = [self.arrayOfFilters objectAtIndex:page-2];
////                                    if(prevFilter.filterType != GPUIMAGE_NOFILTER){
////                                        [self.videoCamera addTarget:prevFilter.filter];
////                                    }
////                                }
////                    
////                                if(page < [self.arrayOfFilters count]-2){
////                    
////                                    GLFilterView * nextFilter = [self.arrayOfFilters objectAtIndex:page+2];
////                                    if(nextFilter.filterType != GPUIMAGE_NOFILTER){
////                                        [self.videoCamera removeTarget:nextFilter.filter];
////                                    }
////                    
////                                }
////                    
////                            }
////                //            NSLog(@"%d",page);
////                        }
////        }
//    
//    
//    scrollView.userInteractionEnabled = YES;
//    
//    
////        if(scrollView.tag == ScrollerTypeFilterScroller){
////    
////            int page = scrollView.contentOffset.y / scrollView.frame.size.height;
////            currentFilterIndex = page;
////            NSLog(@"%d - %d",page,currentFilterIndex);
////    
////    
////            if(scrollDirection == ScrollDirectionDown){
////    
////                if(page >= 2){
////                    GLFilterView * prevFilter = [self.arrayOfFilters objectAtIndex:page-2];
////                    if(prevFilter.filterType != GPUIMAGE_NOFILTER){
////                        [self.videoCamera removeTarget:prevFilter.filter];
////                    }
////                }
////    
////                if(page < [self.arrayOfFilters count]-2){
////                    GLFilterView * nextFilter = [self.arrayOfFilters objectAtIndex:page+2];
////                    if(nextFilter.filterType != GPUIMAGE_NOFILTER){
////                        [self.videoCamera addTarget:nextFilter.filter];
////                    }
////    
////                    //            if(stateEdit){
////                    //                [[self.arrayOfFilters objectAtIndex:currentFilterIndex+1] setImageCapturedUnderFilter:cleanImageFromCamera];
////                    //
////                    //            }
////                }
////    
////    
////    
////    
////            } else if(scrollDirection == ScrollDirectionUp){
////    
////                if(page >= 2){
////                    GLFilterView * prevFilter = [self.arrayOfFilters objectAtIndex:page-2];
////                    if(prevFilter.filterType != GPUIMAGE_NOFILTER){
////                        [self.videoCamera addTarget:prevFilter.filter];
////                    }
////                }
////    
////                if(page < [self.arrayOfFilters count]-2){
////    
////                    GLFilterView * nextFilter = [self.arrayOfFilters objectAtIndex:page+2];
////                    if(nextFilter.filterType != GPUIMAGE_NOFILTER){
////                        [self.videoCamera removeTarget:nextFilter.filter];
////                    }
////    
////                }
////    
////            }
//////            NSLog(@"%d",page);
////        }
//    
//    
//    
//    
//}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    
    
    scrollView.userInteractionEnabled = NO;
    
//    int page = scrollView.contentOffset.y / scrollView.frame.size.height;
//    
//    NSLog(@"%d",page);
//    currentFilterIndex = page+1;
//    
//    if(scrollDirection == ScrollDirectionDown){
//        
//        if(page >= 2){
//            GLFilterView * prevFilter = [self.arrayOfFilters objectAtIndex:page-2];
//            if(prevFilter.filterType != GPUIMAGE_NOFILTER){
//                [self.videoCamera removeTarget:prevFilter.filter];
//            }
//        }
//        
//        if(page < [self.arrayOfFilters count]-2){
//            GLFilterView * nextFilter = [self.arrayOfFilters objectAtIndex:page+2];
//            if(nextFilter.filterType != GPUIMAGE_NOFILTER){
//                [self.videoCamera addTarget:nextFilter.filter];
//            }
//        }
//        
//        
//    } else if(scrollDirection == ScrollDirectionUp){
//        
//        if(page >= 2){
//            GLFilterView * prevFilter = [self.arrayOfFilters objectAtIndex:page-2];
//            if(prevFilter.filterType != GPUIMAGE_NOFILTER){
//                [self.videoCamera addTarget:prevFilter.filter];
//            }
//        }
//        
//        if(page < [self.arrayOfFilters count]-2){
//            
//            GLFilterView * nextFilter = [self.arrayOfFilters objectAtIndex:page+2];
//            if(nextFilter.filterType != GPUIMAGE_NOFILTER){
//                [self.videoCamera removeTarget:nextFilter.filter];
//            }
//            
//        }
//        
//    }
    
    //    int page = scrollView.contentOffset.y / scrollView.frame.size.height;
    
    //    if(currentFilterIndex < [self.arrayOfFilters count]-1){
    
    //    }
    
    
    //    if(currentFilterIndex > [self.arrayOfFilters count]-1){
    //        NSLog(@"im bigger and im gone crash");
    //        currentFilterIndex = page-1;
    //    }
    
    //    NSLog(@"%d - %d",page,currentFilterIndex);
    //
    //
    //    if(scrollView.tag == ScrollerTypeFontsScroller){
    //
    //    }
    //
    //
    //    if(scrollView.tag == ScrollerTypeFilterScroller){
    //
    ////        if(scrollView.tag == ScrollerTypeFilterScroller){
    ////            currentFilterIndex = page;
    //
    ////        }
    //
    //
    //
    //
    //
    //    }
    
    
}

-(void)hideForPicker:(BOOL)no {

    if(no == YES){
        [UIView animateWithDuration:0.2 animations:^{
            self.cameraViewBackground.alpha = 0;
        }];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            self.cameraViewBackground.alpha = 1;
        }];
    }

}

#pragma mark - iCarouselMethods

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index locationInView:(CGPoint)location {
    
    indexOfImageFromCarousel = (int)index;
    
    
    if(index == [self.latestImagesArray count]){ // Set the last item in carousel to a button which opens image picker.
        //        NSLog(@"test");
        
//        OverlayView *overlay = [[OverlayView alloc]
//                                initWithFrame:CGRectMake(0,0,,SCREEN_HEIGTH)];
//        uiimagepicker

        
        [self.delegate openAppleImagePicker];
//        [UIView animateWithDuration:0.2 animations:^{
//        
//            self.mainScrollView.alpha = 0;
//            
//        } completion:^(BOOL finished) {
//            [self.videoCamera stopCameraCapture];
//            //        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
//            //        picker.delegate = self;
//            //
//            fromImagePicker = YES;
//            
//            [self.delegate openAppleImagePicker];
//        }];
        
        
        
//        picker.allowsEditing = YES;
//        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
        
        
////        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
//        //hide all controls
//        picker.showsCameraControls = NO;
//        picker.navigationBarHidden = NO;
//        picker.toolbarHidden = YES;
//        picker.editing = NO;
//        //make the video preview full size
//        picker.wantsFullScreenLayout = YES;
//        picker.wantsFullScreenLayout = YES;
//        slider.value = 1;
        
//        picker.cameraViewTransform = CGAffineTransformScale(picker.cameraViewTransform,slider.value, slider.value);
        //set our custom overlay view
//        picker.cameraOverlayView = overlay;
//        [picker.view addSubview:slider];
        //show picker
        
        
//        [picker.view addSubview:capture];
//        [picker.view addSubview:library];
        //[picker.view addSubview:multicapture];
        
//        [capture addTarget:self action:@selector(takepicture) forControlEvents:UIControlEventTouchUpInside];
//        [library addTarget:self action:@selector(goToLibrary) forControlEvents:UIControlEventTouchUpInside];
//        [self.view addSubview:picker.view];
//        [picker view];
//        [picker viewWillAppear:YES];
//        [picker will];
//        [picker viewDidAppear:YES];
//        [self.view addSubview:picker.view];
        
//        [self presentViewController:picker animated:YES completion:NULL];
    } else {
        
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc]init];
        options.synchronous  = YES;
        options.resizeMode = PHImageRequestOptionsResizeModeExact;
//        options.d
        //        options.normalizedCropRect = CGRectMake(0, 0, 200, 200);
        options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
        
        //        [[GLCamera sharedInstance] setInEditMode:YES];
        
        //        [[[GLCamera sharedInstance] videoCamera] pauseCameraCapture];
        [self.videoCamera stopCameraCapture];
        
        CGRect screenRect = kScreenBounds;
        CGFloat screenWidth = screenRect.size.width;
        
        [[PHImageManager defaultManager]requestImageForAsset:[self.latestImagesArray objectAtIndex:index] targetSize:CGSizeMake(960,1280) contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage *result, NSDictionary *info){
            
//            
//            UIImage * PortraitImage = [[UIImage alloc] initWithCGImage: result.CGImage
//                                                                 scale: 1.0
//                                                           orientation: UIImageOrientationDown];
            
//            result.ima
            
            ////            [self sendImageToEdit:result];
            //            CGImageRef cgRef = result.CGImage;
            //            UIImage * ttimage = [self normalizedImage:result];
            
            
            
            //    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
            //    [self sendImageToEdit:chosenImage];
            //   ;
            
            
            
            
            
            UIImage * croppedImage = [self imageCroppedToFitSize:CGSizeMake(screenWidth, screenWidth*1.33) image:[self unrotateImage:result]];
            
            
            for(GLFilterView * filterView in self.arrayOfFilters){
                [filterView setImageCapturedUnderFilter:croppedImage];
                //        [filterView.filter ]
            }
            croppedImage = nil;
            [self setCameraViewInEditMode:YES];
            
//            [self updateFiltersWithSelectedImage:croppedImage];
            //            ttimage = nil;
            imageSource = ImageSourceRecents;
            
            
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

-(UIImage*)unrotateImage:(UIImage*)image {
    CGSize size = image.size;
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0,0,size.width ,size.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (UIImage *)normalizedImage:(UIImage*)image {
    if (image.imageOrientation == UIImageOrientationUp) return image;
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
}

- (NSInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    //return the total number of items in the carousel
    return [self.latestImagesArray count]+1;
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    
    
    
    view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width*0.31, [[UIScreen mainScreen] bounds].size.width/3)];
    //        ((UIImageView *)view).image = [UIImage imageNamed:@"page.png"];
    view.contentMode = UIViewContentModeScaleAspectFill;
    view.clipsToBounds = YES;
    
    if(index == [self.latestImagesArray count]){
        //        view.backgroundColor = [UIColor purpleColor];
        //        UIImage * i = [[UIImage alloc] ];
        UIImage * image = [UIImage imageNamed:@"GiCon"];
        UIImageView * iv = [[UIImageView alloc] initWithFrame:CGRectMake(45, 45, 90.0f, 90.0f)];
        iv.image = image;
        [view addSubview:iv];
        //        ((UIImageView *)view).image = image;
    } else {
        [[PHImageManager defaultManager]requestImageForAsset:[self.latestImagesArray objectAtIndex:index] targetSize:CGSizeMake(180.0f, 180.0f) contentMode:PHImageContentModeDefault options:nil resultHandler:^(UIImage *result, NSDictionary *info){
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

//- (CGFloat)carouselItemWidth:(iCarousel *)carousel {
//
//    CGFloat w = 180;
//
//    return  w;
//
//}

#pragma mark - otherDelegateMethods

-(void)retrievePhotoFromPicker:(UIImage *)image {



    fromImagePicker = NO;
    CGRect screenRect = kScreenBounds;
    CGFloat screenWidth = screenRect.size.width;
    
    //    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    //    [self sendImageToEdit:chosenImage];
    //   ;
    
    
    for(GLFilterView * filterView in self.arrayOfFilters){
        [filterView setImageCapturedUnderFilter:[self imageCroppedToFitSize:CGSizeMake(screenWidth, screenWidth*1.3333) image:image]];
        //        [filterView.filter ]
    }
    [self setCameraViewInEditMode:YES];
    
    
//    [self updateFiltersWithSelectedImage:[self imageCroppedToFitSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.width*1.333) image:image]];
    
    [UIView animateWithDuration:0.2 animations:^{
        
        self.mainScrollView.alpha = 1;
        
    } completion:^(BOOL finished) {

    }];
    //    self.imageView.image = chosenImage;
    
    //
//    [picker dismissViewControllerAnimated:YES completion:NULL];
    imageSource = ImageSourceGallery;
    imageFromPicker = [self imageCroppedToFitSize:CGSizeMake(480, 640) image:image];
    

}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    fromImagePicker = NO;
    
    //    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    //    [self sendImageToEdit:chosenImage];
    //   ;
    
    [self updateFiltersWithSelectedImage:[self imageCroppedToFitSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.width*1.3333) image:info[UIImagePickerControllerEditedImage]]];
    //    self.imageView.image = chosenImage;
    
    //
    [picker dismissViewControllerAnimated:YES completion:NULL];
    imageSource = ImageSourceGallery;
    imageFromPicker = [self imageCroppedToFitSize:CGSizeMake(480, 640) image:info[UIImagePickerControllerEditedImage]];
    //
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
//    [picker dismissViewControllerAnimated:YES completion:NULL];
//    [self.videoCamera stopCameraCapture];
//    fromImagePicker = NO;
//    imageSource = ImageSourceGallery;
//    imageFromPicker = nil;
//    picker = nil;
}

-(void)resizeableTapped:(UITapGestureRecognizer*)tap {
    
    //    NSLog(@"test");
    [self.editTextViewObj.textView becomeFirstResponder];
    //    [self.resizeAbleView showEditingHandles];
    
}


- (void)userResizableViewDidBeginEditing:(GLResizeableView *)userResizableView {
    //    NSLog(@"userresized");
    //    if(self.resizeAbleView){}
    [self.resizeAbleView showEditingHandles];
    //    currentlyEditingView = userResizableView;
}

- (void)userResizableViewDidEndEditing:(GLResizeableView *)userResizableView {
    //    [self.resizeAbleView hideEditingHandles];
//    if(isEditing == NO){
        [self.resizeAbleView hideEditingHandles];
//    }
    
    //    [self.editTextViewObj setFrame:CGRectMake(userResizableView.bounds.origin.x, userResizableView.bounds.origin.y, userResizableView.bounds.size.width, userResizableView.bounds.size.height)];
    //    [self.editTextViewObj scaleTextView:];
    
}

-(void)viewIsResizing:(CGRect)frame {
    [self.editTextViewObj scaleTextViewByFrame:frame];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([self.resizeAbleView hitTest:[touch locationInView:self.resizeAbleView] withEvent:nil]) {
        return NO;
    }
    return YES;
}

- (void)keyboardDidShow: (NSNotification *) notif{
    // Do something here
//    isEditing = YES;
    //    [self.resizeAbleView showEditingHandles];
}

- (void)keyboardDidHide: (NSNotification *) notif{
    // Do something here
//    isEditing = NO;
    [self.resizeAbleView hideEditingHandles];
}
//- (void)viewIsResizing:(CGRect)bounds gesture:(UIPanGestureRecognizer*)gesture {
////    [self.editTextViewObj setFrame:CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height)];
////    [self.editTextViewObj scaleTextView:gesture location:nil];
//}

#pragma mark - TextField Delegate methods

- (void)focusOnTextField {
    
    //    [self.resizeAbleView showEditingHandles];
    
    [UIView animateWithDuration:0.5 animations:^{
        
        //
        
        flashButton.alpha = 0;
        flipCameraButton.alpha = 0;
        
        addTextButton.alpha = 0;
        backToCameraButton.alpha = 0;
        trashTextButton.alpha = 1;
        approveTextButton.alpha = 1;
        
        self.resizeAbleView.alpha = 1;
        //        resizeableView.alpha = 1;
        //        resizeableView.topLeft.alpha = 1;
        //        resizeableView.topRight.alpha = 1;
        //        resizeableView.bottomLeft.alpha = 1;
        //        resizeableView.bottomRight.alpha = 1;
        //        resizeableView.rotateHandle.alpha = 1;
    }];
}


- (void)focusOutTextField {
    
    [UIView animateWithDuration:0.5 animations:^{
        //        resizeableView.alpha = 0;
        //        resizeableView.topLeft.alpha = 0;
        //        resizeableView.topRight.alpha = 0;
        //        resizeableView.bottomLeft.alpha = 0;
        //        resizeableView.bottomRight.alpha = 0;
        //        resizeableView.rotateHandle.alpha = 0;
        
        //        [self.resizeAbleView hideEditingHandles];
        
        trashTextButton.alpha = 0;
        approveTextButton.alpha = 0;
        
        backToCameraButton.alpha = 1;
        addTextButton.alpha = 1;
        
    }];
    
}

-(void)dismissKeyboard {
    [self.editTextViewObj endEditing:TRUE];
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

-(void)showCamera {

    
    
    if(!firstTime){
        NSLog(@"First time");
    } else {
        NSLog(@"Not First time");
        
//        [self backToCameraFromEditPallette:nil];
        
        
//        [self.mainScrollView setContentOffset:
//         CGPointMake(0, -self.mainScrollView.contentInset.top) animated:NO];
        
    }
    
    [self.videoCamera startCameraCapture];
    
    [UIView animateWithDuration:0.250 animations:^{
        self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    } completion:^(BOOL done){
        
    }];
    
    
    if(firstTime == YES){
        firstTime = NO;
    }
}

-(void)hideCamera {
    
    
    
    
    
//    [self.mainScrollView setContentOffset:
//     CGPointMake(0, -self.mainScrollView.contentInset.top) animated:YES];
//    currentFilterIndex = 0;
//    [self backToCameraFromEditPallette:nil];
//    if(firstTime){
//        firstTime = NO;
//    }

    [UIView animateWithDuration:0.250 animations:^{
        self.view.frame = CGRectMake(0, -self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
    } completion:^(BOOL done){
        [self.videoCamera stopCameraCapture];
        
        [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
        ////
        for(GLFilterView * filterView in self.arrayOfFilters){
            
            [filterView backToCamera];
            //            [[filterView filter] removeAllTargets];
        }
    }];
}

-(void)setCameraViewInEditMode:(BOOL)edit {
    
    isEditing = edit;
    if(edit){// YES
        
        [UIView animateWithDuration:0.2 animations:^{
//            self.carousel.frame = CGRectMake(self.carousel.frame.origin.x, self.carousel.frame.origin.y+self.carousel.frame.size.height, self.carousel.frame.size.width, self.carousel.frame.size.height);
            self.animatedView.alpha = 1;
        } completion:^(BOOL finished) {
            [self.shadowAnimation start];
        }];
    
        [UIView animateWithDuration:0.5 animations:^{
//            self.editPallette.alpha = 1;
            flipCameraButton.alpha = 0;
            backToCameraButton.alpha = 1;
            flashButton.alpha = 0;
            addTextButton.alpha = 1;
            captureButton.alpha = 0;
            finalProcessButton.alpha = 1;
            abortUploadButton.alpha = 0;
            
            
        }];
        
    } else {
        
        [UIView animateWithDuration:0.2 animations:^{
            self.animatedView.alpha = 0;
        } completion:^(BOOL finished) {
            [self.shadowAnimation stop];
        }];
    
        [self approveTextTapped];
        [UIView animateWithDuration:0.5 animations:^{
//            self.editPallette.alpha = 0;
            flipCameraButton.alpha = 1;
            backToCameraButton.alpha = 0;
            flashButton.alpha = 1;
            addTextButton.alpha = 0;
            captureButton.alpha = 1;
            finalProcessButton.alpha = 0;
            abortUploadButton.alpha = 1;
            
            
        }];
        
        
    }
    
    
    
    
    
    
}

//-(void)presentCameraViewController

-(void)finalProcessTapped {
    NSLog(@"final did tapped");
    
    
//    yes = YES;
//    yes = !yes;
    
//    [self hideCamera];
//    if(self.isInFeedMode){
    
    if(imageSource == ImageSourceNone){
        
//        [self hideCamera];
        
    } else {
        
        if(!self.isInFeedMode){
            
            dmut.transform = dmutScaleOriginal;
            [self toggleCamera:YES];
//            [self setCameraViewInEditMode:NO];
//            [self backToCameraFromEditPallette:@"afterSend"];
            [UIView animateWithDuration:0.2 animations:^{
                self.picYourGroup.alpha = 1;
                glanceLogo.alpha = 1;
                flipCameraButton.alpha = 0;
                flashButton.alpha = 0;
                //                self.backButton.alpha=1;
                //                self.membersButton.alpha=1;
            }];
            [[ContainerViewController sharedInstance] lockScrolling:YES];
            [[ContainerViewController sharedInstance] transitToFriendsList:NO direction:UIPageViewControllerNavigationDirectionReverse completion:^{
                [[ContainerViewController sharedInstance] setFriendsFromMain];
                [[ContainerViewController sharedInstance] setFriendsFromMainWithPicture];
            }];
        }
        
//        if(self.isInFeedMode){
//            [self setCameraViewInEditMode:NO];
//        }
//
        
        
        
//        [self hideCamera];
        
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc]init];
        options.synchronous  = YES;
        options.resizeMode = PHImageRequestOptionsResizeModeExact;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
        
        //    [self.videoCamera startCameraCapture];
//        [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
        
//        for(GLFilterView * filterView in self.arrayOfFilters){
//            
////            [filterView backToCamera];
//            //            [[filterView filter] removeAllTargets];
//        }
//        self.videoCamera = nil;
        
        
        [UIView animateWithDuration:0.2 animations:^{
            
//            if(self.isInFeedMode){
            
                [cameraWrapper setFrame:CGRectMake(0, 0, cameraWrapper.frame.size.width, 60)];
                effectView.alpha = 1;
                dmut.center = CGPointMake(firstX, 60);
                [self.cameraViewBackground setFrame:CGRectMake(0, 0, self.cameraViewBackground.frame.size.width, 60)];
                self.backButton.alpha = 1;
                self.membersButton.alpha = 1;
//            }
            
            
            
        } completion:^(BOOL finished) {
            
            switch (imageSource) {
                case ImageSourceCamera:
                {
                    [self processSelectedImageWithFilterTextAndSize:cleanImageFromCamera];
                    
                };
                    break;
                    
                case ImageSourceRecents:
                {
                    [[PHImageManager defaultManager]requestImageForAsset:[self.latestImagesArray objectAtIndex:indexOfImageFromCarousel] targetSize:CGSizeMake(960, 1280) contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage *image, NSDictionary *info){
                        
                        //                dispatch_async(dispatch_get_main_queue(), ^(){});
//                        UIImage * i = [self normalizedImage:image];
                        
                        
                        UIImage * croppedImage = [self imageCroppedToFitSize:CGSizeMake(960, 1280) image:[self unrotateImage:image]];
                        
                        [self processSelectedImageWithFilterTextAndSize:croppedImage];
                    }];
                };
                    break;
                    
                case ImageSourceGallery:
                {
                    [self processSelectedImageWithFilterTextAndSize:imageFromPicker];
                };
                    break;
                    
                default:
                    break;
            }
            
            
            [self createResizableTextView];
            
//            if(self.isInFeedMode){
                [self backToCameraFromEditPallette:@"afterSend"];
//            }
//            [self toggleCamera];
            
        }];
        
        
        
        
        
    }
    
    
//    } else {
    
    
        
        
        
//    }
    
    
    //    [self dismissViewControllerAnimated:YES completion:nil];
    
    
}



-(void)processSelectedImageWithFilterTextAndSize:(UIImage*)imageToFinal {
    
    
    
    
    //    self.resizeAbleView = nil;
    
    //    @autoreleasepool {
    
    UIImage * filteredImage = [self addFilterToImage:imageToFinal];
    
//    [amatorkaFilter.sourcePicture ]
//    GPUImageFilter * t = [[GPUImageFilter alloc] init];
//    [GPUImageFilter prepareForImageCapture];
//    [stillImageSource processImage];
//    UIImage *currentFilteredImage = [amatorkaFilter.sourcePicture imageFromCurrentlyProcessedOutput];
    
    if (addText) {
        
        UIImage * textAsView = [self imageWithText:self.editTextViewObj.textView];
        CGRect frame = [mainOutPutFrame convertRect:self.editTextViewObj.textView.frame fromView:self.editTextViewObj.textView];
        UIImage * resizedTextAsImage = [self resizeLabelImage:textAsView location:CGPointZero];
        UIImage * imageWithText = [self drawText:@"test" inImage:filteredImage atPoint:CGPointMake(frame.origin.x, frame.origin.y) viewToPast:resizedTextAsImage];
        
        
        imageToFinal = nil;
        imageFromPicker = nil;
        cleanImageFromCamera = nil;
        imageToFinal = nil;
        filteredImage = nil;
        textAsView = nil;
        resizedTextAsImage = nil;
        
        if(self.isInFeedMode){
            [self.delegate imageSelected:imageWithText];
        } else {
            
            [self imageCapturedOnMainScreen:imageWithText];
            
        }
        imageWithText = nil;
        [self.resizeAbleView removeFromSuperview];
    } else {
        
        imageToFinal = nil;
        imageFromPicker = nil;
        cleanImageFromCamera = nil;
        if(self.isInFeedMode){
            [self.delegate imageSelected:filteredImage];
        } else {
            [self imageCapturedOnMainScreen:filteredImage];
        }
        filteredImage = nil;
    }
    addText = NO;
    
    
    
}

-(void)imageCapturedOnMainScreen:(UIImage*)finalImage {

//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Adding Photo"
//                                                    message:@"Adding photos from main screen is unavailable for now.. go do it from a feed of one of the groups"
//                                                   delegate:nil
//                                          cancelButtonTitle:@"Ok I Will"
//                                          otherButtonTitles:nil];
//    [alert show];
    
//    if(finalImage == nil){
//        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"" forKey:@"finalImage"];
//        [[NSNotificationCenter defaultCenter] postNotificationName: @"ImageCapturedOnMainScreen" object:nil userInfo:userInfo];
//    } else {
//        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:finalImage forKey:@"finalImage"];
//    [[NSNotificationCenter defaultCenter] postNotificationName: @"ImageCapturedOnMainScreen" object:nil userInfo:nil];
    self.imageForOutSideUpload = finalImage;
//    }
    
    

}

- (UIImage *) imageWithText:(UIView *)view
{
    //    view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width*2, view.frame.size.height*2);
    
    
    //    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    //    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    //    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    //    UIGraphicsEndImageContext();
    
    
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 1.0);
    
    
    
    
    [view.layer renderInContext:UIGraphicsGetCurrentContext() ];
    
    
    //    [ drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

-(UIImage*)addFilterToImage:(UIImage*)inputImage {
    
    
    
    //    GPUImagePicture * sourcePicture = [[GPUImagePicture alloc] initWithImage:inputImage smoothlyScaleOutput:YES];
    //    sourcePicture image
    GLFilterView * currentFIlter = [self.arrayOfFilters objectAtIndex:currentFilterIndex];
    
    UIImage * filteredImage = nil;
//    NSArray * filters = [[NSArray alloc] initWithObjects:, nil];
    
    if(currentFIlter.filterType == GPUIMAGE_AMATORKA){
    
        GPUImageAmatorkaFilter *stillImageFilter2 = [[GPUImageAmatorkaFilter alloc] init];
        filteredImage = [stillImageFilter2 imageByFilteringImage:inputImage];
        
    } else if(currentFIlter.filterType == GPUIMAGE_SOFTELEGANCE){
        GPUImageSoftEleganceFilter *stillImageFilter2 = [[GPUImageSoftEleganceFilter alloc] init];
        filteredImage = [stillImageFilter2 imageByFilteringImage:inputImage];
        
    } else if(currentFIlter.filterType == GPUIMAGE_MISSETIKATE){
        GPUImageMissEtikateFilter *stillImageFilter2 = [[GPUImageMissEtikateFilter alloc] init];
        filteredImage = [stillImageFilter2 imageByFilteringImage:inputImage];
        
    } else if(currentFIlter.filterType == GPUIMAGE_FOGGYNIGHT){
        GPUImageFoggyNightFilter *stillImageFilter2 = [[GPUImageFoggyNightFilter alloc] init];
        filteredImage = [stillImageFilter2 imageByFilteringImage:inputImage];
        
    } else if(currentFIlter.filterType == GPUIMAGE_LATESUNSET){
        GPUImageLateSunsetFilter *stillImageFilter2 = [[GPUImageLateSunsetFilter alloc] init];
        filteredImage = [stillImageFilter2 imageByFilteringImage:inputImage];
    } else {
        filteredImage = [currentFIlter.filter imageByFilteringImage:inputImage];
    }
    
    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
    
    
    
    
    return filteredImage;
}

#pragma mark - Camera Actions

-(void) approveTextTapped {
    
    [self.editTextViewObj endEditing:YES];
    [UIView animateWithDuration:0.5 animations:^{
        //        resizeableView.alpha = 0;
        //        resizeableView.topLeft.alpha = 0;
        //        resizeableView.topRight.alpha = 0;
        //        resizeableView.bottomLeft.alpha = 0;
        //        resizeableView.bottomRight.alpha = 0;
        //        resizeableView.rotateHandle.alpha = 0;
        
        trashTextButton.alpha = 0;
        approveTextButton.alpha = 0;
        
        backToCameraButton.alpha = 1;
        addTextButton.alpha = 1;
        
    }];
}

-(void) updateFiltersWithSelectedImage:(UIImage *)image {
    
    //    GLFilterView * currFilter = [self.arrayOfFilters objectAtIndex:currentFilterIndex];
    //    UIImage * captured = [[GLCamera sharedInstance] imageWithView:currFilter.outputViewCasted];
    
    
    
    [UIView animateWithDuration:0.5 animations:^{
//        self.editPallette.alpha = 1;
        flipCameraButton.alpha = 0;
        backToCameraButton.alpha = 1;
        flashButton.alpha = 0;
        addTextButton.alpha = 1;
        captureButton.alpha = 0;
        finalProcessButton.alpha = 1;
        abortUploadButton.alpha = 0;
        
        
        
    }];
    
    //    croppedImage = nil;
    
    
    
    for(GLFilterView * filterView in self.arrayOfFilters){
        [filterView setImageCapturedUnderFilter:image];
    }
}


-(void) updateFiltersWithCapturedImage {
    
    
    
    GLFilterView * t = [self.arrayOfFilters objectAtIndex:0];
    
    
    
    UIImage * captured = [self imageWithView:t.outputViewCasted];
    
    
    
    for(GLFilterView * filterView in self.arrayOfFilters){
        [filterView setImageCapturedUnderFilter:captured];
    }
}



- (void) captureTapped {
    
//        [self setInEditMode:YES];
    //    [[GLCamera sharedInstance] playCaptureSound];
    
    //    [self.videoCamera capturePhotoAsJPEGProcessedUpToFilter:[[self.arrayOfFilters objectAtIndex:0] filter] withCompletionHandler:^(NSData *processedJPEG, NSError *error) {
    //        [self.videoCamera pauseCameraCapture];
    //
    //        cleanImageFromCamera = [UIImage imageWithData:processedJPEG];
    //
    //        [self updateFiltersWithCapturedImage];
    //
    //
    ////        [];
    //    }];
    //    @autoreleasepool {
    //        [[self.arrayOfFilters objectAtIndex:0] useNextFrameForImageCapture];
    
    CGRect screenRect = kScreenBounds;
    CGFloat screenWidth = screenRect.size.width;
    
    
//    [[[self.arrayOfFilters objectAtIndex:0] filter] useNextFrameForImageCapture];
//    //
//    UIImage * imageFromFilter = [[[self.arrayOfFilters objectAtIndex:0] filter] imageFromCurrentFramebuffer];
//    [self.videoCamera pauseCameraCapture];
//    cleanImageFromCamera = [self imageCroppedToFitSize:CGSizeMake(512, 512) image:imageFromFilter];
//    
//        for(GLFilterView * filterView in self.arrayOfFilters){
//                            [filterView setImageCapturedUnderFilter:[self imageCroppedToFitSize:CGSizeMake(screenWidth, screenWidth) image:imageFromFilter]];
//    //        [filterView.filter ]
//                        }
//    [self setCameraViewInEditMode:YES];
    
    
    
            [self.videoCamera capturePhotoAsImageProcessedUpToFilter:[[self.arrayOfFilters objectAtIndex:0] filter] withCompletionHandler:^(UIImage *processedImage, NSError *error) {
               
                [self.videoCamera stopCameraCapture];
                [self setCameraViewInEditMode:YES];
                
                
                
                cleanImageFromCamera = [self imageCroppedToFitSize:CGSizeMake(480, 640) image:processedImage];
                
                for(GLFilterView * filterView in self.arrayOfFilters){
                    [filterView setImageCapturedUnderFilter:[self imageCroppedToFitSize:CGSizeMake(screenWidth, screenWidth*1.3333) image:processedImage]];
                    //        [filterView.filter ]
                }
                
                
                
                
                
                
                
            }];
    //
    //            [self.videoCamera pauseCameraCapture];
    //
    //            cleanImageFromCamera = [self imageCroppedToFitSize:CGSizeMake(512, 512) image:processedImage];
    //
    //
    //            for(GLFilterView * filterView in self.arrayOfFilters){
    //                [filterView setImageCapturedUnderFilter:[self imageCroppedToFitSize:CGSizeMake(screenWidth, screenWidth) image:processedImage]];
    //            }
    //        }];
    
    imageSource = ImageSourceCamera;
    
    
    
    
    
    
    //    UIImageWriteToSavedPhotosAlbum(captured,
    //                                   nil,
    //                                   @selector(savedone),
    //                                   nil);
    //
    //    [self sendImageToEdit:captured];
    
    
    
    //    GLFilterView * t = [self.arrayOfFilters objectAtIndex:0];
    ////    GPUImageSepiaFilter * defFilter = [[GPUImageSepiaFilter alloc] init];
    //    [(GPUImageSaturationFilter *)t.filter setSaturation:1];
    ////    [self.videoCamera pauseCameraCapture];
    //
    //    self.videoCamera.jpegCompressionQuality = 0.01;
    //    [self.videoCamera capturePhotoAsJPEGProcessedUpToFilter:t.filter withCompletionHandler:^(NSData *processedJPEG, NSError *error) {
    //
    //        UIImage *image=[UIImage imageWithData:processedJPEG];
    //        UIImage * l = [self imageByCroppingImage:image toSize:CGSizeMake(image.size.width, image.size.width)];
    
    
    
    //        [[self.arrayOfFilters objectAtIndex:0] setImageCapturedUnderFilter:captured];
    //        [[self.arrayOfFilters objectAtIndex:1] setImageCapturedUnderFilter:captured];
    //        [[self.arrayOfFilters objectAtIndex:2] setImageCapturedUnderFilter:captured];
    //        [[self.arrayOfFilters objectAtIndex:3] setImageCapturedUnderFilter:captured];
    //        [[self.arrayOfFilters objectAtIndex:4] setImageCapturedUnderFilter:captured];
    //        [[self.arrayOfFilters objectAtIndex:5] setImageCapturedUnderFilter:captured];
    //        image = nil;
    //        l = nil;
    
    //    }];
    
    //    [self.videoCamera capturePhotoAsImageProcessedUpToFilter:t.filter withCompletionHandler:^(UIImage *captureImage, NSError *error){
    //
    ////        NSData *imgData= UIImageJPEGRepresentation(captureImage,0.3 /*compressionQuality*/);
    ////        UIImage *image=[UIImage imageWithData:imgData];
    //
    //
    //        UIImage * l = [self imageByCroppingImage:captureImage toSize:CGSizeMake(captureImage.size.width, captureImage.size.width)];
    //
    //
    //        [[self.arrayOfFilters objectAtIndex:0] setImageCapturedUnderFilter:l];
    ////        [[self.arrayOfFilters objectAtIndex:1] setImageCapturedUnderFilter:l];
    ////        [[self.arrayOfFilters objectAtIndex:2] setImageCapturedUnderFilter:l];
    //
    ////        for(GLFilterView * filterView in self.arrayOfFilters){
    ////
    ////            [filterView setImageCapturedUnderFilter:l];
    ////
    ////        }
    //
    ////        UIImageView * tt = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, t.outputViewCasted.frame.size.width, t.outputViewCasted.frame.size.width)];
    ////        tt.image = l;
    ////        [t.outputViewCasted addSubview:tt];
    //
    ////        if (error) {
    ////            NSLog(@"ERROR: Could not capture!");
    ////        }
    ////        else {
    ////            // save file
    ////
    ////            NSLog(@"PHOTO SAVED - ??");
    ////
    ////            // save photo to album
    //////            UIImageWriteToSavedPhotosAlbum(captureImage, nil, nil, nil);
    ////        }
    ////
    ////        runOnMainQueueWithoutDeadlocking(^{
    ////
    ////            // Start video camera capture again
    //////            [self.videoCamera resumeCameraCapture];
    ////
    ////
    ////        });
    //
    //    }];
    
    
    //    GLFilterView * t = [self.arrayOfFilters objectAtIndex:0];
    //
    //    [self.videoCamera pauseCameraCapture];
    //    UIImage *capturedImage = [self.videoCamera imageFromCurrentlyProcessedOutput];
    //    UIImageWriteToSavedPhotosAlbum(capturedImage, nil, nil, nil);
    //    [self.videoCamera resumeCameraCapture];
    
    
    //    [self.videoCamera capturePhotoAsImageProcessedUpToFilter:nil withCompletionHandler:^(UIImage *processedJPEG, NSError *error){
    //
    //
    //            UIImageWriteToSavedPhotosAlbum(processedJPEG,
    //                                           nil,
    //                                           @selector(savedone),
    //                                           nil);
    
    //        // Save to assets library
    //        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    //
    //        [library writeImageDataToSavedPhotosAlbum:processedJPEG metadata:self.videoCamera.currentCaptureMetadata completionBlock:^(NSURL *assetURL, NSError *error2)
    //         {
    //             if (error2) {
    //                 NSLog(@"ERROR: the image failed to be written");
    //             }
    //             else {
    //                 NSLog(@"PHOTO SAVED - assetURL: %@", assetURL);
    //             }
    //
    //             runOnMainQueueWithoutDeadlocking(^{
    //                 //                 [photoCaptureButton setEnabled:YES];
    //
    //             });
    //         }];
    //    }];
    
//    [UIView animateWithDuration:1.5 animations:^{
//        self.view.alpha = 0;
//    }];
}

-(void)savedone {
    
}

-(void) trashTheText {
    
    addText = NO;
    [UIView animateWithDuration:0.5 animations:^{
        
        self.resizeAbleView.alpha = 0;
        //        resizeableView.alpha = 0;
        //        resizeableView.topLeft.alpha = 0;
        //        resizeableView.topRight.alpha = 0;
        //        resizeableView.bottomLeft.alpha = 0;
        //        resizeableView.bottomRight.alpha = 0;
        //        resizeableView.rotateHandle.alpha = 0;
        
        addTextButton.alpha = 1;
        trashTextButton.alpha = 0;
        
        approveTextButton.alpha = 0;
        backToCameraButton.alpha = 1;
    }];
}


-(void) addTextToImageTapped {
    
    addText = YES;
    
    [UIView animateWithDuration:0.5 animations:^{
        addTextButton.alpha = 0;
        backToCameraButton.alpha = 0;
        trashTextButton.alpha = 1;
        approveTextButton.alpha = 1;
        
        self.resizeAbleView.alpha = 1;
        
        //        resizeableView.alpha = 1;
        //        resizeableView.topLeft.alpha = 1;
        //        resizeableView.topRight.alpha = 1;
        //        resizeableView.bottomLeft.alpha = 1;
        //        resizeableView.bottomRight.alpha = 1;
        //        resizeableView.rotateHandle.alpha = 1;
    }];
}

-(void) sendImageToEdit:(UIImage *)image {
    
    
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
    
    
}

-(void) backToCameraFromEditPallette:(id)sender {
    [self.editTextViewObj endEditing:YES];
    imageSource = ImageSourceNone;
    
    //    self.resizeAbleView.alpha =
    
    //    [[GLCamera sharedInstance] setInEditMode:NO];
    
    for(GLFilterView * filterView in self.arrayOfFilters){
        [filterView backToCamera];
    }
//    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
    [self setCameraViewInEditMode:NO];
//    if(sender == nil){
//        sender = @"";
//    }
    if([sender isKindOfClass:[UIButton class]]){
            [self.videoCamera startCameraCapture];
        }
    
    
    
    
    
//    [UIView animateWithDuration:0.5 animations:^{
//        self.resizeAbleView.alpha = 0;
////        self.editPallette.alpha = 0;
//        flipCameraButton.alpha = 1;
//        backToCameraButton.alpha = 0;
//        flashButton.alpha = 1;
//        addTextButton.alpha = 0;
//        captureButton.alpha = 1;
//    }];
}


-(void)flipCamera {
    
    
    [self.videoCamera rotateCamera];
    
    if(cameraIsBackView){
        if(self.flashIsOn){
            [self toggleFlash];
        }
        [UIView animateWithDuration:0.2 animations:^{
            [flashButton setAlpha:0];
        }];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            [flashButton setAlpha:1];
        }];
    }
    cameraIsBackView = !cameraIsBackView;
    
}


#pragma mark - initiators

- (void)createMainScrollView {
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat filterViewWidth = screenRect.size.width;
    CGFloat filterViewHeight = screenRect.size.width;
    CGFloat screenHeigth = screenRect.size.height;
    
    self.mainScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, filterViewWidth, screenHeigth*0.75)];
    
    self.mainScrollView.backgroundColor = [UIColor orangeColor];
    self.mainScrollView.tag = ScrollerTypeFilterScroller;
    self.mainScrollView.delegate = self;
    self.mainScrollView.bounces = NO;
    self.mainScrollView.pagingEnabled = YES;
    NSInteger numberOfViews = [self.arrayOfFilters count];
    for (int i = 0; i < numberOfViews; i++) {
        CGFloat yOrigin = i * (screenHeigth*0.75);
        GLFilterView * tempFilt = [self.arrayOfFilters objectAtIndex:i];
        [tempFilt.container setFrame:CGRectMake(0, yOrigin, filterViewWidth, screenHeigth*0.75)];
        tempFilt.container.backgroundColor = [UIColor blackColor];
        
        [self.mainScrollView addSubview:tempFilt.container];
        
    }
    self.mainScrollView.contentSize = CGSizeMake(filterViewWidth, ((screenHeigth*0.75)* numberOfViews));
    
    //    [self.mainScrollView setContentOffset:CGPointMake(0, 20)];
    //    [self.mainScrollView scrollsToTop];
    
    [mainOutPutFrame addSubview:self.mainScrollView];
    
    UIView * buttonBg1 = [[UIView alloc] initWithFrame:CGRectMake(10, 0, 60, 60)];
    buttonBg1.backgroundColor = [UIColor blackColor];
    buttonBg1.layer.cornerRadius = 60;
    
    
    flipCameraButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 20, 60, 60)];
    UIImage *btnImage = [UIImage imageNamed:@"FlipCameraIcon"];
    [flipCameraButton addTarget:self action:@selector(flipCamera) forControlEvents:UIControlEventTouchUpInside];
    [flipCameraButton setImage:btnImage forState:UIControlStateNormal];
    [mainOutPutFrame addSubview:flipCameraButton];
    
    flipCameraButton.alpha = 0;
    
    backCameraOn = YES;
    
    flashButton = [[UIButton alloc] initWithFrame:CGRectMake(filterViewWidth - 50, 30, 40, 40)];
    UIImage *btnImage2 = [UIImage imageNamed:@"FlashIcon"];
    [flashButton addTarget:self action:@selector(toggleFlash) forControlEvents:UIControlEventTouchUpInside];
    [flashButton setImage:btnImage2 forState:UIControlStateNormal];
    [self.view addSubview:flashButton];
    
    flashButton.alpha = 0;
    
    flashIsOn = NO;
    
    
    //    self.recentPhotosSlider = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, filterViewWidth, filterViewHeight)];
    //    self.mainScrollView.tag = ScrollerTypeFilterScroller;
    //    self.mainScrollView.delegate = self;
    //    self.mainScrollView.pagingEnabled = YES;
    
}

-(void)toggleFlash {
    self.flashIsOn = !self.flashIsOn;
    // check if flashlight available
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]){
            
            [device lockForConfiguration:nil];
            if (self.flashIsOn) {
                //                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeAuto];
                [flashButton setAlpha:1];
                //torchIsOn = YES; //define as a variable/property if you need to know status
            } else {
                //                [device setTorchMode:AVCaptureTorchModeOff];
                [device setFlashMode:AVCaptureFlashModeOff];
                 [flashButton setAlpha:0.5];
                //torchIsOn = NO;
            }
            [device unlockForConfiguration];
        }
    }
}

-(void) playCaptureSound {
    //Get the filename of the sound file:
    //
    NSString *path = [NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] resourcePath], @"/camera-shutter-click-01.wav"];
    //
    SystemSoundID soundID;
    //
    NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
    //
    //        //Use audio sevices to create the sound
    //
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &soundID);
    
    //Use audio services to play the sound
    
    AudioServicesPlaySystemSound(soundID);
}

//static inline double radians (double degrees) {
//    return degrees * M_PI/180;
//}

- (UIImage *) resizeLabelImage:(UIImage*)image location:(CGPoint)location {
    
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    
    int pictureWidth = 512;
    CGFloat previewWidth = screenRect.size.width;
    
    CGFloat textOriginalWidth = image.size.width;
    CGFloat textOriginalHeight = image.size.height;
    
    
    
    CGFloat ratioBetweenPictureToPreview = pictureWidth/previewWidth;
    
    
    
    
    
    
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(textOriginalWidth * ratioBetweenPictureToPreview,textOriginalHeight * ratioBetweenPictureToPreview), NO, 1.0);
    
    [image drawInRect:CGRectMake(0, 0, textOriginalWidth * ratioBetweenPictureToPreview,textOriginalHeight * ratioBetweenPictureToPreview)];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return newImage;
}



- (UIImage *) imageWithView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 1.0f);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    UIImage * snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return snapshotImage;
}

- (UIImage *)imageByCroppingImage:(UIImage *)image toSize:(CGSize)size
{
    // not equivalent to image.size (which depends on the imageOrientation)!
    double refWidth = CGImageGetWidth(image.CGImage);
    double refHeight = CGImageGetHeight(image.CGImage);
    
    double x = (refWidth - size.width) / 2.0;
    double y = (refHeight - size.height) / 2.0;
    
    CGRect cropRect = CGRectMake(x, y, size.height, size.width);
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);
    
    UIImage *cropped = [UIImage imageWithCGImage:imageRef scale:0.0 orientation:UIImageOrientationUp];
    CGImageRelease(imageRef);
    
    return cropped;
}


-(UIImage*) drawText:(NSString*) text
             inImage:(UIImage*)  image
             atPoint:(CGPoint)   point
          viewToPast:(UIImage*)viewToEmbed
{
    
    
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    
    int pictureWidth = 512;
    CGFloat previewWidth = screenRect.size.width;
    
    CGFloat textOriginalWidth = viewToEmbed.size.width;
    CGFloat textOriginalHeight = viewToEmbed.size.height;
    
    
    
    //
    //512//        //320//    = 1.6
    CGFloat ratioBetweenPictureToPreview = pictureWidth/previewWidth;
    
    //    UIImage * ttt = [self imageWithView:viewToEmbed];
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 1.0);
    
    //     UIGraphicsBeginImageContext(image.size);
    
    //    CGContextSetFillColorWithColor( context, [UIColor clearColor].CGColor );
    //    CGContextSetBlendMode(context, kCGBlendModeClear);
    
    
    [image drawAtPoint:CGPointMake(0,0)];
    [viewToEmbed drawAtPoint:CGPointMake(point.x*ratioBetweenPictureToPreview,point.y*ratioBetweenPictureToPreview)];
    
    
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //    UIFont *font = [UIFont boldSystemFontOfSize:12];
    //    UIGraphicsBeginImageContext(image.size);
    //    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];
    //    CGRect rect = CGRectMake(point.x, point.y, image.size.width, image.size.height);
    //    [[UIColor whiteColor] set];
    //    [text drawInRect:CGRectIntegral(rect) withFont:font];
    //    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    //    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
