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
    //GMGridView *_gmGridView;
}

@property (nonatomic, strong) IBOutlet UIView *gridviewContainer;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *doneButton;
@property (nonatomic, strong) IBOutlet UICollectionView *gridView;

- (void)doneButtonPressed;
- (void)configureGridview;
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
    
    [self configureGridview];
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

#pragma mark - GMGridViewDataSource

/*- (NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView
{
    return [self.takenPhotos count];
}


- (CGSize)GMGridView:(GMGridView *)gridView sizeForItemsInInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return CGSizeMake(71, 71);
}


- (GMGridViewCell *)GMGridView:(GMGridView *)gridView cellForItemAtIndex:(NSInteger)index
{
    //NSLog(@"Creating view indx %d", index);
    
    CGSize size = [self GMGridView:gridView sizeForItemsInInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    
    GMGridViewCell *cell = [gridView dequeueReusableCellWithIdentifier:@"GridCell"]; //[gridView dequeueReusableCell];
    
    if (!cell)
    {
        cell = [[GMGridViewCell alloc] init];
        cell.reuseIdentifier = @"GridCell";
    }
    
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    view.backgroundColor = [UIColor clearColor];
    view.layer.masksToBounds = NO;
    
    cell.contentView = view;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:view.bounds];
    
    if (self.selectedGroup) {
        
        ALAsset *asset = [self.takenPhotos objectAtIndex:index];
        imageView.image = [UIImage imageWithCGImage:asset.thumbnail];
        
    }
    else
    {
        UIImage *image = [UIImage imageWithContentsOfFile:[self.takenPhotos objectAtIndex:index]];
        
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
    
    [cell.contentView addSubview:imageView];
    
    
    // Configure the selection icon
    
    UIImageView *selectedIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"imageUnselected.png"]];
    selectedIcon.userInteractionEnabled = NO;
    selectedIcon.tag = 9001;
    
    if ([selectedPhotos containsObject:[self.takenPhotos objectAtIndex:index]]) {
        
        selectedIcon.image = [UIImage imageNamed:@"imageSelected.png"];
    }
    
    selectedIcon.frame = CGRectMake(imageView.frame.size.width - selectedIcon.bounds.size.width - 5, imageView.frame.size.height - selectedIcon.bounds.size.height - 5, selectedIcon.frame.size.width, selectedIcon.frame.size.height);
    
    [cell.contentView addSubview:selectedIcon];
    
    return cell;
}


#pragma mark - GMGridViewActionDelegate

- (void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position
{
    GMGridViewCell *selectedCell = [gridView cellForItemAtIndex:position];
    
    for (UIImageView *imageView in selectedCell.contentView.subviews) {
        if (imageView.tag == 9001) {
            
            if (![selectedPhotos containsObject:[self.takenPhotos objectAtIndex:position]]) {
                [selectedPhotos addObject:[self.takenPhotos objectAtIndex:position]];
                imageView.image = [UIImage imageNamed:@"imageSelected.png"];
            }
            else
            {
                [selectedPhotos removeObject:[self.takenPhotos objectAtIndex:position]];
                imageView.image = [UIImage imageNamed:@"imageUnselected.png"];
            }
        }
    }
}*/


#pragma mark - Private Methods

- (void)doneButtonPressed
{
    [self packageSelectedPhotos:^(NSArray *selectedPhotoPaths, NSError *error)
     {
         self.doneButton.enabled = YES;
         
         for (NSData *photoData in selectedPhotoPaths) {
             
             NSString *tempPhotoId = nil;
             
             if (IS_IOS6_OR_GREATER) {
                 tempPhotoId = [[NSUUID UUID] UUIDString];
             }
             else
             {
                 CFUUIDRef theUUID = CFUUIDCreate(NULL);
                 CFStringRef string = CFUUIDCreateString(NULL, theUUID);
                 CFRelease(theUUID);
                 
                 tempPhotoId = [NSString stringWithFormat:@"%@",(__bridge NSString *)string];
                 CFRelease(string);
            }
             
             [SVBusinessDelegate saveUploadedPhotoImageData:photoData forPhotoId:tempPhotoId inAlbum:self.selectedAlbum];
         }
         
         [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
     }];
}


- (void)configureGridview
{
    /*if (_gmGridView) {
        [_gmGridView removeFromSuperview];
        _gmGridView.actionDelegate = nil;
        _gmGridView.dataSource = nil;
        _gmGridView = nil;
    }
    
    GMGridView *gmGridView = [[GMGridView alloc] initWithFrame:self.view.bounds];
    gmGridView.autoresizingMask = UIViewAutoresizingFlexibleDimensions | UIViewAutoresizingFlexibleMargins;
    gmGridView.backgroundColor = [UIColor clearColor];
    gmGridView.centerGrid = NO;
    
    [gmGridView setItemSpacing:7];
    [gmGridView setMinEdgeInsets:UIEdgeInsetsMake(7, 7, 7, 7)];
    
    _gmGridView = gmGridView;
    
    _gmGridView.dataSource = self;
    _gmGridView.actionDelegate = self;
    
    [self.view addSubview:_gmGridView];
    
    
    [_gmGridView reloadData];
    
    _gmGridView.dataSource = self;*/
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
