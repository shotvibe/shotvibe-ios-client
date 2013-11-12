//
//  SVAlbumDetailScrollViewController.m
//  shotvibe
//
//  Created by Baluta Cristian
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVPhotoViewerController.h"
#import "SVDefines.h"
#import "MFSideMenu.h"
#import "AlbumUser.h"
#import "AlbumPhoto.h"
#import "AlbumServerPhoto.h"
#import "ShotVibeAppDelegate.h"
#import "MBProgressHUD.h"
#import "SVLinkActivity.h"
#import "PhotoView.h"

static const int NUM_PHOTO_VIEWS = 3;

@interface SVPhotoViewerController () {
	
	UIScrollView *photosScrollView;
	UIView *toolbarView;
	UILabel *detailLabel;
	
	NSMutableArray *cache;
	SVActivityViewController* activity;
	BOOL toolsHidden;
	BOOL navigatingNext;
	BOOL uploadingAviaryPicture;//
	
	UITapGestureRecognizer *singleTap;
	UITapGestureRecognizer *doubleTap;
	
	UIButton *butTrash;
	UIButton *butShare;
	UIButton *butEdit;

    int currentPhotoViewsStartIndex;
    PhotoView *photoViews[NUM_PHOTO_VIEWS];
}

@end



@implementation SVPhotoViewerController


#pragma mark - View Lifecycle

- (void)viewDidLoad {
	
    [super viewDidLoad];
	
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:1];
	toolsHidden = YES;
	
	cache = [[NSMutableArray alloc] initWithCapacity:self.photos.count];
	for (id photo in self.photos) {
		[cache addObject:[NSNull null]];
	}
	
	// Add custom toolbar
	toolbarView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height-44, 320, 44)];
	toolbarView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
	toolbarView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	toolbarView.alpha = 0;
	
	butTrash = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
	[butTrash setImage:[UIImage imageNamed:@"trashIcon.png"] forState:UIControlStateNormal];
	[butTrash addTarget:self action:@selector(deleteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	[toolbarView addSubview:butTrash];
    
	butShare = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-44, 0, 44, 44)];
	[butShare setImage:[UIImage imageNamed:@"exportIcon.png"] forState:UIControlStateNormal];
	[butShare addTarget:self action:@selector(exportButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	butShare.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	[toolbarView addSubview:butShare];
    
	butEdit = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-44-44-10, 0, 44, 44)];
	[butEdit setImage:[UIImage imageNamed:@"PencilWhite.png"] forState:UIControlStateNormal];
	[butEdit addTarget:self action:@selector(displayEditor) forControlEvents:UIControlEventTouchUpInside];
	butEdit.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	[toolbarView addSubview:butEdit];
    
	self.navigationItem.rightBarButtonItem = nil;
	if (!IS_IOS7) self.wantsFullScreenLayout = YES;
	
    photosScrollView = [[UIScrollView alloc] init];
	photosScrollView.scrollEnabled = YES;
	photosScrollView.showsHorizontalScrollIndicator = NO;
	photosScrollView.showsVerticalScrollIndicator = NO;
	photosScrollView.pagingEnabled = YES;// Whether should stop at each page when scrolling
	photosScrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	photosScrollView.delegate = self;
	[self.view addSubview:photosScrollView];

    [self fitScrollViewToOrientation];

    currentPhotoViewsStartIndex = INT_MAX;
    for (int i = 0; i < NUM_PHOTO_VIEWS; ++i) {
        photoViews[i] = [[PhotoView alloc] initWithFrame:[self rectForPhotoIndex:i] withFullControls:YES];
        photoViews[i].contentMode = UIViewContentModeScaleAspectFit;
        [photosScrollView addSubview:photoViews[i]];
    }

    [self setPhotoViewsIndex:MAX(self.index - 1, 0)];

	// Add gestures
	
	doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
	doubleTap.numberOfTapsRequired = 2;
	
	singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
	singleTap.numberOfTapsRequired = 1;
	
	[singleTap requireGestureRecognizerToFail:doubleTap];
}

- (void)viewWillAppear:(BOOL)animated {
	
	[super viewWillAppear:animated];
	
	if (!IS_IOS7) {
		self.navigationController.navigationBar.translucent = YES;
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
	}
	
	[self setControlsHidden:YES animated:YES permanent:NO];
	
	[photosScrollView addGestureRecognizer:doubleTap];
	[photosScrollView addGestureRecognizer:singleTap];
	
	[self updateCaption];
	
	butTrash.enabled = YES;
	butShare.enabled = YES;
	butEdit.enabled = YES;
	navigatingNext = NO;
}

- (void)viewDidAppear:(BOOL)animated {
	
	[super viewDidAppear:animated];
	
	//[self.menuContainerViewController.view setFrame:[[UIScreen mainScreen] bounds]];
	[self didRotateFromInterfaceOrientation:UIInterfaceOrientationPortrait];
}

- (void)viewWillDisappear:(BOOL)animated {
	
    [super viewWillDisappear:animated];
	
	if (!IS_IOS7) {
		self.navigationController.navigationBar.translucent = NO;
		//self.navigationController.toolbar.translucent = NO;
		//[self.navigationController setToolbarHidden:YES animated:YES];
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
	}
	
	[photosScrollView removeGestureRecognizer:doubleTap];
	[photosScrollView removeGestureRecognizer:singleTap];
	
	if ( ! navigatingNext) {
		
		photosScrollView.delegate = nil;
		[photosScrollView removeFromSuperview];
		photosScrollView = nil;
		
		if (activity) {
			[self activityDidClose];
		}
		
		self.photos = nil;
		cache = nil;
		activity = nil;
		
		singleTap = nil;
		doubleTap = nil;
		
		[toolbarView removeFromSuperview];
		toolbarView = nil;
		butTrash = nil;
		[detailLabel removeFromSuperview];
		detailLabel = nil;
	}
	navigatingNext = NO;
}


- (UIStatusBarStyle)preferredStatusBarStyle {
	RCLog(@"preferredStatusBarStyle");
	return UIStatusBarStyleBlackTranslucent;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
	return UIStatusBarAnimationFade;
}

- (BOOL)prefersStatusBarHidden {
	RCLog(@"prefersStatusBarHidden %i", toolsHidden);
	return toolsHidden;// setNeedsStatusBarAppearanceUpdate
}

- (void)fitScrollViewToOrientation {
	
    int w = self.view.frame.size.width;
    int h = self.view.frame.size.height;
	
    photosScrollView.frame = CGRectMake(0, 0, w+GAP_X, h);
    photosScrollView.contentSize = CGSizeMake((w+GAP_X)*self.photos.count, h-40);
    photosScrollView.contentOffset = CGPointMake((w+GAP_X)*self.index, 0);
}

- (CGRect)rectForPhotoIndex:(int)i
{
    int w = self.view.frame.size.width;
    int h = self.view.frame.size.height;

    return CGRectMake((w + GAP_X) * i, 0, w, h);
}

- (void)setPhotoViewsIndex:(int)index
{
    if (currentPhotoViewsStartIndex == index) {
        return;
    }

    for (int i = 0; i < NUM_PHOTO_VIEWS; ++i) {
        if (index + i < self.photos.count) {
            photoViews[i].hidden = NO;
            [photoViews[i] setFrame:[self rectForPhotoIndex:index + i]];
            AlbumPhoto *photo = [self.photos objectAtIndex:index + i];
			RCLogRect(photoViews[i].frame);
			
            if (photo.serverPhoto) {
                [photoViews[i] setPhoto:photo.serverPhoto.photoId
                               photoUrl:photo.serverPhoto.url
                              photoSize:self.albumManager.photoFilesManager.DeviceDisplayPhotoSize
                                manager:self.albumManager.photoFilesManager];
            }
            else if (photo.uploadingPhoto) {
                UIImage *localImage = [[UIImage alloc] initWithContentsOfFile:[photo.uploadingPhoto getFilename]];
                [photoViews[i] setImage:localImage];
            }
        }
        else {
            photoViews[i].hidden = YES;
        }
    }
}



#pragma mark Rotation

- (BOOL)shouldAutorotate {
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    [self fitScrollViewToOrientation];
    currentPhotoViewsStartIndex = INT_MAX;
    [self setPhotoViewsIndex:MAX(self.index - 1, 0)];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

    UIView *currentPhoto = (self.index == 0)
        ? photoViews[0]
        : photoViews[1];

    for (int i = 0; i < NUM_PHOTO_VIEWS; ++i) {
        photoViews[i].hidden = YES;
    }

    currentPhoto.hidden = NO;

    int w = self.view.frame.size.height;
    int h = self.view.frame.size.width;

    [self.view addSubview:currentPhoto];

    CGRect rect = currentPhoto.frame;
    rect.origin.x = 0;
    rect.origin.y = 0;
    currentPhoto.frame = rect;

    [UIView animateWithDuration:duration
                     animations:^{
                         currentPhoto.frame = CGRectMake(0, 0, w, h);
                     }
                     completion:^(BOOL finished) {
                         [photosScrollView addSubview:currentPhoto];
                     }];
}


#pragma mark UIScrollView delegate functions

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	CGFloat pageWidth = photosScrollView.frame.size.width;
	self.index = floor((photosScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
	[self updateCaption];
    [self setPhotoViewsIndex:MAX(self.index - 1, 0)];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    CGFloat pageWidth = photosScrollView.frame.size.width;
    self.index = floor((photosScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    [self setPhotoViewsIndex:MAX(self.index - 1, 0)];
}


#pragma mark Tap gestures

- (void)handleSingleTap:(UITapGestureRecognizer *)sender {
	
    if (sender.state == UIGestureRecognizerStateEnded) {
		if (toolsHidden) {
			[self setControlsHidden:NO animated:YES permanent:NO];
			[self.view addSubview:toolbarView];
		}
		else {
			[self setControlsHidden:YES animated:YES permanent:NO];
		}
    }
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        // TODO toggle zoom
    }
}



#pragma mark - Control Hiding / Showing

// If permanent then we don't set timers to hide again
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent {
    
	toolsHidden = hidden;
	
	// Status bar and nav bar positioning
    if (IS_IOS7) {
	
	}
	else if (self.wantsFullScreenLayout) {
        
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
	if (IS_IOS7) {
		[self setNeedsStatusBarAppearanceUpdate];
	}
	
	// Animate
    if (animated) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.35];
    }
    CGFloat alpha = hidden ? 0 : 1;
	[self.navigationController.navigationBar setAlpha:alpha];
	[toolbarView setAlpha:alpha];
	if (animated) [UIView commitAnimations];
	
}




- (void)updateCaption {
	
	if (detailLabel == nil) {
		
		// Setup detail label
		detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, -57, self.view.frame.size.width, 57)];
		detailLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
		detailLabel.textColor = [UIColor colorWithRed:0.92 green:0.92 blue:0.92 alpha:1.0];
		detailLabel.numberOfLines = 2;
		detailLabel.textAlignment = NSTextAlignmentCenter;
		detailLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
		detailLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[toolbarView addSubview:detailLabel];
	}
	
	NSString *str = NSLocalizedString(@"Uploading photo...", @"");
	
	if (self.photos.count > self.index) {
		
		AlbumPhoto *photo = [self.photos objectAtIndex:self.index];
		
		if (photo.serverPhoto) {
			NSString *dateFormated = [NSDateFormatter localizedStringFromDate:photo.serverPhoto.dateAdded
																	dateStyle:NSDateFormatterLongStyle
																	timeStyle:NSDateFormatterShortStyle];
			str = [NSString stringWithFormat:@"%@\n%@", photo.serverPhoto.authorNickname, dateFormated];
			
			// Hide the trash button for photos that does not belong the the current user
            butTrash.hidden = photo.serverPhoto.authorUserId != [self.albumManager getShotVibeAPI].authData.userId;
		}
		else {
			// Hide the trash button for photos that does not belong the the current user
			butTrash.hidden = YES;
		}
	}
    detailLabel.text = str;
}




#pragma mark - Actions

- (void)deleteButtonPressed {
	
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
		//((UIBarButtonItem*)self.toolbarItems[0]).enabled = YES;
	}
}

- (void)deletePictureAtIndex:(int)i {
	
	butTrash.enabled = NO;
	
	RCLog(@"delete index %i count %i", self.index, cache.count);
	
	AlbumPhoto *photo = [self.photos objectAtIndex:self.index];
	__block PhotoView *image = photoViews[1];
	
	[MBProgressHUD showHUDAddedTo:self.view animated:YES];
	
	// send request
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		
		// Remove from server
		NSMutableArray *photosToDelete = [[NSMutableArray alloc] init];
		[photosToDelete addObject:@{@"photo_id":photo.serverPhoto.photoId}];
		RCLog(@"delete photos %@", photosToDelete);
		__block NSError *error;
		[[self.albumManager getShotVibeAPI] deletePhotos:photosToDelete withError:&error];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[MBProgressHUD hideHUDForView:self.view animated:YES];
			
			if (error) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error connecting to the server at this time.", @"")
																message:nil
															   delegate:nil
													  cancelButtonTitle:NSLocalizedString(@"Ok", @"")
													  otherButtonTitles:nil];
				[alert show];
				butTrash.enabled = YES;
			}
			else {
				// Animate deleted photo to the trashbin
				[UIView animateWithDuration:0.5
								 animations:^{
									 
									 CGRect rect = image.frame;
									 image.frame = CGRectMake(rect.origin.x, rect.size.height, 30, 30);
								 }
								 completion:^(BOOL finished){
									 
									 [self.photos removeObjectAtIndex:self.index];
									 image.hidden = YES;
									 
									 if (self.photos.count == 0) {
										 [self.navigationController popViewControllerAnimated:YES];
									 }
									 else {
										 if (self.index >= self.photos.count) {
											 self.index = self.photos.count - 1;
											 [self setPhotoViewsIndex:MAX(self.index-1, 0)];
										 }
										 else {
											 [self setPhotoViewsIndex:MAX(self.index + 1 - 1, 0)];
										 }
										 [self fitScrollViewToOrientation];
										 [self updateCaption];
										 
										 // Send a notification the the main screen to move this album on top of the list
										 NSDictionary *userInfo = @{@"albumId":[NSNumber numberWithLongLong:self.albumId]};
										 [[NSNotificationCenter defaultCenter] postNotificationName:@"album_changed" object:nil userInfo:userInfo];
										 
									 }
								 }
				 ];
			}
		});
	});
}



#pragma mark Custom Activity

- (void)exportButtonPressed
{
	// Weird bug on a phone, the buttons are touchable when the sharing screen is open
	butTrash.enabled = NO;
	butShare.enabled = NO;
	butEdit.enabled = NO;
	navigatingNext = YES;
	
	AlbumPhoto *photo = [self.photos objectAtIndex:self.index];
    UIImage *image = [photoViews[1] image];
	
	if (activity == nil) {
		activity = [[SVActivityViewController alloc] initWithNibName:@"SVActivityViewController" bundle:[NSBundle mainBundle]];
		activity.controller = self;
		activity.delegate = self;
        // TODO get albums from AlbumManager:
		activity.albums = nil;
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
	
	[UIView animateWithDuration:0.3
						  delay:0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
		rect.origin.y = self.view.frame.size.height - rect.size.height;
		rect.origin.x = self.view.frame.size.width/2 - rect.size.width/2;
		activity.view.alpha = 1;
		activity.activityView.frame = rect;
	}
					 completion:^(BOOL finished) {
		
	}];
}

- (void)toggleMenu {
    [self.menuContainerViewController toggleRightSideMenuCompletion:^{
		
	}];
}

- (void)activityDidClose {
	
	if (activity) {
		activity.controller = nil;
		activity.delegate = nil;
		activity.albums = nil;
		activity = nil;
	}
	butTrash.enabled = YES;
	butShare.enabled = YES;
	butEdit.enabled = YES;
	navigatingNext = NO;
}

- (void)activityDidStartSharing {
	[activity closeAndClean:NO];
}


#pragma mark Aviary sdk
#pragma mark Photo editing tool

- (void)displayEditor
{
	RCLog(@"display editor %i", self.index);
	//AlbumPhoto *photo = [photos objectAtIndex:self.index];
    // TODO load image:
	UIImage *imageToEdit = [photoViews[1] image];
	RCLogO(imageToEdit);
	
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
                // TODO upload photoUploadRequest to photoUploadManager
				
				// Send a notification the the main screen to move this album on top of the list
				NSDictionary *userInfo = @{@"albumId":[NSNumber numberWithLongLong:self.albumId]};
				[[NSNotificationCenter defaultCenter] postNotificationName:@"album_changed" object:nil userInfo:userInfo];
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

@end
