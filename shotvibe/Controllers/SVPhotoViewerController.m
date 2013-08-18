//
//  SVAlbumDetailScrollViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 2/14/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVPhotoViewerController.h"
#import "SVDefines.h"
#import "AlbumPhoto.h"
#import "Album.h"
#import "UINavigationController+MFSideMenu.h"
#import "MFSideMenu.h"
#import "OldMember.h"
#import "SVBusinessDelegate.h"

@interface SVPhotoViewerController ()

@property (nonatomic, strong) UILabel *detailLabel;

- (void)deleteButtonPressed;
- (void)exportButtonPressed;
- (void)toggleMenu;
- (void)updateInfoOnScreen;
@end

@implementation SVPhotoViewerController


//- (void) loadView {
//	
//}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
	self.cache = [[NSMutableDictionary alloc] init];
	
	int w = self.view.frame.size.width;
	int h = self.view.frame.size.height;
	
    NSSortDescriptor *datecreatedDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date_created" ascending:YES];
    //NSSortDescriptor *idDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"photo_id" ascending:YES];
	//self.sortedPhotos = [NSMutableArray arrayWithArray: [[self.selectedPhoto.album.albumPhotos allObjects] sortedArrayUsingDescriptors:@[descriptor]]];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"album.albumId == %@ AND objectSyncStatus != %i", self.selectedPhoto.album.albumId, SVObjectSyncDeleteNeeded];
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"AlbumPhoto"];
	fetchRequest.sortDescriptors = @[datecreatedDescriptor];
	fetchRequest.predicate = predicate;
	
	NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																							   managedObjectContext:[NSManagedObjectContext defaultContext]
																								 sectionNameKeyPath:nil
																										  cacheName:nil];
	[fetchedResultsController performFetch:nil];
	self.sortedPhotos = [NSMutableArray arrayWithArray: [fetchedResultsController fetchedObjects]];
	
	
	photosScrollView = [[RCScrollView alloc] initWithFrame:CGRectMake(0, 0, w+60, h)];
	photosScrollView.contentSize = CGSizeMake((w+60)*[self.sortedPhotos count], h);
	photosScrollView.scrollEnabled = YES;
	photosScrollView.showsHorizontalScrollIndicator = NO;
	photosScrollView.showsVerticalScrollIndicator = NO;
	photosScrollView.pagingEnabled = YES;// Whether should stop at each page when scrolling
	photosScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[photosScrollView setD:self];// set delegate
	[self.view addSubview:photosScrollView];
	
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
    
	[self loadPhoto:self.index andPreloadNext:YES];
	
	photosScrollView.contentSize = CGSizeMake((w+60)*[self.sortedPhotos count], h);
	photosScrollView.contentOffset = CGPointMake((w+60)*self.index, 0);
	
	[self updateInfoOnScreen];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.toolbar.translucent = YES;
	[self.navigationController.toolbar setHidden:NO];
	self.title = self.selectedPhoto.album.name;
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

-(void)willMoveToParentViewController:(UIViewController *)parent {
	NSLog(@"This VC has has been pushed popped OR covered");
	
    if (!parent)
        NSLog(@"This happens ONLY when it's popped");
}



#pragma mark load/unload photos

- (void)loadPhoto:(int)i andPreloadNext:(BOOL)preload {
	
	// Preload only one photo in advance
	if (i > self.index + 1 || i >= self.sortedPhotos.count) {
		return;
	}
	if (i < self.index - 1 || i < 0) {
		return;
	}
	
	int w = self.view.frame.size.width;
	int h = self.view.frame.size.height;
	
	AlbumPhoto *photo = [self.sortedPhotos objectAtIndex:i];
	RCImageView *cachedImage = [self.cache objectForKey:photo.photo_id];
	cachedImage.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
	
	NSLog(@"loadPhoto %i %@", i, photo.photo_id);
	//NSLog(@"acche keys %@", [self.cache allKeys]);
    
    if (cachedImage != nil) {
		NSLog(@"already in cache");
		cachedImage.frame = CGRectMake((w+60)*i, 0, w, h);
    }
	else {
		// If the photo is not in cache try in the saved photos
		RCImageView *rcphoto = [[RCImageView alloc] initWithFrame:CGRectMake((w+60)*i, 0, w, h) delegate:self];
		rcphoto.i = i;
		UIImage *localImage = [[SVEntityStore sharedStore] getImageForPhoto:photo];
		
		if (localImage != nil) {
			NSLog(@"found locally");
			[rcphoto setImage:localImage];
		}
		else {
			NSLog(@"image needs to load from server");
			// In the last instance load the image from server
			[rcphoto loadNetworkImage:photo.photo_url];
		}
		[photosScrollView addSubview:rcphoto];
		[self.cache setObject:rcphoto forKey:photo.photo_id];
	}
	
	if (preload) {
		[self loadPhoto:i+1 andPreloadNext:YES];
		[self loadPhoto:i-1 andPreloadNext:NO];
	}
	
}
- (void)unloadPhoto:(int)i {
	
	if ([[self.sortedPhotos objectAtIndex:i] isKindOfClass:[RCImageView class]]) {
		[[self.sortedPhotos objectAtIndex:i] cancel];
		[[self.sortedPhotos objectAtIndex:i] removeFromSuperview];
		[self.sortedPhotos removeObjectAtIndex:i];
		[self.sortedPhotos insertObject:[NSNull null] atIndex:i];
	}
}
- (void)onPhotoComplete:(NSNumber*)nr {
	
	//int w = self.view.frame.size.width;
	//int h = self.view.frame.size.height;
	
	//[self.cache setObject:rcphoto.image forKey:photo.photo_id];
	
	//NSLog(@"onPhotoComplete currentPhotoNr %i == currentlyLoadingPhoto %i", currentPhotoNr, currentlyLoadingPhoto);
//	if (self.index == [nr intValue]) {
//		[photosScrollView setContentOffset:CGPointMake((w+60)*self.index, 0) animated:NO];
//		
//		// Animate the current photo with a zoomin effect
//		[[self.sortedPhotos objectAtIndex:self.index] setFrame:CGRectMake((w+60)*self.index, 0, w, h)];
//	}
}
- (void)onPhotoProgress:(NSNumber*)percentLoaded nr:(NSNumber*)nr{
	
//	[timelineView setPercent:[percentLoaded doubleValue]
//					   forNr:[nr intValue]
//				   direction:[nr intValue] < currentPhotoNr ? -1 : 1];
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





- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
	
    // Dispose of any resources that can be recreated.
	
	NSArray *keys = [self.cache allKeys];
	
	for (NSString *key in keys) {
		if (![key isEqualToString:self.selectedPhoto.photo_id]) {
			RCImageView *img = [self.cache objectForKey:key];
			[img removeFromSuperview];
			[self.cache removeObjectForKey:key];
		}
	}
}
- (void)dealloc {
	
	NSLog(@"dealloc SVPhotosViewwerController");
	
	for (NSString *key in [self.cache allKeys]) {
		RCImageView *img = [self.cache objectForKey:key];
		[img removeFromSuperview];
	}
	[self.cache removeAllObjects];
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
	
    AlbumPhoto *photo = [self.sortedPhotos objectAtIndex:self.index];
	
	if (photo.objectSyncStatus.intValue == SVObjectSyncUploadProgress) {
		
		self.detailLabel.text = @"Uploading in progress...";
	}
	else {
		NSString *updatedBy = NSLocalizedString(@"Updated by ", @"");
		
//		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//		formatter.dateFormat = @"MM.dd, HH:mm\"";
		NSString *dateFormated = [NSDateFormatter localizedStringFromDate:photo.date_created dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterShortStyle];
		
		NSString *str = [NSString stringWithFormat:@"%@%@\n%@", updatedBy, photo.author.nickname, dateFormated];
		NSLog(@"%@", str);
		self.detailLabel.text = str;
	}
	
	if (photo.hasViewed.intValue == NO) {
		//dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
			[[SVEntityStore sharedStore] setPhotoAsViewed:photo.photo_id];
		//});
	}
}


#pragma mark - Actions

- (void)deleteButtonPressed
{
	
	int w = self.view.frame.size.width;
	int h = self.view.frame.size.height;
	
    AlbumPhoto *photoToDelete = [self.sortedPhotos objectAtIndex:self.index];
	
	// Remove physical file and mark for deletion from server
	[[SVEntityStore sharedStore] deletePhoto:photoToDelete];
	
	// Remove from local array
	[self.sortedPhotos removeObject:photoToDelete];
	
	// Animate deleted photo to the trashbin
	[UIView animateWithDuration:0.3
					 animations:^{
						 
		RCImageView *cachedImage = [self.cache objectForKey:photoToDelete.photo_id];
		if (cachedImage) {
			CGRect rect = cachedImage.frame;
			cachedImage.frame = CGRectMake(rect.origin.x, rect.size.height, 30, 30);
		}
	}
					 completion:^(BOOL finished){
						 NSLog(@"finished trashbin animation. ");
						 RCImageView *cachedImage = [self.cache objectForKey:photoToDelete.photo_id];
						 if (cachedImage) {
							 [cachedImage removeFromSuperview];
							 [self.cache removeObjectForKey:photoToDelete.photo_id];
						 }
					 }];
	
	// Iterate over left photos and rearrange them in the scrollview
	[UIView animateWithDuration:0.6
					 animations:^{
		
		int i = 0;
		for (AlbumPhoto *photo in self.sortedPhotos) {
			RCImageView *cachedImage = [self.cache objectForKey:photo.photo_id];
			if (cachedImage) {
				cachedImage.i = i;
				cachedImage.frame = CGRectMake((w+60)*i, 0, w, h);
			}
			i++;
		}
	}
					 completion:^(BOOL finished){
						 NSLog(@"finished animation. ");
						 photosScrollView.contentSize = CGSizeMake((w+60)*[self.sortedPhotos count], h);
	}];
}


- (void)exportButtonPressed
{
    // Do other stuff
    
    //UIActionSheet *exportOptions = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
//destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Move Picture", @""), NSLocalizedString(@"Share to Facebook", @""),
	//NSLocalizedString(@"Share to Instagram", @""), NSLocalizedString(@"Set as Profile Picture", @""), NSLocalizedString(@"Email photo", @""),
	//NSLocalizedString(@"Get Link", @""), nil];
    
    //[exportOptions showFromToolbar:self.toolbar];
}


- (void)toggleMenu
{
    [self.navigationController.sideMenu toggleRightSideMenu];
}


@end
