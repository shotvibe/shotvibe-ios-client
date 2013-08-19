//
//  CaptureSelectImagesViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 5/1/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "ALAssetsLibrary+helper.h"
#import "Album.h"
#import "AlbumPhoto.h"
#import "CaptureSelectImagesViewController.h"
#import "SVBusinessDelegate.h"
#import "SVDefines.h"
#import "SVEntityStore.h"
#import "SVUploadManager.h"
#import "SVSelectionGridCell.h"
#import "MagicalRecordShorthand.h"
#import "MagicalRecord.h"
#import "MagicalRecord+Actions.h"

@interface CaptureSelectImagesViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
{
}

@property (nonatomic, strong) IBOutlet UIView *gridviewContainer;
@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, strong) IBOutlet UICollectionView *gridView;

- (void)doneButtonPressed;
- (void)packageSelectedPhotos:(void (^)(NSArray *selectedPhotoPaths, NSError *error))block;
@end


@implementation CaptureSelectImagesViewController 
{
    NSMutableArray *selectedPhotos;
}


- (void) setTakenPhotos:(NSArray *)takenPhotos {
	
	selectedPhotos = [[NSMutableArray alloc] initWithArray:takenPhotos];
	_takenPhotos = takenPhotos;
}
- (void) setLibraryPhotos:(NSArray *)libraryPhotos {
	
	selectedPhotos = [[NSMutableArray alloc] init];
	_takenPhotos = libraryPhotos;
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	if (selectedPhotos == nil) {
		selectedPhotos = [[NSMutableArray alloc] init];
	}
    
    [self.gridView registerClass:[SVSelectionGridCell class] forCellWithReuseIdentifier:@"SVSelectionGridCell"];
    
    if (self.selectedGroup) {
        self.title = [self.selectedGroup valueForProperty:ALAssetsGroupPropertyName];
    }
    else {
        self.title = NSLocalizedString(@"Select To Upload", @"");
    }
    
    self.doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(doneButtonPressed)];
    self.navigationItem.rightBarButtonItem = self.doneButton;
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
    return self.takenPhotos.count;
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SVSelectionGridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SVSelectionGridCell" forIndexPath:indexPath];
	
	dispatch_async(dispatch_get_global_queue(0,0),^{
		
		UIImage *image;
		
		if (self.selectedGroup) {
			ALAsset *asset = [self.takenPhotos objectAtIndex:indexPath.row];
			image = [UIImage imageWithCGImage:asset.thumbnail];
		}
		else {
			UIImage *large_image = [UIImage imageWithContentsOfFile:[self.takenPhotos objectAtIndex:indexPath.row]];
			
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
	
	if ([selectedPhotos containsObject:[self.takenPhotos objectAtIndex:indexPath.row]]) {
		cell.selectionIcon.image = [UIImage imageNamed:@"imageSelected.png"];
	}
	else {
		cell.selectionIcon.image = [UIImage imageNamed:@"imageUnselected.png"];
	}
	
    return cell;
}


#pragma mark - UICollectionViewDelegate Methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    SVSelectionGridCell *selectedCell = (SVSelectionGridCell *)[self.gridView cellForItemAtIndexPath:indexPath];
    
    if (![selectedPhotos containsObject:[self.takenPhotos objectAtIndex:indexPath.row]]) {
        [selectedPhotos addObject:[self.takenPhotos objectAtIndex:indexPath.row]];
        selectedCell.selectionIcon.image = [UIImage imageNamed:@"imageSelected.png"];
    }
    else
    {
        [selectedPhotos removeObject:[self.takenPhotos objectAtIndex:indexPath.row]];
        selectedCell.selectionIcon.image = [UIImage imageNamed:@"imageUnselected.png"];
    }
	
	self.title = [NSString stringWithFormat:@"%i Photo%@ Selected", [selectedPhotos count], [selectedPhotos count]==1?@"":@"s"];
}



#pragma mark - Private Methods

- (void)doneButtonPressed
{
	NSLog(@"====================== 0. Done button pressed");
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		
		[self packageSelectedPhotos:^(NSArray *selectedPhotoPaths, NSError *error){
			NSLog(@"====================== 2. Package selected photos, after block call %@", [NSThread isMainThread] ? @"isMainThread":@"isNotMainThread");
			// Save the images inside the app with a random id
			for (NSData *photoData in selectedPhotoPaths) {
				
				[SVBusinessDelegate saveUploadedPhotoImageData:photoData
													forPhotoId:[[NSUUID UUID] UUIDString]
												   withAlbumId:self.selectedAlbum.albumId];
			}
		}];
	});
	
	[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
		
		if ([self.delegate respondsToSelector:@selector(cameraWasDismissedWithAlbum:)]) {
			[self.delegate cameraWasDismissedWithAlbum:self.selectedAlbum];
		}
	}];
}


- (void)packageSelectedPhotos:(void (^)(NSArray *selectedPhotoPaths, NSError *error))block
{
    NSMutableArray *selectedPhotoPaths = [[NSMutableArray alloc] init];
	NSLog(@"====================== 1. Package selected photos %@", [NSThread isMainThread] ? @"isMainThread":@"isNotMainThread");
	
    if (self.selectedGroup) {
        
        for (ALAsset *asset in selectedPhotos) {
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            Byte *buffer = (Byte*)malloc(rep.size);
            NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:rep.size error:nil];
            NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
            if (data) {
                [selectedPhotoPaths addObject:data];
            }
        }
    }
    else {
        for (NSString *selectedPhotoPath in selectedPhotos) {
            NSData *photoData = [NSData dataWithContentsOfFile:selectedPhotoPath];
            if (photoData) {
                [selectedPhotoPaths addObject:photoData];
            }
        }
    }
	block(selectedPhotoPaths, nil);
}

@end
