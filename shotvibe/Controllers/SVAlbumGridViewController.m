//
//  SVAlbumGridViewController.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/13/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVAlbumGridViewController.h"
#import "MFSideMenu.h"
#import "SVDefines.h"
#import "RCImageView.h"
#import "SVPhotoViewerController.h"
#import "SVSidebarMemberController.h"
#import "SVSidebarManagementController.h"
#import "SVSettingsViewController.h"
#import "CaptureNavigationController.h"
#import "SVCameraPickerController.h"
#import "SVImagePickerListViewController.h"
#import "SVAlbumGridViewCell.h"
#import "SVAddFriendsViewController.h"
#import "CaptureNavigationController.h"
#import "AlbumPhoto.h"
#import "UIImageView+WebCache.h"
#import "MWPhotoBrowser.h"
#import "AlbumPhotoBrowserDelegate.h"

@interface SVAlbumGridViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, RCImageViewDelegate>

@property (nonatomic, strong) MFSideMenuContainerViewController *sideMenu;
@property (nonatomic, strong) IBOutlet UIView *gridviewContainer;
@property (nonatomic, strong) IBOutlet UICollectionView *gridView;
@property (nonatomic, strong) IBOutlet UIView *noPhotosView;
@property (nonatomic, strong) IBOutlet UIButton *butTakeVideo;
@property (nonatomic, strong) IBOutlet UIButton *butTakePicture;

- (void)toggleMenu;
- (void)toggleManagement;
- (IBAction)takeVideoPressed:(id)sender;
- (IBAction)takePicturePressed:(id)sender;

@end

@implementation SVAlbumGridViewController
{
    AlbumContents *albumContents;
    BOOL isMenuShowing;
    NSMutableArray *_objectChanges;
    NSMutableArray *_sectionChanges;
    NSMutableDictionary *thumbnailCache;
    UIRefreshControl *refresh;
	CaptureNavigationController *cameraNavController;
}


- (IBAction)takeVideoPressed:(id)sender
{
    [self takePicturePressed:sender];
}


- (IBAction)takePicturePressed:(id)sender
{
	cameraNavController = [[CaptureNavigationController alloc] init];
	cameraNavController.cameraDelegate = self;
	cameraNavController.albumId = self.albumId;
	cameraNavController.albumManager = self.albumManager;
    cameraNavController.nav = self.navigationController;// this is set last
}

- (void)backButtonPressed:(id)sender
{
	// When we leave the album set all the photos as viewed
	
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	
    if ([segue.identifier isEqualToString:@"SettingsSegue"]) {
		
        SVSettingsViewController *destinationController = segue.destinationViewController;
        destinationController.albumManager = self.albumManager;
    }
    else if ([segue.identifier isEqualToString:@"ImagePickerSegue"]) {
		
        UINavigationController *destinationNavigationController = (UINavigationController *)segue.destinationViewController;
        
        SVImagePickerListViewController *destination = [destinationNavigationController.viewControllers objectAtIndex:0];
        destination.albumId = self.albumId;
        destination.albumManager = self.albumManager;
        //destination.selectedAlbum = self.selectedAlbum;
    }
	else if ([segue.identifier isEqualToString:@"AddFriendsSegue"]) {
		
		//UINavigationController *destinationNavigationController = (UINavigationController *)segue.destinationViewController;
        
        //SVAddFriendsViewController *destination = [destinationNavigationController.viewControllers objectAtIndex:0];
        //destination.selectedAlbum = self.selectedAlbum;
		
		//[self.menuContainerViewController setMenuState:MFSideMenuStateClosed];
    }
}




#pragma mark - UIViewController Methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setAlbumContents:[self.albumManager addAlbumContentsListener:self.albumId listener:self]];
    NSLog(@"ALBUM CONTENTS: %@", albumContents);

    _objectChanges = [NSMutableArray array];
    _sectionChanges = [NSMutableArray array];
    thumbnailCache = [[NSMutableDictionary alloc] init];
	
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		self.butTakePicture.enabled = NO;
		self.butTakeVideo.enabled = NO;
	}
    
    // Setup tabbar right button
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"userIcon.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(toggleMenu)];
    self.navigationItem.rightBarButtonItem = menuButton;
    
    // Setup back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(backButtonPressed:)];
    NSDictionary *att = @{UITextAttributeFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:16.0], UITextAttributeTextShadowColor:[UIColor clearColor]};
	[backButton setTitleTextAttributes:att forState:UIControlStateNormal];
	[backButton setTitlePositionAdjustment:UIOffsetMake(15,0) forBarMetrics:UIBarMetricsDefault];
	self.navigationItem.backBarButtonItem = backButton;
	
	((SVSidebarManagementController*)self.menuContainerViewController.leftMenuViewController).parentController = self;
	((SVSidebarMemberController*)self.menuContainerViewController.rightMenuViewController).parentController = self;
	((SVSidebarMemberController*)self.menuContainerViewController.rightMenuViewController).albumContents = albumContents;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	
	if (refresh == nil) {
		refresh = [[UIRefreshControl alloc] init];
		refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
		[refresh addTarget:self action:@selector(refreshView) forControlEvents:UIControlEventValueChanged];
		[self.gridView addSubview:refresh];
		
		[self.albumManager refreshAlbumContents:self.albumId];
		[self.gridView reloadData];
		
		// Remove the previous controller from the stack if it's SVCameraPickerController
		NSMutableArray *allViewControllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
		//[allViewControllers removeObjectAtIndex:allViewControllers.count-2];
		id lastController = allViewControllers[allViewControllers.count-2];
		if ([lastController isKindOfClass:[SVCameraPickerController class]])
			[allViewControllers removeObject:lastController];
		self.navigationController.viewControllers = allViewControllers;
	}
	// Restore the sidemenu state, when is hide it loses x position
	if (self.menuContainerViewController.menuState != MFSideMenuStateClosed) {
		[self.menuContainerViewController setMenuState:self.menuContainerViewController.menuState];
	}
	
	self.menuContainerViewController.panMode = MFSideMenuPanModeCenterViewController;
}


#pragma mark Rotation

- (BOOL)shouldAutorotate {
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskAllButUpsideDown;
}


#pragma mark - Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [thumbnailCache removeAllObjects];
}




#pragma mark camera delegate

- (void)cameraExit {
	cameraNavController = nil;
}

- (void) cameraWasDismissedWithAlbum:(AlbumSummary*)selectedAlbum {
	
	NSLog(@"CAMERA WAS DISMISSED %@", selectedAlbum);
	
	
}




#pragma mark - UICollectionViewDataSource Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	NSLog(@"count photos %i", albumContents.photos.count);
	if (refresh == nil) return 0;
    return albumContents.photos.count;
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SVAlbumGridViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SVAlbumGridViewCell" forIndexPath:indexPath];
    
	[cell.networkImageView setImage:nil];

    int i = indexPath.row;
    AlbumPhoto *photo = [albumContents.photos objectAtIndex:i];

    if (photo.serverPhoto) {
        NSString *fullsizePhotoUrl = photo.serverPhoto.url;
        NSString *thumbnailSuffix = @"_thumb75.jpg";
        NSString *thumbnailUrl = [[fullsizePhotoUrl stringByDeletingPathExtension] stringByAppendingString:thumbnailSuffix];

        // TODO Temporarily using SDWebImage library for a quick and easy way to display photos
        [cell.networkImageView setImageWithURL:[NSURL URLWithString:thumbnailUrl]];

        cell.uploadProgressView.hidden = YES;
    }
    else if (photo.uploadingPhoto) {
        [cell.networkImageView setImage:[photo.uploadingPhoto getThumbnail]];

        cell.uploadProgressView.hidden = NO;
        if ([photo.uploadingPhoto isUploadComplete]) {
            cell.uploadProgressView.progress = 1.0f;
        }
        else {
            cell.uploadProgressView.progress = [photo.uploadingPhoto getUploadProgress];
        }
    }


    /*
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0),^{
		
		dispatch_async(dispatch_get_main_queue(),^{
			
		});
	});
    */
    
    return cell;
}


#pragma mark - UICollectionViewDelegate Methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];

//    AlbumPhotoBrowserDelegate *delegate = [[AlbumPhotoBrowserDelegate alloc] initWithAlbumContents:albumContents];
//    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:delegate];
//    browser.wantsFullScreenLayout = YES;
//    browser.displayActionButton = YES;
//    [browser setInitialPageIndex:indexPath.item];
//
//    [self.navigationController pushViewController:browser animated:YES];
	
	SVPhotoViewerController *detailController = [[SVPhotoViewerController alloc] init];
    detailController.albumContents = albumContents;
	detailController.index = indexPath.item;
	
    [self.navigationController pushViewController:detailController animated:YES];
	self.menuContainerViewController.panMode = MFSideMenuPanModeNone;
}


#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.sideMenu.menuState == MFSideMenuStateClosed) {
        // kill all the recognizers while we're scrolling content
//        while (self.navigationController.view.gestureRecognizers.count) {
//            [self.navigationController.view removeGestureRecognizer:[self.navigationController.view.gestureRecognizers objectAtIndex:0]];
//        }
    }
}


- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (self.sideMenu.menuState == MFSideMenuStateClosed) {
        //[self.sideMenu setupGestureRecognizers];
    }
}


#pragma mark - Private Methods

- (void)toggleMenu
{
    [self.menuContainerViewController toggleRightSideMenuCompletion:^{
		
	}];
}

- (void)toggleManagement
{
    [self.menuContainerViewController toggleLeftSideMenuCompletion:^{
		
	}];
}

-(void)setAlbumContents:(AlbumContents *)album
{
    albumContents = album;

    self.title = albumContents.name;

    self.noPhotosView.hidden = albumContents.photos.count > 0;

    [self.gridView reloadData];

    //self.sidebarRight.albumContents = albumContents;
}

- (void)onAlbumContentsBeginRefresh:(int64_t)albumId
{
	[refresh beginRefreshing];
	refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing photos..."];
}

- (void)onAlbumContentsRefreshComplete:(int64_t)albumId albumContents:(AlbumContents *)album
{
	[refresh endRefreshing];
	refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];

    [self setAlbumContents:album];
}

- (void)onAlbumContentsRefreshError:(int64_t)albumId error:(NSError *)error
{
    [refresh endRefreshing];
	refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
	
    // TODO ...
}

- (void)onAlbumContentsPhotoUploadProgress:(int64_t)albumId
{
    [self.gridView reloadData];
}


#pragma mark refresh control

-(void)refreshView
{
	
	NSLog(@"refreshView");
    [self.albumManager refreshAlbumContents:self.albumId];
}


@end
