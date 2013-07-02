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

@interface CaptureSelectImagesViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
{
}

@property (nonatomic, strong) IBOutlet UIView *gridviewContainer;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *doneButton;
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


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    selectedPhotos = [[NSMutableArray alloc] init];
    
    [self.gridView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"SVSelectionCell"];
    
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
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SVSelectionCell" forIndexPath:indexPath];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:cell.bounds];
    
    if (self.selectedGroup) {
        
        ALAsset *asset = [self.takenPhotos objectAtIndex:indexPath.row];
        imageView.image = [UIImage imageWithCGImage:asset.thumbnail];
        
    }
    else
    {
        UIImage *image = [UIImage imageWithContentsOfFile:[self.takenPhotos objectAtIndex:indexPath.row]];
        
        float oldWidth = image.size.width;
        float scaleFactor = imageView.frame.size.width / oldWidth;
        
        float newHeight = image.size.height * scaleFactor;
        float newWidth = oldWidth * scaleFactor;
        
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
        [image drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        imageView.image = newImage;
        
    }
    
    [cell addSubview:imageView];
    
    
    // Configure the selection icon
    
    UIImageView *selectedIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"imageUnselected.png"]];
    selectedIcon.userInteractionEnabled = NO;
    selectedIcon.tag = 9001;
    
    if ([selectedPhotos containsObject:[self.takenPhotos objectAtIndex:indexPath.row]]) {
        
        selectedIcon.image = [UIImage imageNamed:@"imageSelected.png"];
    }
    
    selectedIcon.frame = CGRectMake(imageView.frame.size.width - selectedIcon.bounds.size.width - 5, imageView.frame.size.height - selectedIcon.bounds.size.height - 5, selectedIcon.frame.size.width, selectedIcon.frame.size.height);
    
    [cell addSubview:selectedIcon];
    
    return cell;
}


#pragma mark - UICollectionViewDelegate Methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    UICollectionViewCell *selectedCell = [self.gridView cellForItemAtIndexPath:indexPath];
    
    for (UIImageView *imageView in selectedCell.subviews) {
        if (imageView.tag == 9001) {
            
            if (![selectedPhotos containsObject:[self.takenPhotos objectAtIndex:indexPath.row]]) {
                [selectedPhotos addObject:[self.takenPhotos objectAtIndex:indexPath.row]];
                imageView.image = [UIImage imageNamed:@"imageSelected.png"];
            }
            else
            {
                [selectedPhotos removeObject:[self.takenPhotos objectAtIndex:indexPath.row]];
                imageView.image = [UIImage imageNamed:@"imageUnselected.png"];
            }
        }
    }
}



#pragma mark - Private Methods

- (void)doneButtonPressed
{
    [self packageSelectedPhotos:^(NSArray *selectedPhotoPaths, NSError *error)
     {
         self.doneButton.enabled = YES;
         
         for (NSData *photoData in selectedPhotoPaths) {
             
             NSString *tempPhotoId = [[NSUUID UUID] UUIDString];
             
             [SVBusinessDelegate saveUploadedPhotoImageData:photoData forPhotoId:tempPhotoId inAlbum:self.selectedAlbum];
         }
         
         [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
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
