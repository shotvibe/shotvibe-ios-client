//
//  SVAlbumGridViewController.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/13/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "Album.h"
#import "Photo.h"
#import "SVAlbumGridViewController.h"
#import "SVEntityStore.h"
#import "GMGridView.h"
#import "SVDefines.h"
#import "NINetworkImageView.h"
#import "SVAlbumDetailScrollViewController.h"
#import "SVSidebarMenuViewController.h"
#import "MFSideMenu.h"
#import "UINavigationController+MFSideMenu.h"
#import "SVSidebarManagementViewController.h"
#import "SVBusinessDelegate.h"


@interface SVAlbumGridViewController () <NSFetchedResultsControllerDelegate, GMGridViewDataSource, GMGridViewActionDelegate, NINetworkImageViewDelegate>
{
    __gm_weak GMGridView *_gmGridView;
    UIPanGestureRecognizer *panGestureRecognizer;
    BOOL isPushingDetail;
}

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) IBOutlet UIView *gridviewContainer;
@property (nonatomic, strong) MFSideMenu *sauronTheSideMenu;

- (void)loadData;
- (void)toggleMenu;
- (void)toggleManagement;
- (void)configureGridview;
- (void)fetchPhotos;
- (void)configureMenuForOrientation:(UIInterfaceOrientation)orientation;
- (void)backButtonPressed;
- (IBAction)homePressed:(id)sender;


@end

@implementation SVAlbumGridViewController
{
    BOOL isMenuShowing;
}


- (IBAction)homePressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}


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
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"userIcon.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(toggleMenu)];
    self.navigationItem.rightBarButtonItem = menuButton;
    
    // Setup menu button
    UIBarButtonItem *managementButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menuIcon.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(toggleManagement)];
    self.navigationItem.leftBarButtonItem = managementButton;
    
    // Setup back button for annoying long album names
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(backButtonPressed)];
    
    self.navigationItem.backBarButtonItem = backButton;
    
    
    // Listen for our RestKit loads to finish
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchPhotos) name:@"SVPhotosLoaded" object:nil];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self loadData];
    
    [self fetchPhotos];
    
    // Initialize the sidebar menu
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    self.sidebarMenuController = [storyboard instantiateViewControllerWithIdentifier:@"SidebarMenuView"];
    self.sidebarMenuController.parentController = self;
    
    self.sidebarManagementController = [storyboard instantiateViewControllerWithIdentifier:@"SidebarManagementView"];
    self.sidebarManagementController.parentController = self;
    
    
    self.sauronTheSideMenu = [MFSideMenu menuWithNavigationController:self.navigationController leftSideMenuController:self.sidebarManagementController rightSideMenuController:self.sidebarMenuController panMode:MFSideMenuPanModeNavigationController];
    
    [self.navigationController setSideMenu:self.sauronTheSideMenu];
    [self configureMenuForOrientation:self.interfaceOrientation];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Kill any drag processes here and now
    [self.navigationController.sideMenu setMenuState:MFSideMenuStateClosed];
    
    // We have to make sure that all the gesture recognizers are removed from the nav controller before we're done with the grid controller.
    while (self.navigationController.view.gestureRecognizers.count) {
        [self.navigationController.view removeGestureRecognizer:[self.navigationController.view.gestureRecognizers objectAtIndex:0]];
    }
    
    // Then kill the sidebar menu. (Only if we're not going to the detail photo view)
    if (!isPushingDetail) {
        UIView *windowRootView = self.navigationController.view.window.rootViewController.view;
        UIView *containerView = windowRootView.superview;
        
        for (UIView *aView in containerView.subviews) {
            if (aView != self.navigationController.view.window.rootViewController.view)
                [aView removeFromSuperview];
        }
        self.sauronTheSideMenu = nil;
    }
    else
    {
        isPushingDetail = NO;
    }
    
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        
        if (IS_IPHONE_5) {
            
            [_gmGridView setItemSpacing:12];
            [_gmGridView setMinEdgeInsets:UIEdgeInsetsMake(12, 12, 12, 12)];
        }
        else
        {
            [_gmGridView setItemSpacing:17];
            [_gmGridView setMinEdgeInsets:UIEdgeInsetsMake(16, 16, 16, 16)];
        }
        
    }
    else
    {
        [_gmGridView setItemSpacing:6];
        [_gmGridView setMinEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
    }
    
    [self configureMenuForOrientation:self.interfaceOrientation];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
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
    return CGSizeMake(99, 98);
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
    
    UIImageView *cellBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"photoFrame.png"]];
    [cell.contentView addSubview:cellBackground];
    
    // Configure thumbnail
    Photo *currentPhoto = [[self.selectedAlbum.photos allObjects] objectAtIndex:index];
    
    
    NINetworkImageView *networkImageView = [[NINetworkImageView alloc] initWithFrame:CGRectMake(4, 3, 91, 91)];
    networkImageView.clipsToBounds = YES;
    networkImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    networkImageView.backgroundColor = [UIColor clearColor];
    networkImageView.contentMode = UIViewContentModeScaleAspectFill;
    networkImageView.sizeForDisplay = NO;
    networkImageView.interpolationQuality = kCGInterpolationHigh;
    networkImageView.initialImage = [UIImage imageNamed:@"placeholderImage.png"];
    networkImageView.delegate = self;
    networkImageView.tag = index;
    [cell.contentView addSubview:networkImageView];
    [networkImageView setPathToNetworkImage:currentPhoto.photoUrl];
    
    return cell;
}


#pragma mark - GMGridViewActionDelegate

- (void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position
{
    NSLog(@"Did tap at index %d", position);
    
    SVAlbumDetailScrollViewController *detailController = [[SVAlbumDetailScrollViewController alloc] init];
    detailController.selectedPhoto = [[self.selectedAlbum.photos allObjects] objectAtIndex:position];
    
    isPushingDetail = YES;
    [self.navigationController pushViewController:detailController animated:YES];
}


#pragma mark - NINetworkImageView Delegate Methods

- (void)networkImageView:(NINetworkImageView *)imageView didLoadImage:(UIImage *)image
{
    Photo *loadedPhoto = [[self.selectedAlbum.photos allObjects] objectAtIndex:imageView.tag];
        
    
    [SVBusinessDelegate saveImage:image forPhoto:loadedPhoto];
}


- (void)networkImageView:(NINetworkImageView *)imageView didFailWithError:(NSError *)error
{
    Photo *failedPhoto = [[self.selectedAlbum.photos allObjects] objectAtIndex:imageView.tag];
    
    UIImage *offlineImage = [SVBusinessDelegate loadImageFromAlbum:self.selectedAlbum withPath:failedPhoto.photoUrl];
    
    if (offlineImage) {
        [imageView setImage:offlineImage];
    }
}


#pragma mark - Private Methods

- (void)loadData
{
    [[SVEntityStore sharedStore] photosForAlbumWithID:self.selectedAlbum.albumId];
}


- (void)toggleMenu
{
    
    [self.navigationController.sideMenu toggleRightSideMenu];
}


- (void)toggleManagement
{
    [self.navigationController.sideMenu toggleLeftSideMenu];
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
    
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        
        if (IS_IPHONE_5) {
            
            [gmGridView setItemSpacing:12];
            [gmGridView setMinEdgeInsets:UIEdgeInsetsMake(12, 12, 12, 12)];
        }
        else
        {
            [gmGridView setItemSpacing:17];
            [gmGridView setMinEdgeInsets:UIEdgeInsetsMake(16, 16, 16, 16)];
        }
        
    }
    else
    {
        [gmGridView setItemSpacing:6];
        [gmGridView setMinEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
    }
    
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
    [SVBusinessDelegate cleanupOfflineStorageForAlbum:self.selectedAlbum];
    [self configureGridview];
}


- (void)configureMenuForOrientation:(UIInterfaceOrientation)orientation
{

    
    CGRect rightFrame = self.navigationController.sideMenu.rightSideMenuViewController.view.frame;
    rightFrame.size.height = 300;
    rightFrame.origin.x = 320 - kMFSideMenuSidebarWidth;
    rightFrame.size.width = kMFSideMenuSidebarWidth;
    rightFrame.origin.y = 20;
    
    CGRect leftFrame = self.navigationController.sideMenu.leftSideMenuViewController.view.frame;
    leftFrame.size.height = 300;
    leftFrame.origin.x = 0;
    leftFrame.size.width = kMFSideMenuSidebarWidth;
    leftFrame.origin.y = 20;
    
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            
            if (IS_IPHONE_5) {
                rightFrame.size.height = 548;
                leftFrame.size.height = 548;

            }
            else
            {
                rightFrame.size.height = 460;
                leftFrame.size.height = 460;

            }
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            if (IS_IPHONE_5) {
                rightFrame.size.height = 548;
                leftFrame.size.height = 548;
            }
            else
            {
                rightFrame.size.height = 460;
                leftFrame.size.height = 460;
            }
            break;
        case UIInterfaceOrientationLandscapeLeft:
            if (IS_IPHONE_5) {
                rightFrame.origin.x = 568 - kMFSideMenuSidebarWidth;
            }
            else
            {
                rightFrame.origin.x = 480 - kMFSideMenuSidebarWidth;
                
            }
            break;
        case UIInterfaceOrientationLandscapeRight:
            if (IS_IPHONE_5) {
                rightFrame.origin.x = 568 - kMFSideMenuSidebarWidth;
            }
            else
            {
                rightFrame.origin.x = 480 - kMFSideMenuSidebarWidth;
                
            }
            break;
    }
    
    self.navigationController.sideMenu.rightSideMenuViewController.view.frame = rightFrame;
    self.navigationController.sideMenu.leftSideMenuViewController.view.frame = leftFrame;

}


- (void)backButtonPressed
{
    [self.navigationController popViewControllerAnimated:YES];
}



@end
