//
//  SVAlbumGridViewController.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/13/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AlbumPhoto.h"
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
#import "SVSettingsViewController.h"
#import "CaptureNavigationController.h"
#import "CaptureViewfinderController.h"
#import "SVImagePickerListViewController.h"


@interface SVAlbumGridViewController () <NSFetchedResultsControllerDelegate, GMGridViewDataSource, GMGridViewActionDelegate, NINetworkImageViewDelegate>
{
    GMGridView *_gmGridView;
    BOOL isPushingDetail;
}

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) IBOutlet UIView *gridviewContainer;
@property (nonatomic, strong) MFSideMenu *sauronTheSideMenu;

- (void)toggleMenu;
- (void)toggleManagement;
- (void)configureGridview;
- (void)configureMenuForOrientation:(UIInterfaceOrientation)orientation;
- (void)backButtonPressed;
- (void)albumRefreshed:(NSNotification *)notification;
- (IBAction)homePressed:(id)sender;
- (IBAction)takePicturePressed:(id)sender;

@end

@implementation SVAlbumGridViewController
{
    BOOL isMenuShowing;
}


- (IBAction)homePressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)takePicturePressed:(id)sender
{
    CaptureViewfinderController *cameraController = [[CaptureViewfinderController alloc] initWithNibName:@"CaptureViewfinder" bundle:[NSBundle mainBundle]];
    cameraController.albums = @[self.selectedAlbum];
    
    CaptureNavigationController *cameraNavController = [[CaptureNavigationController alloc] initWithRootViewController:cameraController];
    
    
    isPushingDetail = YES;
    [self presentViewController:cameraNavController animated:YES completion:nil];
}


#pragma mark - UIViewController Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.title = self.selectedAlbum.name;
     
    [self configureGridview];
    // Setup fetched results
    [self fetchedResultsController];
    
    // Setup menu button
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"userIcon.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(toggleMenu)];
    self.navigationItem.rightBarButtonItem = menuButton;
    
    // Setup menu button
    UIBarButtonItem *managementButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menuIcon.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(toggleManagement)];
    self.navigationItem.leftBarButtonItem = managementButton;
    
    // Setup back button for annoying long album names
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(backButtonPressed)];
    
    self.navigationItem.backBarButtonItem = backButton;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumRefreshed:) name:kSVSyncEngineSyncAlbumCompletedNotification object:nil];
    
    // We've returned from pushing detail
    if (isPushingDetail) {
        [self.sauronTheSideMenu setupGestureRecognizers];
        isPushingDetail = NO;
    }
    else
    {        
        // Initialize the sidebar menu
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
        self.sidebarMenuController = [storyboard instantiateViewControllerWithIdentifier:@"SidebarMenuView"];
        self.sidebarMenuController.parentController = self;
        self.sidebarMenuController.selectedAlbum = self.selectedAlbum;
        
        self.sidebarManagementController = [storyboard instantiateViewControllerWithIdentifier:@"SidebarManagementView"];
        self.sidebarManagementController.parentController = self;
        
        
        self.sauronTheSideMenu = [MFSideMenu menuWithNavigationController:self.navigationController leftSideMenuController:self.sidebarManagementController rightSideMenuController:self.sidebarMenuController panMode:MFSideMenuPanModeNavigationController];
        
        [self.navigationController setSideMenu:self.sauronTheSideMenu];
        [self configureMenuForOrientation:self.interfaceOrientation];
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Kill any drag processes here and now
    [self.navigationController.sideMenu setMenuState:MFSideMenuStateClosed];
    
    // We have to make sure that all the gesture recognizers are removed from the nav controller before we're done with the grid controller.
    while (self.navigationController.view.gestureRecognizers.count) {
        [self.navigationController.view removeGestureRecognizer:[self.navigationController.view.gestureRecognizers objectAtIndex:0]];
    }
    
    // Then kill the sidebar menu. (Only if we're not going to the detail photo view)
    if (!isPushingDetail) {
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];

        UIView *windowRootView = self.navigationController.view.window.rootViewController.view;
        UIView *containerView = windowRootView.superview;
        
        for (UIView *aView in containerView.subviews) {
            if (aView != self.navigationController.view.window.rootViewController.view)
                [aView removeFromSuperview];
        }
        self.sauronTheSideMenu = nil;
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


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    isPushingDetail = YES;
    
    if ([segue.identifier isEqualToString:@"SettingsSegue"]) {
        SVSettingsViewController *destination = (SVSettingsViewController *)segue.destinationViewController;
        destination.currentAlbum = self.selectedAlbum;
    }
    else if ([segue.identifier isEqualToString:@"ImagePickerSegue"])
    {
        UINavigationController *destinationNavigationController = (UINavigationController *)segue.destinationViewController;
        
        SVImagePickerListViewController *destination = [destinationNavigationController.viewControllers objectAtIndex:0];
        destination.selectedAlbum = self.selectedAlbum;
    }
}


- (void)viewDidUnload
{
    [super viewDidUnload];
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
    return self.fetchedResultsController.fetchedObjects.count;
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
    }
    
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    view.backgroundColor = [UIColor clearColor];
    view.layer.masksToBounds = NO;
    
    cell.contentView = view;
    
    UIImageView *cellBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"photoFrame.png"]];
    [cell.contentView addSubview:cellBackground];
    
    // Configure thumbnail
    AlbumPhoto *currentPhoto = [self.fetchedResultsController.fetchedObjects objectAtIndex:index];
    
    NINetworkImageView *networkImageView = [[NINetworkImageView alloc] initWithFrame:CGRectMake(4, 3, 91, 91)];
    networkImageView.clipsToBounds = YES;
    networkImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    networkImageView.backgroundColor = [UIColor clearColor];
    networkImageView.contentMode = UIViewContentModeScaleAspectFill;
    networkImageView.sizeForDisplay = NO;
    networkImageView.interpolationQuality = kCGInterpolationHigh;
    networkImageView.initialImage = [UIImage imageNamed:@"placeholderImage.png"];
    networkImageView.delegate = self;
    networkImageView.imageMemoryCache = nil;
    networkImageView.tag = index;
    [cell.contentView addSubview:networkImageView];
        
    /*[SVBusinessDelegate loadImageFromAlbum:self.selectedAlbum withPath:currentPhoto.photo_id WithCompletion:^(UIImage *image, NSError *error) {
        if (image) {
            [networkImageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
        }
    }];*/
    
    UIImage *photo = [UIImage imageWithData:currentPhoto.photoData];
    [networkImageView setImage:photo];
    
    //
    
    return cell;
}


#pragma mark - GMGridViewActionDelegate

- (void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position
{
    NSLog(@"Did tap at index %d", position);
    
    SVAlbumDetailScrollViewController *detailController = [[SVAlbumDetailScrollViewController alloc] init];
    detailController.selectedPhoto = [self.fetchedResultsController.fetchedObjects objectAtIndex:position];
    
    isPushingDetail = YES;
    [self.navigationController pushViewController:detailController animated:YES];
}


#pragma mark - NINetworkImageView Delegate Methods

- (void)networkImageView:(NINetworkImageView *)imageView didLoadImage:(UIImage *)image
{
    
}


- (void)networkImageView:(NINetworkImageView *)imageView didFailWithError:(NSError *)error
{
    
}


#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.sauronTheSideMenu.menuState == MFSideMenuStateClosed) {
        // kill all the recognizers while we're scrolling content
        while (self.navigationController.view.gestureRecognizers.count) {
            [self.navigationController.view removeGestureRecognizer:[self.navigationController.view.gestureRecognizers objectAtIndex:0]];
        }
    }
}


- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (self.sauronTheSideMenu.menuState == MFSideMenuStateClosed) {
        [self.sauronTheSideMenu setupGestureRecognizers];
    }
}


#pragma mark NSFetchedResultsControllerDelegate methods

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    self.fetchedResultsController = [[SVEntityStore sharedStore] allPhotosForAlbum:self.selectedAlbum WithDelegate:self];
    return _fetchedResultsController;
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [_gmGridView reloadData];
}


#pragma mark - Private Methods

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
    _gmGridView.delegate = self;
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


- (void)albumRefreshed:(NSNotification *)notification
{
    Album *refreshedAlbum = (Album *)notification.object;
    
    if (self.selectedAlbum == refreshedAlbum) {
        [_gmGridView reloadData];
    }
}

@end
