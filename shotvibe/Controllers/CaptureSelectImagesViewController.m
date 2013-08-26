//
//  CaptureSelectImagesViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 5/1/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "CaptureSelectImagesViewController.h"

#import "PhotoUploadRequest.h"

@implementation CaptureSelectImagesViewController


- (void) setTakenPhotos:(NSArray *)takenPhotos {
	
	selectedPhotos = [[NSMutableArray alloc] initWithArray:takenPhotos];
	_takenPhotos = takenPhotos;
}

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
//			NSLog(@"locality:%@, country:%@", placemark.locality, placemark.country);
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
//				NSLog(@"refresh grid");
//				[self.gridView reloadData];
//			}
//		}];
//	}
	
	NSLog(@"%@", sectionsKeys);
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	if (selectedPhotos == nil) {
		selectedPhotos = [[NSMutableArray alloc] init];
	}
    
    [self.gridView registerClass:[SVSelectionGridCell class] forCellWithReuseIdentifier:@"SVSelectionGridCell"];
	[self.gridView registerClass:[CameraRollSection class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"CameraRollSection"];
    
    if (self.selectedGroup) {
        self.title = [self.selectedGroup valueForProperty:ALAssetsGroupPropertyName];
    }
    else {
        self.title = NSLocalizedString(@"Select To Upload", @"");
    }
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"")
																   style:UIBarButtonItemStyleBordered
																  target:self
																  action:@selector(doneButtonPressed)];
    self.navigationItem.rightBarButtonItem = doneButton;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
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


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SVSelectionGridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SVSelectionGridCell" forIndexPath:indexPath];
	__block NSArray *arr = [sections objectForKey:sectionsKeys[indexPath.section]];
	
	dispatch_async(dispatch_get_global_queue(0,0),^{
		
		UIImage *image;
		
		if (self.selectedGroup) {
			ALAsset *asset = [arr objectAtIndex:indexPath.row];
			image = [UIImage imageWithCGImage:asset.thumbnail];
		}
		else {
			// Images taken by camera
			UIImage *large_image = [UIImage imageWithContentsOfFile:[arr objectAtIndex:indexPath.row]];
			
			float oldWidth = large_image.size.width;
			float scaleFactor = cell.imageView.frame.size.width / oldWidth;
			
			float newHeight = large_image.size.height * scaleFactor;
			float newWidth = oldWidth * scaleFactor;
			
			UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
			[image drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
			image = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();
		}
		dispatch_async(dispatch_get_main_queue(),^{
			cell.imageView.image = image;
		});
	});
	
	if ([selectedPhotos containsObject:[arr objectAtIndex:indexPath.row]]) {
		cell.selectionIcon.image = [UIImage imageNamed:@"imageSelected.png"];
	}
	else {
		cell.selectionIcon.image = [UIImage imageNamed:@"imageUnselected.png"];
	}
	
    return cell;
}

// Section headers

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
		   viewForSupplementaryElementOfKind:(NSString *)kind
								 atIndexPath:(NSIndexPath *)indexPath {
	
	if (kind == UICollectionElementKindSectionHeader)
	{
		CameraRollSection *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"CameraRollSection" forIndexPath:indexPath];
		
		// Modify the header
		header.dateLabel.text = sectionsKeys[indexPath.section];
		header.section = indexPath.section;
		header.delegate = self;
		
		NSArray *arr = [sections objectForKey:sectionsKeys[header.section]];
		BOOL allPhotosAreSelected = YES;
		
		// Check how many assets are already selected
		for (ALAsset *asset in arr) {
			if (![selectedPhotos containsObject:asset]) {
				allPhotosAreSelected = NO;
				break;
			}
		}
		[header selectCheckmark:allPhotosAreSelected];
		
		return header;
	}
	return nil;
}


#pragma mark - UICollectionViewDelegate Methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    SVSelectionGridCell *selectedCell = (SVSelectionGridCell *)[self.gridView cellForItemAtIndexPath:indexPath];
	NSArray *arr = [sections objectForKey:sectionsKeys[indexPath.section]];
    
    if (![selectedPhotos containsObject:[arr objectAtIndex:indexPath.row]]) {
        [selectedPhotos addObject:[arr objectAtIndex:indexPath.row]];
        selectedCell.selectionIcon.image = [UIImage imageNamed:@"imageSelected.png"];
    }
    else {
        [selectedPhotos removeObject:[arr objectAtIndex:indexPath.row]];
        selectedCell.selectionIcon.image = [UIImage imageNamed:@"imageUnselected.png"];
    }
	
	self.title = [NSString stringWithFormat:@"%i Photo%@ Selected", [selectedPhotos count], [selectedPhotos count]==1?@"":@"s"];
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
				selectedCell.selectionIcon.image = [UIImage imageNamed:@"imageSelected.png"];
			}
		}
		else {
			if ([selectedPhotos containsObject:asset]) {
				[selectedPhotos removeObject:asset];
				selectedCell.selectionIcon.image = [UIImage imageNamed:@"imageUnselected.png"];
			}
		}
		
		i++;
	}
	
	[section selectCheckmark:!allPhotosAreSelected];
	self.title = [NSString stringWithFormat:@"%i Photo%@ Selected", [selectedPhotos count], [selectedPhotos count]==1?@"":@"s"];
}


#pragma mark - Package photos

- (void)doneButtonPressed {
	
	NSLog(@"====================== 1. Package selected photos %@", [NSThread isMainThread] ? @"isMainThread":@"isNotMainThread");
	
	//dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		
    if (self.selectedGroup) {
        NSMutableArray *photoUploadRequests = [[NSMutableArray alloc] init];
        for (ALAsset *asset in selectedPhotos) {
            PhotoUploadRequest *photoUploadRequest = [[PhotoUploadRequest alloc] initWithAsset:asset];
            [photoUploadRequests addObject:photoUploadRequest];
        }
        [self.albumManager.photoUploadManager uploadPhotos:self.albumId photoUploadRequests:photoUploadRequests];
    }
    else {
        for (NSString *selectedPhotoPath in selectedPhotos) {
            NSData *photoData = [NSData dataWithContentsOfFile:selectedPhotoPath];
            if (photoData) {
				[SVBusinessDelegate saveUploadedPhotoImageData:photoData
													forPhotoId:[[NSUUID UUID] UUIDString]
												   withAlbumId:self.selectedAlbum.albumId];
            }
        }
    }
//	});
	
	[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
		
		if ([self.delegate respondsToSelector:@selector(cameraWasDismissedWithAlbum:)]) {
			[self.delegate cameraWasDismissedWithAlbum:self.selectedAlbum];
		}
	}];
}

@end
