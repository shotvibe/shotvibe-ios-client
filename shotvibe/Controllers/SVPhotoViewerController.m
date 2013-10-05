//
//  SVAlbumDetailScrollViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 2/14/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVPhotoViewerController.h"
#import "SVDefines.h"
#import "MFSideMenu.h"
#import "AlbumMember.h"
#import "AlbumPhoto.h"
#import "AlbumServerPhoto.h"
#import "UIImageView+AFNetworking.h"
#import "ShotVibeAppDelegate.h"
#import "MBProgressHUD.h"
#import "RCImageView.h"
#import "RCScrollImageView.h"
#import "RCTableImageViewCell.h"
#import "SVLinkActivity.h"

@interface SVPhotoViewerController ()
{
	UIScrollView *photosScrollView;
	NSMutableArray *cache;
	SVActivityViewController* activity;
	BOOL toolVisible;
	BOOL navigatingNext;
	BOOL uploadingAviaryPicture;//
	
	UITapGestureRecognizer *singleTap;
	UITapGestureRecognizer *doubleTap;
}

@property (nonatomic, strong) UIView *toolbarView;
@property (nonatomic, strong) UIButton *butTrash;
@property (nonatomic, strong) UILabel *detailLabel;

- (void)deleteButtonPressed;
- (void)exportButtonPressed;
- (void)toggleMenu;
- (void)updateInfoOnScreen;
@end

@implementation SVPhotoViewerController


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
	
	cache = [[NSMutableArray alloc] initWithCapacity:self.photos.count];
	for (id photo in self.photos) {
		[cache addObject:[NSNull null]];
	}
	[self.albumManager addAlbumContentsListener:self.albumId listener:self];
	
	// Add custom toolbar
	self.toolbarView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height-44, 320, 44)];
	self.toolbarView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
	self.toolbarView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	self.toolbarView.alpha = 0;
	
	self.butTrash = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
	[self.butTrash setImage:[UIImage imageNamed:@"trashIcon.png"] forState:UIControlStateNormal];
	[self.butTrash addTarget:self action:@selector(deleteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	[self.toolbarView addSubview:self.butTrash];
    
	UIButton *butShare = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-44, 0, 44, 44)];
	[butShare setImage:[UIImage imageNamed:@"exportIcon.png"] forState:UIControlStateNormal];
	[butShare addTarget:self action:@selector(exportButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	butShare.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	[self.toolbarView addSubview:butShare];
    
	UIButton *butEdit = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-44-44-10, 0, 44, 44)];
	[butEdit setImage:[UIImage imageNamed:@"PencilWhite.png"] forState:UIControlStateNormal];
	[butEdit addTarget:self action:@selector(displayEditor) forControlEvents:UIControlEventTouchUpInside];
	butEdit.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	[self.toolbarView addSubview:butEdit];
    
	self.navigationItem.rightBarButtonItem = nil;
	self.wantsFullScreenLayout = YES;
	
	int w = self.view.frame.size.width;
	int h = self.view.frame.size.height;
	
	photosScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, w+GAP_X, h)];
	photosScrollView.contentSize = CGSizeMake((w+GAP_X)*self.photos.count, h);
	photosScrollView.scrollEnabled = YES;
	photosScrollView.showsHorizontalScrollIndicator = NO;
	photosScrollView.showsVerticalScrollIndicator = NO;
	photosScrollView.pagingEnabled = YES;// Whether should stop at each page when scrolling
	photosScrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	photosScrollView.delegate = self;// set delegate
	photosScrollView.contentSize = CGSizeMake((w+GAP_X)*self.photos.count, h);
	photosScrollView.contentOffset = CGPointMake((w+GAP_X)*self.index, 0);
	[self.view addSubview:photosScrollView];
	
	RCScrollImageView *imageView = [self loadPhoto:self.index andPreloadNext:YES];
	[photosScrollView addSubview:imageView];
	
	// Add gestures
	
	doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
	doubleTap.numberOfTapsRequired = 2;
	
	singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
	singleTap.numberOfTapsRequired = 1;
	
	[singleTap requireGestureRecognizerToFail:doubleTap];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];NSLog(@"photos will appear %@", self.photos);
	
    self.navigationController.navigationBar.translucent = YES;
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
	
	[self setControlsHidden:YES animated:YES permanent:NO];
	
	[photosScrollView addGestureRecognizer:doubleTap];
	[photosScrollView addGestureRecognizer:singleTap];
	
	[self updateInfoOnScreen];
}
- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];NSLog(@"photos did appear");
	
	//[self.menuContainerViewController.view setFrame:[[UIScreen mainScreen] bounds]];
	[self didRotateFromInterfaceOrientation:UIInterfaceOrientationPortrait];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];NSLog(@"photos will disappear");
	
    self.navigationController.navigationBar.translucent = NO;
    //self.navigationController.toolbar.translucent = NO;
	//[self.navigationController setToolbarHidden:YES animated:YES];
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
	
	[photosScrollView removeGestureRecognizer:doubleTap];
	[photosScrollView removeGestureRecognizer:singleTap];
	
	if (!navigatingNext) {
		
		[self.albumManager removeAlbumContentsListener:self.albumId listener:self];
		self.albumManager = nil;
		
		photosScrollView.delegate = nil;
		[photosScrollView removeFromSuperview];
		photosScrollView = nil;
		
		self.photos = nil;
		cache = nil;
		activity = nil;
		
		singleTap = nil;
		doubleTap = nil;
	
		[self.toolbarView removeFromSuperview];
		self.toolbarView = nil;
		self.butTrash = nil;
		[self.detailLabel removeFromSuperview];
		self.detailLabel = nil;
	}
	navigatingNext = NO;
}


#pragma mark Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
	NSLog(@"PhotoViewer did receive memory warning %i %@", self.index, cache);
	
    // Dispose of any resources that can be recreated.
    
	int i = 0;
	NSArray *cacheIter = [NSArray arrayWithArray:cache];
	
	for (id photo in cacheIter) {
		if ([photo isKindOfClass:[RCScrollImageView class]] && self.index != i) {
			NSLog(@"remove photo from cache %i", i);
			RCScrollImageView *cachedImage = photo;
			cachedImage.delegate = nil;
			[cachedImage removeFromSuperview];
			[cache replaceObjectAtIndex:i withObject:[NSNull null]];
		}
		i++;
	}
}

- (void)dealloc {
	
	NSLog(@"dealloc SVPhotosViewwerController");
	
	for (id photo in cache) {
		
		if ([photo isKindOfClass:[RCScrollImageView class]]) {
			
			RCScrollImageView *cachedImage = photo;
			[cachedImage removeFromSuperview];
			cachedImage.delegate = nil;
		}
	}
	[cache removeAllObjects];
}


#pragma mark Rotation

- (BOOL)shouldAutorotate {
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	
	//[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	
	int w = self.view.frame.size.width;
	int h = self.view.frame.size.height;
	int i = 0;
	RCScrollImageView *cachedImage;
	
	for (id photo in cache) {
		
		if ([photo isKindOfClass:[RCScrollImageView class]]) {
			
			cachedImage = photo;
			cachedImage.frame = CGRectMake((w+GAP_X)*i, 0, w, h);
			[cachedImage setMaxMinZoomScalesForCurrentBounds];
			cachedImage.hidden = NO;
			
			if (cachedImage.i == self.index) {
				photosScrollView.frame = CGRectMake(0, 0, w+GAP_X, h);
				photosScrollView.contentSize = CGSizeMake((w+GAP_X)*self.photos.count, h);
				photosScrollView.contentOffset = CGPointMake((w+GAP_X)*self.index, 0);
				[photosScrollView addSubview:cachedImage];
			}
		}
		i++;
	}
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	__block int w = self.view.frame.size.height;
	__block int h = self.view.frame.size.width;
	int i = 0;
	
	// Hide all the images except the visible one
	RCScrollImageView *cachedImage;
	for (id photo in cache) {
		if ([photo isKindOfClass:[RCScrollImageView class]]) {
			
			cachedImage = photo;
			
			if (i == self.index) {
				
				cachedImage.hidden = NO;
				CGRect rect = cachedImage.frame;
				rect.origin.x = 0;
				rect.origin.y = 0;
				cachedImage.frame = rect;
				[self.view addSubview:cachedImage];
				NSLog(@"willRotateToInterfaceOrientation %@", NSStringFromCGRect(rect));
				
				// The method of animating the frame rather than using autoresizingMasks works better
				[UIView animateWithDuration:duration animations:^{
					cachedImage.frame = CGRectMake(0, 0, w, h);
				}];
			}
			else {
				cachedImage.hidden = YES;
			}
		}
		i++;
	}
	
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
}



#pragma mark load/unload photos

- (RCScrollImageView*)loadPhoto:(int)i andPreloadNext:(BOOL)preload {
	
	// Preload only one photo in advance
	if (i > self.index + 1 || i >= self.photos.count) {
		return nil;
	}
	if (i < self.index - 1 || i < 0) {
		return nil;
	}
	
	int w = self.view.frame.size.width;
	int h = self.view.frame.size.height;
	
	id cachedImage = [cache objectAtIndex:i];
	AlbumPhoto *photo = [self.photos objectAtIndex:i];
	
	if ([cachedImage isKindOfClass:[NSNull class]]) {
		
		// If the photo is not in cache load it
		RCScrollImageView *rcphoto = [[RCScrollImageView alloc] initWithFrame:CGRectMake((w+GAP_X)*i, 0, w, h) delegate:self];
		rcphoto.i = i;
		//rcphoto.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;// do not autoresze it
		
		if (photo.serverPhoto) {
			
			NSString *fullsizePhotoUrl = photo.serverPhoto.url;
			NSString *displaySuffix = @"_r_dvgax.jpg";
			NSString *finalUrl = [[fullsizePhotoUrl stringByDeletingPathExtension] stringByAppendingString:displaySuffix];
			[rcphoto loadNetworkImage:finalUrl];
		}
		else if (photo.uploadingPhoto) {
			
			UIImage *localImage = [UIImage imageWithData:[NSData dataWithContentsOfFile:[photo.uploadingPhoto getFilename]]];
			if (localImage != nil) {
				[rcphoto setImage:localImage];
				rcphoto.contentSize = localImage.size;
				[rcphoto setMaxMinZoomScalesForCurrentBounds];
				// Do not call loadComplete from here because the photo is not yet in cache, so you can't scale the photo
			}
		}
		
		cachedImage = rcphoto;
		
		NSLog(@"cache photo: %i", i);
		[cache replaceObjectAtIndex:i withObject:cachedImage];
		
		[photosScrollView addSubview:cachedImage];
	}
	
	if (preload) {
		[self loadPhoto:i+1 andPreloadNext:YES];
		[self loadPhoto:i-1 andPreloadNext:NO];
	}
	return cachedImage;
}
- (void)unloadPhoto:(int)i {
	
	if ([[self.photos objectAtIndex:i] isKindOfClass:[RCImageView class]]) {
		[[self.photos objectAtIndex:i] cancel];
		[[self.photos objectAtIndex:i] removeFromSuperview];
		[self.photos removeObjectAtIndex:i];
		[self.photos insertObject:[NSNull null] atIndex:i];
	}
}
- (void)onPhotoComplete:(NSNumber*)nr {
	NSLog(@"onPhotoComplete %@", nr);
	id photo = [cache objectAtIndex:[nr intValue]];
	if ([photo isKindOfClass:[RCScrollImageView class]]) {
		RCScrollImageView *cachedImage = photo;
		cachedImage.contentSize = cachedImage.image.size;
		[cachedImage loadComplete];
		[cachedImage setMaxMinZoomScalesForCurrentBounds];
	}
}
- (void)onPhotoProgress:(NSNumber*)percentLoaded nr:(NSNumber*)nr{
	
}


#pragma mark UIScrollView delegate functions

- (void)scrollViewDidEndDecelerating {
	
	CGFloat pageWidth = photosScrollView.frame.size.width;
	self.index = floor((photosScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
	[self updateInfoOnScreen];
	
	//RCScrollImageView *image =
	[self loadPhoto:self.index andPreloadNext:YES];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
//	NSLog(@"scrollViewWillBeginDragging");
//	uploadingAviaryPicture = NO;
}


#pragma mark Tap gestures

- (void)handleSingleTap:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
		if (self.toolbarView.alpha == 0) {
			[self setControlsHidden:NO animated:YES permanent:NO];
			[self.view addSubview:self.toolbarView];
		}
		else {
			[self setControlsHidden:YES animated:YES permanent:NO];
		}
    }
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
		RCScrollImageView *imageView = [cache objectAtIndex:self.index];
		[imageView toggleZoom];
    }
}



#pragma mark - Control Hiding / Showing

// If permanent then we don't set timers to hide again
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent {
    
	// Status bar and nav bar positioning
    if (self.wantsFullScreenLayout) {
        
        // Get status bar height if visible
        CGFloat statusBarHeight = 0;
        if (![UIApplication sharedApplication].statusBarHidden) {
            CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
            statusBarHeight = MIN(statusBarFrame.size.height, statusBarFrame.size.width);
        }
        
        // Status Bar
        [[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:animated?UIStatusBarAnimationFade:UIStatusBarAnimationNone];
        
        // Get status bar height if visible
        if (![UIApplication sharedApplication].statusBarHidden) {
            CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
            statusBarHeight = MIN(statusBarFrame.size.height, statusBarFrame.size.width);
        }
        
        // Set navigation bar frame
        CGRect navBarFrame = self.navigationController.navigationBar.frame;
        navBarFrame.origin.y = statusBarHeight;
        self.navigationController.navigationBar.frame = navBarFrame;
    }
	
	// Animate
    if (animated) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.35];
    }
    CGFloat alpha = hidden ? 0 : 1;
	[self.navigationController.navigationBar setAlpha:alpha];
	[self.toolbarView setAlpha:alpha];
	if (animated) [UIView commitAnimations];
	
}




- (void)updateInfoOnScreen
{
	if (self.detailLabel == nil) {
		
		// Setup detail label
		self.detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, -57, self.view.frame.size.width, 57)];
		self.detailLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
		self.detailLabel.textColor = [UIColor colorWithRed:0.92 green:0.92 blue:0.92 alpha:1.0];
		self.detailLabel.numberOfLines = 2;
		self.detailLabel.textAlignment = NSTextAlignmentCenter;
		self.detailLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
		self.detailLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self.toolbarView addSubview:self.detailLabel];
	}
	
	NSString *str = NSLocalizedString(@"Uploading photo...", @"");
	
	if (self.photos.count > self.index) {
		
		AlbumPhoto *photo = [self.photos objectAtIndex:self.index];
		
		if (photo.serverPhoto) {
			NSLog(@"name %@", photo.serverPhoto.authorNickname);
			NSString *dateFormated = [NSDateFormatter localizedStringFromDate:photo.serverPhoto.dateAdded
																	dateStyle:NSDateFormatterLongStyle
																	timeStyle:NSDateFormatterShortStyle];
			str = [NSString stringWithFormat:@"%@\n%@", photo.serverPhoto.authorNickname, dateFormated];
		}
		
		// Hide the trash button for photos that does not belong the the current user
		self.butTrash.hidden = photo.serverPhoto.authorUserId != [self.albumManager getShotVibeAPI].authData.userId;
	}
    self.detailLabel.text = str;
}




#pragma mark - Actions

- (void)deleteButtonPressed
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete picture", @"")
													message:NSLocalizedString(@"Deleting this picture will delete it from the cloud as well, are you sure you want to continue?", @"")
												   delegate:self
										  cancelButtonTitle:NSLocalizedString(@"No", @"")
										  otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
	[alert show];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	if (buttonIndex == 1) {
		[self deletePictureAtIndex:self.index];
	}
	else {
		((UIBarButtonItem*)self.toolbarItems[0]).enabled = YES;
	}
}

- (void)deletePictureAtIndex:(int)i {
	
	self.butTrash.enabled = NO;
	
	int w = self.view.frame.size.width;
	int h = self.view.frame.size.height;
	NSLog(@"delete index %i count %i", self.index, cache.count);
	
	AlbumPhoto *photo = [self.photos objectAtIndex:self.index];
	__block RCScrollImageView *cachedImage = [cache objectAtIndex:self.index];
	
	[MBProgressHUD showHUDAddedTo:self.view animated:YES];
	
	// send request
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		
		// Remove from server
		NSMutableArray *photosToDelete = [[NSMutableArray alloc] init];
		[photosToDelete addObject:@{@"photo_id":photo.serverPhoto.photoId}];
		NSLog(@"delete photos %@", photosToDelete);
		__block NSError *error;
		[[self.albumManager getShotVibeAPI] deletePhotos:photosToDelete withError:&error];
		NSLog(@"delete photo with error %@", error);
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[MBProgressHUD hideHUDForView:self.view animated:YES];
		});
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if (error) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error connecting to the server at this time.", @"")
																message:nil
															   delegate:nil
													  cancelButtonTitle:NSLocalizedString(@"Ok", @"")
													  otherButtonTitles:nil];
				[alert show];
				self.butTrash.enabled = YES;
			}
			else {
				// Animate deleted photo to the trashbin
				[UIView animateWithDuration:0.5
								 animations:^{
									 
									 if ([photo isKindOfClass:[RCScrollImageView class]]) {
										 CGRect rect = cachedImage.frame;
										 cachedImage.frame = CGRectMake(rect.origin.x, rect.size.height, 30, 30);
									 }
								 }
								 completion:^(BOOL finished){
									 
									 [self.photos removeObjectAtIndex:self.index];
									 [cache removeObjectAtIndex:self.index];
									 [cachedImage removeFromSuperview];
									 
									 if (self.photos.count == 0) {
										 [self.navigationController popViewControllerAnimated:YES];
									 }
									 else {
										 if (self.index >= self.photos.count) {
											 self.index = self.photos.count - 1;
											 [self loadPhoto:self.index andPreloadNext:YES];
										 }
										 else {
											 [self loadPhoto:self.index+1 andPreloadNext:YES];
										 }
										 
										 
										 // Iterate over all remaining photos and rearrange them in the scrollview
										 [UIView animateWithDuration:0.5
														  animations:^{
															  // Shift the indexes and photos to the left
															  int i = 0;
															  RCScrollImageView *cachedImage_;
															  for (id photo in cache) {
																  if ([photo isKindOfClass:[RCScrollImageView class]]) {
																	  cachedImage_ = photo;
																	  cachedImage_.i = i;
																	  cachedImage_.frame = CGRectMake((w+GAP_X)*i, 0, w, h);
																  }
																  i++;
															  }
														  }
														  completion:^(BOOL finished){
															  photosScrollView.contentSize = CGSizeMake((w+GAP_X)*[self.photos count], h);
															  self.butTrash.enabled = YES;
															  NSLog(@"finish rearanging left photos %i", cache.count);
														  }];
									 }
								 }];
			}
		});
	});
}



#pragma mark Custom Activity

- (void)exportButtonPressed
{
	AlbumPhoto *photo = [self.photos objectAtIndex:self.index];
	RCScrollImageView *cachedImage = [cache objectAtIndex:self.index];
	UIImage *image = cachedImage.image;
	
	if (activity == nil) {
		activity = [[SVActivityViewController alloc] initWithNibName:@"SVActivityViewController" bundle:[NSBundle mainBundle]];
		activity.controller = self;
		activity.delegate = self;
		activity.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
		activity.modalPresentationStyle = UIModalPresentationCurrentContext;
	}
    activity.activityDescription = NSLocalizedString(@"This is the text that goes with the sharing!", nil);
	activity.activityUrl = [NSURL URLWithString:photo.serverPhoto.url];
	activity.activityImage = image;
	
	[self.view addSubview:activity.view];
	
	activity.view.alpha = 0;
	__block CGRect rect = activity.activityView.frame;
	rect.origin.y = self.view.frame.size.height;
	activity.activityView.frame = rect;
	
	[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		rect.origin.y = self.view.frame.size.height - rect.size.height;
		rect.origin.x = self.view.frame.size.width/2 - rect.size.width/2;
		activity.view.alpha = 1;
		activity.activityView.frame = rect;
	}completion:^(BOOL finished) {
		
	}];
}

- (void)toggleMenu
{
    [self.menuContainerViewController toggleRightSideMenuCompletion:^{
		
	}];
}
-(void)activityDidClose {
	NSLog(@"activity did close");
	if (activity) {
		activity.controller = nil;
		activity.delegate = nil;
		activity = nil;
	}
}
-(void)activityDidStartSharing {
	[activity closeAndClean:NO];
}


#pragma mark Aviary sdk
#pragma mark Photo editing tool

- (void)displayEditor
{
	//AlbumPhoto *photo = [photos objectAtIndex:self.index];
	RCScrollImageView *cachedImage = [cache objectAtIndex:self.index];
	UIImage *imageToEdit = cachedImage.image;
	
    AFPhotoEditorController *editorController = [[AFPhotoEditorController alloc] initWithImage:imageToEdit];
    [editorController setDelegate:self];
	
	navigatingNext = YES;
    [self presentViewController:editorController animated:YES completion:nil];
	
}

- (void)photoEditor:(AFPhotoEditorController *)editor finishedWithImage:(UIImage *)image
{
	// Save the image to disk
	NSString *imagePath = [NSHomeDirectory() stringByAppendingString:@"/Library/Caches/AviaryPhoto.jpg"];
	NSString *thumbPath = [NSHomeDirectory() stringByAppendingString:@"/Library/Caches/AviaryPhoto_thumb.jpg"];
	
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		
		if ([UIImageJPEGRepresentation(image, 0.9) writeToFile:imagePath atomically:YES]) {
			
			CGSize newSize = CGSizeMake(200, 200);
			
			float oldWidth = image.size.width;
			float scaleFactor = newSize.width / oldWidth;
			
			float newHeight = image.size.height * scaleFactor;
			float newWidth = oldWidth * scaleFactor;
			
			UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
			[image drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
			UIImage *thumbImage = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();
			
			[UIImageJPEGRepresentation(thumbImage, 0.5) writeToFile:thumbPath atomically:YES];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				
				uploadingAviaryPicture = YES;
				
				// Upload the saved photo. This will call the refresh 2 times, one with the local photo and one after the photo is being uploaded
				PhotoUploadRequest *photoUploadRequest = [[PhotoUploadRequest alloc] initWithPath:imagePath];
				[self.albumManager.photoUploadManager uploadPhotos:self.albumId photoUploadRequests:@[photoUploadRequest]];
			});
		}
	});
	
	
	[editor dismissViewControllerAnimated:YES completion:^{
		[editor setDelegate:nil];
	}];
}



- (void)photoEditorCanceled:(AFPhotoEditorController *)editor
{
	[editor dismissViewControllerAnimated:YES completion:^{
		
	}];
}



#pragma mark Album update

- (void)onAlbumContentsBeginRefresh:(int64_t)albumId
{
	NSLog(@"---------------begin refresh");
}

- (void)onAlbumContentsRefreshComplete:(int64_t)albumId albumContents:(AlbumContents *)album
{
	// TODO: take into account when the refresh is coming from the AlbumGrid and when is coming from the PhotoViewer
	NSLog(@"---------------end refresh");
	NSLog(@"---------------photos count %i new photos count %i", self.photos.count, album.photos.count);
	
	if (self.photos.count == album.photos.count - 1) {
		[self.photos addObject:[album.photos lastObject]];
		[cache addObject:[NSNull null]];
	}
	else if (self.photos.count == album.photos.count) {
		[self.photos removeAllObjects];
		[self.photos addObjectsFromArray:album.photos];
		uploadingAviaryPicture = NO;
		[self updateInfoOnScreen];
	}
	
	if (uploadingAviaryPicture) {
		// Move the scrollbar to the new picture
		int w = self.view.frame.size.width;
		int h = self.view.frame.size.height;
		self.index = self.photos.count - 1;
		[self loadPhoto:self.index andPreloadNext:YES];
		photosScrollView.contentSize = CGSizeMake((w+GAP_X)*self.photos.count, h);
		photosScrollView.contentOffset = CGPointMake((w+GAP_X)*self.index, 0);
		[self updateInfoOnScreen];
	}
}

- (void)onAlbumContentsRefreshError:(int64_t)albumId error:(NSError *)error
{
	NSLog(@"error refresh");
}
- (void)onAlbumContentsPhotoUploadProgress:(int64_t)albumId {
	
}

@end
