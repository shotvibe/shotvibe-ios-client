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
	cache = [[NSMutableDictionary alloc] init];
	photos = [NSMutableArray arrayWithArray:self.albumContents.photos];
	
	
    // Setup navigation buttons
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"userIcon.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(toggleMenu)];
    self.navigationItem.rightBarButtonItem = menuButton;
	
	UIBarItem* flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
                                                  target: nil
                                                  action: nil];
    
	// Setup toolbar buttons
	UIImage* exportIcon = [UIImage imageNamed:@"exportIcon.png"];
	
	UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithImage: exportIcon
																   style: UIBarButtonItemStylePlain
																  target: self
																  action: @selector(exportButtonPressed)];
    
	UIImage* deleteIcon = [UIImage imageNamed:@"trashIcon.png"];
	
	UIBarButtonItem *previousButton = [[UIBarButtonItem alloc] initWithImage: deleteIcon
																	   style: UIBarButtonItemStylePlain
																	  target: self
																	  action: @selector(deleteButtonPressed)];
	
    self.toolbarItems = [NSArray arrayWithObjects:previousButton, flexibleSpace, nextButton, nil];
    self.navigationController.toolbarHidden = YES;
    
	[self showViewerOfType:PhotoViewerTypeScrollView];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];NSLog(@"photos will appear");
	
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.toolbar.translucent = YES;
	self.navigationController.toolbarHidden = YES;
	self.title = self.albumContents.name;
}
- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];NSLog(@"photos did appear");
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
	
	[self.menuContainerViewController.view setFrame:[[UIScreen mainScreen] bounds]];
	[self didRotateFromInterfaceOrientation:UIInterfaceOrientationPortrait];
	
//	[UIView animateWithDuration:0.4 animations:^{
//		[self.menuContainerViewController.view setFrame:[[UIScreen mainScreen] bounds]];
//	} completion:^(BOOL fin){
//		[self didRotateFromInterfaceOrientation:UIInterfaceOrientationPortrait];
//	}];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];NSLog(@"photos will disappear");
	
    self.navigationController.navigationBar.translucent = NO;
    //self.navigationController.toolbar.translucent = NO;
	[self.navigationController setToolbarHidden:YES animated:YES];
	self.detailLabel.hidden = YES;
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
	
	[UIView animateWithDuration:0.4 animations:^{
		[self.menuContainerViewController.view setFrame:[[UIScreen mainScreen] applicationFrame]];
	} completion:^(BOOL finished) {
		
	}];
}
- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];NSLog(@"photos did disappear");
	
	self.toolbarItems = nil;
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
	
	for (AlbumPhoto *photo in photos) {
		
		RCScrollImageView *cachedImage = [cache objectForKey:photo.serverPhoto.photoId];
		cachedImage.frame = CGRectMake((w+GAP_X)*i, 0, w, h);
		[cachedImage setMaxMinZoomScalesForCurrentBounds];
		cachedImage.hidden = NO;
		i++;
		
		if (cachedImage.i == self.index) {
			photosScrollView.frame = CGRectMake(0, 0, w+GAP_X, h);
			photosScrollView.contentSize = CGSizeMake((w+GAP_X)*photos.count, h);
			photosScrollView.contentOffset = CGPointMake((w+GAP_X)*self.index, 0);
			[photosScrollView addSubview:cachedImage];
		}
	}
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	__block int w = self.view.frame.size.height;
	__block int h = self.view.frame.size.width;
	
	// Hide all the images except the visible one
	for (AlbumPhoto *photo in photos) {
		RCScrollImageView *cachedImage = [cache objectForKey:photo.serverPhoto.photoId];
		if (cachedImage.i != self.index) {
			cachedImage.hidden = YES;
		}
	}
	
	if (w == 300) w = 320;
	if (w == 460) w = 480;
	if (h == 300) h = 320;
	if (h == 460) h = 480;
	
	AlbumPhoto *photo = [photos objectAtIndex:self.index];
	RCScrollImageView *cachedImage = [cache objectForKey:photo.serverPhoto.photoId];
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
			self.detailLabel.hidden = YES;
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
				
				[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
				[self.navigationController setToolbarHidden:YES animated:YES];
				[self.navigationController setNavigationBarHidden:YES animated:YES];
				self.detailLabel.hidden = YES;
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
	
	AlbumPhoto *photo = [photos objectAtIndex:i];
	RCScrollImageView *cachedImage = [cache objectForKey:photo.serverPhoto.photoId];
	
	//NSLog(@"loadPhoto %i %@", i, photo.serverPhoto.photoId);
	//NSLog(@"acche keys %@", [cache allKeys]);
    
    if (cachedImage == nil) {
		
		// If the photo is not in cache try in the saved photos
		RCScrollImageView *rcphoto = [[RCScrollImageView alloc] initWithFrame:CGRectMake((w+GAP_X)*i, 0, w, h) delegate:self];
		rcphoto.i = i;
		
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
			}
		}
		
		cachedImage = rcphoto;
		[cache setObject:rcphoto forKey:photo.serverPhoto.photoId];
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
	
	AlbumPhoto *photo = [photos objectAtIndex:[nr intValue]];
	RCScrollImageView *cachedImage = [cache objectForKey:photo.serverPhoto.photoId];
	cachedImage.contentSize = cachedImage.image.size;
	[cachedImage.loadingIndicator stopAnimating];
	[cachedImage setMaxMinZoomScalesForCurrentBounds];
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
	
	AlbumPhoto *photo = [photos objectAtIndex:self.index];
	RCScrollImageView *cachedImage = [cache objectForKey:photo.serverPhoto.photoId];
	
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
	
	int w = self.view.frame.size.width;
	int h = self.view.frame.size.height;
	
	RCScrollImageView *image = [self loadPhoto:self.index andPreloadNext:YES];
	image.frame = CGRectMake((w+GAP_X)*self.index, 0, w, h);
	[photosScrollView addSubview:image];
}


#pragma mark RCScrollView delegate

- (void)areaTouched {
	
	if (self.navigationController.toolbarHidden) {
		//[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
		[self.navigationController setToolbarHidden:NO animated:YES];
		[self.navigationController setNavigationBarHidden:NO animated:YES];
		self.detailLabel.hidden = NO;
	}
	else {
		//[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
		[self.navigationController setToolbarHidden:YES animated:YES];
		[self.navigationController setNavigationBarHidden:YES animated:YES];
		self.detailLabel.hidden = YES;
	}
}

//- (void)areaTouchedForExit {
//	[self.navigationController popViewControllerAnimated:YES];
//	if (self.navigationController.toolbar.hidden) [self areaTouched];
//}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
	NSLog(@"PhotoViewer did receive memory warning");
	
    // Dispose of any resources that can be recreated.
    
	NSArray *keys = [cache allKeys];
	int i = 0;
	
	for (NSString *key in keys) {
		AlbumPhoto *photo = [photos objectAtIndex:i];
		if (photo.serverPhoto && ![key isEqualToString:photo.serverPhoto.photoId]) {
			RCScrollImageView *img = [cache objectForKey:key];
			[img removeFromSuperview];
			[cache removeObjectForKey:key];
		}
		i++;
	}
}
- (void)dealloc {
	
	NSLog(@"dealloc SVPhotosViewwerController");
	
	for (NSString *key in [cache allKeys]) {
		RCImageView *img = [cache objectForKey:key];
		[img removeFromSuperview];
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
		[self.navigationController.toolbar addSubview:self.detailLabel];
	}
	
    AlbumPhoto *photo = [photos objectAtIndex:self.index];
	NSString *dateFormated = [NSDateFormatter localizedStringFromDate:photo.serverPhoto.dateAdded
															dateStyle:NSDateFormatterLongStyle
															timeStyle:NSDateFormatterShortStyle];
	
	NSString *str = [NSString stringWithFormat:@"%@\n%@", photo.serverPhoto.authorNickname, dateFormated];
	self.detailLabel.text = str;

	/*
	if (photo.hasViewed.intValue == NO) {
		//dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
			[[SVEntityStore sharedStore] setPhotoAsViewed:photo.photo_id];
		//});
	}
     */
}


#pragma mark - Actions

- (void)deleteButtonPressed
{
	((UIBarButtonItem*)self.toolbarItems[0]).enabled = NO;
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
			int w = self.view.frame.size.width;
			int h = self.view.frame.size.height;
			
			AlbumPhoto *photoToDelete = [photos objectAtIndex:self.index];
			RCImageView *cachedImage = [cache objectForKey:photoToDelete.serverPhoto.photoId];
			
			// Remove physical file and mark for deletion from server
			//[[SVEntityStore sharedStore] deletePhoto:photoToDelete];
			
			// Remove from local array
			[photos removeObject:photoToDelete];
			
			// Animate deleted photo to the trashbin
			[UIView animateWithDuration:0.3
							 animations:^{
								 
								 if (cachedImage) {
									 CGRect rect = cachedImage.frame;
									 cachedImage.frame = CGRectMake(rect.origin.x, rect.size.height, 30, 30);
								 }
							 }
							 completion:^(BOOL finished){
								 
								 if (cachedImage) {
									 [cachedImage removeFromSuperview];
									 [cache removeObjectForKey:photoToDelete.serverPhoto.photoId];
								 }
							 }];
			
			// Iterate over all remaining photos and rearrange them in the scrollview
			[UIView animateWithDuration:0.6
							 animations:^{
								 
								 int i = 0;
								 for (AlbumPhoto *photo in photos) {
									 RCScrollImageView *cachedImage = [cache objectForKey:photo.serverPhoto.photoId];
									 if (cachedImage) {
										 cachedImage.i = i;
										 cachedImage.frame = CGRectMake((w+60)*i, 0, w, h);
									 }
									 i++;
								 }
							 }
							 completion:^(BOOL finished){
								 photosScrollView.contentSize = CGSizeMake((w+60)*[photos count], h);
								 ((UIBarButtonItem*)self.toolbarItems[0]).enabled = YES;
							 }];
		}break;
	}
}



#pragma mark Custom Activity

- (void)exportButtonPressed
{
	[self.navigationController setToolbarHidden:YES animated:YES];
	self.detailLabel.hidden = YES;
	
	AlbumPhoto *photo = [photos objectAtIndex:self.index];
	RCScrollImageView *imageView = [cache objectForKey:photo.serverPhoto.photoId];
	UIImage *image = imageView.image;
	
	if (activity == nil) {
		activity = [[SVActivityViewController alloc] initWithNibName:@"SVActivityViewController" bundle:[NSBundle mainBundle]];
		activity.controller = self;
		activity.delegate = self;
		activity.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
		activity.modalPresentationStyle = UIModalPresentationCurrentContext;
	}
    activity.activityDescription = NSLocalizedString(@"This is the text that goes with the sharing!", nil);
	activity.activityUrl = [NSURL URLWithString:@"http://shotvibe.com"];
	activity.activityImage = image;
	
	[self.view addSubview:activity.view];
	
	activity.view.alpha = 0;
	__block CGRect rect = activity.activityView.frame;
	rect.origin.y = self.view.frame.size.height;
	activity.activityView.frame = rect;
	
	[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		rect.origin.y = self.view.frame.size.height - rect.size.height;
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
		[self.navigationController setToolbarHidden:NO animated:YES];
		self.detailLabel.hidden = NO;
	}
}
-(void)activityDidStartSharing {
	[activity cancelHandler:nil];
}

@end
