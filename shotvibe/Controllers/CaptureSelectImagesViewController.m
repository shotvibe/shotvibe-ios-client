//
//  CaptureSelectImagesViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 5/1/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "CaptureSelectImagesViewController.h"
#import "SVDefines.h"
#import "GMGridView.h"
#import "Album.h"
#import "SVEntityStore.h"

@interface CaptureSelectImagesViewController () <GMGridViewDataSource, GMGridViewActionDelegate>
{
    GMGridView *_gmGridView;
}

@property (nonatomic, strong) IBOutlet UIView *gridviewContainer;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *doneButton;


- (void)doneButtonPressed;
- (void)configureGridview;
- (NSArray *)packageSelectedPhotos;

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
    
    self.title = NSLocalizedString(@"Select To Upload", @"");
    
    self.doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(doneButtonPressed)];
    self.navigationItem.rightBarButtonItem = self.doneButton;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];

    [self configureGridview];

}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - GMGridViewDataSource

- (NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView
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
    
    GMGridViewCell *cell = [gridView dequeueReusableCell];
    
    if (!cell)
    {
        cell = [[GMGridViewCell alloc] init];
    }
    
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    view.backgroundColor = [UIColor clearColor];
    view.layer.masksToBounds = NO;
    
    cell.contentView = view;
        
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:view.frame];
    

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
}


#pragma mark - Private Methods

- (void)doneButtonPressed
{
    // TODO: Handle submitting the photos
    
    NSArray *selectedPhotoData = [self packageSelectedPhotos];
    
    self.doneButton.enabled = NO;
    
    [[SVEntityStore sharedStore] addPhotos:selectedPhotoData ToAlbumWithID:self.selectedAlbum.albumId WithCompletion:^(BOOL success, NSError *error) {
        if (!error) {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
        }
        else
        {
            UIAlertView *uploadErrorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Network Error", @"") message:NSLocalizedString(@"Something went wrong uploading your photos. Please try again.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles: nil];
            
            [uploadErrorAlert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
            
            self.doneButton.enabled = YES;
        }
    }];
}


- (void)configureGridview
{
    if (_gmGridView) {
        [_gmGridView removeFromSuperview];
        _gmGridView.actionDelegate = nil;
        _gmGridView.dataSource = nil;
        _gmGridView = nil;
    }
    
    GMGridView *gmGridView = [[GMGridView alloc] initWithFrame:self.gridviewContainer.bounds];
    gmGridView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    gmGridView.backgroundColor = [UIColor clearColor];
    gmGridView.centerGrid = NO;
    
    [gmGridView setItemSpacing:7];
    [gmGridView setMinEdgeInsets:UIEdgeInsetsMake(7, 7, 7, 7)];
    
    [self.gridviewContainer addSubview:gmGridView];
    _gmGridView = gmGridView;
    
    _gmGridView.actionDelegate = self;
    _gmGridView.dataSource = self;

    [_gmGridView reloadData];
}


- (NSArray *)packageSelectedPhotos
{
    NSMutableArray *selectedPhotoPaths = [[NSMutableArray alloc] init];
    
    for (NSString *selectedPhotoPath in selectedPhotos) {
        NSData *photoData = [NSData dataWithContentsOfFile:selectedPhotoPath];
        
        if (photoData) {
            [selectedPhotoPaths addObject:photoData];
        }
    }
    
    return selectedPhotoPaths;
}

@end