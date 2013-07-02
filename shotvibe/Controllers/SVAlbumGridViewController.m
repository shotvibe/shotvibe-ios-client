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
#import "SVAlbumGridViewCell.h"

@interface SVAlbumGridViewController () <NSFetchedResultsControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NINetworkImageViewDelegate>
{
    BOOL isPushingDetail;
}

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) IBOutlet UIView *gridviewContainer;
@property (nonatomic, strong) MFSideMenu *sauronTheSideMenu;
@property (nonatomic, strong) IBOutlet UICollectionView *gridView;

@property (nonatomic, strong) NSOperationQueue *imageLoadingQueue;

- (void)toggleMenu;
- (void)toggleManagement;
- (void)configureMenuForOrientation:(UIInterfaceOrientation)orientation;
- (void)backButtonPressed;
- (void)configureCell:(SVAlbumGridViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (IBAction)homePressed:(id)sender;
- (IBAction)takePicturePressed:(id)sender;

@end

@implementation SVAlbumGridViewController
{
    BOOL isMenuShowing;
    NSMutableArray *_objectChanges;
    NSMutableArray *_sectionChanges;
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
        
    _objectChanges = [NSMutableArray array];
    _sectionChanges = [NSMutableArray array];
    
    self.imageLoadingQueue = [[NSOperationQueue alloc] init];
    self.imageLoadingQueue.maxConcurrentOperationCount = 1;
     
    // Setup fetched results
    
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
    
    [self fetchedResultsController];
        
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
        
        UIView *windowRootView = self.navigationController.view.window.rootViewController.view;
        UIView *containerView = windowRootView.superview;
        
        for (UIView *aView in containerView.subviews) {
            if (aView != self.navigationController.view.window.rootViewController.view)
                [aView removeFromSuperview];
        }
        self.sauronTheSideMenu = nil;
        self.sidebarMenuController.view = nil;
        self.sidebarManagementController.view = nil;
        self.sidebarManagementController = nil;
        self.sidebarMenuController = nil;
    }
    
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{    
    [self configureMenuForOrientation:self.interfaceOrientation];
    [self.gridView reloadData];
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


#pragma mark - UICollectionViewDataSource Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SVAlbumGridViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SVAlbumGridViewCell" forIndexPath:indexPath];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}


#pragma mark - UICollectionViewDelegate Methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    SVAlbumDetailScrollViewController *detailController = [[SVAlbumDetailScrollViewController alloc] init];
    detailController.selectedPhoto = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    isPushingDetail = YES;
    [self.navigationController pushViewController:detailController animated:YES];
}


- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        return UIEdgeInsetsMake(5, 5, 5, 5);
    }
    
    if (IS_IPHONE_5) {
        return UIEdgeInsetsMake(5, 12, 5, 12);
    }
    else
    {
        return UIEdgeInsetsMake(5, 17, 5, 17);
    }
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
    [self.gridView reloadData];
    return _fetchedResultsController;
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    
    NSMutableDictionary *change = [NSMutableDictionary new];
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = @(sectionIndex);
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = @(sectionIndex);
            break;
    }
    
    [_sectionChanges addObject:change];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    
    NSMutableDictionary *change = [NSMutableDictionary new];
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = newIndexPath;
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeUpdate:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeMove:
            change[@(type)] = @[indexPath, newIndexPath];
            break;
    }
    [_objectChanges addObject:change];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if ([_sectionChanges count] > 0)
    {
        [self.gridView performBatchUpdates:^{
            
            for (NSDictionary *change in _sectionChanges)
            {
                [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                    
                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                    switch (type)
                    {
                        case NSFetchedResultsChangeInsert:
                            [self.gridView insertSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeDelete:
                            [self.gridView deleteSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeUpdate:
                            [self.gridView reloadSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                    }
                }];
            }
        } completion:nil];
    }
    
    if ([_objectChanges count] > 0 && [_sectionChanges count] == 0)
    {
        
        if ([self shouldReloadCollectionViewToPreventKnownIssue] || self.gridView.window == nil) {
            // This is to prevent a bug in UICollectionView from occurring.
            // The bug presents itself when inserting the first object or deleting the last object in a collection view.
            // http://stackoverflow.com/questions/12611292/uicollectionview-assertion-failure
            // This code should be removed once the bug has been fixed, it is tracked in OpenRadar
            // http://openradar.appspot.com/12954582
            [self.gridView reloadData];
            
        } else {
            
            [self.gridView performBatchUpdates:^{
                
                for (NSDictionary *change in _objectChanges)
                {
                    [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                        
                        NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                        switch (type)
                        {
                            case NSFetchedResultsChangeInsert:
                                [self.gridView insertItemsAtIndexPaths:@[obj]];
                                break;
                            case NSFetchedResultsChangeDelete:
                                [self.gridView deleteItemsAtIndexPaths:@[obj]];
                                break;
                            case NSFetchedResultsChangeUpdate:
                                [self.gridView reloadItemsAtIndexPaths:@[obj]];
                                break;
                            case NSFetchedResultsChangeMove:
                                [self.gridView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                                break;
                        }
                    }];
                }
            } completion:nil];
        }
    }
    
    [_sectionChanges removeAllObjects];
    [_objectChanges removeAllObjects];
}

- (BOOL)shouldReloadCollectionViewToPreventKnownIssue {
    __block BOOL shouldReload = NO;
    for (NSDictionary *change in _objectChanges) {
        [change enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSFetchedResultsChangeType type = [key unsignedIntegerValue];
            NSIndexPath *indexPath = obj;
            switch (type) {
                case NSFetchedResultsChangeInsert:
                    if ([self.gridView numberOfItemsInSection:indexPath.section] == 0) {
                        shouldReload = YES;
                    } else {
                        shouldReload = NO;
                    }
                    break;
                case NSFetchedResultsChangeDelete:
                    if ([self.gridView numberOfItemsInSection:indexPath.section] == 1) {
                        shouldReload = YES;
                    } else {
                        shouldReload = NO;
                    }
                    break;
                case NSFetchedResultsChangeUpdate:
                    shouldReload = NO;
                    break;
                case NSFetchedResultsChangeMove:
                    shouldReload = NO;
                    break;
            }
        }];
    }
    
    return shouldReload;
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


- (void)configureCell:(SVAlbumGridViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [cell.networkImageView prepareForReuse];
    cell.networkImageView.sizeForDisplay = NO;
    cell.networkImageView.interpolationQuality = kCGInterpolationHigh;
    
    if (!cell.networkImageView.initialImage) {
        cell.networkImageView.initialImage = [UIImage imageNamed:@"placeholderImage.png"];
    }
    cell.networkImageView.tag = indexPath.row;
    
    __block AlbumPhoto *currentPhoto = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    __block NSIndexPath *tagIndex = indexPath;
    [self.imageLoadingQueue addOperationWithBlock:^{
        [[SVEntityStore sharedStore] getImageForPhoto:currentPhoto WithCompletion:^(UIImage *image) {
            if (image && cell.networkImageView.tag == tagIndex.row) {
                [cell.networkImageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
            }
        }];
    }];
}

@end
