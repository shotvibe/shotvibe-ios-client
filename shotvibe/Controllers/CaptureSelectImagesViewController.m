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
#import "SVUploadQueueManager.h"
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


#pragma mark - Initializers

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
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
    
    [self.gridView registerClass:[SVSelectionGridCell class] forCellWithReuseIdentifier:@"SVSelectionCell"];
    
    if (self.selectedGroup) {
        self.title = [self.selectedGroup valueForProperty:ALAssetsGroupPropertyName];
    }
    else
    {
        self.title = NSLocalizedString(@"Select To Upload", @"");
    }
    
    self.doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(doneButtonPressed)];
    self.navigationItem.rightBarButtonItem = self.doneButton;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
    
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (void)didReceiveMemoryWarning
{
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
    SVSelectionGridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SVSelectionCell" forIndexPath:indexPath];
    
    cell.imageView = [[UIImageView alloc] initWithFrame:cell.bounds];
    
    if (self.selectedGroup) {
        
        ALAsset *asset = [self.takenPhotos objectAtIndex:indexPath.row];
        cell.imageView.image = [UIImage imageWithCGImage:asset.thumbnail];
        
    }
    else
    {
        UIImage *image = [UIImage imageWithContentsOfFile:[self.takenPhotos objectAtIndex:indexPath.row]];
        
        float oldWidth = image.size.width;
        float scaleFactor = cell.imageView.frame.size.width / oldWidth;
        
        float newHeight = image.size.height * scaleFactor;
        float newWidth = oldWidth * scaleFactor;
        
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
        [image drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        cell.imageView.image = newImage;
        
    }
    
    [cell.contentView addSubview:cell.imageView];
    
    
    // Configure the selection icon
    
    cell.selectionIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"imageUnselected.png"]];
    cell.selectionIcon.userInteractionEnabled = NO;
    cell.selectionIcon.tag = 9001;
    
    if ([selectedPhotos containsObject:[self.takenPhotos objectAtIndex:indexPath.row]]) {
        
        cell.selectionIcon.image = [UIImage imageNamed:@"imageSelected.png"];
    }
    
    cell.selectionIcon.frame = CGRectMake(cell.imageView.frame.size.width - cell.selectionIcon.bounds.size.width - 5, cell.imageView.frame.size.height - cell.selectionIcon.bounds.size.height - 5, cell.selectionIcon.frame.size.width, cell.selectionIcon.frame.size.height);
    
    [cell.contentView addSubview:cell.selectionIcon];
    
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

}



#pragma mark - Private Methods

- (void)doneButtonPressed
{
    [self packageSelectedPhotos:^(NSArray *selectedPhotoPaths, NSError *error){
		
         self.doneButton.enabled = YES;
         
         for (NSData *photoData in selectedPhotoPaths) {
             
             __block NSString *tempPhotoId = [[NSUUID UUID] UUIDString];
             __block NSData *blockData = photoData;
             __block NSString *albumId = self.selectedAlbum.albumId;
             
             if (!albumId) {
                 Album *selectedAlbum = (Album *)[[NSManagedObjectContext defaultContext] objectWithID:self.selectedAlbum.objectID];
                 albumId = selectedAlbum.albumId;
             }
             
             dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                 
                 [SVBusinessDelegate saveUploadedPhotoImageData:blockData forPhotoId:tempPhotoId withAlbumId:albumId];
                 
             });
         }
         
         [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
             Album *localAlbum = (Album *)[localContext objectWithID:self.selectedAlbum.objectID];
             [localAlbum setObjectSyncStatus:[NSNumber numberWithInteger:SVObjectSyncUploadNeeded]];
             
         }];
         //[[SVUploadQueueManager sharedManager] start];
         
         [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
             
			 if ([self.delegate respondsToSelector:@selector(cameraWasDismissedWithAlbum:)]) {
				 [self.delegate cameraWasDismissedWithAlbum:self.selectedAlbum];
			 }
         }];
     }];
}


- (void)packageSelectedPhotos:(void (^)(NSArray *selectedPhotoPaths, NSError *error))block
{
    NSMutableArray *selectedPhotoPaths = [[NSMutableArray alloc] init];
    NSUInteger assetCount = 0;
    
    if (self.selectedGroup) {
        
        for (ALAsset *asset in selectedPhotos) {
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            Byte *buffer = (Byte*)malloc(rep.size);
            NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:rep.size error:nil];
            NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
            
            if (data) {
                [selectedPhotoPaths addObject:data];
            }
            
            assetCount++;
            
            if (assetCount >= selectedPhotos.count) {
                block(selectedPhotoPaths, nil);
            }
            
        }
    }
    else
    {
        for (NSString *selectedPhotoPath in selectedPhotos) {
            NSData *photoData = [NSData dataWithContentsOfFile:selectedPhotoPath];
            
            if (photoData) {
                [selectedPhotoPaths addObject:photoData];
            }
            
            assetCount++;
            
            if (assetCount >= selectedPhotos.count) {
                block(selectedPhotoPaths, nil);
            }
        }
    }
    
}

@end
