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
    
	if (!self.oneImagePicker) {
		UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"")
																	   style:UIBarButtonItemStyleBordered
																	  target:self
																	  action:@selector(doneButtonPressed)];
		self.navigationItem.rightBarButtonItem = doneButton;
	}
    
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
	NSLog(@"cell %@", indexPath);
	
    SVSelectionGridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SVSelectionGridCell" forIndexPath:indexPath];
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
			cell.selectionIcon.image = [UIImage imageNamed:@"imageSelected.png"];
		}
		else {
			cell.selectionIcon.image = [UIImage imageNamed:@"imageUnselected.png"];
		}
	}
	else {
		cell.selectionIcon.hidden = YES;
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
		
		return header;
	}
	return nil;
}


#pragma mark - UICollectionViewDelegate Methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
	if (!self.oneImagePicker) {
		
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
    else {
		
		NSArray *arr = [sections objectForKey:sectionsKeys[indexPath.section]];
		ALAsset *asset = [arr objectAtIndex:indexPath.row];
		NSDictionary *dict = [asset valueForProperty:ALAssetPropertyURLs];
		NSLog(@"dict %@", dict);
		NSURL *url = [dict objectForKey:@"public.jpeg"];
		if (url == nil) {
			url = [dict objectForKey:@"public.png"];
		}
		
		ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset){
			ALAssetRepresentation *rep = [myasset defaultRepresentation];
			CGImageRef iref = [rep fullScreenImage];
			if (iref) {
				SVImageCropViewController *cropController = [[SVImageCropViewController alloc] initWithNibName:@"SVImageCropViewController" bundle:[NSBundle mainBundle]];
				cropController.delegate = self.cropDelegate;
				cropController.image = [UIImage imageWithCGImage:iref];
				[self.navigationController pushViewController:cropController animated:YES];
			}
			else {
				NSLog(@"error creating the fullscreen version of the image");
			}
		};
		ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror){
			NSLog(@"Cant get image - %@", [myerror localizedDescription]);
		};
		
		ALAssetsLibrary *assetslibrary = [[ALAssetsLibrary alloc] init];
		[assetslibrary assetForURL:url resultBlock:resultblock failureBlock:failureblock];
	}
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
	if (!self.oneImagePicker) {
		[section selectCheckmark:!allPhotosAreSelected];
		self.title = [NSString stringWithFormat:@"%i Photo%@ Selected", [selectedPhotos count], [selectedPhotos count]==1?@"":@"s"];
	}
}


#pragma mark - Package photos

- (void)doneButtonPressed {
	
	NSLog(@"====================== 1. Package selected photos %@", [NSThread isMainThread] ? @"isMainThread":@"isNotMainThread");
	
	//dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		
    //if (self.selectedGroup) {
	NSMutableArray *photoUploadRequests = [[NSMutableArray alloc] init];
	for (ALAsset *asset in selectedPhotos) {
		PhotoUploadRequest *photoUploadRequest = [[PhotoUploadRequest alloc] initWithAsset:asset];
		[photoUploadRequests addObject:photoUploadRequest];
	}
	[self.albumManager.photoUploadManager uploadPhotos:self.albumId photoUploadRequests:photoUploadRequests];
//    }
//    else {
//        for (NSString *selectedPhotoPath in selectedPhotos) {
//            NSData *photoData = [NSData dataWithContentsOfFile:selectedPhotoPath];
//            if (photoData) {
//				[SVBusinessDelegate saveUploadedPhotoImageData:photoData
//													forPhotoId:[[NSUUID UUID] UUIDString]
//												   withAlbumId:self.selectedAlbum.albumId];
//            }
//        }
//    }
//	});

    /*
	for (ALAsset *asset in selectedPhotos) {
		ALAssetRepresentation *rep = [asset defaultRepresentation];
		Byte *buffer = (Byte*)malloc(rep.size);
		NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:rep.size error:nil];
		NSData *photoData = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
		if (photoData) {
			[SVBusinessDelegate saveUploadedPhotoImageData:photoData
												forPhotoId:[[NSUUID UUID] UUIDString]
											   withAlbumId:self.selectedAlbum.albumId];
		}
	}
    */
	
	[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
		
		if ([self.delegate respondsToSelector:@selector(cameraWasDismissedWithAlbum:)]) {
			[self.delegate cameraWasDismissedWithAlbum:self.selectedAlbum];
		}
	}];
}

@end
