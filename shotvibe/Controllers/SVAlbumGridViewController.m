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
#import "RCImageView.h"
#import "SVPhotoViewerController.h"
#import "SVSidebarAlbumMemberViewController.h"
#import "MFSideMenu.h"
#import "UINavigationController+MFSideMenu.h"
#import "SVSidebarAlbumManagementViewController.h"
#import "SVBusinessDelegate.h"
#import "SVSettingsViewController.h"
#import "CaptureNavigationController.h"
#import "CaptureViewfinderController.h"
#import "SVImagePickerListViewController.h"
#import "SVAlbumGridViewCell.h"
#import "SVAddFriendsViewController.h"
#import "SVUploadManager.h"

@interface SVAlbumGridViewController () <NSFetchedResultsControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, RCImageViewDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) MFSideMenu *sauronTheSideMenu;
@property (nonatomic, strong) IBOutlet UIView *gridviewContainer;
@property (nonatomic, strong) IBOutlet UICollectionView *gridView;
@property (nonatomic, strong) IBOutlet UIView *noPhotosView;

- (void)toggleMenu;
- (void)toggleManagement;
- (void)configureMenuForOrientation:(UIInterfaceOrientation)orientation;
- (IBAction)takeVideoPressed:(id)sender;
- (IBAction)takePicturePressed:(id)sender;

@end

@implementation SVAlbumGridViewController
{
    BOOL isMenuShowing;
    NSMutableArray *_objectChanges;
    NSMutableArray *_sectionChanges;
    NSMutableDictionary *thumbnailCache;
}


- (IBAction)takeVideoPressed:(id)sender
{
    [self takePicturePressed:sender];
}


- (IBAction)takePicturePressed:(id)sender
{
    CaptureViewfinderController *cameraController = [[CaptureViewfinderController alloc] initWithNibName:@"CaptureViewfinder" bundle:[NSBundle mainBundle]];
    cameraController.albums = @[self.selectedAlbum];
    CaptureNavigationController *cameraNavController = [[CaptureNavigationController alloc] initWithRootViewController:cameraController];
    
    [self presentViewController:cameraNavController animated:YES completion:nil];
}

- (void)backButtonPressed:(id)sender
{
	NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!BACKKKKKK FROM PHOTOS");
	// When we leave the album set all the photos as viewed
	
	
    [self.navigationController popViewControllerAnimated:YES];
}



#pragma mark - UIViewController Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.title = self.selectedAlbum.name;
	
    _objectChanges = [NSMutableArray array];
    _sectionChanges = [NSMutableArray array];
    thumbnailCache = [[NSMutableDictionary alloc] init];
	
    // Setup fetched results
    
    // Setup tabbar right button
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"userIcon.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(toggleMenu)];
    self.navigationItem.rightBarButtonItem = menuButton;
    
    // Setup back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(backButtonPressed:)];
    NSDictionary *att = @{UITextAttributeFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:16.0], UITextAttributeTextShadowColor:[UIColor clearColor]};
	[backButton setTitleTextAttributes:att forState:UIControlStateNormal];
	[backButton setTitlePositionAdjustment:UIOffsetMake(15,0) forBarMetrics:UIBarMetricsDefault];
	self.navigationItem.backBarButtonItem = backButton;
	
	NSInteger nrOfPhotos = [self collectionView:nil numberOfItemsInSection:0];
	
	self.noPhotosView.hidden = (nrOfPhotos > 0);
	
	[self fetchedResultsController];
	
	// Initialize the sidebar menu
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
	self.sidebarRight = [storyboard instantiateViewControllerWithIdentifier:@"SidebarMenuView"];
	self.sidebarRight.parentController = self;
	self.sidebarRight.selectedAlbum = self.selectedAlbum;
	
	self.sidebarLeft = [storyboard instantiateViewControllerWithIdentifier:@"SidebarManagementView"];
	self.sidebarLeft.parentController = self;
	
	self.sauronTheSideMenu = [MFSideMenu menuWithNavigationController:self.navigationController
											   leftSideMenuController:self.sidebarLeft
											  rightSideMenuController:self.sidebarRight
															  panMode:MFSideMenuPanModeNavigationController];
	
	[self.navigationController setSideMenu:self.sauronTheSideMenu];
	[self configureMenuForOrientation:self.interfaceOrientation];
}


-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.gridView reloadData];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	
	// Restore the sidemenu state, when is hide it loses x position
	NSLog(@"viewDidappear %i", self.navigationController.sideMenu.menuState);
	if (self.navigationController.sideMenu.menuState != MFSideMenuStateClosed) {
		[self.navigationController.sideMenu setMenuState:self.navigationController.sideMenu.menuState];
	}
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{    
    [self configureMenuForOrientation:self.interfaceOrientation];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationMaskPortrait;// UIInterfaceOrientationMaskAllButUpsideDown;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	NSLog(@"prepareForSegue %@", segue.identifier);
    if ([segue.identifier isEqualToString:@"SettingsSegue"]) {
		
        SVSettingsViewController *destination = (SVSettingsViewController *)segue.destinationViewController;
        destination.currentAlbum = self.selectedAlbum;
    }
    else if ([segue.identifier isEqualToString:@"ImagePickerSegue"]) {
		
        UINavigationController *destinationNavigationController = (UINavigationController *)segue.destinationViewController;
        
        SVImagePickerListViewController *destination = [destinationNavigationController.viewControllers objectAtIndex:0];
        destination.selectedAlbum = self.selectedAlbum;
    }
	else if ([segue.identifier isEqualToString:@"AddFriendsSegue"]) {
		
		UINavigationController *destinationNavigationController = (UINavigationController *)segue.destinationViewController;
        
        SVAddFriendsViewController *destination = [destinationNavigationController.viewControllers objectAtIndex:0];
        destination.selectedAlbum = self.selectedAlbum;
		
		//[self.navigationController.sideMenu setMenuState:MFSideMenuStateClosed];
    }
}



#pragma mark - Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [thumbnailCache removeAllObjects];
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
    
	[cell.networkImageView setImage:nil];
    cell.tag = indexPath.row;
	__block NSIndexPath *tagIndex = indexPath;
    
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0),^{
		
		AlbumPhoto *currentPhoto = [self.fetchedResultsController objectAtIndexPath:indexPath];
		UIImage *image = [thumbnailCache objectForKey:currentPhoto.photo_id];
		
		//NSLog(@"---------> photo cell: %i %@ objectSyncStatus: %@", indexPath.item, currentPhoto.date_created, currentPhoto.objectSyncStatus);
		//NSLog(@"image is cached to %@", image);
		
		if (!image) {
			// Holding onto the tag index so that when our block returns we can check if we're still even looking at the same cell... This should prevent the roulette wheel
			__block NSString *photoId = currentPhoto.photo_id;
			
			[[SVEntityStore sharedStore] getImageForPhoto:currentPhoto WithCompletion:^(UIImage *image) {
				
				if (image && cell.tag == tagIndex.row) {
					
					[thumbnailCache setObject:image forKey:photoId];
					
					dispatch_async(dispatch_get_main_queue(),^{
						[cell.networkImageView setImage:image];
					});
				}
			}];
		}
		else {
			dispatch_async(dispatch_get_main_queue(),^{
				if (cell.tag == tagIndex.row) [cell.networkImageView setImage:image];
			});
		}
		
		dispatch_async(dispatch_get_main_queue(),^{
			
			if (cell.tag == tagIndex.row) {
				if (currentPhoto.objectSyncStatus.integerValue == SVObjectSyncUploadNeeded) {
					[cell.activityView startAnimating];
					cell.networkImageView.alpha = 0.3;
				}
				else if (currentPhoto.objectSyncStatus.integerValue == SVObjectSyncUploadProgress) {
					[cell.activityView startAnimating];
					cell.networkImageView.alpha = 0.3;
				}
				else {
					[cell.activityView stopAnimating];
					cell.networkImageView.alpha = 1.0;
				}
				
				cell.labelNewView.hidden = [currentPhoto.hasViewed boolValue];
			}
		});
	});
    
    return cell;
}


#pragma mark - UICollectionViewDelegate Methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    SVPhotoViewerController *detailController = [[SVPhotoViewerController alloc] init];
    detailController.selectedPhoto = [self.fetchedResultsController objectAtIndexPath:indexPath];
	detailController.index = indexPath.item;
	NSLog(@"didSelectItemAtIndexPath %@ %@", indexPath, detailController.selectedPhoto);
    
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
//        while (self.navigationController.view.gestureRecognizers.count) {
//            [self.navigationController.view removeGestureRecognizer:[self.navigationController.view.gestureRecognizers objectAtIndex:0]];
//        }
    }
}


- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (self.sauronTheSideMenu.menuState == MFSideMenuStateClosed) {
        //[self.sauronTheSideMenu setupGestureRecognizers];
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


- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
	 forChangeType:(NSFetchedResultsChangeType)type
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

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
	 forChangeType:(NSFetchedResultsChangeType)type
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
	NSLog(@"SVAlbumGrid controllerDidChangeContent");
	if (self.isViewLoaded && self.view.window){
		// viewController is visible
	}
	else return;
    
    if ([_objectChanges count] > 0)
    {
		[self.gridView performBatchUpdates:^{
			
			for (NSDictionary *change in _objectChanges)
			{
				[change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
					
					NSFetchedResultsChangeType type = [key unsignedIntegerValue];
					switch (type)
					{
						case NSFetchedResultsChangeInsert:
							NSLog(@"insert");
							[self.gridView insertItemsAtIndexPaths:@[obj]];
							[[SVUploadManager sharedManager] upload];
							break;
						case NSFetchedResultsChangeDelete:
							NSLog(@"delete");
							[self.gridView deleteItemsAtIndexPaths:@[obj]];
							[[SVUploadManager sharedManager] deletePhotos];
							break;
						case NSFetchedResultsChangeUpdate:
							NSLog(@"update");
							[self.gridView reloadItemsAtIndexPaths:@[obj]];
							break;
						case NSFetchedResultsChangeMove:
							NSLog(@"move");
							[self.gridView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
							break;
					}
				}];
			}
		} completion:nil];
    }
    
    [_sectionChanges removeAllObjects];
    [_objectChanges removeAllObjects];
	
	NSInteger nrOfPhotos = [self collectionView:nil numberOfItemsInSection:0];
	self.noPhotosView.hidden = (nrOfPhotos > 0);
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
	NSLog(@"configureMenuForOrientation");
	return;
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
            } else {
                rightFrame.size.height = 460;
                leftFrame.size.height = 460;
            }
            break;
			
        case UIInterfaceOrientationPortraitUpsideDown:
            if (IS_IPHONE_5) {
                rightFrame.size.height = 548;
                leftFrame.size.height = 548;
            } else {
                rightFrame.size.height = 460;
                leftFrame.size.height = 460;
            }
            break;
			
        case UIInterfaceOrientationLandscapeLeft:
            if (IS_IPHONE_5) {
                rightFrame.origin.x = 568 - kMFSideMenuSidebarWidth;
            } else {
                rightFrame.origin.x = 480 - kMFSideMenuSidebarWidth;
            }
            break;
        case UIInterfaceOrientationLandscapeRight:
            if (IS_IPHONE_5) {
                rightFrame.origin.x = 568 - kMFSideMenuSidebarWidth;
            } else {
                rightFrame.origin.x = 480 - kMFSideMenuSidebarWidth;
            }
            break;
    }
    
    self.navigationController.sideMenu.rightSideMenuViewController.view.frame = rightFrame;
    self.navigationController.sideMenu.leftSideMenuViewController.view.frame = leftFrame;

}


@end
