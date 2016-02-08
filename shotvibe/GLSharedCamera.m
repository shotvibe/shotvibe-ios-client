//
//  GLSharedCamera.m
//  shotvibe
//
//  Created by Tsah Kashkash on 15/10/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

//#import "GLSharedCamera.h"
#import "RBVolumeButtons.h"
#import "SVAddFriendsViewController.h"
#import "UIImage+ImageEffects.h"
#import "UIImage+FX.h"
#import "GLScoreViewController.h"
#import "FXImageView.h"
#import "ShotVibeAPI.h"
#import "GLProfilePageViewController.h"
#import "GLSharedVideoPlayer.h"
#import "GLContainersViewController.h"
#import "M13ProgressViewPie.h"
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import "GLCameraGradientView.h"




@interface GradientView : UIView

@property (nonatomic, strong, readonly) CAGradientLayer *layer;

@end

@implementation GradientView

+ (Class)layerClass {
    return [CAGradientLayer class];
}

@end


@implementation GLSharedCamera {
    ScrollDirection scrollDirection;
    int currentFilterIndex;
    int indexOfImageFromCarousel;
    int imageSource;
    int flashState;
    int lastPage;
    BOOL backCameraOn;
    BOOL cameraIsBackView;
    BOOL isEditing;
    BOOL stateEdit;
    BOOL fromImagePicker;
    BOOL flashIsOn;
    BOOL firstTime;
    BOOL addText;
    BOOL cameraVisble;
    BOOL yes;
    UIView * cameraWrapper;
    UIView * scoreBg;
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
    GLFilterView * cosmopolitanFilter;
    GLFilterView * daquiriFilter;
    GLFilterView * fizzFilter;
    GLFilterView * margaritaFilter;
    GLFilterView * martiniFilter;
    GLFilterView * mojitoFilter;
    PHFetchResult *fetchResult;
    UILabel * testLabel;
    UITextField * dummyTextField;
    CGFloat cameraSlideTopLimit;
    CGFloat firstX;
    CGFloat firstY;
    UIVisualEffectView *effectView;
    CGAffineTransform dmutScaleOriginal;
    RBVolumeButtons *buttonStealer;
    CGFloat draggedLength;
    UIImageView * glanceLogo;
    GradientView * gradView;
    BOOL cameraIsOpen;
    
    UIView * gradBackgroundViewWrapper;
    GLCameraGradientView * gradBackgroundView;
    
    NSMutableArray * gradientColorViewsArray;
    UIScrollView * gradientColorsScroller;
    UIVisualEffectView *gradientBlurredBgEffectView;
    BOOL doingGeadientBg;
    
    UIButton * addGrdientButton;
    
    UIScrollView * cameraFeaturesScroller;
    
    NSArray * gradientColorsArray;
    
    UIView * effeectViewWrapper;
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
        
        cameraIsOpen = NO;
        doingGeadientBg = NO;
        flashState = 0;
        lastPage = 0;
        self.afterLogin = NO;
        self.captureStoppedByTimer = NO;
        self.captureTimeLineWrapper.alpha = 0;
        self.cameraIsShown = NO;
        self.goneUploadAmovie = NO;
        self.isInFeedMode = NO;
        cameraVisble = NO;
        yes = YES;
        addText = NO;
        firstTime = YES;
        imageSource = ImageSourceNone;
        isEditing = NO;
        stateEdit = NO;
        fromImagePicker = NO;
        cameraIsBackView = YES;
        
        
        self.colorArray = [[NSMutableArray alloc] init];
        self.colorArray = @[ @0x000000, @0x262626, @0x4d4d4d, @0x666666, @0x808080, @0x990000, @0xcc0000, @0xfe0000, @0xff5757, @0xffabab, @0xffabab, @0xffa757, @0xff7900, @0xcc6100, @0x994900, @0x996f00, @0xcc9400, @0xffb900, @0xffd157, @0xffe8ab, @0xfff4ab, @0xffe957, @0xffde00, @0xccb200, @0x998500, @0x979900, @0xcacc00, @0xfcff00, @0xfdff57, @0xfeffab, @0xf0ffab, @0xd2ff00, @0xa8cc00, @0x7e9900, @0x038001, @0x04a101, @0x05c001, @0x44bf41, @0x81bf80, @0x81c0b8, @0x41c0af, @0x00c0a7, @0x00a18c, @0x00806f, @0x040099, @0x0500cc, @0x0600ff, @0x5b57ff, @0xadabff, @0xd8abff, @0xb157ff, @0x6700bf, @0x5700a1, @0x450080, @0x630080, @0x7d00a1, @0x9500c0, @0xa341bf, @0xb180bf, @0xbf80b2, @0xbf41a6, @0xbf0199, @0xa10181, @0x800166, @0x999999, @0xb3b3b3, @0xcccccc, @0xe6e6e6, @0xffffff];
        
        
        
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat width = screenRect.size.width;
        CGFloat heigth = screenRect.size.height;
        self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, heigth)];
        self.view.clipsToBounds = YES;
        self.view.backgroundColor = [UIColor whiteColor];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(dismissKeyboard)];
        [self.view addGestureRecognizer:tap];
        
        
        CGFloat screenWidth = screenRect.size.width;
        CGFloat screenHeight = screenRect.size.height;
        
        mainOutPutFrame = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight*0.75)];
        mainOutPutFrame.backgroundColor = [UIColor blackColor];
//        [self.view addSubview:mainOutPutFrame];
        
        self.arrayOfFilters = [[NSMutableArray alloc] init];
        self.latestImagesArray =[[NSMutableArray alloc] init];
        
        [self setupVideoCamera];
        
        int recentsLimit = 15;
        
        PHFetchOptions *fetchOptions = [PHFetchOptions new];
        fetchOptions.includeAllBurstAssets = NO;
        fetchOptions.includeHiddenAssets = NO;
        fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];
        
        if([fetchResult count] < recentsLimit){
            recentsLimit = (int)[fetchResult count];
        }
        
        for(int r = 0; r < recentsLimit; r++){
            [self.latestImagesArray addObject:[fetchResult objectAtIndex:r]];
        }
        
        self.carousel = [[iCarousel alloc] initWithFrame:CGRectMake(0, mainOutPutFrame.frame.size.height, screenWidth, self.view.frame.size.height/5.4)];
        self.carousel.type = iCarouselTypeLinear;
        [self.view addSubview:self.carousel];
        
        
        UIView * bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, screenHeight-self.carousel.frame.size.height, self.view.frame.size.width, self.carousel.frame.size.height)];
        
        UIView * gap = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 13)];
        gap.backgroundColor = [UIColor whiteColor];
        [bottomBar addSubview:gap];
        
        bottomBar.backgroundColor = [UIColor whiteColor];
        
        [self.view addSubview:bottomBar];
        
        
        
        
        self.carousel.parentView = self.view;
        self.carousel.delegate = self;
        self.carousel.dataSource = self;
        self.carousel.backgroundColor = [UIColor clearColor];
        [self.carousel scrollByNumberOfItems:1 duration:0.3];
        
        
        
        [self.view addSubview:self.carousel];
        
        
        UIView * bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.mainScrollView.frame.size.height+self.carousel.frame.size.height, self.view.frame.size.width, self.view.frame.size.height-(self.mainScrollView.frame.size.height+self.carousel.frame.size.height))];
        
        bottomLine.backgroundColor = UIColorFromRGB(0x40b4b5);
        [self.view addSubview:bottomLine];
        
        
        self.animatedView = [[UIButton alloc] initWithFrame:CGRectMake((self.view.frame.size.width/2)-50, 0, 100, 50)];
        [self.animatedView addTarget:self action:@selector(finalProcessTapped) forControlEvents:UIControlEventTouchUpInside];
        self.animatedView.titleLabel.font = [UIFont fontWithName:@"GothamRounded-Bold" size:85];
        [self.animatedView setTitle:@"⇢" forState:UIControlStateNormal];
        [self.animatedView setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.shadowAnimation = [JTSlideShadowAnimation new];
        self.shadowAnimation.animatedView = self.animatedView;
        self.shadowAnimation.shadowWidth = 20.;
        self.animatedView.alpha = 0;
        [bottomLine addSubview:self.animatedView];
        
        
        
        captureButton = [[UIButton alloc] initWithFrame:CGRectMake(10,self.mainScrollView.frame.size.height-80, 70, 70)];
        UIImage *btnImage3 = [UIImage imageNamed:@"CaptureButton"];
        [captureButton setImage:btnImage3 forState:UIControlStateNormal];
        
        [captureButton addTarget:self action:@selector(captureTapped) forControlEvents:UIControlEventTouchUpInside];
        
        UILongPressGestureRecognizer *btn_LongPress_gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleBtnLongPressgesture:)];
        [captureButton addGestureRecognizer:btn_LongPress_gesture];
        
        UIPanGestureRecognizer * capturePan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(captureDragged:)];
        
        [captureButton addGestureRecognizer:capturePan];
        [mainOutPutFrame addSubview:captureButton];
        
        
        
        backToCameraButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 33, 30, 30)];
        backToCameraButton.userInteractionEnabled = YES;
        [backToCameraButton addTarget:self action:@selector(backToCameraFromEditPallette:) forControlEvents:UIControlEventTouchUpInside];
        UIImage *btnImage4 = [UIImage imageNamed:@"backToCameraIcon"];
        
        backToCameraButton.alpha = 0;
        [backToCameraButton setImage:btnImage4 forState:UIControlStateNormal];
        [mainOutPutFrame addSubview:backToCameraButton];
        
        addTextButton = [[UIButton alloc] initWithFrame:CGRectMake(screenWidth - 40, 32, 30, 30)];
        UIImage *btnImage5 = [UIImage imageNamed:@"addTextIcon"];
        addTextButton.alpha = 0;
        [addTextButton addTarget:self action:@selector(addTextToImageTapped) forControlEvents:UIControlEventTouchUpInside];
        [addTextButton setImage:btnImage5 forState:UIControlStateNormal];
        [mainOutPutFrame addSubview:addTextButton];
        
        trashTextButton = [[UIButton alloc] initWithFrame:CGRectMake(screenWidth - 50, 25, 38, 38)];
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
        touchPointCircle.alpha = 0;
        
        [mainOutPutFrame addSubview:touchPointCircle];
        
        for(GLFilterView * filter in self.arrayOfFilters){
            filter.title.alpha = 0 ;
        }
        self.view.userInteractionEnabled = YES;
        
        self.cameraViewBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, (self.view.frame.size.height/3))];
        
        
        cameraWrapper = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height/3)];
        cameraWrapper.clipsToBounds = YES;
        [cameraWrapper addSubview:self.view];
        [self.cameraViewBackground addSubview:cameraWrapper];
        
        
        self.dmut = [[UIImageView alloc] initWithFrame:CGRectMake(60, ([UIScreen mainScreen].bounds.size.height/3)-86, 256, 104)];
        self.dmut.userInteractionEnabled = YES;
        self.dmut.image = [UIImage imageNamed:@"Dmut"];
        [self.cameraViewBackground addSubview:self.dmut];
        dmutScaleOriginal = self.dmut.transform;
        
        UIPanGestureRecognizer * gest = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dmutDragged:)];
        
        [self.dmut addGestureRecognizer:gest];

        cameraSlideTopLimit = [self.dmut center].y;
        
        // add effect to an effect view
        
        effeectViewWrapper = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 80)];
//        effeectViewWrapper.backgroundColor = [UIColor purpleColor];
        effeectViewWrapper.hidden = YES;
        
        effectView = [[UIVisualEffectView alloc] init];
        effectView.frame = CGRectMake(0, 0, self.view.frame.size.width, 80);
        effectView.alpha = 0;
        //        effectView.hidden = NO;
        
        
        //        self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 20, 40, 70)];
        self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 23, 27, 45)];
        
        self.backButton.alpha = 0;
        //        self.backButton.backgroundColor = [UIColor redColor];
        [self.backButton setBackgroundImage:[UIImage imageNamed:@"feedBackIcon"] forState:UIControlStateNormal];
        //        [self.backButton setImage:[UIImage imageNamed:@"feedBackIcon"] forState:UIControlStateNormal];
        //        self.backButton.imageEdgeInsets = UIEdgeInsetsMake(-10, -15, -25, 0);
        
        
        [self.backButton addTarget:self action:@selector(backButtonPressed)
                  forControlEvents:UIControlEventTouchDown];
        
        self.membersButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-43, 30, 30, 30)];
        self.membersButton.alpha = 0;
        [self.membersButton addTarget:self action:@selector(membersButtonPressed)
                     forControlEvents:UIControlEventTouchUpInside];
        
        [self.membersButton setBackgroundImage:[UIImage imageNamed:@"feedMembersIcon"] forState:UIControlStateNormal];
        
        
        [effeectViewWrapper addSubview:effectView];
        
        [effeectViewWrapper addSubview:self.backButton];
        [effeectViewWrapper addSubview:self.membersButton];
        [self.cameraViewBackground addSubview:effeectViewWrapper];
        
        
        Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
        if (captureDeviceClass != nil) {
            AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            if ([device hasTorch] && [device hasFlash]){
                
                [device lockForConfiguration:nil];
                [device setFlashMode:AVCaptureFlashModeAuto];
                [device unlockForConfiguration];
                
            }
        }
        
        
        
        self.captureTimeLineWrapper = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 20)];
        self.captureTimeLineWrapper.clipsToBounds = YES;
        
        gradView = [[GradientView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 20)];
        
        [self drawGradientOverContainer:gradView];
        [self.captureTimeLineWrapper addSubview:gradView];
        [mainOutPutFrame addSubview:self.captureTimeLineWrapper];
        
        
        

        
        cameraFeaturesScroller = [[UIScrollView alloc] initWithFrame:self.mainScrollView.frame];
        cameraFeaturesScroller.contentSize = CGSizeMake(self.mainScrollView.frame.size.width*2, self.mainScrollView.frame.size.height);
        cameraFeaturesScroller.pagingEnabled = YES;
        cameraFeaturesScroller.bounces = NO;
        cameraFeaturesScroller.delegate = self;
        cameraFeaturesScroller.tag = ScrollerTypeCameraFeaturesScroller;
        [cameraFeaturesScroller addSubview:mainOutPutFrame];
        
        
//        UIView * testv = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width, 0, mainOutPutFrame.frame.size.width, mainOutPutFrame.frame.size.height)];
//        testv.backgroundColor = [UIColor purpleColor];
//        
//        [cameraFeaturesScroller addSubview:testv];
//        [self createGradientBackgroundVIew];
        
        gradBackgroundView = [[GLCameraGradientView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) colorsArrayInHex:@[@"0xf07480",@"0x40b4b5"]];
        gradBackgroundView.backgroundColor = [UIColor purpleColor];
        
        gradBackgroundViewWrapper = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width, 0, self.view.frame.size.width, self.view.frame.size.height)];
//        gradBackgroundViewWrapper.backgroundColor = [UIColor redColor];
        
        
        
        [gradBackgroundViewWrapper addSubview:gradBackgroundView];
        [cameraFeaturesScroller addSubview:gradBackgroundViewWrapper];
        
        [self createGradientBackgroundVIew];
        
        [self.view addSubview:cameraFeaturesScroller];
        
        [self createResizableTextView];
        
        self.userScore = [[GLUserScore alloc] initWithView:self.view];
        
        
        [self.cameraViewBackground bringSubviewToFront:self.dmut];
//        UISwipeGestureRecognizer*   swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
//        swipeGesture.delegate = self;
//        [mainOutPutFrame addGestureRecognizer:swipeGesture];
        
        
        
        
        
        
        
    }
    return self;
}

//-(void)createResizableTextViewForGradient {
//    
//    CGRect screenRect = kScreenBounds;
//    CGFloat screenWidth = screenRect.size.width;
//    //    CGFloat screenHeight = screenRect.size.height;
//    
//    
////    gradientResizeAbleView
//    
//    CGRect gripFrame = CGRectMake(screenWidth/4, screenWidth/3, screenWidth/2, screenWidth/1.5);
//    self.resizeAbleView = [[GLResizeableView alloc] initWithFrame:gripFrame];
//    UIView *contentView = [[UIView alloc] initWithFrame:gripFrame];
//    [contentView setBackgroundColor:[UIColor clearColor]];
//    self.resizeAbleView.contentView = contentView;
//    self.resizeAbleView.delegate = self;
//    self.resizeAbleView.parentView = self.view;
//    //    [self.resizeAbleView hideEditingHandles];
//    
////    self.resizeAbleView.alpha = 0;
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
//    testLabel = [[UILabel alloc] initWithFrame:CGRectMake(-self.resizeAbleView.frame.size.width, -self.resizeAbleView.frame.size.height, self.resizeAbleView.frame.size.width, self.resizeAbleView.frame.size.height)];
//    testLabel.center = self.resizeAbleView.center;
//    testLabel.text = @"Hi :)";
//    testLabel.font = [UIFont fontWithName:@"GothamRounded-Bold" size:300];
//    testLabel.textAlignment = NSTextAlignmentCenter;
//    testLabel.numberOfLines = 6;
//    testLabel.lineBreakMode = NSLineBreakByTruncatingTail;
//    testLabel.textColor = [UIColor whiteColor];
//    
//    
//    dummyTextField = [[UITextField alloc] initWithFrame:gripFrame];
//    dummyTextField.alpha = 0;
//    dummyTextField.delegate = self;
//    [self.view addSubview:dummyTextField];
//    
//    dummyTextField.returnKeyType = UIReturnKeyDone;
//    dummyTextField.keyboardAppearance = UIKeyboardAppearanceAlert;
//    dummyTextField.textAlignment = NSTextAlignmentCenter;
//    dummyTextField.autocorrectionType = UITextAutocorrectionTypeNo;
//    //    dummyTextField.
//    
//    [dummyTextField addTarget:self
//                       action:@selector(textFieldDidChange)
//             forControlEvents:UIControlEventEditingChanged];
//    
//    dummyTextField.text = testLabel.text;
//    
//    
//    self.editTextViewObj.userInteractionEnabled = NO;
//    
//    testLabel.userInteractionEnabled = NO;
//    
//    self.editTextViewObj.delegate = self;
//    self.editTextViewObj.parentView = self.view;
//    
//    
//    [self.resizeAbleView addSubview:testLabel];
//    [self sizeLabel:testLabel toRect:self.resizeAbleView.contentView.frame];
//    
//    
////    [mainOutPutFrame addSubview:self.resizeAbleView];
//    
//    self.editPallette.alpha = 0;
//    
//    
//    self.colorArray = [[NSMutableArray alloc] init];
//    self.colorArray = @[ @0x000000, @0x262626, @0x4d4d4d, @0x666666, @0x808080, @0x990000, @0xcc0000, @0xfe0000, @0xff5757, @0xffabab, @0xffabab, @0xffa757, @0xff7900, @0xcc6100, @0x994900, @0x996f00, @0xcc9400, @0xffb900, @0xffd157, @0xffe8ab, @0xfff4ab, @0xffe957, @0xffde00, @0xccb200, @0x998500, @0x979900, @0xcacc00, @0xfcff00, @0xfdff57, @0xfeffab, @0xf0ffab, @0xd2ff00, @0xa8cc00, @0x7e9900, @0x038001, @0x04a101, @0x05c001, @0x44bf41, @0x81bf80, @0x81c0b8, @0x41c0af, @0x00c0a7, @0x00a18c, @0x00806f, @0x040099, @0x0500cc, @0x0600ff, @0x5b57ff, @0xadabff, @0xd8abff, @0xb157ff, @0x6700bf, @0x5700a1, @0x450080, @0x630080, @0x7d00a1, @0x9500c0, @0xa341bf, @0xb180bf, @0xbf80b2, @0xbf41a6, @0xbf0199, @0xa10181, @0x800166, @0x999999, @0xb3b3b3, @0xcccccc, @0xe6e6e6, @0xffffff];
//    
//    int numOfColors = 69;
//    
//    
//    
//    self.colors = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
//    self.colors.backgroundColor = [UIColor clearColor];
//    self.colors.delegate = self;
//    
//    UITapGestureRecognizer *colorSelectedGest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(colorDidSelected:)];
//    [colorSelectedGest setDelegate:self];
//    
//    [self.colors addGestureRecognizer:colorSelectedGest];
//    
//    self.colorViewsArray = [[NSMutableArray alloc] init];
//    
//    for(int x = 0; x < numOfColors;x++){
//        
//        UIView * colorView = [[UIView alloc] initWithFrame:CGRectMake(x*40, 4, 33, 33)];
//        colorView.clipsToBounds = NO;
//        colorView.layer.cornerRadius = 16.5;
//        int c = (int)[self.colorArray objectAtIndex:x];
//        colorView.backgroundColor = UIColorFromRGB(c);
//        [self.colorViewsArray addObject:colorView];
//        [self.colors addSubview:colorView];
//        
//    }
//    
//    self.colors.contentSize = CGSizeMake(numOfColors*40,50);
//    self.colors.tag = ScrollerTypeColorsScroller;
//    
//    UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 37)];
//    numberToolbar.barStyle = UIBarStyleBlackTranslucent;
//    [numberToolbar addSubview:self.colors];
//    
//    dummyTextField.inputAccessoryView = numberToolbar;
//    
//}

//- (void)toggleGradView {
//    
//    [self.videoCamera pauseCameraCapture];
//    [self createGradientBackgroundVIew];
//    doingGeadientBg = YES;
//    [dummyTextField becomeFirstResponder];
//    [self presentTheGradientScroller];
//}

- (void)createGradientBackgroundVIew {
    
    
//    GLCameraGradientView * gradBackgroundView = [[GLCameraGradientView alloc] initWithFrame:CGRectMake(self.view.frame.size.width*2, 0, self.view.frame.size.width, self.view.frame.size.width) colorsArrayInHex:@[@"0xf07480",@"0x40b4b5"]];
//    [cameraFeaturesScroller addSubview:gradBackgroundView];
    
//    [self addTextToImageTapped];
//    [mainOutPutFrame bringSubviewToFront:self.resizeAbleView];
    
    
    
    gradientColorsScroller = [[UIScrollView alloc] initWithFrame:CGRectMake(5, 20, self.view.frame.size.width-5, 50)];
    gradientColorsScroller.backgroundColor = [UIColor clearColor];
    gradientColorsScroller.delegate = self;
    
    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    
    gradientBlurredBgEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    
    gradientBlurredBgEffectView.frame = CGRectMake(0, 0, self.view.frame.size.width, 65);
    [gradientBlurredBgEffectView addSubview:gradientColorsScroller];
    
    
    [gradBackgroundViewWrapper addSubview:gradientBlurredBgEffectView];
//    
    UITapGestureRecognizer * gradientColorSelected = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gradientColorDidSelected:)];
    [gradientColorSelected setDelegate:self];
    
    [gradientColorsScroller addGestureRecognizer:gradientColorSelected];
    
    gradientColorViewsArray = [[NSMutableArray alloc] init];
    
    gradientColorsArray = @[@0xffd1dc,@0xd1fff4,@0xffd1f3,@0xffd1dc,@0xffddd1,@0xd1f3ff,@0xd1ffdd,@0xd1dcff, @0xdcffd1,@0xf4d1ff,@0xdcffd1,@0xd1fff4,@0xff85a2,@0xff9eb5,@0xffb8c9,@0xffd1dc, @0xffebef, @0xfdfd96,@0x9696fd,@0xfdca96,@0xfdfd96,@0xcafd96,@0xff6961,@0xff6181, @0xff6173,@0xff6166,@0xff6961,@0xff7661,@0x77dd77,@0xffb347];
    
    for(int x = 0; x < gradientColorsArray.count;x++){
        
        UIView * colorView = [[UIView alloc] initWithFrame:CGRectMake(x*40, 4, 33, 33)];
        colorView.clipsToBounds = NO;
        //        colorView.layer.cornerRadius = 16.5;
        int c = (int)[gradientColorsArray objectAtIndex:x];
        colorView.backgroundColor = UIColorFromRGB(c);
        [gradientColorViewsArray addObject:colorView];
        [gradientColorsScroller addSubview:colorView];
        
    }
    
    gradientColorsScroller.contentSize = CGSizeMake(gradientColorsArray.count*40,50);
    gradientColorsScroller.tag = ScrollerTypeColorsScroller;
    
    
    
    
    
    //    [dummyTextField becomeFirstResponder];
    
    
}

-(void)presentTheGradientScroller {
    
    [UIView animateWithDuration:0.3 animations:^{
        gradientBlurredBgEffectView.frame = CGRectMake(0, 0, self.view.frame.size.width, 65);
        //        flashButton.alpha = 0;
    }];
    
}

-(void)hideTheGradientScroller {
    [UIView animateWithDuration:0.3 animations:^{
        gradientBlurredBgEffectView.frame = CGRectMake(0, -65, self.view.frame.size.width, 65);
    }];
}

- (void)gradientColorDidSelected:(UITapGestureRecognizer *)tapGesture {
    
    CGPoint touchPoint = [tapGesture locationInView: gradientColorsScroller];
    NSLog(@"the x is: %f",floor((touchPoint.x+0.5)/40));
    
    int tIndex = floor((touchPoint.x+0.5)/40);
    
    int tempColor = (int)[gradientColorsArray objectAtIndex:tIndex];
    
    UIColor * one = UIColorFromRGB(tempColor);
    UIColor * two = UIColorFromRGB(tempColor);
    
    [gradBackgroundView updateGradientWithColors:@[one,two]];
    
    
    UIView * selectedColorView = [gradientColorViewsArray objectAtIndex:tIndex];
    
    for(UIView * colorV in gradientColorViewsArray){
        if(colorV == selectedColorView){
            colorV.clipsToBounds = YES;
            
            [UIView animateWithDuration:0.3 animations:^{
                
                colorV.transform = CGAffineTransformScale(colorV.transform, 0.3, 0.3);
                
            } completion:^(BOOL finished){
                [UIView animateWithDuration:0.3 animations:^{
                    colorV.transform = CGAffineTransformScale(colorV.transform, 2, 2);
                }];
                
            }];
            
        } else {
            if(colorV.clipsToBounds){
                colorV.clipsToBounds = NO;
                [UIView animateWithDuration:0.3 animations:^{
                    colorV.transform = CGAffineTransformScale(colorV.transform, 1.6, 1.6);
                }];
            }
        }
    }
    
    
    //    [UIView transitionWithView:testLabel duration:0.20 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
    //        [testLabel setTextColor:UIColorFromRGB(tempColor)];
    //        testLabel.transform = CGAffineTransformScale(testLabel.transform, 1.20f, 1.20f);
    //    } completion:^(BOOL finished) {
    //        [UIView transitionWithView:testLabel duration:0.20 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
    //            testLabel.transform = CGAffineTransformIdentity;
    //        } completion:nil];
    //    }];
    
}

- (void)colorDidSelected:(UITapGestureRecognizer *)tapGesture {
    
    CGPoint touchPoint = [tapGesture locationInView: self.colors];
    NSLog(@"the x is: %f",(touchPoint.x/40));
    
    int tIndex = floor(touchPoint.x/40);
    
    int tempColor = (int)[self.colorArray objectAtIndex:tIndex];
    
    UIView * selectedColorView = [self.colorViewsArray objectAtIndex:tIndex];
    
    for(UIView * colorV in self.colorViewsArray){
        if(colorV == selectedColorView){
            colorV.clipsToBounds = YES;
            
            [UIView animateWithDuration:0.3 animations:^{
                
                colorV.transform = CGAffineTransformScale(colorV.transform, 0.3, 0.3);
                
            } completion:^(BOOL finished){
                [UIView animateWithDuration:0.3 animations:^{
                    colorV.transform = CGAffineTransformScale(colorV.transform, 2, 2);
                }];
                
            }];
            
        } else {
            if(colorV.clipsToBounds){
                colorV.clipsToBounds = NO;
                [UIView animateWithDuration:0.3 animations:^{
                    colorV.transform = CGAffineTransformScale(colorV.transform, 1.6, 1.6);
                }];
            }
        }
    }
    
    
    [UIView transitionWithView:testLabel duration:0.20 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [testLabel setTextColor:UIColorFromRGB(tempColor)];
        testLabel.transform = CGAffineTransformScale(testLabel.transform, 1.20f, 1.20f);
    } completion:^(BOOL finished) {
        [UIView transitionWithView:testLabel duration:0.20 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            testLabel.transform = CGAffineTransformIdentity;
        } completion:nil];
    }];
    
}


- (IBAction)captureDragged:(UIPanGestureRecognizer *)recognizer {
    
    CGPoint translation = [recognizer translationInView:mainOutPutFrame];
    
    
    
    //    if(translation.y < mainOutPutFrame.frame.size.height){
    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                         recognizer.view.center.y + translation.y);
    //    }
    
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        // Check here for the position of the view when the user stops touching the screen
        
        // Set "CGFloat finalX" and "CGFloat finalY", depending on the last position of the touch
        
        // Use this to animate the position of your view to where you want
        [UIView animateWithDuration: 0.2
                              delay: 0
                            options: UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             //                             CGPoint finalPoint = CGPointMake(recognizer.view.frame.origin.x, recognizer.view.frame.origin.y);
                             //                             recognizer.view.center = finalPoint; }
                             
                         }
                         completion:nil];
    }
    
    
    [recognizer setTranslation:CGPointMake(0, 0) inView:mainOutPutFrame];
    
}


-(void)backFromVideoTapped {
    [self.videoCamera startCameraCapture];
    [self.previewPlayer stop];
    [self.previewPlayer.view removeFromSuperview];
    //    self.goneUploadAmovie = NO;
    [UIView animateWithDuration:0.2 animations:^{
        //            self.carousel.frame = CGRectMake(self.carousel.frame.origin.x, self.carousel.frame.origin.y+self.carousel.frame.size.height, self.carousel.frame.size.width, self.carousel.frame.size.height);
        self.animatedView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.shadowAnimation stop];
    }];
    [UIView animateWithDuration:0.2 animations:^{
        flashButton.alpha = 1;
        flipCameraButton.alpha = 1;
        captureButton.alpha = 1;
        for(GLFilterView * filterView in self.arrayOfFilters){
            filterView.title.alpha = 1;
        }
    }];
    
    
}

-(void)completeCapturing {
    
    //    [self.videoCamera stopCameraCapture];
    
    self.captureTimeLineWrapper.alpha = 0;
    self.captureTimeLineWrapper.frame = CGRectMake(0, 0, 0, 20);
    
    
    
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mp4"];
    
    NSString *path = [NSString stringWithFormat:@"%@/recordFinished.wav", [[NSBundle mainBundle] resourcePath]];
    NSURL *soundUrl = [NSURL fileURLWithPath:path];
    
    [self.theAudio stop];
    // Create audio player object and initialize with URL to sound
    self.theAudio = [[AVAudioPlayer alloc] initWithContentsOfURL:soundUrl error:nil];
    [self.theAudio play];
    
    GLFilterView * filter = [self.arrayOfFilters objectAtIndex:currentFilterIndex];
    [filter.filter removeTarget:self.movieWriter];
    
    [self.movieWriter finishRecordingWithCompletionHandler:^{
        
        [self.videoCamera stopCameraCapture];
        
        // Wait a little bit since it seems that it takes some time for the file to be fully written to disk
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            self.library = [[ALAssetsLibrary alloc] init];
            NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mp4"];
            [self.library saveVideoWithPath:pathToMovie toAlbum:@"Glance" withCompletionBlock:^(NSError *error) {
            }];
            
            NSLog(@"Movie completed and written to disk im ready to start upload but before that we neeed to display the priview of tht movie");
            
            
            self.goneUploadAmovie = YES;
            [UIView animateWithDuration:0.2 animations:^{
                
                self.animatedView.alpha = 1;
                //                [UIView animateWithDuration:0.2 animations:^{
                //                    self.animatedView.transform = CGAffineTransformScale(self.animatedView.transform, 1.5, 1.5);
                //                } completion:^(BOOL finished) {
                //
                //                }];
                
                
            } completion:^(BOOL finished) {
                [self.shadowAnimation start];
                
                
                
                
            }];
            
            [UIView animateWithDuration:0.2 animations:^{
                captureButton.alpha = 0;
            }];
            
            self.previewPlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:pathToMovie]];
            [self.previewPlayer.view setFrame:mainOutPutFrame.frame];
            [mainOutPutFrame addSubview:self.previewPlayer.view];
            
            self.videoPreviewCloseButton = [[UIButton alloc] initWithFrame:backToCameraButton.frame];
            [self.videoPreviewCloseButton setImage:backToCameraButton.imageView.image forState:UIControlStateNormal];
            [self.videoPreviewCloseButton addTarget:self action:@selector(backFromVideoTapped) forControlEvents:UIControlEventTouchUpInside];
            [self.previewPlayer.view addSubview:self.videoPreviewCloseButton];
            
            [self.previewPlayer prepareToPlay];
            self.previewPlayer.view.clipsToBounds = YES;
            self.previewPlayer.movieSourceType = MPMovieSourceTypeFile;
            self.previewPlayer.scalingMode = MPMovieScalingModeAspectFill;
            self.previewPlayer.controlStyle = MPMovieControlStyleNone;
            self.previewPlayer.shouldAutoplay = YES;
            self.previewPlayer.repeatMode = MPMovieRepeatModeOne;
            
            
            UIImage *screenShot =  [self.previewPlayer thumbnailImageAtTime:1 timeOption:MPMovieTimeOptionExact];
            [self saveVideoThumbToFile:screenShot];
            [self.previewPlayer play];
            self.movieWriter = nil;
            
            
            
            
            
        });
        
    }];
    
    self.videoCamera.audioEncodingTarget = nil;
    [self.videoCaptureTimer invalidate];
    self.videoCaptureTimer = nil;
    
    
}




-(void)saveVideoThumbToFile:(UIImage*)image {
    
    
    __block NSString *filePath = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/Library/Caches/Video_Photo%i.jpg", 0]];
    
    
    // Save large image
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    dispatch_async(queue, ^(void) {
        
        
        
        
        [UIImageJPEGRepresentation(image, 1.0) writeToFile:filePath atomically:YES];
        
        CFURLRef url = CFURLCreateWithString(NULL, (CFStringRef)[NSString stringWithFormat:@"file://%@", filePath], NULL);
        CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypeJPEG, 1, NULL);
        CFRelease(url);
        
        NSDictionary *jfifProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        (__bridge id)kCFBooleanTrue, kCGImagePropertyJFIFIsProgressive,
                                        nil];
        
        NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithFloat:.7], kCGImageDestinationLossyCompressionQuality,
                                    jfifProperties, kCGImagePropertyJFIFDictionary,
                                    nil];
        
        CGImageDestinationAddImage(destination, ((UIImage*)image).CGImage, (__bridge CFDictionaryRef)properties);
        CGImageDestinationFinalize(destination);
        CFRelease(destination);
        
        
        NSLog(@"FINISH to SAVE NO MAIN QUE with path %@",filePath);
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
        if(fileExists){
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"FINISH to write image");
            });
        } else {
            NSLog(@"file wasnt saved correctly !!! isnt found on path!");
        }
    });
}


-(void)captureReachedMaxTime {
    self.captureStoppedByTimer = YES;
    [self completeCapturing];
}

-(void)startCapturingVideo {
    
    
    [UIView animateWithDuration:0.2 animations:^{
        flashButton.alpha = 0;
        flipCameraButton.alpha = 0;
        for(GLFilterView * filterView in self.arrayOfFilters){
            filterView.title.alpha = 0;
        }
    }];
    
    self.captureStoppedByTimer = NO;
    
    NSString *path = [NSString stringWithFormat:@"%@/recordStart.wav", [[NSBundle mainBundle] resourcePath]];
    NSURL *soundUrl = [NSURL fileURLWithPath:path];
    
    [self.theAudio stop];
    // Create audio player object and initialize with URL to sound
    self.theAudio = [[AVAudioPlayer alloc] initWithContentsOfURL:soundUrl error:nil];
    [self.theAudio play];
    
    GLFilterView * filter = [self.arrayOfFilters objectAtIndex:currentFilterIndex];
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mp4"];
    
    unlink([pathToMovie UTF8String]);
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    [[NSFileManager defaultManager] removeItemAtURL:movieURL error:nil];
    
    
    self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(480.0, 640.0)];
    self.movieWriter.encodingLiveVideo = YES;
    self.videoCamera.audioEncodingTarget = self.movieWriter;
    
    [filter.filter addTarget:self.movieWriter];
    
    NSLog(@"Start recording");
    
    NSError *error = nil;
    if (![self.videoCamera.inputCamera lockForConfiguration:&error])
    {
        NSLog(@"Error locking for configuration: %@", error);
    }
    
    
    if(flashState == 0){
        if([self.videoCamera.inputCamera isTorchModeSupported:AVCaptureTorchModeOn]){
            [self.videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOn];
        }
    } else if(flashState == 1){
        if([self.videoCamera.inputCamera isTorchModeSupported:AVCaptureTorchModeOff]){
            [self.videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOff];
        }
    } else if (flashState == 2){
        if([self.videoCamera.inputCamera isTorchModeSupported:AVCaptureTorchModeAuto]){
            [self.videoCamera.inputCamera setTorchMode:AVCaptureTorchModeAuto];
        }
    }
    
    
    [self.videoCamera.inputCamera unlockForConfiguration];
    
    [self.movieWriter startRecording];
    self.videoCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:10.0
                                                              target:self
                                                            selector:@selector(captureReachedMaxTime)
                                                            userInfo:nil
                                                             repeats:NO];
    
}

- (void)drawGradientOverContainer:(UIView *)container
{
    
    
    UIColor * yellow = UIColorFromRGB(0xfcd22e);
    UIColor * green = UIColorFromRGB(0x36a6a5);
    UIColor * pink = UIColorFromRGB(0xe95b6d);
    
    CAGradientLayer *maskLayer = [CAGradientLayer layer];
    maskLayer.opacity = 1.0;
    maskLayer.colors = [NSArray arrayWithObjects:(id)pink.CGColor,
                        (id)yellow.CGColor, (id)green.CGColor, nil];
    
    // Hoizontal - commenting these two lines will make the gradient veritcal
    maskLayer.startPoint = CGPointMake(0.0, 0.5);
    maskLayer.endPoint = CGPointMake(1.0, 0.5);
    
    NSNumber *gradTopStart = [NSNumber numberWithFloat:0.0];
    NSNumber *gradTopEnd = [NSNumber numberWithFloat:0.6];
    NSNumber *gradBottomStart = [NSNumber numberWithFloat:0.9];
    NSNumber *gradBottomEnd = [NSNumber numberWithFloat:1.0];
    maskLayer.locations = @[gradTopStart, gradTopEnd, gradBottomStart, gradBottomEnd];
    
    maskLayer.bounds = container.bounds;
    maskLayer.anchorPoint = CGPointZero;
    [container.layer addSublayer:maskLayer];
}

- (void)handleBtnLongPressgesture:(UILongPressGestureRecognizer *)recognizer{
    
    
    //as you hold the button this would fire
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        
        
        self.captureTimeLineWrapper.frame = CGRectMake(0, 0, 0, 20);
        self.captureTimeLineWrapper.alpha = 1;
        [UIView animateWithDuration:10.0 animations:^{
            self.captureTimeLineWrapper.frame = CGRectMake(0, 0, self.view.frame.size.width, 20);
        } completion:^(BOOL finished) {
            if(self.captureTimeLineWrapper.alpha == 1){
                self.captureTimeLineWrapper.alpha = 0;
                self.captureTimeLineWrapper.frame = CGRectMake(0, 0, 0, 20);
            }
        }];
        
        NSLog(@"Hold Began");
        [self startCapturingVideo];
    }
    
    //as you release the button this would fire
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        
        
        if(!self.captureStoppedByTimer){
            NSLog(@"Hold Ended");
            
            [self completeCapturing];
        }
    }
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
            
            if(firstY+location.y < self.view.frame.size.height - self.dmut.frame.size.height){
                
                [cameraWrapper setFrame:CGRectMake(0, 0, cameraWrapper.frame.size.width, firstY+location.y+35)];
                [self.cameraViewBackground setFrame:CGRectMake(0, 0, self.cameraViewBackground.frame.size.width, firstY+location.y+35)];
                
                //        dmut.frame = CGRectMake(27, firstY+location.y
                //                                , 320, 110);
                self.dmut.center = CGPointMake(firstX, firstY+location.y);
                
            } else {
                
                [cameraWrapper setFrame:CGRectMake(0, 0, cameraWrapper.frame.size.width, firstY+location.y+35)];
                [self.cameraViewBackground setFrame:CGRectMake(0, 0, self.cameraViewBackground.frame.size.width, firstY+location.y+35)];
                
            }
            
            
            
        }
        
        
        //
        //
    } else if(gest.state == UIGestureRecognizerStateEnded){
        
        
        self.dmut.userInteractionEnabled = NO;
        
        CGPoint velocity = [gest velocityInView:self.view];
        
        if (velocity.y < 0)   // panning down
        {
            
            
            [UIView animateWithDuration:0.3 animations:^(){
                
                
                
                
                if(self.isInFeedMode){
                    
                    //                    [[self videoCamera] stopCameraCapture];
                    [cameraWrapper setFrame:CGRectMake(0, 0, cameraWrapper.frame.size.width, 60)];
                    effectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
                    effectView.alpha = 1;
                    effeectViewWrapper.hidden = NO;
                    effeectViewWrapper.alpha = 1;

                    //                    effectView.hidden = NO;
                    self.dmut.center = CGPointMake(firstX, 60);
                    [self.cameraViewBackground setFrame:CGRectMake(0, 0, self.cameraViewBackground.frame.size.width, 60)];
                    self.backButton.alpha=1;
                    self.membersButton.alpha=1;
                    self.picYourGroup.alpha = 0;
                    glanceLogo.alpha = 0;
                    scoreBg.alpha = 0;
                    
                } else {
                    
                    self.picYourGroup.alpha = 1;
                    glanceLogo.alpha = 1;
                    scoreBg.alpha = 1;
                    [cameraWrapper setFrame:CGRectMake(0, 0, cameraWrapper.frame.size.width, self.view.frame.size.height/3)];
                    self.dmut.center = CGPointMake(firstX, cameraSlideTopLimit);
                    [self.cameraViewBackground setFrame:CGRectMake(0, 0, self.cameraViewBackground.frame.size.width, self.view.frame.size.height/3)];
                }
                
                if(!self.isInFeedMode){
                    self.dmut.transform = CGAffineTransformIdentity;
                }
                
            } completion:^(BOOL finished) {
                //                if(self.isInFeedMode){
                //                    [[self videoCamera] stopCameraCapture];
                //                }
                
                
                
                if(cameraIsOpen == YES){
                    
                    
                    
                    [self cameraFinishedSlidingClose];
                    
                    if(self.isInFeedMode){
                        [[GLContainersViewController sharedInstance] enableSideMembers];
                    }
                    
                    NSLog(@"camera closed");
                    [self resetFeaturesScroller];
                    //                    if(cameraIsOpen == YES){
                    if(!self.isInFeedMode){
                        [[GLContainersViewController sharedInstance] unlockScrollingPages];
                        //                [[ContainerViewController sharedInstance] lockScrolling:NO];
                    }
                    //                    self.cropViewController.view
                    [self.cropViewController.view removeFromSuperview];
                    [self.cropViewController removeFromParentViewController];
                    self.cropViewController = nil;
                    self.dmut.userInteractionEnabled = YES;
                    cameraIsOpen = NO;
                    //                    }
                } else {
                    self.dmut.userInteractionEnabled = YES;
                }
                
                //                self.cameraIsShown = YES;
                //                [[GLSharedVideoPlayer sharedInstance] play];
                //
                //                if(self.isInFeedMode){
                //                    self.score.alpha = 0;
                //                    scoreBg.alpha = 0 ;
                //                }
            }];
            //            [self toggleCamera:YES];
            
            
            
        }
        else                // panning up
        {
            
            [UIView animateWithDuration:0.3 animations:^(){
                
                self.picYourGroup.alpha = 0;
                glanceLogo.alpha = 0;
                scoreBg.alpha = 0;
                self.score.alpha = 0;
                
                [cameraWrapper setFrame:CGRectMake(0, 0, cameraWrapper.frame.size.width, self.view.frame.size.height)];
                
                [self.cameraViewBackground setFrame:CGRectMake(0, 0, self.cameraViewBackground.frame.size.width, self.view.frame.size.height)];
                
                if(self.isInFeedMode){
                    self.backButton.alpha=0;
                    self.membersButton.alpha=0;
                    
                    effeectViewWrapper.hidden = YES;
                    effectView.effect = nil;
                    effectView.alpha = 0;
                    effeectViewWrapper.alpha = 0;
                    
                    //                    effectView.alpha = 0;
                    //                    effectView.hidden = YES;
                    self.dmut.center = CGPointMake(firstX, self.view.frame.size.height-187.5);
                } else {
                    self.dmut.center = CGPointMake(firstX, self.view.frame.size.height-187.5);
                }
                
                
                if(!self.isInFeedMode){
                    CGFloat xScale = self.dmut.transform.a;
                    
                    if(xScale == 1){
                        self.dmut.transform = CGAffineTransformScale(self.dmut.transform, 0.6, 0.6);
                    }
                    
                }
            } completion:^(BOOL finished) {
                
                
                if(cameraIsOpen == NO){
                    
                    NSLog(@"camera open");
                    [[GLContainersViewController sharedInstance] lockScrollingPages];
                    [[GLContainersViewController sharedInstance] disableSideMembers];
                    [self cameraFinishedSlidingOpen];
                    
                    cameraIsOpen = YES;
                    
                } else {
                    self.dmut.userInteractionEnabled = YES;
                }
                
                
            }];
            
        }
        
    }
    
}

- (void)hideCameraButtons {
    
    
    for(GLFilterView * filterView in self.arrayOfFilters){
        filterView.title.alpha = 0;
    }
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         
                         
                         flipCameraButton.alpha = 0;
                         flashButton.alpha = 0;
                         
                     } completion:NULL];
    
}

- (void)showCameraButtons {
    
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         
                         for(GLFilterView * filterView in self.arrayOfFilters){
                             filterView.title.alpha = 1;
                         }
                         flipCameraButton.alpha = 1;
                         flashButton.alpha = 1;
                     } completion:NULL];
    
}

- (void)cameraFinishedSlidingOpen {
    
    
    self.dmut.userInteractionEnabled = YES;
    [self.userScore hideUserScore];
    [self showCameraButtons];
    
    [[self videoCamera] startCameraCapture];
    [[GLSharedVideoPlayer sharedInstance] pause];
    
}

-(void)cameraFinishedSlidingClose {
    
    [self hideCameraButtons];
    [self.userScore showUserScore];
    self.dmut.userInteractionEnabled = YES;
    [self backToCameraFromEditPallette:nil];
    [self hideCameraButtons];
    
    if(self.isInFeedMode){
        [[self videoCamera] stopCameraCapture];
        [[GLSharedVideoPlayer sharedInstance] play];
    } else {
        [[self videoCamera] startCameraCapture];
    }
    
    
}

-(void)setCameraInMain {
    self.isInFeedMode = NO;
    [self.userScore showUserScore];
    [self hideCameraButtons];
    [[self videoCamera] startCameraCapture];
    [UIView animateWithDuration:0.2 animations:^{
        self.dmut.transform = CGAffineTransformIdentity;
        effeectViewWrapper.hidden = YES;
        effectView.effect = nil;
        effectView.alpha = 0;
        effeectViewWrapper.alpha = 0;
        self.cameraViewBackground.frame = CGRectMake(0, 0, self.view.frame.size.width, (self.view.frame.size.height/3));
        cameraWrapper.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height/3);
        self.dmut.frame = CGRectMake(60, ([UIScreen mainScreen].bounds.size.height/3)-86, 256, 104);
    }];
}

- (void)setCameraInFeedAfterGroupOpenedWithoutImage {
    
    self.isInFeedMode = YES;
    [[self videoCamera] stopCameraCapture];
    [UIView animateWithDuration:0.2 animations:^{
        
        effeectViewWrapper.hidden = NO;
        effectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        effectView.alpha = 1;
        effeectViewWrapper.alpha = 1;
        self.backButton.alpha = 1;
        self.membersButton.alpha = 1;
        scoreBg.alpha = 0;
        self.score.alpha = 0;
        self.dmut.frame = CGRectMake(self.dmut.frame.origin.x, 20, self.dmut.frame.size.width, self.dmut.frame.size.height);
        
        effectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        effectView.alpha = 1;
        effeectViewWrapper.alpha = 1;
        [self.cameraViewBackground bringSubviewToFront:effeectViewWrapper];
        
        self.dmut.transform = CGAffineTransformScale(self.dmut.transform, 0.60, 0.60);
        self.dmut.center = CGPointMake(self.dmut.center.x, self.dmut.center.y-12.5);
        
        cameraWrapper.frame = CGRectMake(0, 0, cameraWrapper.frame.size.width, 80);
        self.cameraViewBackground.frame = CGRectMake(0, 0, self.cameraViewBackground.frame.size.width, 80);
        
        
        [self.cameraViewBackground bringSubviewToFront:self.dmut];
    }];
    
}

- (void)setCameraInFeed {
    
    self.isInFeedMode = YES;
    [[self videoCamera] stopCameraCapture];
    [self.cameraViewBackground bringSubviewToFront:self.dmut];
    
    
}

-(void)setInFeedMode:(BOOL)feed dmutNeedTransform:(BOOL)needTransform {
    
    if(feed){
        
        [[self videoCamera] stopCameraCapture];
        
        [UIView animateWithDuration:0.2 animations:^{
            
            self.dmut.frame = CGRectMake(self.dmut.frame.origin.x, 20, self.dmut.frame.size.width, self.dmut.frame.size.height);
            effeectViewWrapper.hidden = NO;
            effectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
            effectView.alpha = 1;
            effeectViewWrapper.alpha = 1;
            if(needTransform != NO){
                self.dmut.transform = CGAffineTransformScale(self.dmut.transform, 0.60, 0.60);
                self.dmut.center = CGPointMake(self.dmut.center.x, self.dmut.center.y-12.5);
            }
            
            
            cameraWrapper.frame = CGRectMake(0, 0, cameraWrapper.frame.size.width, 80);
            self.cameraViewBackground.frame = CGRectMake(0, 0, self.cameraViewBackground.frame.size.width, 80);
            [self.cameraViewBackground bringSubviewToFront:self.dmut];
        }];
        
    } else {
        
        [[self videoCamera] startCameraCapture];
        [UIView animateWithDuration:0.2 animations:^{
            self.dmut.transform = CGAffineTransformIdentity;
            effeectViewWrapper.hidden = YES;
            effectView.effect = nil;
            effectView.alpha = 0;
            effeectViewWrapper.alpha = 0;
            self.cameraViewBackground.frame = CGRectMake(0, 0, self.view.frame.size.width, (self.view.frame.size.height/3));
            cameraWrapper.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height/3);
            self.dmut.frame = CGRectMake(60, ([UIScreen mainScreen].bounds.size.height/3)-86, 256, 104);
        }];
        
    }
    self.isInFeedMode = feed;
    
}

-(void)membersButtonPressed {
    
    [self.delegate membersPressed];
}

-(void)backButtonPressed {
    [self.delegate backPressed];
}
-(void)abortUploadButtonTapped {
    [self hideCamera];
}

- (void)fixAfterLogin {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self createMainScrollView];
    });
}

- (void)setupVideoCamera {
    
    self.videoCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    self.videoCamera.horizontallyMirrorRearFacingCamera = NO;
    [self createFiltersViews];
    [self createMainScrollView];
    [self.videoCamera startCameraCapture];
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


- (void) sizeLabel: (UILabel *) label toRect: (CGRect) labelRect  {
    
    // Set the frame of the label to the targeted rectangle
    label.frame = labelRect;
    
    // Try all font sizes from largest to smallest font size
    int fontSize = 300;
    int minFontSize = 5;
    
    // Fit label width wize
    CGSize constraintSize = CGSizeMake(label.frame.size.width, MAXFLOAT);
    
    do {
        // Set current font size
        label.font = [UIFont fontWithName:label.font.fontName size:fontSize];
        
        // Find label size for current font size
        CGRect textRect = [[label text] boundingRectWithSize:constraintSize
                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                  attributes:@{NSFontAttributeName:label.font}
                                                     context:nil];
        
        CGSize labelSize = textRect.size;
        
        // Done, if created label is within target size
        if( labelSize.height <= label.frame.size.height )
            break;
        
        // Decrease the font size and try again
        fontSize -= 2;
        
    } while (fontSize > minFontSize);
}

-(void)createResizableTextView {
    
    CGRect screenRect = kScreenBounds;
    CGFloat screenWidth = screenRect.size.width;
    //    CGFloat screenHeight = screenRect.size.height;
    
    CGRect gripFrame = CGRectMake(screenWidth/4, screenWidth/3, screenWidth/2, screenWidth/1.5);
    self.resizeAbleView = [[GLResizeableView alloc] initWithFrame:gripFrame];
    UIView *contentView = [[UIView alloc] initWithFrame:gripFrame];
    [contentView setBackgroundColor:[UIColor clearColor]];
    self.resizeAbleView.contentView = contentView;
    self.resizeAbleView.delegate = self;
    self.resizeAbleView.parentView = self.view;
    //    [self.resizeAbleView hideEditingHandles];
    
    self.resizeAbleView.alpha = 1;
    
    
    CGFloat minWidth  = 100;
    CGFloat minHeight = 50;
    
    UITapGestureRecognizer * tapOnWindow = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resizeableTapped:)];
    [self.resizeAbleView addGestureRecognizer:tapOnWindow];
    
    
    
    
    testLabel = [[UILabel alloc] initWithFrame:CGRectMake(-self.resizeAbleView.frame.size.width, -self.resizeAbleView.frame.size.height, self.resizeAbleView.frame.size.width, self.resizeAbleView.frame.size.height)];
    testLabel.center = self.resizeAbleView.center;
    testLabel.text = @"Hi :)";
    testLabel.font = [UIFont fontWithName:@"GothamRounded-Bold" size:300];
    testLabel.textAlignment = NSTextAlignmentCenter;
    testLabel.numberOfLines = 6;
    testLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    testLabel.textColor = [UIColor whiteColor];
    
    
    dummyTextField = [[UITextField alloc] initWithFrame:gripFrame];
    dummyTextField.alpha = 0;
    dummyTextField.delegate = self;
    [self.view addSubview:dummyTextField];
    
    dummyTextField.returnKeyType = UIReturnKeyDone;
    dummyTextField.keyboardAppearance = UIKeyboardAppearanceAlert;
    dummyTextField.textAlignment = NSTextAlignmentCenter;
    dummyTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    //    dummyTextField.
    
    [dummyTextField addTarget:self
                       action:@selector(textFieldDidChange)
             forControlEvents:UIControlEventEditingChanged];
    
    dummyTextField.text = testLabel.text;
    
    
    self.editTextViewObj.userInteractionEnabled = NO;
    
    testLabel.userInteractionEnabled = NO;
    
    self.editTextViewObj.delegate = self;
    self.editTextViewObj.parentView = self.view;
    
    
    [self.resizeAbleView addSubview:testLabel];
    [self sizeLabel:testLabel toRect:self.resizeAbleView.contentView.frame];
    
    
    [gradBackgroundView addSubview:self.resizeAbleView];
    
    self.editPallette.alpha = 0;
    
    
    
    
    int numOfColors = 69;
    
    
    
    self.colors = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    self.colors.backgroundColor = [UIColor clearColor];
    self.colors.delegate = self;
    
    UITapGestureRecognizer *colorSelectedGest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(colorDidSelected:)];
    [colorSelectedGest setDelegate:self];
    
    [self.colors addGestureRecognizer:colorSelectedGest];
    
    self.colorViewsArray = [[NSMutableArray alloc] init];
    
    for(int x = 0; x < numOfColors;x++){
        
        UIView * colorView = [[UIView alloc] initWithFrame:CGRectMake(x*40, 4, 33, 33)];
        colorView.clipsToBounds = NO;
        colorView.layer.cornerRadius = 16.5;
        int c = (int)[self.colorArray objectAtIndex:x];
        colorView.backgroundColor = UIColorFromRGB(c);
        [self.colorViewsArray addObject:colorView];
        [self.colors addSubview:colorView];
        
    }
    
    self.colors.contentSize = CGSizeMake(numOfColors*40,50);
    self.colors.tag = ScrollerTypeColorsScroller;
    
    UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 37)];
    numberToolbar.barStyle = UIBarStyleBlackTranslucent;
    [numberToolbar addSubview:self.colors];
    
    dummyTextField.inputAccessoryView = numberToolbar;
    
}


-(void)textFieldDidChange {
    
    testLabel.text = dummyTextField.text;
    [self sizeLabel:testLabel toRect:self.resizeAbleView.contentView.frame];
    
    
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
    [self.arrayOfFilters addObject:missEtikateFilter];
    
    foggyNightFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_FOGGYNIGHT];
    foggyNightFilter.delegate = self;
    [self.arrayOfFilters addObject:foggyNightFilter];
    
    lateSunsetFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_LATESUNSET];
    lateSunsetFilter.delegate = self;
    [self.arrayOfFilters addObject:lateSunsetFilter];
    
    cosmopolitanFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_COSMOPOLITAN];
    cosmopolitanFilter.delegate = self;
    [self.arrayOfFilters addObject:cosmopolitanFilter];
    
    daquiriFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_DAQUIRI];
    daquiriFilter.delegate = self;
    [self.arrayOfFilters addObject:daquiriFilter];
    
    fizzFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_FIZZ];
    fizzFilter.delegate = self;
    [self.arrayOfFilters addObject:fizzFilter];
    
    margaritaFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_MARGARITA];
    margaritaFilter.delegate = self;
    [self.arrayOfFilters addObject:margaritaFilter];
    
    martiniFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_MARTINI];
    martiniFilter.delegate = self;
    [self.arrayOfFilters addObject:martiniFilter];
    
    mojitoFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_MOJITO];
    mojitoFilter.delegate = self;
    [self.arrayOfFilters addObject:mojitoFilter];
    
    sepiaFIlter = [[GLFilterView alloc] initWithType:GPUIMAGE_SEPIA];
    sepiaFIlter.delegate = self;
    [self.arrayOfFilters addObject:sepiaFIlter];
    
    grayScaleFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_GRAYSCALE];
    grayScaleFilter.delegate = self;
    [self.arrayOfFilters addObject:grayScaleFilter];
    
    exposureFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_EXPOSURE];
    exposureFilter.delegate = self;
    [self.arrayOfFilters addObject:exposureFilter];
    
    saturationFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_SATURATION];
    saturationFilter.delegate = self;
    [self.arrayOfFilters addObject:saturationFilter];
    
    selectiveBlurFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_GAUSSIAN_SELECTIVE];
    selectiveBlurFilter.delegate = self;
    [self.arrayOfFilters addObject:selectiveBlurFilter];
    
    vignetteFilter = [[GLFilterView alloc] initWithType:GPUIMAGE_VIGNETTE];
    vignetteFilter.delegate = self;
    [self.arrayOfFilters addObject:vignetteFilter];
    
    
}

#pragma mark - FitlersScrollViewMethods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    NSLog(@"%f",scrollView.contentOffset.x);
//    if(scrollView.contentOffset.x){
//    self.mainScrollView.userInteractionEnabled = NO;
//    }
    
    if (self.lastContentOffset > scrollView.contentOffset.y)
        scrollDirection = ScrollDirectionUp;
    else if (self.lastContentOffset < scrollView.contentOffset.y)
        scrollDirection = ScrollDirectionDown;
    
    self.lastContentOffset = scrollView.contentOffset.y;
    
    
    
    if(scrollView.tag == ScrollerTypeFontsScroller || scrollView.tag == ScrollerTypeColorsScroller){
        
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
        
        [cosmopolitanFilter.container setContentOffset:CGPointMake(0, (cosmopolitanFilter.container.frame.size.height*6)-offsetY)];
        cosmopolitanFilter.sliderView.frame = CGRectMake(0, (cosmopolitanFilter.container.frame.size.height*6)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [daquiriFilter.container setContentOffset:CGPointMake(0, (daquiriFilter.container.frame.size.height*7)-offsetY)];
        daquiriFilter.sliderView.frame = CGRectMake(0, (daquiriFilter.container.frame.size.height*7)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [fizzFilter.container setContentOffset:CGPointMake(0, (fizzFilter.container.frame.size.height*8)-offsetY)];
        fizzFilter.sliderView.frame = CGRectMake(0, (fizzFilter.container.frame.size.height*8)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [margaritaFilter.container setContentOffset:CGPointMake(0, (margaritaFilter.container.frame.size.height*9)-offsetY)];
        margaritaFilter.sliderView.frame = CGRectMake(0, (margaritaFilter.container.frame.size.height*9)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [martiniFilter.container setContentOffset:CGPointMake(0, (martiniFilter.container.frame.size.height*10)-offsetY)];
        martiniFilter.sliderView.frame = CGRectMake(0, (martiniFilter.container.frame.size.height*10)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [mojitoFilter.container setContentOffset:CGPointMake(0, (mojitoFilter.container.frame.size.height*11)-offsetY)];
        mojitoFilter.sliderView.frame = CGRectMake(0, (mojitoFilter.container.frame.size.height*11)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        
        
        [sepiaFIlter.container setContentOffset:CGPointMake(0, (sepiaFIlter.container.frame.size.height*12)-offsetY)];
        sepiaFIlter.sliderView.frame = CGRectMake(0, (sepiaFIlter.container.frame.size.height*12)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [grayScaleFilter.container setContentOffset:CGPointMake(0, (grayScaleFilter.container.frame.size.height*13)-offsetY)];
        grayScaleFilter.sliderView.frame = CGRectMake(0, (grayScaleFilter.container.frame.size.height*13)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [exposureFilter.container setContentOffset:CGPointMake(0, (exposureFilter.container.frame.size.height*14)-offsetY)];
        exposureFilter.sliderView.frame = CGRectMake(0, (exposureFilter.container.frame.size.height*14)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [saturationFilter.container setContentOffset:CGPointMake(0, (saturationFilter.container.frame.size.height*15)-offsetY)];
        saturationFilter.sliderView.frame = CGRectMake(0, (saturationFilter.container.frame.size.height*15)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [selectiveBlurFilter.container setContentOffset:CGPointMake(0, (selectiveBlurFilter.container.frame.size.height*16)-offsetY)];
        selectiveBlurFilter.sliderView.frame = CGRectMake(0, (selectiveBlurFilter.container.frame.size.height*16)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
        [vignetteFilter.container setContentOffset:CGPointMake(0, (vignetteFilter.container.frame.size.height*17)-offsetY)];
        vignetteFilter.sliderView.frame = CGRectMake(0, (vignetteFilter.container.frame.size.height*17)-offsetY, scrollView.frame.size.width, scrollView.frame.size.height);
        
    }
    
    
}

-(void) featuresScrollerEndScrolling {


    NSLog(@"end scrolling");
    
    int page = cameraFeaturesScroller.contentOffset.x / cameraFeaturesScroller.frame.size.width;
    
    NSLog(@"page: %D",page);
    
    [[GLContainersViewController sharedInstance] disableSideMembers];
    
    if(page == 1){
        self.colors.alpha = 0;
        [dummyTextField becomeFirstResponder];
        cameraFeaturesScroller.scrollEnabled = NO;
        doingGeadientBg = YES;
    } else {
        
        [UIView animateWithDuration:0.2 animations:^{
            self.animatedView.alpha = 0;
        } completion:^(BOOL finished) {
            [self.shadowAnimation stop];
        
        }];

        
                cameraFeaturesScroller.scrollEnabled = YES;
        self.colors.alpha = 1;
        [dummyTextField resignFirstResponder];
        doingGeadientBg = NO;
    }

}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
//    scrollView.
    if(scrollView.tag == ScrollerTypeFilterScroller){
//        NSLog(@"",scrollView);
//        self.mainScrollView.userInteractionEnabled = NO;
        [self stoppedScrolling];
    }
    
    if(scrollView.tag == ScrollerTypeCameraFeaturesScroller){
        [self featuresScrollerEndScrolling];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    if(scrollView.tag == ScrollerTypeFilterScroller){
        
//        self.mainScrollView.userInteractionEnabled = NO;
        if (!decelerate) {
         
            [self stoppedScrolling];
        }
    }
    
    if(scrollView.tag == ScrollerTypeCameraFeaturesScroller){
        if (!decelerate) {
            [self featuresScrollerEndScrolling];
        }
        
    }
}

- (void)stoppedScrolling
{
    // done, do whatever
    self.mainScrollView.userInteractionEnabled = YES;
    int page = self.mainScrollView.contentOffset.y / self.mainScrollView.frame.size.height;
    
    NSLog(@"page: %D",page);
    
    ScrollDirection direction;
    
    if(page > lastPage){
        direction = ScrollDirectionDown;
    } else if(page < lastPage) {
        direction = ScrollDirectionUp;
    }
    lastPage = page;
    
    currentFilterIndex = page;
    
    if(page > 1 && page < self.arrayOfFilters.count-1){
        if(direction == ScrollDirectionDown){
            GLFilterView * nextFilter = [self.arrayOfFilters objectAtIndex:page+1];
            [self.videoCamera addTarget:nextFilter.filter];
            
            GLFilterView * prevFilter = [self.arrayOfFilters objectAtIndex:page-2];
            if(prevFilter.filterType != GPUIMAGE_NOFILTER){
                [self.videoCamera removeTarget:prevFilter.filter];
            }
        } else {
            GLFilterView * nextFilter = [self.arrayOfFilters objectAtIndex:page-1];
            [self.videoCamera addTarget:nextFilter.filter];
            
            if(page < self.arrayOfFilters.count-2){
                GLFilterView * prevFilter = [self.arrayOfFilters objectAtIndex:page+2];
                [self.videoCamera removeTarget:prevFilter.filter];
            }
        }
    }
}



- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView {
    
    NSLog(@"%f",scrollView.contentOffset.x);
    
}


- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    
    if(scrollView.tag == ScrollerTypeFilterScroller){
        scrollView.userInteractionEnabled = NO;
    }
    
    
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
    
    if(doingGeadientBg){
        [self resetFeaturesScroller];
    }
    
    if(index == [self.latestImagesArray count]){ // Set the last item in carousel to a button which opens image picker.
        self.picYourGroup.hidden = YES;
        if(self.isInFeedMode){
            [self.delegate openAppleImagePicker];
        } else {
            [[GLContainersViewController sharedInstance] openAppleImagePicker];
        }
    } else {
        
        [self.videoCamera stopCameraCapture];
        if(self.cropViewController != nil){
            [self.cropViewController.view removeFromSuperview];
            [self.cropViewController removeFromParentViewController];
            self.cropViewController = nil;
        }
        
        //        PHImageRequestOptions *options = [[PHImageRequestOptions alloc]init];
        //        options.synchronous  = YES;
        //        options.resizeMode = PHImageRequestOptionsResizeModeExact;
        //        options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
        
        
        __block M13ProgressViewPie * progressView = [[M13ProgressViewPie alloc] initWithFrame:CGRectMake(0, 0, [[self.carousel itemViewAtIndex:index] frame].size.height/4, [[self.carousel itemViewAtIndex:index] frame].size.height/4)];
        progressView.center = [[self.carousel itemViewAtIndex:index] center];
        [[self.carousel itemViewAtIndex:index] addSubview:progressView];
        [progressView setPrimaryColor:[UIColor whiteColor]];
        [progressView setSecondaryColor:[UIColor whiteColor]];
        [progressView setProgress:0.0 animated:NO];
        //        progressView
        //        progressView.hidden = YES;
        
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.resizeMode = PHImageRequestOptionsResizeModeExact;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat; //I only want the highest possible quality
        options.synchronous = NO;
        options.networkAccessAllowed = YES;
        options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
            NSLog(@"loading image progress - %f", progress); //follow progress + update progress bar
            [progressView setProgress:progress animated:YES];
            
        };
        
        CGRect screenRect = kScreenBounds;
        CGFloat screenWidth = screenRect.size.width;
        
        [[PHImageManager defaultManager]requestImageForAsset:[self.latestImagesArray objectAtIndex:index] targetSize:CGSizeMake(960,1280) contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage *result, NSDictionary *info){
            
            UIImage * croppedImage = [self imageCroppedToFitSize:CGSizeMake(screenWidth, screenWidth*1.33) image:[self unrotateImage:result]];
            
            
            for(GLFilterView * filterView in self.arrayOfFilters){
                [filterView setImageCapturedUnderFilter:croppedImage];
            }
            croppedImage = nil;
            [self setCameraViewInEditMode:YES];
            
            imageSource = ImageSourceRecents;
            [progressView setProgress:1.0 animated:YES];
            [progressView performAction:M13ProgressViewActionSuccess animated:YES];
            
            [UIView animateWithDuration:0.25
                                  delay:0.5
                                options:0
                             animations:^(void){
                                 [progressView setAlpha:0];
                                 
                                 //                                 controller.layer.backgroundColor = [UIColor blueColor].CGColor;
                             }
                             completion:^(BOOL done){
                                 [progressView removeFromSuperview];
                                 progressView = nil;
                             }];
            
            //            [progressView setHidden:YES];
            
            
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
    view.contentMode = UIViewContentModeScaleAspectFill;
    view.clipsToBounds = YES;
    
    if(index == [self.latestImagesArray count]){
        
        UIImage * image = [UIImage imageNamed:@"GiCon"];
        UIImageView * iv = [[UIImageView alloc] initWithFrame:CGRectMake(14, 45/2, 90.0f, 90.0f)];
        iv.image = image;
        
        [view addSubview:iv];
        
    } else {
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc]init];
        options.synchronous  = YES;
        [[PHImageManager defaultManager]requestImageForAsset:[self.latestImagesArray objectAtIndex:index] targetSize:CGSizeMake(180.0f, 180.0f) contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *result, NSDictionary *info){
            ((UIImageView *)view).image = result;
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


#pragma mark - otherDelegateMethods



-(void)retrievePhotoFromLoginPicker:(UIImage *)image {
    
    
    
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


-(void)retrievePhotoFromPicker:(UIImage *)image {
    
    
    
    [UIView animateWithDuration:0.2 animations:^{
        captureButton.alpha = 0;
        flashButton.alpha = 0;
    }];
    
    //    [self setCameraViewInEditMode:YES];
    //    [mainOutPutFrame bringSubviewToFront:backToCameraButton];
    
    self.cropViewController = [[PECropViewController alloc] init];
    self.cropViewController.delegate = self;
    //    controller
    
    self.cropViewController.image = [[self normalizedImage:image] imageScaledToFitSize:CGSizeMake(480, 640)];
    //    controller.isRotationEnabled = NO;
    
    //    UIImage *image = image;
    //    CGFloat width = [[UIScreen mainScreen] bounds].size.width;
    //    CGFloat height = [[UIScreen mainScreen] bounds].size.height*0.75;
    //    CGFloat length = MIN(width, height);
    //    controller.imageCropRect = CGRectMake(0,
    //                                          0,
    //                                          0,
    //                                          0);
    //    controller.imageCropRect = CGRectMake((width - length) / 2,
    //                                          (height - length) / 2,
    //                                          length,
    //                                          length);
    
    //    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    //
    //    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    //        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    //    }
    
    
    /*Calling the addChildViewController: method also calls
     the child’s willMoveToParentViewController: method automatically */
    self.cropViewController.view.frame = mainOutPutFrame.frame;//CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height*0.75);
    [[[GLContainersViewController sharedInstance] navigationController] addChildViewController:self.cropViewController];
    [self.cropViewController didMoveToParentViewController:[[GLContainersViewController sharedInstance] navigationController]];
    [self.cropViewController setKeepingCropAspectRatio:NO];
    [self.cropViewController setRotationEnabled:NO];
    //    [controller setCropAspectRatio:2.0f / 3.0f];
    
    
    
    
    
    
    
    [[GLContainersViewController sharedInstance]disableSideMembers];
    
    [mainOutPutFrame addSubview:self.cropViewController.view];
    
    
    //    controller setim
    
    mainOutPutFrame.clipsToBounds = YES;
    
    
}


- (void)cropViewController:(PECropViewController *)controller didFinishCroppingImage:(UIImage *)croppedImage {
    
    [[GLContainersViewController sharedInstance]disableSideMembers];
    
    controller.completeCropButton.alpha = 0;
    
    
    UIGraphicsBeginImageContextWithOptions(controller.view.bounds.size, NO, 0);
    [controller.view drawViewHierarchyInRect:controller.view.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //    image = [self imageByCroppingImage:<#(UIImage *)#> toSize:<#(CGSize)#>];
    
    fromImagePicker = NO;
    CGRect screenRect = kScreenBounds;
    CGFloat screenWidth = screenRect.size.width;
    
    for(GLFilterView * filterView in self.arrayOfFilters){
        //        [filterView setImageCapturedUnderFilter:[self imageCroppedToFitSize:CGSizeMake(screenWidth, screenWidth*1.3333) image:image]];
        
        [filterView setImageCapturedUnderFilter:image];
        
    }
    [self setCameraViewInEditMode:YES];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.mainScrollView.alpha = 1;
    } completion:^(BOOL finished) {
    }];
    imageSource = ImageSourceGallery;
    imageFromPicker = image;
    
    [controller.view removeFromSuperview];
    [controller removeFromParentViewController];
    controller = nil;
    //    [self ]
    
    //    controller.
    //    UIGraphicsBeginImageContextWithOptions(controller.view.bounds.size, controller.view.opaque, 0.0);
    //    [controller.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    //    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    //    UIGraphicsEndImageContext();
    
    
    
    NSLog(@"Now need to create again the same but in a real image. and send it to filter surface.");
    
}


-(void)resizeableTapped:(UITapGestureRecognizer*)tap {
//    if(doingGeadientBg){
//        [self presentTheGradientScroller];
//    }
    
    [dummyTextField becomeFirstResponder];
    cameraFeaturesScroller.scrollEnabled = NO;
//    [self addTextToImageTapped];
}


- (void)userResizableViewDidBeginEditing:(GLResizeableView *)userResizableView {
    [self.resizeAbleView showEditingHandles];
    cameraFeaturesScroller.scrollEnabled = NO;
}

- (void)userResizableViewDidEndEditing:(GLResizeableView *)userResizableView {
    if(!isEditing){
        [self.resizeAbleView hideEditingHandles];
        if(doingGeadientBg){
            cameraFeaturesScroller.scrollEnabled = YES;
        } else {
            cameraFeaturesScroller.scrollEnabled = NO;
        }
    }
}

-(void)viewIsResizing:(CGRect)frame {
    [self sizeLabel:testLabel toRect:frame];
    [self sizeLabel:testLabel toRect:frame];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([self.resizeAbleView hitTest:[touch locationInView:self.resizeAbleView] withEvent:nil]) {
        return NO;
    }
//    self.mainScrollView.scrollEnabled = NO;
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [dummyTextField resignFirstResponder];

    if(doingGeadientBg){
        cameraFeaturesScroller.scrollEnabled = YES;
    } else {
        cameraFeaturesScroller.scrollEnabled = NO;
    }
    [self.resizeAbleView hideEditingHandles];
    isEditing = NO;
    if(doingGeadientBg){
        
        [UIView animateWithDuration:0.2 animations:^{
            self.animatedView.alpha = 1;
        } completion:^(BOOL finished) {
            [self.shadowAnimation start];
            
            
            CABasicAnimation *theAnimation;
            theAnimation=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
            theAnimation.duration=0.5;
            theAnimation.repeatCount=HUGE_VALF;
            theAnimation.autoreverses=YES;
            theAnimation.fromValue=[NSNumber numberWithFloat:1.0];
            theAnimation.toValue=[NSNumber numberWithFloat:0.7];
            theAnimation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
            [self.shadowAnimation.animatedView.layer addAnimation:theAnimation forKey:@"animateOpacity"];
        }];

        
//        [self setCameraViewInEditMode:YES];
    }
    
    return NO;
}

- (void)keyboardDidShow: (NSNotification *) notif{
    isEditing = YES;
    [self.resizeAbleView showEditingHandles];
}

- (void)keyboardDidHide: (NSNotification *) notif{
    
    cameraFeaturesScroller.scrollEnabled = NO;
    
    if(isEditing){
        [self.resizeAbleView hideEditingHandles];
        
        if(doingGeadientBg){
            
        [UIView animateWithDuration:0.2 animations:^{
            self.animatedView.alpha = 1;
        } completion:^(BOOL finished) {
            [self.shadowAnimation start];
            
            
            CABasicAnimation *theAnimation;
            theAnimation=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
            theAnimation.duration=0.5;
            theAnimation.repeatCount=HUGE_VALF;
            theAnimation.autoreverses=YES;
            theAnimation.fromValue=[NSNumber numberWithFloat:1.0];
            theAnimation.toValue=[NSNumber numberWithFloat:0.7];
            theAnimation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
            [self.shadowAnimation.animatedView.layer addAnimation:theAnimation forKey:@"animateOpacity"];
        }];
            
            
            cameraFeaturesScroller.scrollEnabled = YES;
        } else {
            cameraFeaturesScroller.scrollEnabled = NO;
        }
        
        
    }

    isEditing = NO;
}


#pragma mark - TextField Delegate methods

- (void)focusOnTextField {
    
    [UIView animateWithDuration:0.5 animations:^{
        
        flashButton.alpha = 0;
        flipCameraButton.alpha = 0;
        
        addTextButton.alpha = 0;
        backToCameraButton.alpha = 0;
        trashTextButton.alpha = 1;
        approveTextButton.alpha = 1;
        
        self.resizeAbleView.alpha = 1;
    }];
}


- (void)focusOutTextField {
    
    [UIView animateWithDuration:0.5 animations:^{
        
        trashTextButton.alpha = 0;
        approveTextButton.alpha = 0;
        backToCameraButton.alpha = 1;
        addTextButton.alpha = 1;
        
    }];
    
}

-(void)dismissKeyboard {
    [dummyTextField endEditing:YES];
//    if(doingGeadientBg){
//        [self hideTheGradientScroller];
//    }
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
    
    [UIView animateWithDuration:0.250 animations:^{
        self.view.frame = CGRectMake(0, -self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
    } completion:^(BOOL done){
        [self.videoCamera stopCameraCapture];
        [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
        for(GLFilterView * filterView in self.arrayOfFilters){
            [filterView backToCamera];
        }
    }];
}

-(void)setCameraViewInEditMode:(BOOL)edit {
    
    isEditing = edit;
    if(edit){// YES
        cameraFeaturesScroller.scrollEnabled = NO;
        [UIView animateWithDuration:0.2 animations:^{
            self.animatedView.alpha = 1;
        } completion:^(BOOL finished) {
            [self.shadowAnimation start];
            
            
            CABasicAnimation *theAnimation;
            theAnimation=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
            theAnimation.duration=0.5;
            theAnimation.repeatCount=HUGE_VALF;
            theAnimation.autoreverses=YES;
            theAnimation.fromValue=[NSNumber numberWithFloat:1.0];
            theAnimation.toValue=[NSNumber numberWithFloat:0.7];
            theAnimation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
            [self.shadowAnimation.animatedView.layer addAnimation:theAnimation forKey:@"animateOpacity"];
        }];
        
        [UIView animateWithDuration:0.5 animations:^{
            flipCameraButton.alpha = 0;
            backToCameraButton.alpha = 1;
            flashButton.alpha = 0;
            addTextButton.alpha = 1;
            captureButton.alpha = 0;
            finalProcessButton.alpha = 1;
            abortUploadButton.alpha = 0;
        }];
        
    } else {
        
                cameraFeaturesScroller.scrollEnabled = YES;
        
        [UIView animateWithDuration:0.2 animations:^{
            self.animatedView.alpha = 0;
        } completion:^(BOOL finished) {
            [self.shadowAnimation stop];
        }];
        
        [self approveTextTapped];
        [UIView animateWithDuration:0.5 animations:^{
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

-(void)closeCameraViewWithSlideFromFeed {
    [UIView animateWithDuration:0.2 animations:^{
        [cameraWrapper setFrame:CGRectMake(0, 0, cameraWrapper.frame.size.width, 60)];
        [self.cameraViewBackground setFrame:CGRectMake(0, 0, self.cameraViewBackground.frame.size.width, 60)];
        self.dmut.center = CGPointMake(firstX, 60);
        effeectViewWrapper.hidden = NO;
        effectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        effectView.alpha = 1;
        effeectViewWrapper.alpha = 1;
        self.backButton.alpha = 1;
        self.membersButton.alpha = 1;
    }];
    [self backToCameraFromEditPallette:0];
}

-(void)closeCameraViewWithSlideFromMain {
    [[self videoCamera] startCameraCapture];
    [UIView animateWithDuration:0.2 animations:^{
        self.dmut.transform = CGAffineTransformIdentity;
        effeectViewWrapper.hidden = YES;
        effectView.effect = nil;
        effectView.alpha = 0;
        effeectViewWrapper.alpha = 0;
        self.cameraViewBackground.frame = CGRectMake(0, 0, self.view.frame.size.width, (self.view.frame.size.height/3));
        cameraWrapper.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height/3);
        self.dmut.frame = CGRectMake(60, ([UIScreen mainScreen].bounds.size.height/3)-86, 256, 104);
    }];
    
    [self.userScore showUserScore];
    [self backToCameraFromEditPallette:nil];
    [self hideCameraButtons];
}

- (void)startUploadingVideo {
    
    
    
    if(self.isInFeedMode){
        
        [self.delegate videoSelected];
        self.goneUploadAmovie = NO;
        
        
    }
}

- (void)startUploadingAsset:(UIImage*)image {
    NSLog(@"gone start upload asset now");
    self.library = [[ALAssetsLibrary alloc] init];
    [self.library saveImage:image toAlbum:@"Glance" withCompletionBlock:^(NSError *error) {
        if(error){
            [KVNProgress showErrorWithStatus:@"Image failed to saved"];
        } else {
            //                    [KVNProgress showSuccessWithStatus:@"Image saved succesfully to custom album"];
        }
        
    }];
    
    if(self.isInFeedMode){
        [self.delegate imageSelected:image];
    }
}

-(void)resetFeaturesScroller {
    doingGeadientBg = NO;
    [cameraFeaturesScroller setContentOffset:CGPointMake(0, 0) animated:YES];
}

-(void)finalProcessTapped {
    NSLog(@"final did tapped");
    
    
    //    if(){}
    
    
    if(doingGeadientBg){
        
        

       UIImage * image = [self imageWithView:gradBackgroundView];
        image = [self imageToFitSize:CGSizeMake(image.size.width, image.size.height*0.75) method:MGImageResizeCropStart image:image];
//        image = [self imageCroppedToFitSize:CGSizeMake(image.size.width, image.size.height*0.75) image:image];
        cameraIsOpen = NO;
        doingGeadientBg = NO;
        if(self.isInFeedMode){
            [self.delegate imageSelected:image];
            [self closeCameraViewWithSlideFromFeed];
            
        } else {
            
            [[GLContainersViewController sharedInstance] goToFriendsListViewAnimatedBeforeUploadingPhoto:NO completed:^{
                
            } executeWhenFriendsDone:^{
                [self.delegate imageSelected:image];
                [self setCameraInFeed];
//                [self.cameraViewBackground bringSubviewToFront:self.dmut];
                [self closeCameraViewWithSlideFromFeed];
                
            }];
            
//            [self closeCameraViewWithSlideFromMain];
        }
            [self resetFeaturesScroller];
        
        
    } else {
        if(self.goneUploadAmovie == YES){
            [self.previewPlayer stop];
        }
        if(self.isInFeedMode){
            
            if(self.cropViewController != nil){
                [self.cropViewController.view removeFromSuperview];
                [self.cropViewController removeFromParentViewController];
                self.cropViewController = nil;
            }
            
            
            if(self.goneUploadAmovie == YES){
                [self backFromVideoTapped];
                [self startUploadingVideo];
            } else {
                UIImage * finalProccedImage = [self processImageBySourceAndPrepareWithTextandSizes];
                [self startUploadingAsset:finalProccedImage];
            }
            [self closeCameraViewWithSlideFromFeed];
            [self createResizableTextView];
            cameraIsOpen = NO;
            
        } else {
            
            
            [[GLContainersViewController sharedInstance] goToFriendsListViewAnimatedBeforeUploadingPhoto:NO completed:^{
                
            } executeWhenFriendsDone:^{
                
                
                if(self.cropViewController != nil){
                    [self.cropViewController.view removeFromSuperview];
                    [self.cropViewController removeFromParentViewController];
                    self.cropViewController = nil;
                }
                [self setCameraInFeed];
                if(self.goneUploadAmovie == YES){
                    [self backFromVideoTapped];
                    [self startUploadingVideo];
                } else {
                    UIImage * finalProccedImage = [self processImageBySourceAndPrepareWithTextandSizes];
                    [self startUploadingAsset:finalProccedImage];
                }
                [self closeCameraViewWithSlideFromFeed];
                [self createResizableTextView];
                cameraIsOpen = NO;
                
            }];
            
        }
    }
    [[GLSharedVideoPlayer sharedInstance] pause];
    
    
    
    
    
    
    //    if(self.goneUploadAmovie == YES){
    //        [self.previewPlayer stop];
    //        if(self.isInFeedMode){
    //            [self.videoCamera stopCameraCapture];
    //        }
    //        [self performSelector:@selector(backFromVideoTapped)];
    //        self.goneUploadAmovie = NO;
    //
    //        if(!self.isInFeedMode){
    //            self.dmut.transform = dmutScaleOriginal;
    //
    //
    //            [self.userScore showUserScore];
    //            [self hideCameraButtons];
    //
    //
    //
    ////            [[GLContainersViewController sharedInstance] goToFriendsListViewAnimatedBeforeMovingPhoto:<#(BOOL)#> photoId:<#(NSString *)#>];
    //
    ////            [[GLContainersViewController sharedInstance] goToFeedViewAnimated:YES withAlbumId:nil];
    ////            [self toggleCamera:YES];
    ////            [UIView animateWithDuration:0.2 animations:^{
    ////                self.picYourGroup.alpha = 1;
    ////                glanceLogo.alpha = 1;
    ////                scoreBg.alpha = 1;
    ////                self.score.alpha = 1;
    ////                flipCameraButton.alpha = 0;
    ////                flashButton.alpha = 0;
    ////            }];
    //
    ////            [[ContainerViewController sharedInstance] lockScrolling:YES];
    ////            [[ContainerViewController sharedInstance] setFriendsFromMainWithPicture];
    ////            [[ContainerViewController sharedInstance] transitToFriendsList:NO direction:UIPageViewControllerNavigationDirectionReverse completion:^{
    ////                [[ContainerViewController sharedInstance] setFriendsFromMain];
    ////
    ////            }];
    //
    //        }
    //
    //        [UIView animateWithDuration:0.2 animations:^{
    //
    //            //            if(self.isInFeedMode){
    //            if(!self.afterLogin){
    //                [cameraWrapper setFrame:CGRectMake(0, 0, cameraWrapper.frame.size.width, 60)];
    //                [self.cameraViewBackground setFrame:CGRectMake(0, 0, self.cameraViewBackground.frame.size.width, 60)];
    //                self.dmut.center = CGPointMake(firstX, 60);
    //
    ////                effectView.alpha = 1;
    ////                effectView.hidden = NO;
    //                effectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    //                effectView.alpha = 1;
    //                self.backButton.alpha = 1;
    //                self.membersButton.alpha = 1;
    //            } else {
    //
    //
    //            }
    //
    //
    //
    //        }];
    //
    //
    //        NSLog(@"ok this is the time to start the upload we the movie that we prepared");
    //        if(self.isInFeedMode){
    //            [self.delegate videoSelected];
    //        } else {
    //            self.videoToUploadPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mp4"];
    //        }
    //
    //    } else {
    //
    //        if(imageSource != ImageSourceNone){
    //
    //            if(!self.isInFeedMode){
    //
    //                [[GLContainersViewController sharedInstance] goToFriendsListViewAnimatedBeforeUploadingPhoto:NO completed:^{
    //
    //                }];
    //
    //
    //
    //                [[GLSharedCamera sharedInstance] setCameraInMain];
    //                [[GLSharedCamera sharedInstance] resetCameraAfterBack];
    //                self.dmut.transform = dmutScaleOriginal;
    //
    ////                [[GLContainersViewController sharedInstance] ];
    //
    ////                [self toggleCamera:YES];
    ////                [UIView animateWithDuration:0.2 animations:^{
    ////                    self.picYourGroup.alpha = 1;
    ////                    glanceLogo.alpha = 1;
    ////                    scoreBg.alpha = 1;
    ////                    self.score.alpha = 1;
    ////                    flipCameraButton.alpha = 0;
    ////                    flashButton.alpha = 0;
    ////                }];
    ////                [[ContainerViewController sharedInstance] lockScrolling:YES];
    ////                [[ContainerViewController sharedInstance] setFriendsFromMainWithPicture];
    ////                [[ContainerViewController sharedInstance] transitToFriendsList:NO direction:UIPageViewControllerNavigationDirectionReverse completion:^{
    ////                    [[ContainerViewController sharedInstance] setFriendsFromMain];
    ////
    ////                }];
    //            } else {
    //
    //
    //
    //
    //
    //
    //
    //
    //            }
    //
    //            [self.userScore showUserScore];
    //            [self hideCameraButtons];
    //
    //
    //
    //            [UIView animateWithDuration:0.2 animations:^{
    //                if(!self.afterLogin && self.isInFeedMode){
    //                    [cameraWrapper setFrame:CGRectMake(0, 0, cameraWrapper.frame.size.width, 60)];
    //                    [self.cameraViewBackground setFrame:CGRectMake(0, 0, self.cameraViewBackground.frame.size.width, 60)];
    //                    self.dmut.center = CGPointMake(firstX, 60);
    //
    ////                    effectView.alpha = 1;
    ////                    effectView.hidden = NO;
    //                    effectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    //                    effectView.alpha = 1;
    //                    self.backButton.alpha = 1;
    //                    self.membersButton.alpha = 1;
    //                }
    //
    //            } completion:^(BOOL finished) {
    //
    //                [self processImageBySourceAndPrepareWithTextandSizes];
    //
    //
    //                if(self.isInFeedMode){
    //                    [self createResizableTextView];
    //                    [self backToCameraFromEditPallette:@"afterSend"];
    //                } else {
    //                    [self imageCapturedOnMainScreen:nil];
    //                }
    //
    //                if(self.afterLogin){
    //
    ////                    self.picYourGroup.alpha = 1;
    ////                    glanceLogo.alpha = 1;
    ////                    scoreBg.alpha = 1;
    ////                    self.score.alpha = 1;
    ////                    flipCameraButton.alpha = 0;
    ////                    flashButton.alpha = 0;
    //
    //                    [self.userScore showUserScore];
    ////                    if(self.isInFeedMode){
    //                        [self hideCameraButtons];
    ////                    }
    //
    //                }
    //            }];
    //        }
    //    }
}

-(UIImage*)processImageBySourceAndPrepareWithTextandSizes {
    
    __block UIImage * finalImage;
    switch (imageSource) {
        case ImageSourceCamera:
        {
            finalImage =[self processSelectedImageWithFilterTextAndSize:cleanImageFromCamera];
            
        };
            break;
            
        case ImageSourceRecents:
        {
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc]init];
            options.synchronous  = YES;
            options.resizeMode = PHImageRequestOptionsResizeModeFast;
            options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
            [[PHImageManager defaultManager]requestImageForAsset:[self.latestImagesArray objectAtIndex:indexOfImageFromCarousel] targetSize:CGSizeMake(960, 1280) contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage *image, NSDictionary *info){
                
                finalImage = [self processSelectedImageWithFilterTextAndSize:[self unrotateImage:[image imageCroppedAndScaledToSize:CGSizeMake(960, 1280) contentMode:UIViewContentModeScaleAspectFill padToFit:NO]]];
            }];
        };
            break;
            
        case ImageSourceGallery:
        {
            finalImage = [self processSelectedImageWithFilterTextAndSize:imageFromPicker];
        };
            break;
            
        default:
            break;
    }
    return finalImage;
}

-(void)resetCameraAfterUploadingFromMain {
    
}



-(UIImage *)processSelectedImageWithFilterTextAndSize:(UIImage*)imageToFinal {
    UIImage * finalImage;
    UIImage * filteredImage = [self addFilterToImage:imageToFinal];
    if (addText) {
        UIImage * textAsView = [self imageWithText:testLabel];
        CGRect frame = [mainOutPutFrame convertRect:testLabel.frame fromView:testLabel];
        UIImage * resizedTextAsImage = [self resizeLabelImage:textAsView size:filteredImage.size location:CGPointZero];
        UIImage * imageWithText = [self drawText:@"test" inImage:filteredImage atPoint:CGPointMake(frame.origin.x, frame.origin.y) viewToPast:resizedTextAsImage];
        
        
        imageToFinal = nil;
        imageFromPicker = nil;
        cleanImageFromCamera = nil;
        imageToFinal = nil;
        filteredImage = nil;
        textAsView = nil;
        resizedTextAsImage = nil;
        finalImage = imageWithText;
        //        if(self.isInFeedMode){
        //            [self.delegate imageSelected:imageWithText];
        //        } else {
        //
        //            [self imageCapturedOnMainScreen:imageWithText];
        //
        //        }
        imageWithText = nil;
        [self.resizeAbleView removeFromSuperview];
    } else {
        finalImage = filteredImage;
        imageToFinal = nil;
        imageFromPicker = nil;
        cleanImageFromCamera = nil;
        //        if(self.isInFeedMode){
        //            [self.delegate imageSelected:filteredImage];
        //        } else {
        //            [self imageCapturedOnMainScreen:filteredImage];
        //        }
        filteredImage = nil;
    }
    addText = NO;
    return finalImage;
    
    
}

-(void)resetCameraAfterBack {
    self.imageForOutSideUpload = nil;
}

-(void)imageCapturedOnMainScreen:(UIImage*)finalImage {
    self.imageForOutSideUpload = finalImage;
}

- (UIImage *) imageWithText:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 1.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

-(UIImage*)addFilterToImage:(UIImage*)inputImage {
    GLFilterView * currentFIlter = [self.arrayOfFilters objectAtIndex:currentFilterIndex];
    UIImage * filteredImage = nil;
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
    } else if(currentFIlter.filterType == GPUIMAGE_MOJITO){
        GPUImageMojitoFilter *stillImageFilter2 = [[GPUImageMojitoFilter alloc] init];
        filteredImage = [stillImageFilter2 imageByFilteringImage:inputImage];
    } else if(currentFIlter.filterType == GPUIMAGE_COSMOPOLITAN){
        GPUImageCosmopolitanFilter *stillImageFilter2 = [[GPUImageCosmopolitanFilter alloc] init];
        filteredImage = [stillImageFilter2 imageByFilteringImage:inputImage];
    } else if(currentFIlter.filterType == GPUIMAGE_DAQUIRI){
        GPUImageDaquiriFilter *stillImageFilter2 = [[GPUImageDaquiriFilter alloc] init];
        filteredImage = [stillImageFilter2 imageByFilteringImage:inputImage];
    } else if(currentFIlter.filterType == GPUIMAGE_FIZZ){
        GPUImageFizzFilter *stillImageFilter2 = [[GPUImageFizzFilter alloc] init];
        filteredImage = [stillImageFilter2 imageByFilteringImage:inputImage];
    } else if(currentFIlter.filterType == GPUIMAGE_MARTINI){
        GPUImageMartiniFilter *stillImageFilter2 = [[GPUImageMartiniFilter alloc] init];
        filteredImage = [stillImageFilter2 imageByFilteringImage:inputImage];
    } else if(currentFIlter.filterType == GPUIMAGE_MARGARITA){
        GPUImageMargaritaFilter *stillImageFilter2 = [[GPUImageMargaritaFilter alloc] init];
        filteredImage = [stillImageFilter2 imageByFilteringImage:inputImage];
    } else {
        filteredImage = [currentFIlter.filter imageByFilteringImage:inputImage];
    }
    
    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
    
    
    
    
    return filteredImage;
}

#pragma mark - Camera Actions



-(void) updateFiltersWithSelectedImage:(UIImage *)image {
    
    [UIView animateWithDuration:0.5 animations:^{
        flipCameraButton.alpha = 0;
        backToCameraButton.alpha = 1;
        flashButton.alpha = 0;
        addTextButton.alpha = 1;
        captureButton.alpha = 0;
        finalProcessButton.alpha = 1;
        abortUploadButton.alpha = 0;
        
    }];
    
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
    
    CGRect screenRect = kScreenBounds;
    CGFloat screenWidth = screenRect.size.width;
    
    cleanImageFromCamera = nil;
    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
    
    [self.videoCamera capturePhotoAsImageProcessedUpToFilter:[[self.arrayOfFilters objectAtIndex:0] filter] withCompletionHandler:^(UIImage *processedImage, NSError *error) {
        
        [self.videoCamera stopCameraCapture];
        
        
        
        
        //
        
        
        [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
        
        
        if (processedImage.imageOrientation == UIImageOrientationUp) {
            
            
            @autoreleasepool {
                
                int width = 960;
                int height = 1280;
                
                CGImageRef imageRef = [processedImage CGImage];
                CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
                
                //if (alphaInfo == kCGImageAlphaNone)
                alphaInfo = kCGImageAlphaNoneSkipLast;
                
                CGContextRef bitmap = CGBitmapContextCreate(NULL, width, height, CGImageGetBitsPerComponent(imageRef), 4 * width, CGImageGetColorSpace(imageRef), alphaInfo);
                CGContextDrawImage(bitmap, CGRectMake(0, 0, width, height), imageRef);
                CGImageRef ref = CGBitmapContextCreateImage(bitmap);
                cleanImageFromCamera = [UIImage imageWithCGImage:ref];
                //            cleanImageFromCamera.imag
                
                CGContextRelease(bitmap);
                CGImageRelease(ref);
                bitmap = nil;
                ref = nil;
                alphaInfo = nil;
                imageRef = nil;
                
            }
            
            
            NSLog(@"portrait");
            [self setCameraViewInEditMode:YES];
            for(GLFilterView * filterView in self.arrayOfFilters){
                @autoreleasepool {
                    [filterView setImageCapturedUnderFilter:[self imageCroppedToFitSize:CGSizeMake(screenWidth, screenWidth*1.3333) image:processedImage]];
                }
                
            }
            
        } else if (processedImage.imageOrientation == UIImageOrientationLeft || processedImage.imageOrientation == UIImageOrientationRight) {
            NSLog(@"landscape");
            
            
            //            UIImage *imageToDisplay =
            //            [UIImage imageWithCGImage:[originalImage CGImage]
            //                                scale:1.0
            //                          orientation: UIImageOrientationUp];
            
            UIImage * unrotatedImage = [self unrotateImage:processedImage];
            //            UIImage * normalized = [self normalizedImage:processedImage];
            [self retrievePhotoFromPicker:[self unrotateImage:processedImage]];
        }
        
        
        
    }];
    
    imageSource = ImageSourceCamera;
    
}

- (void) approveTextTapped {
  
    cameraFeaturesScroller.scrollEnabled = YES;
    [dummyTextField endEditing:YES];
    [self.resizeAbleView hideEditingHandles];
    [UIView animateWithDuration:0.5 animations:^{
        trashTextButton.alpha = 0;
        approveTextButton.alpha = 0;
        backToCameraButton.alpha = 1;
        addTextButton.alpha = 1;
    }];
}

-(void) trashTheText {
    
    addText = NO;
    
    
    [dummyTextField resignFirstResponder];
//    [self hideTheGradientScroller];
    [UIView animateWithDuration:0.5 animations:^{
        self.resizeAbleView.alpha = 0;
        addTextButton.alpha = 1;
        trashTextButton.alpha = 0;
        approveTextButton.alpha = 0;
        backToCameraButton.alpha = 1;
    }];
    
    
    [self.resizeAbleView removeFromSuperview];
//    [mainOutPutFrame addSubview:self.resizeAbleView];
    cameraFeaturesScroller.scrollEnabled = YES;
    
    [self createResizableTextView];
}

-(void)addTextToImageTapped {
    
    [dummyTextField becomeFirstResponder];
    
    addText = YES;
    [self.resizeAbleView removeFromSuperview];
    [mainOutPutFrame addSubview:self.resizeAbleView];
    cameraFeaturesScroller.scrollEnabled = NO;
    
    [UIView animateWithDuration:0.5 animations:^{
        addTextButton.alpha = 0;
        backToCameraButton.alpha = 0;
        trashTextButton.alpha = 1;
        approveTextButton.alpha = 1;
        self.resizeAbleView.alpha = 1;
    }];
    
}

-(void)backToCameraFromEditPallette:(id)sender {
    [self.editTextViewObj endEditing:YES];
    self.goneUploadAmovie = NO;
    if(sender != 0){
        imageSource = ImageSourceNone;
    }
    
    for(GLFilterView * filterView in self.arrayOfFilters){
        [filterView backToCamera];
    }
    
    [self setCameraViewInEditMode:NO];
    if([sender isKindOfClass:[UIButton class]]){
        [self.videoCamera startCameraCapture];
    }
    
    

    
    [UIView animateWithDuration:0.25 animations:^{
        self.resizeAbleView.alpha = 0;
    } completion:^(BOOL finished) {
            [self.resizeAbleView removeFromSuperview];
        [self createResizableTextView];
    }];
    
}

- (void)setCameraIsBackView:(BOOL)isBackView {
    cameraIsBackView = isBackView;
}


-(void)fixAfterProfileScreenAndActivitaion {
    [self.videoCamera rotateCamera];
    [mainOutPutFrame bringSubviewToFront:captureButton];
    captureButton.alpha = 1;
    captureButton.hidden = NO;
    [flashButton setAlpha:0];
    [mainOutPutFrame bringSubviewToFront:self.captureTimeLineWrapper];
    [mainOutPutFrame bringSubviewToFront:flipCameraButton];
    [mainOutPutFrame bringSubviewToFront:backToCameraButton];
    [mainOutPutFrame bringSubviewToFront:flashButton];
    [mainOutPutFrame bringSubviewToFront:addTextButton];
    [mainOutPutFrame bringSubviewToFront:captureButton];
    [mainOutPutFrame bringSubviewToFront:finalProcessButton];
    [mainOutPutFrame bringSubviewToFront:abortUploadButton];
    [mainOutPutFrame bringSubviewToFront:touchPointCircle];

}

-(void)flipCamera {
    
    [self.videoCamera rotateCamera];
    if(cameraIsBackView){
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
    
//    self.mainScrollView.directionalLockEnabled = YES;
    self.mainScrollView.backgroundColor = [UIColor blackColor];
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
    
    [mainOutPutFrame addSubview:self.mainScrollView];
    
//    self.mainScrollView.scrollEnabled = NO;
    
    UIView * buttonBg1 = [[UIView alloc] initWithFrame:CGRectMake(10, 0, 60, 60)];
    buttonBg1.backgroundColor = [UIColor blackColor];
    buttonBg1.layer.cornerRadius = 60;
    
    
    flipCameraButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 30, 28, 32)];
    UIImage *btnImage = [UIImage imageNamed:@"FlipCameraIcon"];
    [flipCameraButton addTarget:self action:@selector(flipCamera) forControlEvents:UIControlEventTouchUpInside];
    [flipCameraButton setImage:btnImage forState:UIControlStateNormal];
    [mainOutPutFrame addSubview:flipCameraButton];
    
    flipCameraButton.alpha = 0;
    
    backCameraOn = YES;
    
    flashButton = [[UIButton alloc] initWithFrame:CGRectMake(filterViewWidth - 48, 32, 25, 33)];
    UIImage *btnImage2 = [UIImage imageNamed:@"flashAutoIcon"];
    [flashButton addTarget:self action:@selector(toggleFlash) forControlEvents:UIControlEventTouchUpInside];
    [flashButton setImage:btnImage2 forState:UIControlStateNormal];
    [mainOutPutFrame addSubview:flashButton];
    
    flashButton.alpha = 0;
    
    flashIsOn = NO;
    
    
    
//    addGrdientButton = [[UIButton alloc] initWithFrame:CGRectMake(filterViewWidth - 48, 70, 33, 33)];
//    UIImage *btnImage3 = [UIImage imageNamed:@"gradientBgButtonCamera"];
//    [addGrdientButton addTarget:self action:@selector(toggleGradView) forControlEvents:UIControlEventTouchUpInside];
//    [addGrdientButton setImage:btnImage3 forState:UIControlStateNormal];
//    [mainOutPutFrame addSubview:addGrdientButton];
    
    
    
}

-(void)toggleFlash {
    
    
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]){
            
            [device lockForConfiguration:nil];
            if(flashState == 0){
                flashState = 1;
                [device setFlashMode:AVCaptureFlashModeOn];
                flashButton.alpha = 1;
                flashButton.frame = CGRectMake(self.view.frame.size.width - 40, 32, 18, 33);
                UIImage *btnImage = [UIImage imageNamed:@"FlashIcon"];
                [flashButton setImage:btnImage forState:UIControlStateNormal];
            } else if(flashState == 1){
                flashState = 2;
                [device setFlashMode:AVCaptureFlashModeOff];
                flashButton.alpha = 0.5;
            } else if (flashState == 2){
                flashState = 0;
                [device setFlashMode:AVCaptureFlashModeAuto];
                flashButton.alpha = 1;
                flashButton.frame = CGRectMake(self.view.frame.size.width - 48, 32, 25, 33);
                UIImage * btnImage = [UIImage imageNamed:@"flashAutoIcon"];
                [flashButton setImage:btnImage forState:UIControlStateNormal];
            }
            [device unlockForConfiguration];
        }
    }
}

- (UIImage *) resizeLabelImage:(UIImage*)image size:(CGSize)size location:(CGPoint)location {
    CGFloat screenWidth = self.view.frame.size.width;
    CGFloat screenHeight = self.view.frame.size.height;
    CGFloat labelWidth = image.size.width;
    CGFloat labelHeight = image.size.height;
    CGFloat newWidth = labelWidth * (size.width/screenWidth);
    CGFloat newHeight = labelHeight * (size.width/screenWidth);
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(newWidth, newHeight), NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
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
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0);
    [image drawAtPoint:CGPointMake(0,0)];
    [viewToEmbed drawAtPoint:CGPointMake(point.x*(image.size.width/screenRect.size.width),point.y*(image.size.width/screenRect.size.width))];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end