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

@interface SVPhotoViewerController ()

@property (nonatomic, strong) UIView *toolbarView;
@property (nonatomic, strong) UIButton *butTrash;
@property (nonatomic, strong) UILabel *detailLabel;

- (void)deleteButtonPressed;
- (void)exportButtonPressed;
- (void)toggleMenu;
- (void)updateInfoOnScreen;
- (void)showViewerOfType:(PhotoViewerType)type;
@end

@implementation SVPhotoViewerController


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
	
	albumContents = [self.albumManager addAlbumContentsListener:self.albumId listener:self];
	
	cache = [[NSMutableArray alloc] init];
	photos = [NSMutableArray arrayWithArray:albumContents.photos];
	for (id photo in photos) {
		[cache addObject:[NSNull null]];
	}
	
    // Setup navigation buttons
//    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"userIcon.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(toggleMenu)];
//    self.navigationItem.rightBarButtonItem = menuButton;
//	
//	UIBarItem* flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
//                                                  target: nil
//                                                  action: nil];
//    
//	// Setup toolbar buttons
//	UIImage* exportIcon = [UIImage imageNamed:@"exportIcon.png"];
//	
//	UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithImage: exportIcon
//																   style: UIBarButtonItemStylePlain
//																  target: self
//																  action: @selector(exportButtonPressed)];
//    
//	UIImage* deleteIcon = [UIImage imageNamed:@"trashIcon.png"];
//	
//	UIBarButtonItem *previousButton = [[UIBarButtonItem alloc] initWithImage: deleteIcon
//																	   style: UIBarButtonItemStylePlain
//																	  target: self
//																	  action: @selector(deleteButtonPressed)];
//	
//    self.toolbarItems = [NSArray arrayWithObjects:previousButton, flexibleSpace, nextButton, nil];
//    self.navigationController.toolbarHidden = YES;
	
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
	[butEdit setImage:[UIImage imageNamed:@"editProfileImageIcon.png"] forState:UIControlStateNormal];
	[butEdit addTarget:self action:@selector(displayEditor) forControlEvents:UIControlEventTouchUpInside];
	butEdit.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	[self.toolbarView addSubview:butEdit];
    
	[self showViewerOfType:PhotoViewerTypeScrollView];
	
	UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
	doubleTap.numberOfTapsRequired = 2;
	[photosScrollView addGestureRecognizer:doubleTap];
	
	UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
	singleTap.numberOfTapsRequired = 1;
	[photosScrollView addGestureRecognizer:singleTap];
	
	[singleTap requireGestureRecognizerToFail:doubleTap];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];NSLog(@"photos will appear");
	
    self.navigationController.navigationBar.translucent = YES;
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
	
	[self setControlsHidden:YES animated:YES permanent:NO];
	
	self.title = albumContents.name;
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
}
- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];NSLog(@"photos did disappear");
	
	//self.toolbarItems = nil;
	[self.detailLabel removeFromSuperview];
	self.detailLabel = nil;
	[self.view removeFromSuperview];
}



#pragma mark Rotation

- (BOOL)shouldAutorotate {
	return (viewerType == PhotoViewerTypeScrollView);
}

- (NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	
	//[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	
	int w = self.view.frame.size.width;
	int h = self.view.frame.size.height;
	int i = 0;
	
	for (id photo in cache) {
		
		RCScrollImageView *cachedImage;
		
		if ([photo isKindOfClass:[RCScrollImageView class]]) {
			
			cachedImage = photo;
			cachedImage.frame = CGRectMake((w+GAP_X)*i, 0, w, h);
			[cachedImage setMaxMinZoomScalesForCurrentBounds];
			cachedImage.hidden = NO;
			
			if (cachedImage.i == self.index) {
				photosScrollView.frame = CGRectMake(0, 0, w+GAP_X, h);
				photosScrollView.contentSize = CGSizeMake((w+GAP_X)*photos.count, h);
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


#pragma mark Viewer

- (void)showViewerOfType:(PhotoViewerType)type {
	viewerType = type;
	
	switch (viewerType) {
		case PhotoViewerTypeTableView:
		{
			if (photosTableView == nil) {
				photosTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 44, self.view.frame.size.width, self.view.frame.size.height-44) style:UITableViewStylePlain];
				//photosTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
				photosTableView.rowHeight = IMAGE_CELL_HEIGHT;
//				photosTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
				photosTableView.separatorColor = [UIColor grayColor];
				photosTableView.delegate = self;
				photosTableView.dataSource = self;
				photosTableView.backgroundColor = [UIColor blackColor];
				[self.view addSubview:photosTableView];
				[photosTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.index inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
				
			}
			photosTableView.alpha = 1;
			photosTableView.userInteractionEnabled = YES;
			[[UIApplication sharedApplication] setStatusBarHidden:NO];
			[self.navigationController setToolbarHidden:YES animated:YES];
			[self.navigationController setNavigationBarHidden:NO animated:YES];
		}
		break;
		
		case PhotoViewerTypeScrollView:
		{
			if (photosScrollView == nil) {
				self.navigationItem.rightBarButtonItem = nil;
				self.wantsFullScreenLayout = YES;
				
				int w = self.view.frame.size.width;
				int h = self.view.frame.size.height;
				
				photosScrollView = [[RCScrollView alloc] initWithFrame:CGRectMake(0, 0, w+GAP_X, h)];
				photosScrollView.contentSize = CGSizeMake((w+GAP_X)*photos.count, h);
				photosScrollView.scrollEnabled = YES;
				photosScrollView.showsHorizontalScrollIndicator = NO;
				photosScrollView.showsVerticalScrollIndicator = NO;
				photosScrollView.pagingEnabled = YES;// Whether should stop at each page when scrolling
				photosScrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
				photosScrollView.scrollDelegate = self;// set delegate
				photosScrollView.contentSize = CGSizeMake((w+GAP_X)*photos.count, h);
				photosScrollView.contentOffset = CGPointMake((w+GAP_X)*self.index, 0);
				if (photosTableView != nil) photosScrollView.alpha = 0;
				[self.view addSubview:photosScrollView];
				
				RCScrollImageView *imageView = [self loadPhoto:self.index andPreloadNext:YES];
				[photosScrollView addSubview:imageView];
				[self updateInfoOnScreen];
				
				//[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
				//[self.navigationController setToolbarHidden:YES animated:YES];
				//[self.navigationController setNavigationBarHidden:YES animated:YES];
			}
		}
		break;
	}
}

#pragma mark load/unload photos

- (RCScrollImageView*)loadPhoto:(int)i andPreloadNext:(BOOL)preload {
	
	// Preload only one photo in advance
	if (i > self.index + 1 || i >= photos.count) {
		return nil;
	}
	if (i < self.index - 1 || i < 0) {
		return nil;
	}
	
	int w = self.view.frame.size.width;
	int h = self.view.frame.size.height;
	
	id cachedImage = [cache objectAtIndex:i];
	AlbumPhoto *photo = [photos objectAtIndex:i];
	
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
		
		if (viewerType == PhotoViewerTypeScrollView) {
			[photosScrollView addSubview:cachedImage];
		}
	}
	
	if (preload) {
		[self loadPhoto:i+1 andPreloadNext:YES];
		[self loadPhoto:i-1 andPreloadNext:NO];
	}
	return cachedImage;
}
- (void)unloadPhoto:(int)i {
	
	if ([[photos objectAtIndex:i] isKindOfClass:[RCImageView class]]) {
		[[photos objectAtIndex:i] cancel];
		[[photos objectAtIndex:i] removeFromSuperview];
		[photos removeObjectAtIndex:i];
		[photos insertObject:[NSNull null] atIndex:i];
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






#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return photos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RCTableImageViewCell *cell = (RCTableImageViewCell*)[tableView dequeueReusableCellWithIdentifier:@"SVPhotoViewerCell"];
	self.index = indexPath.row;
	
	if (cell == nil) {
		cell = [[RCTableImageViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SVPhotoViewerCell"];
		cell.contentView.clipsToBounds = YES;
		cell.delegate = self;
	}
	RCScrollImageView *image = [self loadPhoto:indexPath.row andPreloadNext:NO];
	image.frame = CGRectMake(0, 5, 320, IMAGE_CELL_HEIGHT-40);
	cell.largeImageView = image;
	
	// Add description
	AlbumPhoto *photo = [photos objectAtIndex:self.index];
	NSString *dateFormated = [NSDateFormatter localizedStringFromDate:photo.serverPhoto.dateAdded dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterShortStyle];
	cell.detailLabel.text = [NSString stringWithFormat:@"%@ - %@", photo.serverPhoto.authorNickname, dateFormated];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	//cell.backgroundColor = [UIColor whiteColor];
	
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	
}


#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	tableView.userInteractionEnabled = NO;
	self.index = indexPath.row;
	[self showViewerOfType:PhotoViewerTypeScrollView];
	
	//
	__block int w = self.view.frame.size.width;
	__block int h = self.view.frame.size.height;
	
	if (w == 300) w = 320;
	if (w == 460) w = 480;
	if (h == 300) h = 320;
	if (h == 460) h = 480;
	
	//AlbumPhoto *photo = [photos objectAtIndex:self.index];
	RCScrollImageView *cachedImage = [cache objectAtIndex:self.index];
	
	// Get the cell rect and adjust it to consider scroll offset
	__block CGRect cellRect = [tableView rectForRowAtIndexPath:indexPath];
	cellRect = CGRectOffset(cellRect, -tableView.contentOffset.x, -tableView.contentOffset.y);
	
//	RCTableImageViewCell *cell = (RCTableImageViewCell*)[tableView cellForRowAtIndexPath:indexPath];
//	__block CGRect r = [cell convertRect:cell.frame toView:self.view];
	NSLog(@"zoom from %@", NSStringFromCGRect(cellRect));
	cachedImage.frame = cellRect;
	
	[self.view addSubview:photosScrollView];
	[self.view addSubview:cachedImage];
	
	[UIView animateWithDuration:0.4 animations:^{
		cachedImage.frame = CGRectMake(0, 0, w, h);
		photosTableView.alpha = 0;
		photosScrollView.alpha = 1;
	} completion:^(BOOL f){
		cachedImage.frame = CGRectMake((w + GAP_X) * self.index, 0, w, h);
		[photosScrollView addSubview:cachedImage];
	}];
}




#pragma mark ScrollView delegate functions

- (void)scrollViewDidEndDecelerating {
    //pageControlUsed = NO;
	CGFloat pageWidth = photosScrollView.frame.size.width;
	self.index = floor((photosScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
	[self updateInfoOnScreen];
	
//	int w = self.view.frame.size.width;
//	int h = self.view.frame.size.height;
	
	//RCScrollImageView *image =
	[self loadPhoto:self.index andPreloadNext:YES];
//	image.frame = CGRectMake((w+GAP_X)*self.index, 0, w, h);
//	[photosScrollView addSubview:image];
}


#pragma mark RCScrollView delegate

- (void)areaTouched {
	/*
	if (self.toolbarView.alpha == 0) {
		[self setControlsHidden:NO animated:YES permanent:NO];
		[self.view addSubview:self.toolbarView];
		
//		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
//		//[self.navigationController setToolbarHidden:NO animated:YES];
//		[self.view addSubview:self.toolbarView];
//		[UIView animateWithDuration:0.4 animations:^{
//			self.toolbarView.hidden = NO;
//			self.toolbarView.alpha = 1;
//		}];
//		[self.navigationController setNavigationBarHidden:NO animated:YES];
	}
	else {
		[self setControlsHidden:YES animated:YES permanent:NO];
		
//		[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
//		//[self.navigationController setToolbarHidden:YES animated:YES];
//		[UIView animateWithDuration:0.4 animations:^{
//			self.toolbarView.alpha = 0;
//		} completion:^(BOOL finished) {
//			self.toolbarView.hidden = YES;
//		}];
//		[self.navigationController setNavigationBarHidden:YES animated:YES];
	}*/
}

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




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
	NSLog(@"PhotoViewer did receive memory warning");
	
    // Dispose of any resources that can be recreated.
    
	int i = 0;
	
	for (id photo in cache) {
		if ([photo isKindOfClass:[RCScrollImageView class]] && self.index != i) {
			RCScrollImageView *img = photo;
			[img removeFromSuperview];
			[cache replaceObjectAtIndex:i withObject:[NSNull null]];
		}
		i++;
	}
}
- (void)dealloc {
	
	NSLog(@"dealloc SVPhotosViewwerController");
	
	for (id photo in cache) {
		if ([photo isKindOfClass:[RCScrollImageView class]]) {
			[photo removeFromSuperview];
		}
	}
	[cache removeAllObjects];
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
	
    AlbumPhoto *photo = [photos objectAtIndex:self.index];
	
	if (photo.serverPhoto) {
		NSString *dateFormated = [NSDateFormatter localizedStringFromDate:photo.serverPhoto.dateAdded
																dateStyle:NSDateFormatterLongStyle
																timeStyle:NSDateFormatterShortStyle];
		self.detailLabel.text = [NSString stringWithFormat:@"%@\n%@", photo.serverPhoto.authorNickname, dateFormated];
	}
	else {
		self.detailLabel.text = NSLocalizedString(@"Uploading photo...", @"");
	}
}


#pragma mark - Actions

- (void)deleteButtonPressed
{
	//((UIBarButtonItem*)self.toolbarItems[0]).enabled = NO;
	[self askIfOkToDelete];
}

- (void)deleteButtonPressedForIndex:(RCTableImageViewCell*)cell
{
	NSIndexPath *indexPath = [photosTableView indexPathForCell:cell];
	self.index = indexPath.row;
	[self deleteButtonPressed];
}

- (void)askIfOkToDelete {
	
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
	
	switch (viewerType) {
		case PhotoViewerTypeTableView:
		{
			NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.index inSection:0];
			[photosTableView beginUpdates];
			[photosTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
			AlbumPhoto *photoToDelete = [photos objectAtIndex:self.index];
			[photos removeObject:photoToDelete];
			[photosTableView endUpdates];
			((UIBarButtonItem*)self.toolbarItems[0]).enabled = YES;
		}break;
			
		case PhotoViewerTypeScrollView:
		{
			self.butTrash.enabled = NO;
			
			int w = self.view.frame.size.width;
			int h = self.view.frame.size.height;
			NSLog(@"delete index %i %i", self.index, cache.count);
			AlbumPhoto *photo = [photos objectAtIndex:self.index];
			RCScrollImageView *cachedImage = [cache objectAtIndex:self.index];
			
			// Remove physical file and mark for deletion from server
			//[[SVEntityStore sharedStore] deletePhoto:photoToDelete];
			
			// Remove from local array
			[photos removeObject:photo];
			
			// Animate deleted photo to the trashbin
			[UIView animateWithDuration:0.4
							 animations:^{
								 
								 if ([photo isKindOfClass:[RCScrollImageView class]]) {
									 CGRect rect = cachedImage.frame;
									 cachedImage.frame = CGRectMake(rect.origin.x, rect.size.height, 30, 30);
								 }
							 }
							 completion:^(BOOL finished){
								 
								[cachedImage removeFromSuperview];
								[cache removeObject:cachedImage];
								 [self loadPhoto:self.index+1 andPreloadNext:YES];
								 NSLog(@"deleted at index %i %i", self.index, cache.count);
								 
								 // Iterate over all remaining photos and rearrange them in the scrollview
								 [UIView animateWithDuration:0.5
												  animations:^{
													  
													  int i = 0;
													  RCScrollImageView *cachedImage;
													  for (id photo in cache) {
														  if ([photo isKindOfClass:[RCScrollImageView class]]) {
															  cachedImage = photo;
															  cachedImage.i = i;
															  cachedImage.frame = CGRectMake((w+60)*i, 0, w, h);
														  }
														  i++;
													  }
												  }
												  completion:^(BOOL finished){
													  photosScrollView.contentSize = CGSizeMake((w+60)*[photos count], h);
													  self.butTrash.enabled = YES;
													  NSLog(@"finish rearanging left photos %i", cache.count);
												  }];
							 }];
		}break;
	}
}



#pragma mark Custom Activity

- (void)exportButtonPressed
{
	AlbumPhoto *photo = [photos objectAtIndex:self.index];
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

- (void)shareButtonPressedForIndex:(RCTableImageViewCell*)cell {
	NSIndexPath *indexPath = [photosTableView indexPathForCell:cell];
	self.index = indexPath.row;
	[self exportButtonPressed];
}

- (void)toggleMenu
{
    [self.menuContainerViewController toggleRightSideMenuCompletion:^{
		
	}];
}
-(void)activityDidClose {
	if (viewerType == PhotoViewerTypeScrollView) {
		NSLog(@"activity did close");
		if (activity) {
			activity.controller = nil;
			activity.delegate = nil;
			activity = nil;
		}
	}
}
-(void)activityDidStartSharing {
	[activity closeAndClean:NO];
}


#pragma mark Aviary sdk
#pragma mark Photo editing tool

- (void)displayEditor
{
	AlbumPhoto *photo = [photos objectAtIndex:self.index];
	RCScrollImageView *cachedImage = [cache objectAtIndex:self.index];
	UIImage *imageToEdit = cachedImage.image;
	
    AFPhotoEditorController *editorController = [[AFPhotoEditorController alloc] initWithImage:imageToEdit];
    [editorController setDelegate:self];
	
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
				
				[cache addObject:[NSNull null]];
				
				// Upload the saved photo
				PhotoUploadRequest *photoUploadRequest = [[PhotoUploadRequest alloc] initWithPath:imagePath];
				[self.albumManager.photoUploadManager uploadPhotos:self.albumId photoUploadRequests:@[photoUploadRequest]];
			});
		}
	});
	
	
	[editor dismissViewControllerAnimated:YES completion:^{
		
	}];
}



- (void)photoEditorCanceled:(AFPhotoEditorController *)editor
{
	
    // Handle cancellation here
	[editor dismissViewControllerAnimated:YES completion:^{
		
	}];
}



#pragma mark content refresh

- (void)onAlbumContentsBeginRefresh:(int64_t)albumId
{
	NSLog(@"begin refresh");
}

- (void)onAlbumContentsRefreshComplete:(int64_t)albumId albumContents:(AlbumContents *)album
{
	NSLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>>>> reload data from length %i", photos.count);
	albumContents = album;
	photos = [NSMutableArray arrayWithArray:albumContents.photos];
	self.index = photos.count - 1;
	
	[self loadPhoto:self.index andPreloadNext:YES];
	[self updateInfoOnScreen];
	
	int w = self.view.frame.size.width;
	int h = self.view.frame.size.height;
	photosScrollView.contentOffset = CGPointMake((w+GAP_X)*self.index, 0);
}

- (void)onAlbumContentsRefreshError:(int64_t)albumId error:(NSError *)error
{
}

- (void)onAlbumContentsPhotoUploadProgress:(int64_t)albumId
{
}

@end
