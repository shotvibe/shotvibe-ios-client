//
//  CaptureViewfinderController.m
//  
//
//  Created by John Gabelmann on 4/23/12.
//  Copyright (c) 2012 Reticent Media. All rights reserved.
//

#import "CaptureViewfinderController.h"
#import "AVCamCaptureManager.h"
#import "AVCamRecorder.h"
#import "UIImage+JMCResize.h"
#import "SVDefines.h"
#import "Album.h"
#import "CaptureSelectImagesViewController.h"

#define kFlashModeOff   0
#define kFlashModeOn    1
#define kFlashModeAuto  2

static void *AVCamFocusModeObserverContext = &AVCamFocusModeObserverContext;

@interface CaptureViewfinderController () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) IBOutlet UIScrollView *albumScrollView;
@property (nonatomic, strong) IBOutlet UIPageControl *albumPageControl;
@property (nonatomic, strong) IBOutlet UIImageView *albumPreviewImage;
@property (nonatomic, strong) IBOutlet UILabel *imagePileCounterLabel;
@property (nonatomic, strong) IBOutlet UIView *topBarContainer;
@property (nonatomic, strong) IBOutlet UIButton *saveButton;
@property (nonatomic, strong) IBOutlet UILabel *saveLabel;

- (IBAction)albumPageControlDidChangeIndex:(id)sender;

@end

@interface CaptureViewfinderController (InternalMethods)

- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates;
- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer;
- (void)tapToContinouslyAutoFocus:(UIGestureRecognizer *)gestureRecognizer;
- (void)tapToHideUI:(UIGestureRecognizer *)gestureRecognizer;
- (void)updateButtonStates;
- (void)configureAlbumScrollView;
- (void)scrollToAlbumAtIndex:(NSInteger)index;
@end

@interface CaptureViewfinderController (AVCamCaptureManagerDelegate) <AVCamCaptureManagerDelegate>
@end

@implementation CaptureViewfinderController
{
    NSInteger flashMode;
    UIImage *selectedImage;
    NSMutableArray *imagePile;
    
    Album *selectedAlbum;
    
    BOOL memwarningDisplayed;
    BOOL topBarHidden;
    BOOL isCapable;
    BOOL topBarDisabled;
}

#pragma mark - Properties

@synthesize captureManager;
@synthesize cameraToggleButton;
@synthesize stillButton;
@synthesize videoPreviewView;
@synthesize vignetteView;
@synthesize captureVideoPreviewLayer;
@synthesize flashButtonAuto;
@synthesize flashButtonOn;
@synthesize flashButtonOff;
@synthesize delegate;
@synthesize isFinishedSelectingPhotoEarly;


#pragma mark - Actions

- (IBAction)albumPageControlDidChangeIndex:(id)sender
{
    
    [self scrollToAlbumAtIndex:self.albumPageControl.currentPage];
}


#pragma mark - Initializers

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    
    self.title = NSLocalizedString(@"Back", @"");
    
    [self configureAlbumScrollView];
    
    imagePile = [[NSMutableArray alloc] init];
    
    flashMode = kFlashModeAuto;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        // if so, does that camera support video?
        NSArray *mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        isCapable = [mediaTypes containsObject:(NSString *)kUTTypeMovie];
    }

    if (isCapable) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        
        if ([device hasFlash]) {
            [device lockForConfiguration:nil];
            [device setFlashMode:AVCaptureFlashModeAuto];
            [device unlockForConfiguration];
        }
        else {
            self.flashButtonAuto.enabled = NO;
            self.flashButtonAuto.hidden = YES;
        }
        
        if ([self captureManager] == nil) {
            AVCamCaptureManager *manager = [[AVCamCaptureManager alloc] init];
            [self setCaptureManager:manager];
            
            [[self captureManager] setDelegate:self];
            
            if ([[self captureManager] setupSession]) {
                // Create video preview layer and add it to the UI
                AVCaptureVideoPreviewLayer *newCaptureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:[[self captureManager] session]];
                
                self.videoPreviewView.frame = self.view.bounds;
                
                UIView *view = [self videoPreviewView];
                CALayer *viewLayer = [view layer];
                [viewLayer setMasksToBounds:YES];
                
                CGRect bounds = [view bounds];
                [newCaptureVideoPreviewLayer setFrame:bounds];
                
                if ([newCaptureVideoPreviewLayer connection].supportsVideoOrientation) {
                    [[newCaptureVideoPreviewLayer connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];
                }
                
                [newCaptureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
                
                [viewLayer insertSublayer:newCaptureVideoPreviewLayer below:[[viewLayer sublayers] objectAtIndex:0]];
                
                [self setCaptureVideoPreviewLayer:newCaptureVideoPreviewLayer];
                
                // Start the session. This is done asychronously since -startRunning doesn't return until the session is running.
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [[[self captureManager] session] startRunning];
                });
                
                [self updateButtonStates];
                
                // Add a single tap gesture to focus on the point tapped, then lock focus
                UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToAutoFocus:)];
                [singleTap setDelegate:self];
                [singleTap setNumberOfTapsRequired:1];
                [view addGestureRecognizer:singleTap];
                
                // Add a double tap gesture to reset the focus mode to continuous auto focus
                UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToHideUI:)];
                [doubleTap setDelegate:self];
                [doubleTap setNumberOfTapsRequired:2];
                [singleTap requireGestureRecognizerToFail:doubleTap];
                [view addGestureRecognizer:doubleTap];
                
                UITapGestureRecognizer *tripleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToContinouslyAutoFocus:)];
                [tripleTap setDelegate:self];
                [tripleTap setNumberOfTapsRequired:3];
                [singleTap requireGestureRecognizerToFail:tripleTap];
                [doubleTap requireGestureRecognizerToFail:tripleTap];
                [view addGestureRecognizer:tripleTap];
            }		
        }
    }
    
    
    
    [super viewDidLoad];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES];
    
    if (isCapable) {
        if ([self captureManager] != nil) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[[self captureManager] session] startRunning];
            });
        }
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
    // Dismiss the view if we're done working with photos.
    if (isFinishedSelectingPhotoEarly) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];

    }
    
    if (!isCapable) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Camera", @"") message:NSLocalizedString(@"We cannot find a usable camera on this device.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles: nil];
        [alert show];
        
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];

    }
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (isCapable) {
        [[[self captureManager] session] stopRunning];
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == AVCamFocusModeObserverContext) {
        
	} else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)didReceiveMemoryWarning
{
    self.stillButton.enabled = NO;
    
    if (!memwarningDisplayed) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Low Memory", @"") message:NSLocalizedString(@"You need to upload some of the pictures you've taken before you can take more!", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles: nil];
        
        [alertView show];
    }
    
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Actions

- (IBAction)toggleCamera:(id)sender
{
    // Toggle between cameras when there is more than one
    [[self captureManager] toggleCamera];
    
    AVCaptureDevicePosition position = [[[[self captureManager] videoInput] device] position];
    
    if (position == AVCaptureDevicePositionFront) {
        self.flashButtonOn.enabled = NO;
        self.flashButtonOn.hidden = YES;
        self.flashButtonAuto.enabled = NO;
        self.flashButtonAuto.hidden = YES;
        self.flashButtonOff.enabled = NO;
        self.flashButtonOff.hidden = YES;
    }
    else
    {
        AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        if ([device hasFlash]){
            [device lockForConfiguration:nil];
            
            switch (flashMode) {
                case kFlashModeAuto:
                    self.flashButtonOn.enabled = NO;
                    self.flashButtonOn.hidden = YES;
                    self.flashButtonAuto.enabled = YES;
                    self.flashButtonAuto.hidden = NO;
                    [device setFlashMode:AVCaptureFlashModeOff];
                    break;
                case kFlashModeOff:
                    self.flashButtonAuto.enabled = NO;
                    self.flashButtonAuto.hidden = YES;
                    self.flashButtonOff.enabled = YES;
                    self.flashButtonOff.hidden = NO;
                    [device setFlashMode:AVCaptureFlashModeOn];
                    break;
                case kFlashModeOn:
                    self.flashButtonOff.enabled = NO;
                    self.flashButtonOff.hidden = YES;
                    self.flashButtonOn.enabled = YES;
                    self.flashButtonOn.hidden = NO;
                    [device setFlashMode:AVCaptureFlashModeAuto];
                    break;
                default:
                    break;
            }
            
            [device unlockForConfiguration];
        }
    }
    
    // Do an initial focus
    [[self captureManager] continuousFocusAtPoint:CGPointMake(.5f, .5f)];
}


- (IBAction)captureStillImage:(id)sender
{
    // Capture a still image
    [[self stillButton] setEnabled:NO];
    
    [[self captureManager] captureStillImage];
}


- (IBAction)exitButtonPressed:(id)sender
{
    
    [[[self captureManager] session] stopRunning];
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];

}


- (IBAction)pickFromLibraryButtonPressed:(id)sender
{
    // This is now used for the picture pile.
    CaptureSelectImagesViewController *imageSelectorController = [[CaptureSelectImagesViewController alloc] initWithNibName:@"CaptureSelectImagesViewController" bundle:[NSBundle mainBundle]];
    imageSelectorController.takenPhotos = [[NSArray alloc] initWithArray:imagePile];
    imageSelectorController.selectedAlbum = selectedAlbum;
    
    [self.navigationController pushViewController:imageSelectorController animated:YES];
}


- (IBAction)changeFlashModeButtonPressed:(id)sender
{   
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if ([device hasFlash]){
        [device lockForConfiguration:nil];
        
        switch (flashMode) {
            case kFlashModeAuto:
                self.flashButtonAuto.enabled = NO;
                self.flashButtonAuto.hidden = YES;
                self.flashButtonOff.enabled = YES;
                self.flashButtonOff.hidden = NO;
                flashMode = kFlashModeOff;
                [device setFlashMode:AVCaptureFlashModeOff];
                break;
            case kFlashModeOff:
                self.flashButtonOff.enabled = NO;
                self.flashButtonOff.hidden = YES;
                self.flashButtonOn.enabled = YES;
                self.flashButtonOn.hidden = NO;
                flashMode = kFlashModeOn;
                [device setFlashMode:AVCaptureFlashModeOn];
                break;
            case kFlashModeOn:
                self.flashButtonOn.enabled = NO;
                self.flashButtonOn.hidden = YES;
                self.flashButtonAuto.enabled = YES;
                self.flashButtonAuto.hidden = NO;
                flashMode = kFlashModeAuto;
                [device setFlashMode:AVCaptureFlashModeAuto];
                break;
            default:
                break;
        }
        
        [device unlockForConfiguration];
    }
    
    
}


#pragma mark - ImagePickerController Delegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{    
    
}


#pragma mark - Memory Management

- (void)dealloc
{
   // [self removeObserver:self forKeyPath:@"captureManager.videoInput.device.focusMode"];
	
}

@end

@implementation CaptureViewfinderController (InternalMethods)


#pragma mark - Internal Methods

// Convert from view coordinates to camera coordinates, where {0,0} represents the top left of the picture area, and {1,1} represents
// the bottom right in landscape mode with the home button on the right.
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates 
{
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = [[self videoPreviewView] frame].size;
    
    if ([captureVideoPreviewLayer connection].videoMirrored) {
        viewCoordinates.x = frameSize.width - viewCoordinates.x;
    }

    
    if ( [[captureVideoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResize] ) {
		// Scale, switch x and y, and reverse x
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for (AVCaptureInputPort *port in [[[self captureManager] videoInput] ports]) {
            if ([port mediaType] == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;
                
                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;
                
                if ( [[captureVideoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspect] ) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
						// If point is inside letterboxed area, do coordinate conversion; otherwise, don't change the default value returned (.5,.5)
                        if (point.x >= blackBar && point.x <= blackBar + x2) {
							// Scale (accounting for the letterboxing on the left and right of the video preview), switch x and y, and reverse x
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
						// If point is inside letterboxed area, do coordinate conversion. Otherwise, don't change the default value returned (.5,.5)
                        if (point.y >= blackBar && point.y <= blackBar + y2) {
							// Scale (accounting for the letterboxing on the top and bottom of the video preview), switch x and y, and reverse x
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if ([[captureVideoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
					// Scale, switch x and y, and reverse x
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2; // Account for cropped height
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2); // Account for cropped width
                        xc = point.y / frameSize.height;
                    }
                }
                
                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }
    
    return pointOfInterest;
}


// Auto focus at a particular point. The focus mode will change to locked once the auto focus happens.
- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer
{
    if ([[[captureManager videoInput] device] isFocusPointOfInterestSupported]) {
        CGPoint tapPoint = [gestureRecognizer locationInView:[self videoPreviewView]];
        CGPoint convertedFocusPoint = [self convertToPointOfInterestFromViewCoordinates:tapPoint];
        [captureManager autoFocusAtPoint:convertedFocusPoint];
    }
}


// Change to continuous auto focus. The camera will constantly focus at the point choosen.
- (void)tapToContinouslyAutoFocus:(UIGestureRecognizer *)gestureRecognizer
{
    if ([[[captureManager videoInput] device] isFocusPointOfInterestSupported])
        [captureManager continuousFocusAtPoint:CGPointMake(.5f, .5f)];
}


- (void)tapToHideUI:(UIGestureRecognizer *)gestureRecognizer
{
    if (!topBarDisabled) {
        if (topBarHidden) {
            [UIView animateWithDuration:0.3 animations:^{
                self.topBarContainer.frame = CGRectMake(0, 0, 320, self.topBarContainer.frame.size.height);
            } completion:^(BOOL finished) {
                topBarHidden = !topBarHidden;
            }];
        }
        else
        {
            [UIView animateWithDuration:0.3 animations:^{
                self.topBarContainer.frame = CGRectMake(0, -78, 320, self.topBarContainer.frame.size.height);
            } completion:^(BOOL finished) {
                topBarHidden = !topBarHidden;
            }];
        }
        
        if (!gestureRecognizer) {
            topBarDisabled = YES;
        }
    }
    
}


// Update button states based on the number of available cameras and mics
- (void)updateButtonStates
{
	NSUInteger cameraCount = [[self captureManager] cameraCount];
    
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        if (cameraCount < 2) {
            [[self cameraToggleButton] setEnabled:NO]; 
            
            if (cameraCount < 1) {
                [[self stillButton] setEnabled:NO];
                
            } else {
                [[self stillButton] setEnabled:YES];
            }
        } else {
            [[self cameraToggleButton] setEnabled:YES];
            [[self stillButton] setEnabled:YES];
        }
    });
}


- (void)configureAlbumScrollView
{
    // Create the labels
    if (self.albums.count > 1) {
        for (NSUInteger index = 0; index < self.albums.count; index++) {
            UILabel *albumLabel = [[UILabel alloc] initWithFrame:CGRectMake(index*320, 0, 320, 32)];
            albumLabel.backgroundColor = [UIColor clearColor];
            
            if (IS_IOS6_OR_GREATER) {
                albumLabel.textAlignment = NSTextAlignmentCenter;
            }
            else
            {
                albumLabel.textAlignment = NSTextAlignmentCenter;
            }
            
            albumLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:18];
            albumLabel.textColor = [UIColor colorWithRed:0.92 green:0.92 blue:0.92 alpha:1.0];
            albumLabel.shadowColor = [UIColor blackColor];
            albumLabel.shadowOffset = CGSizeMake(0, 1);
            
            Album *currentAlbum = [self.albums objectAtIndex:index];
            albumLabel.text = currentAlbum.name;
            
            [self.albumScrollView addSubview:albumLabel];
        }
        
        [self.albumScrollView setContentSize:CGSizeMake(self.albumScrollView.frame.size.width*self.albums.count, self.albumScrollView.frame.size.height)];
        [self.albumPageControl setNumberOfPages:self.albums.count];
    }
    else
    {
        [self tapToHideUI:nil];
    }
    
    
    
    if (self.albums.count > 0) {
        selectedAlbum = [self.albums objectAtIndex:0];
    }
}


- (void)scrollToAlbumAtIndex:(NSInteger)index
{
    [self.albumScrollView scrollRectToVisible:CGRectMake(index*self.albumScrollView.frame.size.width, 0, self.albumScrollView.frame.size.width, self.albumScrollView.frame.size.height) animated:YES];
    
    selectedAlbum = [self.albums objectAtIndex:index];
}


#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSUInteger pageIndex = scrollView.contentOffset.x / scrollView.frame.size.width;
    
    [self.albumPageControl setCurrentPage:pageIndex];
    
    selectedAlbum = [self.albums objectAtIndex:pageIndex];
}

@end


#pragma mark - AVCamCaptureManagerDelegate

@implementation CaptureViewfinderController (AVCamCaptureManagerDelegate)

- (void)captureManager:(AVCamCaptureManager *)captureManager didFailWithError:(NSError *)error
{
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                            message:[error localizedFailureReason]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"OK button title")
                                                  otherButtonTitles:nil];
        [alertView show];
    });
}


- (void)captureManagerRecordingBegan:(AVCamCaptureManager *)captureManager
{
   
}


- (void)captureManagerRecordingFinished:(AVCamCaptureManager *)captureManager
{
    
}


- (void)captureManagerStillImageCaptured:(AVCamCaptureManager *)captureManager withImageData:(NSData *)data
{
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        [[self stillButton] setEnabled:YES];
    });
    
    if (imagePile.count == 0) {
        self.saveLabel.hidden = NO;
        self.saveButton.hidden = NO;
        
        [UIView animateWithDuration:0.3 animations:^{
            self.saveButton.alpha = 1.0;
            self.saveLabel.alpha = 1.0;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 delay:3.0 options:UIViewAnimationOptionCurveLinear animations:^{
                self.saveButton.alpha = 0.0;
                self.saveLabel.alpha = 0.0;
            } completion:^(BOOL finished) {
                self.saveLabel.hidden = YES;
                self.saveButton.hidden = YES;
            }];
        }];
    }
    
    
    NSString *filePath = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/Library/Caches/Photo%i.png", imagePile.count]];
    [data writeToFile:filePath atomically:YES];
    
    // Grab image data
    UIImage *stillImage = [UIImage imageWithData:data];
    UIImageView *animatedImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    animatedImageView.image = stillImage;
    [self.view addSubview:animatedImageView];
    
    [UIView animateWithDuration:0.6 animations:^{
        animatedImageView.frame = self.albumPreviewImage.frame;
    } completion:^(BOOL finished) {
        self.albumPreviewImage.image = stillImage;
        [imagePile addObject:filePath];
        self.imagePileCounterLabel.text = [NSString stringWithFormat:@"%i", imagePile.count];
        [animatedImageView removeFromSuperview];
    }];

}


- (void)captureManagerDeviceConfigurationChanged:(AVCamCaptureManager *)captureManager
{
	[self updateButtonStates];
}





@end
