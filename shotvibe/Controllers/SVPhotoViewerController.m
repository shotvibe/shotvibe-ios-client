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
	
	
    // Setup menu button
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"userIcon.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(toggleMenu)];
    self.navigationItem.rightBarButtonItem = menuButton;
	
	UIBarItem* flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
                                                  target: nil
                                                  action: nil];
    
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
    self.navigationController.toolbarHidden = NO;
    
	[self showViewerOfType:PhotoViewerTypeTableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.toolbar.translucent = YES;
	//[self.navigationController.toolbar setHidden:NO];
	self.title = self.albumContents.name;
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.translucent = NO;
	[self.navigationController.toolbar setHidden:YES];
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
}
- (void)viewDidDisappear:(BOOL)animated {
	
	[super viewDidDisappear:animated];
	[self.detailLabel removeFromSuperview];
	self.detailLabel = nil;
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
	NSLog(@"This VC has has been pushed popped OR covered");
	
    if (!parent)
        NSLog(@"This happens ONLY when it's popped");
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	
	int w = self.view.frame.size.width;
	int h = self.view.frame.size.height;
	int i = 0;
	
	photosScrollView.contentSize = CGSizeMake((w+60)*self.albumContents.photos.count, h);
	photosScrollView.contentOffset = CGPointMake((w+60)*self.index, 0);
	
	for (AlbumPhoto *photo in self.albumContents.photos) {
		
		RCScrollImageView *cachedImage = [cache objectForKey:photo.serverPhoto.photoId];
		cachedImage.frame = CGRectMake((w+60)*i, 0, w, h);
		[cachedImage setMaxMinZoomScalesForCurrentBounds];
		cachedImage.hidden = NO;
		i++;
	}
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
	if (viewerType == PhotoViewerTypeTableView) {
		return;
	}
	
	__block int w = self.view.frame.size.height;
	__block int h = self.view.frame.size.width;
	__block int i = 0;
	
	// Hide all the images except the visible one
	for (AlbumPhoto *photo in photos) {
		RCScrollImageView *cachedImage = [cache objectForKey:photo.serverPhoto.photoId];
		if (cachedImage.i == i) {
			//visible_photo = photo;
		}
		else cachedImage.hidden = YES;
		i++;
	}
	i = 0;
	
//	RCScrollImageView *cachedImage = [cache objectForKey:visible_photo.photo_id];
//	CGRect oldFrame = cachedImage.frame;
//	oldFrame.size.width = w;
//	oldFrame.size.height = h;
//	NSLog(@"%i %@", j, cachedImage);
	
	[UIView animateWithDuration:duration animations:^{
		//cachedImage.frame = oldFrame;
		
		for (AlbumPhoto *photo in photos) {
			RCScrollImageView *cachedImage = [cache objectForKey:photo.serverPhoto.photoId];
			if (cachedImage.i == i) {
				if (w == 300) w = 320;
				if (w == 460) w = 480;
				if (h == 300) h = 320;
				if (h == 460) h = 480;
				CGRect oldFrame = cachedImage.frame;
				oldFrame.size.width = w;
				oldFrame.size.height = h;
				cachedImage.frame = oldFrame;
			}
			i++;
		}
	}];
}


#pragma mark Viewer

- (void)showViewerOfType:(PhotoViewerType)type {
	viewerType = type;
	
	switch (viewerType) {
		case PhotoViewerTypeTableView:
		{
			if (photosTableView == nil) {
				photosTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 44, self.view.frame.size.width, self.view.frame.size.height-44) style:UITableViewStylePlain];
				photosTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
				photosTableView.rowHeight = IMAGE_CELL_HEIGHT;
				photosTableView.delegate = self;
				photosTableView.dataSource = self;
				[self.view addSubview:photosTableView];
				[self.navigationController.toolbar setHidden:YES];
				[photosTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.index inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
			}
		}
		break;
			
		case PhotoViewerTypeScrollView:
		{
			if (photosScrollView == nil) {
				int w = self.view.frame.size.width;
				int h = self.view.frame.size.height;
				
				photosScrollView = [[RCScrollView alloc] initWithFrame:CGRectMake(0, 0, w+60, h)];
				photosScrollView.contentSize = CGSizeMake((w+60)*self.albumContents.photos.count, h);
				photosScrollView.scrollEnabled = YES;
				photosScrollView.showsHorizontalScrollIndicator = NO;
				photosScrollView.showsVerticalScrollIndicator = NO;
				photosScrollView.pagingEnabled = YES;// Whether should stop at each page when scrolling
				photosScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
				[photosScrollView setD:self];// set delegate
				[self.view addSubview:photosScrollView];
				
				photosScrollView.contentSize = CGSizeMake((w+60)*photos.count, h);
				photosScrollView.contentOffset = CGPointMake((w+60)*self.index, 0);
				
				[self loadPhoto:self.index andPreloadNext:YES];
				[self updateInfoOnScreen];
				[self.navigationController.toolbar setHidden:NO];
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
    
    if (cachedImage != nil) {
		cachedImage.frame = CGRectMake((w+60)*i, 0, w, h);
		cachedImage.contentSize = cachedImage.image.size;
    }
	else {
		// If the photo is not in cache try in the saved photos
		RCScrollImageView *rcphoto = [[RCScrollImageView alloc] initWithFrame:CGRectMake((w+60)*i, 0, w, h) delegate:self];
		rcphoto.i = i;
		rcphoto.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		
		if (photo.serverPhoto) {
			
			NSString *fullsizePhotoUrl = photo.serverPhoto.url;
			NSString *displaySuffix = @"_r_dvgax.jpg";
			NSString *finalUrl = [[fullsizePhotoUrl stringByDeletingPathExtension] stringByAppendingString:displaySuffix];
			NSLog(@"loadNetworkImage %@", finalUrl);
			[rcphoto loadNetworkImage:finalUrl];
		}
		else if (photo.uploadingPhoto) {
			UIImage *localImage = [UIImage imageWithData:[NSData dataWithContentsOfFile:[photo.uploadingPhoto getFilename]]];
			if (localImage != nil) {
				NSLog(@"found locally");
				[rcphoto setImage:localImage];
			}
		}
		
		cachedImage = rcphoto;
		[cache setObject:rcphoto forKey:photo.serverPhoto.photoId];
	}
	
	switch (viewerType) {
		case PhotoViewerTypeTableView:
		{
			cachedImage.frame = CGRectMake(0, 0, w, h);
		}break;
			
		case PhotoViewerTypeScrollView:
		{
			cachedImage.frame = CGRectMake((w+60)*i, 0, w, h);
			[photosScrollView addSubview:cachedImage];
		}break;
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
	}
	RCScrollImageView *image = [self loadPhoto:indexPath.row andPreloadNext:NO];
	cell.largeImageView = image;
	
	// Add description
	AlbumPhoto *photo = [photos objectAtIndex:self.index];
	NSString *updatedBy = NSLocalizedString(@"Updated by ", @"");
	NSString *dateFormated = [NSDateFormatter localizedStringFromDate:photo.serverPhoto.dateAdded dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterShortStyle];
	cell.detailLabel.text = [NSString stringWithFormat:@"%@%@ on %@", updatedBy, photo.serverPhoto.authorNickname, dateFormated];
	
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
	
}




#pragma mark ScrollView delegate functions

- (void)scrollViewDidEndDecelerating {
    //pageControlUsed = NO;
	CGFloat pageWidth = photosScrollView.frame.size.width;
	self.index = floor((photosScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
	[self updateInfoOnScreen];
	
	NSLog(@"scrollViewDidEndDecelerating with currentPhotoNr = %i", self.index);
	[self loadPhoto:self.index andPreloadNext:YES];
}


#pragma mark RCScrollView delegate

- (void)areaTouched {
	
	if (self.navigationController.toolbar.hidden) {
		
		[[UIApplication sharedApplication] setStatusBarHidden:NO];
		[self.navigationController setToolbarHidden:NO animated:YES];
		[self.navigationController setNavigationBarHidden:NO animated:YES];
	}
	else {
		[[UIApplication sharedApplication] setStatusBarHidden:YES];
		[self.navigationController setToolbarHidden:YES animated:YES];
		[self.navigationController setNavigationBarHidden:YES animated:YES];
	}
}

- (void)areaTouchedForExit {
	[self.navigationController popViewControllerAnimated:YES];
	if (self.navigationController.toolbar.hidden) [self areaTouched];
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
	NSLog(@"PhotoViewer did receive memory warning");
	
    // Dispose of any resources that can be recreated.
    
	NSArray *keys = [cache allKeys];
	
//	for (NSString *key in keys) {
//		if (![key isEqualToString:self.selectedPhoto.photo_id]) {
//			RCImageView *img = [cache objectForKey:key];
//			[img removeFromSuperview];
//			[cache removeObjectForKey:key];
//		}
//	}
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
		self.detailLabel.backgroundColor = [UIColor clearColor];
		self.detailLabel.textColor = [UIColor colorWithRed:0.92 green:0.92 blue:0.92 alpha:1.0];
		self.detailLabel.numberOfLines = 2;
		self.detailLabel.textAlignment = NSTextAlignmentCenter;
		self.detailLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
		self.detailLabel.shadowOffset = CGSizeMake(0, 1);
		self.detailLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
		[self.navigationController.toolbar addSubview:self.detailLabel];
	}
	
    AlbumPhoto *photo = [self.albumContents.photos objectAtIndex:self.index];
	
	NSString *updatedBy = NSLocalizedString(@"Updated by ", @"");
	
//		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//		formatter.dateFormat = @"MM.dd, HH:mm\"";
	NSString *dateFormated = [NSDateFormatter localizedStringFromDate:photo.serverPhoto.dateAdded dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterShortStyle];
	
	NSString *str = [NSString stringWithFormat:@"%@%@\n%@", updatedBy, photo.serverPhoto.authorNickname, dateFormated];
	NSLog(@"%@", str);
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
							RCImageView *cachedImage = [cache objectForKey:photo.serverPhoto.photoId];
							if (cachedImage) {
								cachedImage.i = i;
								cachedImage.frame = CGRectMake((w+60)*i, 0, w, h);
							}
							i++;
						}
	}
					 completion:^(BOOL finished){
						 NSLog(@"finished animation. ");
						 photosScrollView.contentSize = CGSizeMake((w+60)*[photos count], h);
	}];
}

- (void)toggleMenu
{
    //[self.navigationController.sideMenu toggleRightSideMenu];
}





#pragma mark Custom Activity

- (void)exportButtonPressed
{
    
	// Activity items
	NSMutableArray *activityItems = [NSMutableArray array];
	[activityItems addObject:NSLocalizedString(@"This is the text that goes with the sharing!", nil)];
	[activityItems addObject:[NSURL URLWithString:@"http://shotvibe.com"]];
	
	AlbumPhoto *photo = [photos objectAtIndex:self.index];
//	UIImage *currentImage = [[SVEntityStore sharedStore] getImageForPhoto:photo];
//	if (currentImage != nil) {
//		[activityItems addObject:currentImage];
//	}
    //SVLinkEvent *linkEvent = [self createLinkEvent];
    
	// Application activities
    SVLinkActivity *linkActivity = [[SVLinkActivity alloc] init];
    linkActivity.delegate = self;
    
    SVActivityViewController* activity = [[SVActivityViewController alloc] initWithActivityItems:[NSArray arrayWithArray:activityItems]
                                                                           applicationActivities:@[linkActivity]];
    //activity.excludedActivityTypes = @[UIActivityTypePostToWeibo, UIActivityTypePrint, UIActivityTypeSaveToCameraRoll, UIActivityTypeAssignToContact];
    
    [self presentViewController:activity animated:YES completion:NULL];
     
}

-(SVLinkEvent *)createLinkEvent
{
    SVLinkEvent *linkEvent = [[SVLinkEvent alloc] init];
    linkEvent.URL = [NSURL URLWithString:@"http://shotvibe.com"];
    return linkEvent;
}

#pragma mark - NHCalendarActivityDelegate

-(void)calendarActivityDidFinish:(SVLinkEvent *)event
{
    NSLog(@"Event: %@", event.URL);
}

-(void)calendarActivityDidFail:(SVLinkEvent *)event withError:(NSError *)error
{
    NSLog(@"Ops!");
}


@end
