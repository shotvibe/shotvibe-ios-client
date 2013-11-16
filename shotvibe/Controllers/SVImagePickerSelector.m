//
//  SVImagePickerSelector.m
//  shotvibe
//
//  Created by John Gabelmann on 5/1/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVImagePickerSelector.h"
#import "SVImageCropViewController.h"
#import "PhotoUploadRequest.h"
#import "SVAlbumGridViewController.h"
#import "SVDefines.h"

@implementation SVImagePickerSelector


- (void) setLibraryPhotos:(NSArray *)libraryPhotos {
	
	selectedPhotos = [[NSMutableArray alloc] init];
	_takenPhotos = libraryPhotos;
	geocoder = [[CLGeocoder alloc] init];
	
	// Group the photos by date
	sections = [[NSMutableDictionary alloc] init];
	sectionsKeys = [[NSMutableArray alloc] init];
	
	for (ALAsset *photo in _takenPhotos) {
		
		NSString *key = [NSDateFormatter localizedStringFromDate:[photo valueForProperty:ALAssetPropertyDate]
													   dateStyle:NSDateFormatterLongStyle
													   timeStyle:NSDateFormatterNoStyle];
		NSMutableArray *arr = [sections objectForKey:key];
		
		if (arr == nil) {
			arr = [NSMutableArray array];
			[sectionsKeys insertObject:key atIndex:0];
		}
		[arr addObject:photo];
		[sections setObject:arr forKey:key];
	}
	
	// Group the photos by location
//	__block int i = 0;
//	for (ALAsset *photo in _takenPhotos) {
//		
//		CLLocation *location = [photo valueForProperty:ALAssetPropertyLocation];
//		
//		[geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
//			MKPlacemark *placemark = [placemarks objectAtIndex:0];
//			RCLog(@"locality:%@, country:%@", placemark.locality, placemark.country);
//			
//			NSString *key = placemark.locality;
//			if (key == nil) {
//				key = @"Unknown Location";
//			}
//			
//			NSMutableArray *arr = [sections objectForKey:key];
//			
//			if (arr == nil) {
//				arr = [NSMutableArray array];
//				[sectionsKeys insertObject:key atIndex:0];
//			}
//			[arr addObject:photo];
//			[sections setObject:arr forKey:key];
//			
//			i ++;
//			if (_takenPhotos.count == i) {
//				RCLog(@"refresh grid");
//				[self.gridView reloadData];
//			}
//		}];
//	}
	
	//RCLog(@"%@", sectionsKeys);
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	if (selectedPhotos == nil) {
		selectedPhotos = [[NSMutableArray alloc] init];
	}
    
    [self.gridView registerClass:[SVSelectionGridCell class]
	  forCellWithReuseIdentifier:@"SVSelectionGridCell"];
	
	[self.gridView registerClass:[CameraRollSection class]
	  forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
			 withReuseIdentifier:@"CameraRollSection"];
    
    if (self.selectedGroup) {
        self.title = [self.selectedGroup valueForProperty:ALAssetsGroupPropertyName];
    }
    else {
        self.title = NSLocalizedString(@"Select To Upload", @"");
    }
    
	if (!self.oneImagePicker) {
		UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"")
																	   style:UIBarButtonItemStyleBordered
																	  target:self
																	  action:@selector(doneButtonPressed)];
		self.navigationItem.rightBarButtonItem = doneButton;
	}
    
	self.gridView.contentInset = UIEdgeInsetsMake(44, 0, 0, 0);
	[self.gridView addSubview:self.headerView];
	self.headerView.frame = CGRectMake(0, -44, 320, 44);
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //[self.navigationController setNavigationBarHidden:NO];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if (!IS_IOS7) [self.gridView setContentOffset:CGPointMake(0, -44) animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UICollectionViewDataSource Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	NSArray *arr = [sections objectForKey:sectionsKeys[section]];
    return arr.count;
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [sectionsKeys count];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
				  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SVSelectionGridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SVSelectionGridCell" forIndexPath:indexPath];
	cell.delegate = self;
	__block NSArray *arr = [sections objectForKey:sectionsKeys[indexPath.section]];
	
	dispatch_async(dispatch_get_global_queue(0,0),^{
		
		UIImage *image;
		ALAsset *asset = [arr objectAtIndex:indexPath.row];
		image = [UIImage imageWithCGImage:asset.thumbnail];
		
		dispatch_async(dispatch_get_main_queue(),^{
			cell.imageView.image = image;
		});
	});
	
	if (!self.oneImagePicker) {
		if ([selectedPhotos containsObject:[arr objectAtIndex:indexPath.row]]) {
			[cell.selectionImage setImage:[UIImage imageNamed:@"imageSelected.png"]];
		}
		else {
			[cell.selectionImage setImage:[UIImage imageNamed:@"imageUnselected.png"]];
		}
	}
	else {
		cell.selectionImage.hidden = YES;
	}
	
    return cell;
}

// Section headers

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
		   viewForSupplementaryElementOfKind:(NSString *)kind
								 atIndexPath:(NSIndexPath *)indexPath {
	
	if (kind == UICollectionElementKindSectionHeader)
	{
		CameraRollSection *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
																	   withReuseIdentifier:@"CameraRollSection"
																			  forIndexPath:indexPath];
		
		// Modify the header
		header.dateLabel.text = sectionsKeys[indexPath.section];
		header.section = indexPath.section;
		header.delegate = self;
		header.tag = indexPath.section+1000;
		[self checkSectionHeaderView:header];
		
		return header;
	}
	return nil;
}

- (void)checkSectionHeaderView:(CameraRollSection*)header {
	
	NSArray *arr = [sections objectForKey:sectionsKeys[header.section]];
	BOOL allPhotosAreSelected = YES;
	
	// Check how many assets are already selected
	for (ALAsset *asset in arr) {
		if (![selectedPhotos containsObject:asset]) {
			allPhotosAreSelected = NO;
			break;
		}
	}
	if (!self.oneImagePicker) {
		[header selectCheckmark:allPhotosAreSelected];
	}
}


#pragma mark - UICollectionViewDelegate Methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
	if (!self.oneImagePicker) {
		
		SVSelectionGridCell *cell = (SVSelectionGridCell*)[self.gridView cellForItemAtIndexPath:indexPath];
		[self cellDidCheck:cell];
	}
    else {
		
		NSArray *arr = [sections objectForKey:sectionsKeys[indexPath.section]];
		ALAsset *asset = [arr objectAtIndex:indexPath.row];
		NSDictionary *dict = [asset valueForProperty:ALAssetPropertyURLs];
		
		NSURL *url = [dict objectForKey:@"public.jpeg"];
		if (url == nil) {
			url = [dict objectForKey:@"public.png"];
		}
		
		ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset){
			ALAssetRepresentation *rep = [myasset defaultRepresentation];
			CGImageRef iref = [rep fullScreenImage];
			if (iref) {
				SVImageCropViewController *cropController = [[SVImageCropViewController alloc] initWithNibName:@"SVImageCropViewController"
																										bundle:[NSBundle mainBundle]];
				cropController.delegate = self.cropDelegate;
				cropController.image = [UIImage imageWithCGImage:iref];
				[self.navigationController pushViewController:cropController animated:YES];
			}
			else {
				RCLog(@"error creating the fullscreen version of the image");
			}
		};
		ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror){
			RCLog(@"Cant get image - %@", [myerror localizedDescription]);
		};
		
		ALAssetsLibrary *assetslibrary = [[ALAssetsLibrary alloc] init];
		[assetslibrary assetForURL:url resultBlock:resultblock failureBlock:failureblock];
	}
}


- (void)cellDidCheck:(SVSelectionGridCell*)cell {
	
	NSIndexPath *indexPath = [self.gridView indexPathForCell:cell];
	NSArray *arr = [sections objectForKey:sectionsKeys[indexPath.section]];
	
	if (![selectedPhotos containsObject:[arr objectAtIndex:indexPath.row]]) {
		[selectedPhotos addObject:[arr objectAtIndex:indexPath.row]];
		[cell.selectionImage setImage:[UIImage imageNamed:@"imageSelected.png"]];
	}
	else {
		[selectedPhotos removeObject:[arr objectAtIndex:indexPath.row]];
		[cell.selectionImage setImage:[UIImage imageNamed:@"imageUnselected.png"]];
	}
	
	self.title = [NSString stringWithFormat:@"%i Photo%@ Selected", [selectedPhotos count], [selectedPhotos count]==1?@"":@"s"];
	
	CameraRollSection *header = (CameraRollSection*)[self.gridView viewWithTag:indexPath.section+1000];
	[self checkSectionHeaderView:header];
	
	BOOL allSelected = selectedPhotos.count == _takenPhotos.count;
	[self.butSelectAll setTitle:allSelected?@"Unselect All":@"Select All" forState:UIControlStateNormal];
}

- (void)cellDidLongPress:(SVSelectionGridCell*)cell {
	
	NSIndexPath *indexPath = [self.gridView indexPathForCell:cell];
	NSArray *arr = [sections objectForKey:sectionsKeys[indexPath.section]];
	
	if (![selectedPhotos containsObject:[arr objectAtIndex:indexPath.row]]) {
		SVSelectionGridCell *cell = (SVSelectionGridCell*)[self.gridView cellForItemAtIndexPath:indexPath];
		[self cellDidCheck:cell];
	}
	
	ALAsset *asset = [arr objectAtIndex:indexPath.row];
	NSDictionary *dict = [asset valueForProperty:ALAssetPropertyURLs];
	
	NSURL *url = [dict objectForKey:@"public.jpeg"];
	if (url == nil) {
		url = [dict objectForKey:@"public.png"];
	}
	
	ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset){
		ALAssetRepresentation *rep = [myasset defaultRepresentation];
		CGImageRef iref = [rep fullScreenImage];
		if (iref) {
			UIImage *localImage = [UIImage imageWithCGImage:iref];
			PhotosQuickView *photo = [[PhotosQuickView alloc] initWithFrame:self.view.frame delegate:nil];
			photo.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
			photo.quickDelegate = self;
			photo.indexPath = indexPath;
			[photo setImage:localImage];
			photo.contentSize = localImage.size;
			[photo setMaxMinZoomScalesForCurrentBounds];
			photo.alpha = 0.2;
			photo.transform = CGAffineTransformMakeScale(0.8, 0.8);
			[self.view addSubview:photo];
			[self.view addSubview:photo.selectionButton];
			
			[UIView animateWithDuration:0.2 animations:^{
				photo.alpha = 1;
				photo.transform = CGAffineTransformMakeScale(1, 1);
				[self.navigationController.navigationBar setAlpha:0];
			} completion:^(BOOL finished) {
				
			}];
		}
		else {
			RCLog(@"error creating the fullscreen version of the image");
		}
	};
	ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror){
		RCLog(@"Cant get image - %@", [myerror localizedDescription]);
	};
	
	ALAssetsLibrary *assetslibrary = [[ALAssetsLibrary alloc] init];
	[assetslibrary assetForURL:url resultBlock:resultblock failureBlock:failureblock];
}

- (void)photoDidCheck:(NSIndexPath*)indexPath {
	
	SVSelectionGridCell *cell = (SVSelectionGridCell*)[self.gridView cellForItemAtIndexPath:indexPath];
	[self cellDidCheck:cell];
}

- (void)photoDidClose:(PhotosQuickView*)photo {
	
	[photo.selectionButton removeFromSuperview];
	[UIView animateWithDuration:0.2 animations:^{
		photo.alpha = 0;
		photo.transform = CGAffineTransformMakeScale(0.8, 0.8);
		[self.navigationController.navigationBar setAlpha:1];
	} completion:^(BOOL finished) {
		[photo removeFromSuperview];
	}];
}


- (void)sectionCheckmarkTouched:(CameraRollSection*)section {
	
	NSArray *arr = [sections objectForKey:sectionsKeys[section.section]];
	int i = 0;
	BOOL allPhotosAreSelected = YES;
	
	// Check how many assets are already selected
	for (ALAsset *asset in arr) {
		if (![selectedPhotos containsObject:asset]) {
			allPhotosAreSelected = NO;
			break;
		}
	}
	
	for (ALAsset *asset in arr) {
		
		SVSelectionGridCell *selectedCell = (SVSelectionGridCell *)[self.gridView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section.section]];
		
		if (!allPhotosAreSelected) {
			if (![selectedPhotos containsObject:asset]) {
				[selectedPhotos addObject:asset];
				[selectedCell.selectionImage setImage:[UIImage imageNamed:@"imageSelected.png"]];
			}
		}
		else {
			if ([selectedPhotos containsObject:asset]) {
				[selectedPhotos removeObject:asset];
				[selectedCell.selectionImage setImage:[UIImage imageNamed:@"imageUnselected.png"]];
			}
		}
		
		i++;
	}
	if (!self.oneImagePicker) {
		[section selectCheckmark:!allPhotosAreSelected];
		self.title = [NSString stringWithFormat:@"%i Photo%@ Selected", [selectedPhotos count], [selectedPhotos count]==1?@"":@"s"];
	}
}


- (void)selectAll:(id)sender {
	
	BOOL allSelected = selectedPhotos.count == _takenPhotos.count;
	[self.butSelectAll setTitle:!allSelected?@"Unselect All":@"Select All" forState:UIControlStateNormal];
	RCLogI(allSelected);
	int section = 0;
	for (NSString *key in sectionsKeys) {
		
		NSArray *arr = [sections objectForKey:key];
		int i = 0;
		
		for (ALAsset *asset in arr) {
			
			SVSelectionGridCell *selectedCell = (SVSelectionGridCell *)[self.gridView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section]];
			
			if (!allSelected) {
				if (![selectedPhotos containsObject:asset]) {
					[selectedPhotos addObject:asset];
					[selectedCell.selectionImage setImage:[UIImage imageNamed:@"imageSelected.png"]];
				}
			}
			else {
				if ([selectedPhotos containsObject:asset]) {
					[selectedPhotos removeObject:asset];
					[selectedCell.selectionImage setImage:[UIImage imageNamed:@"imageUnselected.png"]];
				}
			}
			
			i++;
		}
		section++;
	}
	
	//[section selectCheckmark:!allPhotosAreSelected];
	self.title = [NSString stringWithFormat:@"%i Photo%@ Selected", [selectedPhotos count], [selectedPhotos count]==1?@"":@"s"];
}


#pragma mark - Upload photos

- (void)doneButtonPressed {
	
	RCLog(@"====================== 1. Package selected photos");
	RCLogThread();
	
	// Send a notification the the main screen to move this album on top of the list
	NSDictionary *userInfo = @{@"albumId":[NSNumber numberWithLongLong:self.albumId]};
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATIONCENTER_ALBUM_CHANGED object:nil userInfo:userInfo];
	
	NSMutableArray *photoUploadRequests = [[NSMutableArray alloc] init];
	for (ALAsset *asset in selectedPhotos) {
		PhotoUploadRequest *photoUploadRequest = [[PhotoUploadRequest alloc] initWithAsset:asset];
		[photoUploadRequests addObject:photoUploadRequest];
	}
	[self.albumManager.photoUploadManager uploadPhotos:self.albumId photoUploadRequests:photoUploadRequests];
	
	if (self.nav != nil) {
		// Insert the AlbumGrid controller before the CameraPicker controller
		
		UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
		SVAlbumGridViewController *controller = (SVAlbumGridViewController*)[mainStoryboard instantiateViewControllerWithIdentifier:@"SVAlbumGridViewController"];
		controller.albumManager = self.albumManager;
		controller.albumId = self.albumId;
		controller.scrollToTop = YES;
		
		// Should be 2 controllers, SVAlbumListViewController and SVCameraPickerController.
		NSMutableArray *controllers = [NSMutableArray arrayWithArray:self.nav.viewControllers];
		[controllers addObject:controller];
		RCLogO(controllers);
		
		[self.nav setViewControllers:controllers animated:NO];
	}
	
	// Dismiss the controller
	[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
		
		if ([self.delegate respondsToSelector:@selector(cameraWasDismissedWithAlbum:)]) {
			[self.delegate cameraWasDismissedWithAlbum:self.selectedAlbum];
		}
	}];
}

@end
