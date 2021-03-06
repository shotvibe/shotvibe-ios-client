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
#import "SL/AuthData.h"
#import "SL/ShotVibeAPI.h"
#import "SL/AlbumUser.h"
#import "SL/AlbumPhoto.h"
#import "SL/AlbumServerPhoto.h"
#import "AlbumUploadingPhoto.h"
#import "ShotVibeAppDelegate.h"
#import "MBProgressHUD.h"
#import "SVLinkActivity.h"
#import "PhotoScrollView.h"
#import "SL/DateTime.h"
#import "SL/ArrayList.h"
#import "TmpFilePhotoUploadRequest.h"


@interface SVPhotoViewerController () {
	
	UITapGestureRecognizer *singleTap;
	UITapGestureRecognizer *doubleTap;
	UIScrollView *photosScrollView;
	NSMutableArray *cache;
	UIView *toolbarView;
	UIButton *butTrash;
	UIButton *butShare;
	UIButton *butEdit;
	UILabel *detailLabel;
	
	SVActivityViewController* activity;
	BOOL toolsHidden;
	BOOL navigatingNext;
	BOOL uploadingAviaryPicture;
}

@end



@implementation SVPhotoViewerController
{
    SLAlbumManager *albumManager_;
    PhotoFilesManager *photoFilesManager_;
}


#pragma mark - View Lifecycle

- (void)loadView {
	UIView *v = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.view = v;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    photoFilesManager_ = [ShotVibeAppDelegate sharedDelegate].photoFilesManager;

    albumManager_ = [ShotVibeAppDelegate sharedDelegate].albumManager;

    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:1];
    toolsHidden = YES;

    cache = [[NSMutableArray alloc] initWithCapacity:self.photos.count];
    for (id photo in self.photos) {
        [cache addObject:[NSNull null]];
    }

    // Add custom toolbar
    toolbarView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 44, 320, 44)];
    toolbarView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    toolbarView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    toolbarView.alpha = 0;

    butTrash = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 44, 0, 44, 44)];
    [butTrash setImage:[UIImage imageNamed:@"trashIcon.png"] forState:UIControlStateNormal];
    [butTrash addTarget:self action:@selector(deleteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [toolbarView addSubview:butTrash];

    butShare = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    [butShare setImage:[UIImage imageNamed:@"exportIcon.png"] forState:UIControlStateNormal];
    [butShare addTarget:self action:@selector(exportButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    butShare.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [toolbarView addSubview:butShare];

    butEdit = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 44 - 44 - 10, 0, 44, 44)];
    [butEdit setImage:[UIImage imageNamed:@"edit.png"] forState:UIControlStateNormal];
    [butEdit addTarget:self action:@selector(displayEditor) forControlEvents:UIControlEventTouchUpInside];
    butEdit.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [toolbarView addSubview:butEdit];

    self.navigationItem.rightBarButtonItem = nil;

    if (IS_IOS7) {
        self.navigationController.navigationBar.translucent = YES;
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.extendedLayoutIncludesOpaqueBars = YES;
        // This next lines will pad the y of the view to 44 or 64, depending if the status bar is visible
//		if([self respondsToSelector:@selector(edgesForExtendedLayout)])
//			self.edgesForExtendedLayout = UIRectEdgeNone;
    } else {
        self.wantsFullScreenLayout = YES;
    }

    photosScrollView = [[UIScrollView alloc] init];
    photosScrollView.scrollEnabled = YES;
    photosScrollView.showsHorizontalScrollIndicator = NO;
    photosScrollView.showsVerticalScrollIndicator = NO;
    photosScrollView.pagingEnabled = YES; // Whether should stop at each page when scrolling
    photosScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    photosScrollView.delegate = self;
    [self.view addSubview:photosScrollView];

    [self fitScrollViewToOrientation];
    [self setPhotoViewsIndex:self.index];

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
	
    [self setControlsHidden:NO animated:NO permanent:NO];
    [self.view addSubview:toolbarView];
	
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
	
	[self.menuContainerViewController.view setFrame:[[UIScreen mainScreen] bounds]];
	[self didRotateFromInterfaceOrientation:UIInterfaceOrientationPortrait];
}

- (void)viewWillDisappear:(BOOL)animated {
	
    [super viewWillDisappear:animated];
	
    self.navigationController.navigationBar.translucent = NO;
	if (!IS_IOS7) {
		//self.navigationController.toolbar.translucent = NO;
		//[self.navigationController setToolbarHidden:YES animated:YES];
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
	}
	else {
//		if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
//        self.edgesForExtendedLayout = UIRectEdgeNone;
//		self.navigationController.navigationBar.translucent = YES;
	}
	
	[photosScrollView removeGestureRecognizer:doubleTap];
	[photosScrollView removeGestureRecognizer:singleTap];
	
	if ( ! navigatingNext) {
		RCLog(@"viewWillDisappear !navigatingNext");
		photosScrollView.delegate = nil;
		[photosScrollView removeFromSuperview];
		photosScrollView = nil;
		
		if (activity) {
			[self activityDidClose];
		}
		
		self.photos = nil;
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


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
	RCLog(@"PhotoViewer did receive memory warning %i %@", self.index, cache);
	
    // Dispose of any resources that can be recreated.
    
	int i = 0;
	NSArray *cacheIter = [NSArray arrayWithArray:cache];
	
	for (id photo in cacheIter) {
		if ([photo isKindOfClass:[PhotoScrollView class]] && self.index != i) {
			RCLog(@"remove photo from cache %i", i);
			PhotoScrollView *cachedImage = photo;
			cachedImage.delegate = nil;
			[cachedImage removeFromSuperview];
			[cache replaceObjectAtIndex:i withObject:[NSNull null]];
		}
		i++;
	}
}


- (void)dealloc {
	
	RCLog(@"dealloc SVPhotosViewwerController");
	
	for (id photo in cache) {
		
		if ([photo isKindOfClass:[PhotoScrollView class]]) {
			
			PhotoScrollView *cachedImage = photo;
			[cachedImage removeFromSuperview];
			cachedImage.delegate = nil;
		}
	}
	[cache removeAllObjects];
}


- (UIStatusBarStyle)preferredStatusBarStyle {
//	RCLog(@"preferredStatusBarStyle");
	return UIStatusBarStyleBlackTranslucent;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
	return UIStatusBarAnimationSlide;
}

- (BOOL)prefersStatusBarHidden {
//	RCLog(@"prefersStatusBarHidden %i", toolsHidden);
	return toolsHidden;// setNeedsStatusBarAppearanceUpdate
}

- (void)fitScrollViewToOrientation {
	
    int w = self.view.frame.size.width;
    int h = self.view.frame.size.height;
	
    photosScrollView.frame = CGRectMake(0, 0, w+GAP_X, h);
    photosScrollView.contentSize = CGSizeMake((w+GAP_X)*self.photos.count, h);
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
	RCLog(@"setPhotoViewsIndex %i", index);
    for (int i = -1; i < 2; i++) {
		
		if (index + i >= 0 && index + i < self.photos.count) {
			
			id cachedImage = [cache objectAtIndex:index + i];
            SLAlbumPhoto *photo = [self.photos objectAtIndex:index + i];
			
			if ([cachedImage isKindOfClass:[NSNull class]]) {
				
				RCLog(@"create %i", index+i);
				// If the photo is not in cache load it
				PhotoScrollView *rcphoto = [[PhotoScrollView alloc] initWithFrame:[self rectForPhotoIndex:index + i] withFullControls:YES];
				cachedImage = rcphoto;
				
				[cache replaceObjectAtIndex:index+i withObject:cachedImage];
				[photosScrollView addSubview:cachedImage];
			}
			
			if (((PhotoScrollView*)cachedImage).index != index + i) {
				RCLog(@"load %i", index+i);
				((PhotoScrollView*)cachedImage).index = index + i;
                if ([photo getServerPhoto]) {
                    [cachedImage setPhoto:[[photo getServerPhoto] getId]
                                 photoUrl:[[photo getServerPhoto] getUrl]
                                photoSize:photoFilesManager_.DeviceDisplayPhotoSize
                                  manager:photoFilesManager_];
                } else if ([photo getUploadingPhoto]) {
                    // TODO: Get this working like it used to
                    //SLAlbumUploadingPhoto *uploadingPhoto = [photo getUploadingPhoto];
                    //UIImage *localImage = [[UIImage alloc] initWithContentsOfFile:[uploadingPhoto getFullResFilename]];
                    //[cachedImage setImage:localImage];
				}
			}
			
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

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
    __block int w = self.view.frame.size.height;
	__block int h = self.view.frame.size.width;
	int i = 0;
	
	// Hide all the images except the visible one
	PhotoScrollView *cachedImage;
	for (id photo in cache) {
		if ([photo isKindOfClass:[PhotoScrollView class]]) {
			
			cachedImage = photo;
			
			if (i == self.index) {
				
				cachedImage.hidden = NO;
				CGRect rect = cachedImage.frame;
				rect.origin.x = 0;
				rect.origin.y = 0;
				cachedImage.frame = rect;
				[self.view addSubview:cachedImage];
				
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
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	
	int i = 0;
	PhotoScrollView *cachedImage;
	
	for (id photo in cache) {
		
		if ([photo isKindOfClass:[PhotoScrollView class]]) {
			
			cachedImage = photo;
			cachedImage.frame = [self rectForPhotoIndex:i];
			[cachedImage setMaxMinZoomScalesForCurrentBounds];
			cachedImage.hidden = NO;
			
			if (cachedImage.index == self.index) {
				[self fitScrollViewToOrientation];
				[photosScrollView addSubview:cachedImage];
			}
		}
		i++;
	}
}


#pragma mark UIScrollView delegate functions

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	CGFloat pageWidth = photosScrollView.frame.size.width;
	self.index = floor((photosScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
	RCLogI(self.index);
	[self updateCaption];
    [self setPhotoViewsIndex:self.index];
}

//- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
//    CGFloat pageWidth = photosScrollView.frame.size.width;
//    //self.index = floor((photosScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
//}


#pragma mark Tap gestures

- (void)handleSingleTap:(UITapGestureRecognizer *)sender {
	RCLog(@"single tap");
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
        
		PhotoScrollView *cachedImage = [cache objectAtIndex:self.index];
		[cachedImage toggleZoom];
    }
}



#pragma mark - Control Hiding / Showing

// If permanent then we don't set timers to hide again
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent {
    
	toolsHidden = hidden;
	
	// Status bar and nav bar positioning
    if (IS_IOS7) {
		if (animated) {
			[UIView animateWithDuration:0.3 animations:^{
				[self setNeedsStatusBarAppearanceUpdate];
			}];
		}
		else {
			[self setNeedsStatusBarAppearanceUpdate];
		}
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
	
		// Setup detail label
	if (detailLabel == nil) {
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
		
        SLAlbumPhoto *photo = [self.photos objectAtIndex:self.index];
		
        if ([photo getServerPhoto]) {
            long long seconds = [[[photo getServerPhoto] getDateAdded] getTimeStamp] / 1000000LL;
            NSDate *dateAdded = [[NSDate alloc] initWithTimeIntervalSince1970:seconds];
            NSString *dateFormated = [NSDateFormatter localizedStringFromDate:dateAdded
																	dateStyle:NSDateFormatterLongStyle
																	timeStyle:NSDateFormatterShortStyle];
            str = [NSString stringWithFormat:@"Updated by %@\n%@", [[[photo getServerPhoto] getAuthor] getMemberNickname], dateFormated];
			
			// Hide the trash button for photos that does not belong the the current user
            butTrash.hidden = [[[photo getServerPhoto] getAuthor] getMemberId] != [[[albumManager_ getShotVibeAPI] getAuthData] getUserId];
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

- (void)deletePictureAtIndex:(int)i
{
    butTrash.enabled = NO;

    RCLog(@"delete index %i", self.index);

    SLAlbumPhoto *photo = [self.photos objectAtIndex:self.index];
    __block PhotoScrollView *cachedImage = [cache objectAtIndex:self.index];

    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    // send request
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // Remove from server
        NSMutableArray *photosToDelete = [[NSMutableArray alloc] init];
        [photosToDelete addObject:[[photo getServerPhoto] getId]];

        RCLog(@"delete photos %@", photosToDelete);
        SLAPIException *apiException = nil;
        @try {
            [[albumManager_ getShotVibeAPI] deletePhotosWithJavaLangIterable:[[SLArrayList alloc] initWithInitialArray:photosToDelete]];
        } @catch (SLAPIException *exception) {
            apiException = exception;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];

            if (apiException) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error connecting to the server at this time.", @"")
                                                                message:nil
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"Ok", @"")
                                                      otherButtonTitles:nil];
                [alert show];
                butTrash.enabled = YES;
            } else {
                // Animate deleted photo to the trashbin
                CGRect rect = cachedImage.frame;
                [UIView animateWithDuration:0.5
                                 animations:^{
                    cachedImage.frame = CGRectMake(rect.origin.x, rect.size.height, 30, 30);
                }


                                 completion:^(BOOL finished) {
                    cachedImage.image = nil;
                    cachedImage.frame = rect;

                    [self.photos removeObjectAtIndex:self.index];
                    [cache removeObjectAtIndex:self.index];
                    if (self.index < self.photos.count) {
                        [cache replaceObjectAtIndex:self.index withObject:[NSNull null]];
                    }

                    butTrash.enabled = YES;

                    if (self.photos.count <= 0) {
                        [self.navigationController popViewControllerAnimated:YES];
                    } else {
                        if (self.index >= self.photos.count) {
                            self.index = self.photos.count - 1;
                            [self setPhotoViewsIndex:self.index];
                        } else {
                            [self setPhotoViewsIndex:MAX(self.index + 1, 0)];
                        }
                        [self fitScrollViewToOrientation];
                        [self updateCaption];

                        // Send a notification the the main screen to move this album on top of the list
                        NSDictionary *userInfo = @{ @"albumId" : [NSNumber numberWithLongLong:self.albumId] };
                        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATIONCENTER_ALBUM_CHANGED object:nil userInfo:userInfo];
                    }
                }


                ];
            }
        }


                       );
    }


                   );
}



#pragma mark Custom Activity

- (void)exportButtonPressed
{
    NSLog(@"share");

    // For iOS 8 and later we use the system share dialog (UIActivityViewController).
    // For earlier versions we use a custom dialog

    NSString *iOS8 = @"8.0";

    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    if ([currSysVer compare:iOS8 options:NSNumericSearch] != NSOrderedAscending) {
        // Running iOS 8.0 or later

        UIImage *image = [[cache objectAtIndex:self.index] image];

        NSArray *activityItems = @[image];

        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                                                                             applicationActivities:nil];
        [self.navigationController presentViewController:activityViewController animated:YES completion:nil];

        return;
    }

    // Running older version of iOS...

	// Weird bug on a phone, the buttons are touchable when the sharing screen is open
	butTrash.enabled = NO;
	butShare.enabled = NO;
	butEdit.enabled = NO;
	navigatingNext = YES;
	
    SLAlbumPhoto *photo = [self.photos objectAtIndex:self.index];
    UIImage *image = [[cache objectAtIndex:self.index] image];
	
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
    activity.activityUrl = [NSURL URLWithString:[[photo getServerPhoto] getUrl]];
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
	RCLog(@"activityDidClose");
	
	if (activity) {
		activity.controller = nil;
		activity.delegate = nil;
		activity.albums = nil;
		activity = nil;
	}
	butTrash.enabled = YES;
	butShare.enabled = YES;
	butEdit.enabled = YES;
	
	// viewdiddisappear is called before activityDidClose and is causing the scrollview to disappear
	// do not set navigatingNext to NO yet
	//navigatingNext = NO;
	
	if (IS_IOS7) {
		[self setControlsHidden:NO animated:YES permanent:NO];
	}
}

- (void)activityDidStartSharing {
	RCLog(@"activityDidStartSharing");
	[activity closeAndClean:YES];
}


#pragma mark Aviary sdk
#pragma mark Photo editing tool

- (void)displayEditor
{
	RCLog(@"display editor %i", self.index);
	//AlbumPhoto *photo = [photos objectAtIndex:self.index];
    // TODO load image:
	UIImage *imageToEdit = [[cache objectAtIndex:self.index] image];
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

                TmpFilePhotoUploadRequest *photoUploadRequest = [[TmpFilePhotoUploadRequest alloc] initWithTmpFile:imagePath];
                NSMutableArray *photoUploadRequests = [[NSMutableArray alloc] init];
                [photoUploadRequests addObject:photoUploadRequest];
                [albumManager_ uploadPhotosWithLong:self.albumId
                                   withJavaUtilList:[[SLArrayList alloc] initWithInitialArray:photoUploadRequests]];

				// Send a notification the the main screen to move this album on top of the list
				NSDictionary *userInfo = @{@"albumId":[NSNumber numberWithLongLong:self.albumId]};
				[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATIONCENTER_ALBUM_CHANGED object:nil userInfo:userInfo];
			});
		}
	});
	
	[editor dismissViewControllerAnimated:YES completion:^{
		[editor setDelegate:nil];
        [self setControlsHidden:NO animated:NO permanent:YES];
        [self.navigationController popViewControllerAnimated:YES];
	}];
}



- (void)photoEditorCanceled:(AFPhotoEditorController *)editor
{
	[editor dismissViewControllerAnimated:YES completion:^{
		
	}];
}

@end
