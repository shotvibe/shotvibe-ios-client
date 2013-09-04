//
//  SVCameraPickerController.m
//  shotvibe
//
//  Created by Baluta Cristian on 22/08/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVCameraPickerController.h"


@implementation SVCameraPickerController


- (void)viewDidLoad {
	
    [super viewDidLoad];
    
	selectedPhotos = [[NSMutableArray alloc] init];
    self.capturedImages = [[NSMutableArray alloc] init];
	[self.sliderZoom addTarget:self
						action:@selector(zoomChanged:)
			  forControlEvents:UIControlEventValueChanged];
	
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(orientationChanged:)
												 name:UIDeviceOrientationDidChangeNotification
											   object:nil];
    
	tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
	
	[self configureAlbumScrollView];
	
    [self.gridView registerClass:[SVSelectionGridCell class] forCellWithReuseIdentifier:@"SVSelectionGridCell"];
	
	self.title = NSLocalizedString(@"Select To Upload", @"");
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"")
																   style:UIBarButtonItemStyleBordered
																  target:self
																  action:@selector(doneButtonPressed)];
    self.navigationItem.rightBarButtonItem = doneButton;
	self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewDidAppear:(BOOL)animated {
	
	[super viewDidAppear:animated];
	if (self.imagePickerController == nil) {
		[self showImagePickerForSourceType: UIImagePickerControllerSourceTypeCamera];
	}
	
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
	if (UIDeviceOrientationIsLandscape(deviceOrientation) || self.albums.count <= 1) {
		self.topBarContainer.hidden = YES;
		[self performSelector:@selector(hideTopBar) withObject:nil afterDelay:1];
    }
}
- (void)hideTopBar {
	
	self.topBarContainer.frame = CGRectMake(0, -60, 320, 150);
	self.swipeLabel.hidden = YES;
	self.topBarContainer.alpha = 0;
	
	[UIView animateWithDuration:0.3 animations:^{
		self.topBarContainer.alpha = 1;
		self.topBarContainer.hidden = NO;
	}];
	
	NSLayoutConstraint *topSpaceConstraint = [NSLayoutConstraint constraintWithItem:self.topBarContainer
                                                                             attribute:NSLayoutAttributeTop
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:self.overlayView
                                                                             attribute:NSLayoutAttributeTop
                                                                            multiplier:1.0
                                                                              constant:-60.0];
	[self.overlayView addConstraint:topSpaceConstraint];
}

- (void)orientationChanged:(NSNotification *)notification
{
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsLandscape(deviceOrientation) && !isShowingLandscapeView) {
		int angle = deviceOrientation == UIDeviceOrientationLandscapeLeft ? 90 : -90;
        isShowingLandscapeView = YES;
		[self.butShutter setImage:[UIImage imageNamed:@"cameraCaptureButton-Vertical.png"] forState:UIControlStateNormal];
		[UIView animateWithDuration:0.2 animations:^{
			self.butFlash.transform = CGAffineTransformMakeRotation(angle*M_PI/180);
			self.butToggleCamera.transform = CGAffineTransformMakeRotation(angle*M_PI/180);
			//self.tileContainer.transform = CGAffineTransformMakeRotation(-angle*M_PI/180);
		}];
		// Hide
		[UIView animateWithDuration:0.4 animations:^{
			self.topBarContainer.frame = CGRectMake(0, -60, 320, 150);
		}];
    }
    else if (UIDeviceOrientationIsPortrait(deviceOrientation) && isShowingLandscapeView) {
        isShowingLandscapeView = NO;
		[self.butShutter setImage:[UIImage imageNamed:@"cameraCaptureButton.png"] forState:UIControlStateNormal];
		[UIView animateWithDuration:0.2 animations:^{
			self.butFlash.transform = CGAffineTransformIdentity;
			self.butToggleCamera.transform = CGAffineTransformIdentity;
			//self.tileContainer.transform = CGAffineTransformIdentity;
		}];
		// Hide
		if (self.albums.count > 1) {
			NSLog(@"animate to 0");
			[UIView animateWithDuration:0.4 animations:^{
				self.topBarContainer.frame = CGRectMake(0, 0, 320, 150);
			}];
		}
    }
}


- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	
//    self.butShutter.enabled = NO;
//    
//	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Low Memory", @"")
//														message:NSLocalizedString(@"You need to upload some of the pictures you've taken before you can take more!", @"")
//													   delegate:nil
//											  cancelButtonTitle:NSLocalizedString(@"OK", @"")
//											  otherButtonTitles:nil];
//	
//	[alertView show];
}


- (void)tap:(UITapGestureRecognizer *)tapGesture {
	NSLog(@"add tap");
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	NSLog(@"touches began in controller");
	[super touchesBegan:touches withEvent:event];
}


- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType {
	
	self.imagePickerController = [[UIImagePickerController alloc] init];
	self.imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
	self.imagePickerController.sourceType = sourceType;
	self.imagePickerController.delegate = self;
    self.imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
	
    if (sourceType == UIImagePickerControllerSourceTypeCamera) {
		self.imagePickerController.showsCameraControls = NO;
//		self.overlayView.frame = self.imagePickerController.cameraOverlayView.frame;
//		self.imagePickerController.cameraOverlayView = self.overlayView;
//		self.imagePickerController.cameraOverlayView.hidden = YES;
//        self.overlayView = nil;
		
		SVCameraOverlay *overlayView_ = [[SVCameraOverlay alloc] initWithFrame:self.imagePickerController.view.frame];
		overlayView_.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		self.overlayView.frame = self.imagePickerController.cameraOverlayView.frame;
		[overlayView_ addSubview:self.overlayView];
		self.imagePickerController.cameraOverlayView = overlayView_;
    }
	
	// Device's screen size (ignoring rotation intentionally):
	CGSize screenSize = [[UIScreen mainScreen] bounds].size;
	
	// iOS is going to calculate a size which constrains the 4:3 aspect ratio
	// to the screen size. We're basically mimicking that here to determine
	// what size the system will likely display the image at on screen.
	// NOTE: screenSize.width may seem odd in this calculation - but, remember,
	// the devices only take 4:3 images when they are oriented *sideways*.
	float cameraAspectRatio = 4.0 / 3.0;
	float imageWidth = floorf(screenSize.width * cameraAspectRatio);
	float scale = ceilf((screenSize.height / imageWidth) * 10.0) / 10.0;
	
	self.imagePickerController.cameraViewTransform = CGAffineTransformMakeScale(scale, scale);
	self.sliderZoom.minimumValue = scale;
	
    [self presentViewController:self.imagePickerController animated:YES completion:^{
		
		self.imagePickerController.cameraOverlayView.hidden = NO;
		//[self.imagePickerController.cameraOverlayView addGestureRecognizer:tapGesture];
	}];
}





#pragma mark - Buttons Actions

- (IBAction)toggleCamera:(id)sender
{
    // Toggle between cameras when there is more than one
	if (self.imagePickerController.cameraDevice == UIImagePickerControllerCameraDeviceRear) {
		self.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
		self.butFlash.hidden = YES;
	}
	else {
		self.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
		self.butFlash.hidden = NO;
		// If necessary reset the flash mode
	}
}


- (IBAction)shooterPressed:(id)sender {
    // Capture a still image
    self.butShutter.enabled = NO;
    [self.imagePickerController takePicture];
	
	if (self.takeAnotherImage.hidden) {
		self.takeAnotherImage.hidden = NO;
	}
	else if (self.takeAnotherImage.alpha > 0) {
		self.takeAnotherImage.alpha = 0;
	}
}


- (IBAction)exitButtonPressed:(id)sender {
	
	if ([self.delegate respondsToSelector:@selector(cameraExit)]) {
		[self.delegate cameraExit];
	}
	
    [self.imagePickerController dismissViewControllerAnimated:YES completion:^{
		
	}];
}

- (IBAction)done:(id)sender {
	
	if (self.capturedImages.count > 0) {
		[self.imagePickerController dismissViewControllerAnimated:YES completion:^{
			
			[selectedPhotos addObjectsFromArray:self.capturedImages];
			[self.gridView reloadData];
			self.imagePickerController = nil;
		}];
	}
}

- (IBAction)changeFlashModeButtonPressed:(id)sender {
	
    switch (self.imagePickerController.cameraFlashMode) {
		case UIImagePickerControllerCameraFlashModeOff:
			self.imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
			[self.butFlash setImage:[UIImage imageNamed:@"cameraFlashOn.png"] forState:UIControlStateNormal];
			break;
		case UIImagePickerControllerCameraFlashModeOn:
			self.imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
			[self.butFlash setImage:[UIImage imageNamed:@"cameraFlashAuto.png"] forState:UIControlStateNormal];
			break;
		case UIImagePickerControllerCameraFlashModeAuto:
			self.imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
			[self.butFlash setImage:[UIImage imageNamed:@"cameraFlashOff.png"] forState:UIControlStateNormal];
			break;
		default:
			break;
	}
}



#pragma mark - UIImagePickerControllerDelegate

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	
	UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
	if (UIDeviceOrientationIsLandscape(deviceOrientation) || self.albums.count <= 1) {
		self.topBarContainer.hidden = YES;
	}
	
	self.butShutter.enabled = YES;
	
	// TODO: save the image at 1600x1200px
    UIImage *originalImage = [info valueForKey:UIImagePickerControllerOriginalImage];
	__block UIImage *thumbImage;
	NSString *filePath = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/Library/Caches/Photo%i.png", self.capturedImages.count]];
	NSString *thumbPath = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/Library/Caches/Photo%i_thumb.png", self.capturedImages.count]];
	
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		
		if ([UIImageJPEGRepresentation(originalImage, 0.9) writeToFile:filePath atomically:YES]) {
			
			CGSize newSize = CGSizeMake(200, 200);
			
			float oldWidth = originalImage.size.width;
			float scaleFactor = newSize.width / oldWidth;
			
			float newHeight = originalImage.size.height * scaleFactor;
			float newWidth = oldWidth * scaleFactor;
			
			UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
			[originalImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
			thumbImage = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();
			
			[UIImageJPEGRepresentation(thumbImage, 0.5) writeToFile:thumbPath atomically:YES];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				self.albumPreviewImage.image = thumbImage;
			});
		}
	});
    
    // Grab image data
    UIImageView *animatedImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    animatedImageView.image = originalImage;
    [self.imagePickerController.cameraOverlayView addSubview:animatedImageView];
	
	// Animation not working, TODO
    [UIView animateWithDuration:0.6 animations:^{
		CGRect f = self.albumPreviewImage.frame;
		f.origin.x += self.tileContainer.frame.origin.x;
		f.origin.y += self.view.frame.size.height - 25;
        animatedImageView.frame = f;
    }
	completion:^(BOOL finished) {
        
        [self.capturedImages addObject:filePath];
        self.imagePileCounterLabel.text = [NSString stringWithFormat:@"%i", self.capturedImages.count];
        [animatedImageView removeFromSuperview];
		
		if (UIDeviceOrientationIsLandscape(deviceOrientation) || self.albums.count <= 1) {
			[self performSelector:@selector(hideTopBar) withObject:nil afterDelay:0.6];
		}
    }];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}



#pragma mark Albums scroll

- (void)configureAlbumScrollView {
	
    // Create the labels
    if (self.albums.count > 1) {
        for (NSUInteger index = 0; index < self.albums.count; index++) {
            UILabel *albumLabel = [[UILabel alloc] initWithFrame:CGRectMake(index*320, 0, 320, 32)];
            albumLabel.backgroundColor = [UIColor clearColor];
			albumLabel.textAlignment = NSTextAlignmentCenter;
            albumLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
            albumLabel.textColor = [UIColor colorWithRed:0.92 green:0.92 blue:0.92 alpha:1.0];
            
            AlbumSummary *currentAlbum = [self.albums objectAtIndex:index];
            albumLabel.text = currentAlbum.name;
            
            [self.albumScrollView addSubview:albumLabel];
        }
        
        [self.albumScrollView setContentSize:CGSizeMake(self.albumScrollView.frame.size.width*self.albums.count, self.albumScrollView.frame.size.height)];
        [self.albumPageControl setNumberOfPages:self.albums.count];
    }
	
    if (self.albums.count > 0) {
        self.selectedAlbum = [self.albums objectAtIndex:0];
    }
}
- (void)goLeft:(id)sender {
	NSUInteger pageIndex = self.albumScrollView.contentOffset.x / self.albumScrollView.frame.size.width;
	[self scrollToAlbumAtIndex:pageIndex-1];
}
- (void)goRight:(id)sender {
	NSUInteger pageIndex = self.albumScrollView.contentOffset.x / self.albumScrollView.frame.size.width;
	[self scrollToAlbumAtIndex:pageIndex+1];
}


- (void)scrollToAlbumAtIndex:(NSInteger)index {
	if (index < 0 || index >= self.albumPageControl.numberOfPages) {
		return;
	}
    [self.albumScrollView scrollRectToVisible:CGRectMake(index*self.albumScrollView.frame.size.width, 0, self.albumScrollView.frame.size.width, self.albumScrollView.frame.size.height) animated:YES];
    self.selectedAlbum = [self.albums objectAtIndex:index];
    [self.albumPageControl setCurrentPage:index];
}


#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	
    NSUInteger pageIndex = scrollView.contentOffset.x / scrollView.frame.size.width;
    [self.albumPageControl setCurrentPage:pageIndex];
    self.selectedAlbum = [self.albums objectAtIndex:pageIndex];
}


#pragma mark zoom

- (void)zoomChanged:(UISlider*)slider {
	
	self.imagePickerController.cameraViewTransform = CGAffineTransformMakeScale(slider.value, slider.value);
}



#pragma mark Select photos

- (void) setTakenPhotos:(NSArray *)takenPhotos {
	
	selectedPhotos = [[NSMutableArray alloc] initWithArray:takenPhotos];
	
}




#pragma mark - UICollectionViewDataSource Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.capturedImages.count;
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SVSelectionGridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SVSelectionGridCell" forIndexPath:indexPath];
	
	dispatch_async(dispatch_get_global_queue(0,0),^{
		
		NSMutableString *thumbPath = [NSMutableString stringWithString:self.capturedImages[indexPath.row]];
		[thumbPath replaceOccurrencesOfString:@".png"
								   withString:@"_thumb.png"
									  options:NSLiteralSearch
										range:NSMakeRange(0, [thumbPath length])];
		UIImage *thumbImage = [UIImage imageWithContentsOfFile:thumbPath];
		
		dispatch_async(dispatch_get_main_queue(),^{
			cell.imageView.image = thumbImage;
		});
	});
	
	if ([selectedPhotos containsObject:[self.capturedImages objectAtIndex:indexPath.row]]) {
		cell.selectionIcon.image = [UIImage imageNamed:@"imageSelected.png"];
	}
	else {
		cell.selectionIcon.image = [UIImage imageNamed:@"imageUnselected.png"];
	}
	
    return cell;
}


#pragma mark - UICollectionViewDelegate Methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    SVSelectionGridCell *selectedCell = (SVSelectionGridCell *)[self.gridView cellForItemAtIndexPath:indexPath];
	
    if (![selectedPhotos containsObject:[self.capturedImages objectAtIndex:indexPath.row]]) {
        [selectedPhotos addObject:[self.capturedImages objectAtIndex:indexPath.row]];
        selectedCell.selectionIcon.image = [UIImage imageNamed:@"imageSelected.png"];
    }
    else {
        [selectedPhotos removeObject:[self.capturedImages objectAtIndex:indexPath.row]];
        selectedCell.selectionIcon.image = [UIImage imageNamed:@"imageUnselected.png"];
    }
	
	self.title = [NSString stringWithFormat:@"%i Photo%@ Selected", [selectedPhotos count], [selectedPhotos count]==1?@"":@"s"];
}


- (void)doneButtonPressed {
	
	NSLog(@"====================== 1. Package selected photos %@", [NSThread isMainThread] ? @"isMainThread":@"isNotMainThread");
	
	for (NSString *selectedPhotoPath in selectedPhotos) {
		NSData *photoData = [NSData dataWithContentsOfFile:selectedPhotoPath];
		if (photoData) {
            /*
			[SVBusinessDelegate saveUploadedPhotoImageData:photoData
												forPhotoId:[[NSUUID UUID] UUIDString]
											   withAlbumId:self.selectedAlbum.albumId];
             */
		}
	}
	
	// Upload the taken photos
	NSMutableArray *photoUploadRequests = [[NSMutableArray alloc] init];
	for (NSString *selectedPhotoPath in selectedPhotos) {
		//PhotoUploadRequest *photoUploadRequest = [[PhotoUploadRequest alloc] initWithAsset:asset];
		//[photoUploadRequests addObject:photoUploadRequest];
	}
	[self.albumManager.photoUploadManager uploadPhotos:self.albumId photoUploadRequests:photoUploadRequests];
	
	if ([self.delegate respondsToSelector:@selector(cameraWasDismissedWithAlbum:)]) {
		[self.delegate cameraWasDismissedWithAlbum:self.selectedAlbum];
	}
}

@end
