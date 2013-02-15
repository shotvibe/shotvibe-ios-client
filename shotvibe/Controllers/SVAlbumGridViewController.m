//
//  SVAlbumGridViewController.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/13/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import "Album.h"
#import "Photo.h"
#import "SVAlbumGridViewController.h"
#import "SVEntityStore.h"
#import "GMGridView.h"
#import "SVDefines.h"
#import "NINetworkImageView.h"
#import "SVAlbumDetailScrollViewController.h"


@interface SVAlbumGridViewController () <NSFetchedResultsControllerDelegate, GMGridViewDataSource, GMGridViewActionDelegate>
{
    __gm_weak GMGridView *_gmGridView;
}

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) IBOutlet UIView *gridviewContainer;

- (void)loadData;
- (void)toggleMenu;
- (void)configureGridview;
- (void)fetchPhotos;

@end

@implementation SVAlbumGridViewController

#pragma mark - UIViewController Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.title = self.selectedAlbum.name;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"album.albumId = %d", [self.selectedAlbum.albumId stringValue]];
    fetchRequest.sortDescriptors = @[descriptor];
    fetchRequest.predicate = predicate;
    
    // Setup fetched results
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
    [self.fetchedResultsController setDelegate:self];
    
    
    // Setup menu button
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menuIcon.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(toggleMenu)];
    self.navigationItem.rightBarButtonItem = menuButton;
    
    // Listen for our RestKit loads to finish
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchPhotos) name:@"SVPhotosLoaded" object:nil];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self loadData];
    
    [self fetchPhotos];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - GMGridViewDataSource

- (NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView
{
    return [self.selectedAlbum.photos count];
}


- (CGSize)GMGridView:(GMGridView *)gridView sizeForItemsInInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return CGSizeMake(100, 102);
}


- (GMGridViewCell *)GMGridView:(GMGridView *)gridView cellForItemAtIndex:(NSInteger)index
{
    //NSLog(@"Creating view indx %d", index);
    
    CGSize size = [self GMGridView:gridView sizeForItemsInInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    
    GMGridViewCell *cell = [gridView dequeueReusableCell];
    
    if (!cell)
    {
        cell = [[GMGridViewCell alloc] init];
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        view.backgroundColor = [UIColor clearColor];
        view.layer.masksToBounds = NO;
        
        cell.contentView = view;
    }
    
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    UIImageView *cellBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gridCellBackground.png"]];
    [cell.contentView addSubview:cellBackground];
    
    // Configure thumbnail
    Photo *currentPhoto = [[self.selectedAlbum.photos allObjects] objectAtIndex:index];
    
    NSString *thumbnailUrl = [[currentPhoto.photoUrl stringByDeletingPathExtension] stringByAppendingString:kPhotoThumbExtension];
    
    NINetworkImageView *networkImageView = [[NINetworkImageView alloc] initWithFrame:CGRectMake(2, 2, 96, 96)];
    networkImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    networkImageView.backgroundColor = [UIColor clearColor];
    networkImageView.contentMode = UIViewContentModeScaleAspectFill;
    networkImageView.sizeForDisplay = YES;
    networkImageView.scaleOptions = NINetworkImageViewScaleToFitCropsExcess;
    networkImageView.interpolationQuality = kCGInterpolationHigh;
    [cell.contentView addSubview:networkImageView];
    [networkImageView setPathToNetworkImage:thumbnailUrl];
    
    return cell;
}


#pragma mark - GMGridViewActionDelegate

- (void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position
{
    NSLog(@"Did tap at index %d", position);
    
    SVAlbumDetailScrollViewController *detailController = [[SVAlbumDetailScrollViewController alloc] init];
    detailController.selectedPhoto = [[self.selectedAlbum.photos allObjects] objectAtIndex:position];
    
    [self.navigationController pushViewController:detailController animated:YES];
}


#pragma mark - Private Methods

- (void)loadData
{
    [[SVEntityStore sharedStore] photosForAlbumWithID:self.selectedAlbum.albumId];
}


- (void)toggleMenu
{
    // TODO: Add logic to trigger the menu show/hide, we have no psd for this?
    
    NSLog(@"Menu toggled");
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
    gmGridView.itemSpacing = 5;
    [self.gridviewContainer addSubview:gmGridView];
    _gmGridView = gmGridView;
    
    _gmGridView.actionDelegate = self;
    _gmGridView.dataSource = self;
}


- (void)fetchPhotos
{
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        RKLogError(@"There was an error loading the fetched result controller: %@", error);
    }
    RKLogInfo(@"This album contains %d photos", self.selectedAlbum.photos.count);
    [self configureGridview];
}
@end
