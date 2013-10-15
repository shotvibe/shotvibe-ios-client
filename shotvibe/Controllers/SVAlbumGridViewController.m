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
#import "SVCameraNavController.h"
#import "SVCameraPickerController.h"
#import "SVImagePickerListViewController.h"
#import "SVAlbumGridViewCell.h"
#import "SVAddFriendsViewController.h"
#import "SVCameraNavController.h"
#import "AlbumPhoto.h"
#import "UIImageView+WebCache.h"
#import "SVAlbumGridSection.h"

@interface SVAlbumGridViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, RCImageViewDelegate>
{
    AlbumContents *albumContents;
    BOOL isMenuShowing;
	BOOL refreshManualy;
	BOOL navigatingNext;
	NSMutableArray *sectionsKeys;
	NSMutableDictionary *sections;
    UIRefreshControl *refresh;
	SVCameraNavController *cameraNavController;
	SortType sort;
}

@property (nonatomic, strong) MFSideMenuContainerViewController *sideMenu;
@property (nonatomic, strong) IBOutlet UIView *gridviewContainer;
@property (nonatomic, strong) IBOutlet UICollectionView *gridView;
@property (nonatomic, strong) IBOutlet UIView *noPhotosView;
@property (nonatomic, strong) IBOutlet UIButton *butTakeVideo;
@property (nonatomic, strong) IBOutlet UIButton *butTakePicture;
@property (nonatomic, strong) IBOutlet UIButton *butTakeVideo2;
@property (nonatomic, strong) IBOutlet UIButton *butTakePicture2;
@property (nonatomic, strong) IBOutlet UIView *switchView;
@property (nonatomic, strong) IBOutlet UISegmentedControl *switchSort;

- (void)toggleMenu;
- (void)toggleManagement;
- (IBAction)takeVideoPressed:(id)sender;
- (IBAction)takePicturePressed:(id)sender;

@end

@implementation SVAlbumGridViewController


#pragma mark - UIViewController Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	NSAssert(self.albumId, @"SVAlbumGridViewController can't be initialized withou albumId");
	
	self.gridView.alwaysBounceVertical = YES;
	
	sections = [[NSMutableDictionary alloc] init];
	sectionsKeys = [[NSMutableArray alloc] init];
	sort = [[NSUserDefaults standardUserDefaults] integerForKey:@"sort_photos"];
	
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		self.butTakePicture.enabled = NO;
		self.butTakePicture2.enabled = NO;
		self.butTakeVideo.enabled = NO;
		self.butTakeVideo2.enabled = NO;
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
	
	[self.gridView registerClass:[SVAlbumGridSection class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"SVAlbumGridSection"];
	[self.gridView addSubview:self.switchView];
	self.switchView.frame = CGRectMake(0, 0, 320, 45);
	self.switchSort.frame = CGRectMake(200, 10, 320-207, 30);
	[self.switchSort addTarget:self action:@selector(switchSortHandler:) forControlEvents:UIControlEventValueChanged];
	self.switchSort.selectedSegmentIndex = sort;
	
	((SVSidebarManagementController*)self.menuContainerViewController.leftMenuViewController).parentController = self;
	((SVSidebarMemberController*)self.menuContainerViewController.rightMenuViewController).parentController = self;
	
	AlbumContents *contents = [self.albumManager addAlbumContentsListener:self.albumId listener:self];
	[self setAlbumContents:contents];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];RCLog(@"photos grid will appear");
	RCLog(@"-------view will appear. ALBUM CONTENTS, album id %lld %@ %@", self.albumId, self.albumManager, albumContents);
	
	if (albumContents == nil) {
		//AlbumContents *contents;
		albumContents = [self.albumManager addAlbumContentsListener:self.albumId listener:self];
		//[self setAlbumContents:contents];
	}
	[self.albumManager refreshAlbumContents:self.albumId];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
	if (refresh == nil) {
		refresh = [[UIRefreshControl alloc] init];
		refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
		[refresh addTarget:self action:@selector(beginRefreshing) forControlEvents:UIControlEventValueChanged];
		[self.gridView addSubview:refresh];
		
		// Remove the previous controller from the stack if it's SVCameraPickerController
		NSMutableArray *allViewControllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
		id lastController = allViewControllers[allViewControllers.count-2];
		if ([lastController isKindOfClass:[SVCameraPickerController class]])
			[allViewControllers removeObject:lastController];
		self.navigationController.viewControllers = allViewControllers;
	}
	if (self.scrollToBottom) {
		self.scrollToBottom = NO;
		RCLogSize(self.gridView.contentSize);
		RCLogRect(self.gridView.bounds);
		[self.gridView scrollRectToVisible:CGRectMake(0,
													  self.gridView.contentSize.height - self.gridView.bounds.size.height,
													  self.gridView.bounds.size.width,
													  self.gridView.bounds.size.height)
								  animated:NO];
	}
	
	self.menuContainerViewController.panMode = MFSideMenuPanModeCenterViewController;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];RCLog(@"-----------photos grid will disappear navigatingNext %i", navigatingNext);
	
	if (!navigatingNext) {
		
		[self.albumManager removeAlbumContentsListener:self.albumId listener:self];
		albumContents = nil;
		
		RCLog(@"clean everything");
		self.albumManager = nil;
		((SVSidebarManagementController*)self.menuContainerViewController.leftMenuViewController).parentController = nil;
		((SVSidebarMemberController*)self.menuContainerViewController.rightMenuViewController).parentController = nil;
		self.sideMenu = nil;
		self.gridviewContainer = nil;
		self.gridView = nil;
		self.noPhotosView = nil;
		self.butTakeVideo = nil;
		self.butTakePicture = nil;
		[self.switchSort removeTarget:self action:@selector(switchSortHandler:) forControlEvents:UIControlEventValueChanged];
		self.switchSort = nil;
	}
	navigatingNext = NO;
}

- (void)dealloc {
	RCLog(@"dealloc SVAlbumGridViewController %lli", self.albumId);
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
}


#pragma mark Actions

- (IBAction)takeVideoPressed:(id)sender
{
    [self takePicturePressed:sender];
}


- (IBAction)takePicturePressed:(id)sender
{
	navigatingNext = YES;
	self.scrollToBottom = YES;
	
	cameraNavController = [[SVCameraNavController alloc] init];
	cameraNavController.cameraDelegate = self;
	cameraNavController.albumId = self.albumId;
	cameraNavController.albumManager = self.albumManager;
    cameraNavController.nav = self.navigationController;// this is set last
}

- (void)backButtonPressed:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	navigatingNext = YES;
	
    if ([segue.identifier isEqualToString:@"SettingsSegue"]) {
		
        SVSettingsViewController *destinationController = segue.destinationViewController;
        destinationController.albumManager = self.albumManager;
    }
    else if ([segue.identifier isEqualToString:@"ImagePickerSegue"]) {
		
        UINavigationController *destinationNavigationController = (UINavigationController *)segue.destinationViewController;
        
        SVImagePickerListViewController *destination = [destinationNavigationController.viewControllers objectAtIndex:0];
        destination.albumId = self.albumId;
        destination.albumManager = self.albumManager;
		self.scrollToBottom = YES;
    }
	else if ([segue.identifier isEqualToString:@"AddFriendsSegue"]) {
		
		UINavigationController *destinationNavigationController = (UINavigationController *)segue.destinationViewController;
        SVAddFriendsViewController *destination = [destinationNavigationController.viewControllers objectAtIndex:0];
        destination.albumManager = self.albumManager;
		destination.albumId = self.albumId;
    }
}




- (void) updateEmptyState
{
	if (albumContents.photos.count == 0) {
		[self.gridView addSubview:self.noPhotosView];
		self.switchView.hidden = YES;
	}
	else if ([self.noPhotosView isDescendantOfView:self.gridView] || [self.noPhotosView isDescendantOfView:self.view]) {
		[self.noPhotosView removeFromSuperview];
		self.switchView.hidden = NO;
	}
}



#pragma mark camera delegate

- (void)cameraExit {
	cameraNavController = nil;
	self.scrollToBottom = NO;
}

- (void) cameraWasDismissedWithAlbum:(AlbumSummary*)selectedAlbum {
	
	RCLog(@"CAMERA WAS DISMISSED %@", selectedAlbum);
	
}




#pragma mark - UICollectionViewDataSource Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	NSArray *arr = [sections objectForKey:sectionsKeys[section]];
    return arr.count;
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [sectionsKeys count];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SVAlbumGridViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SVAlbumGridViewCell" forIndexPath:indexPath];
    __block NSArray *arr = [sections objectForKey:sectionsKeys[indexPath.section]];
	
	[cell.networkImageView setImage:nil];
	
    AlbumPhoto *photo = [arr objectAtIndex:indexPath.row];

    if (photo.serverPhoto) {
		
        NSString *fullsizePhotoUrl = photo.serverPhoto.url;
        NSString *thumbnailSuffix = @"_thumb75.jpg";
        NSString *thumbnailUrl = [[fullsizePhotoUrl stringByDeletingPathExtension] stringByAppendingString:thumbnailSuffix];
		
        [cell.networkImageView setImageWithURL:[NSURL URLWithString:thumbnailUrl]];
        cell.uploadProgressView.hidden = YES;
    }
    else if (photo.uploadingPhoto) {
		
        [cell.networkImageView setImage:[photo.uploadingPhoto getThumbnail]];
		
        cell.uploadProgressView.hidden = NO;
        cell.uploadProgressView.progress = 0.0f;
    }
    
    return cell;
}

// Section headers

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
		   viewForSupplementaryElementOfKind:(NSString *)kind
								 atIndexPath:(NSIndexPath *)indexPath {
	
	if (kind == UICollectionElementKindSectionHeader)
	{
		SVAlbumGridSection *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
																		withReuseIdentifier:@"SVAlbumGridSection"
																			   forIndexPath:indexPath];
		
		// Modify the header
		[header setType:sort];
		
		header.dateLabel.text = sectionsKeys[indexPath.section];
		header.dateLabel.backgroundColor = [UIColor clearColor];
		
		if (sort == SortByAuthor) {
			NSArray *arr = [sections objectForKey:sectionsKeys[indexPath.section]];
			AlbumPhoto *photo = [arr objectAtIndex:indexPath.row];
			
			//Search through the members
			for (AlbumMember *member in albumContents.members) {
				if (photo.serverPhoto.authorUserId == member.memberId) {
					[header.imageView loadNetworkImage:member.avatarUrl];
					break;
				}
			}
		}
		
		
		return header;
	}
	return nil;
}




#pragma mark - UICollectionViewDelegate Methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
	
	int i = 0;
	int section = 0;
	for (NSString *key in sectionsKeys) {
		BOOL canBreak = NO;
		int item = 0;
		NSArray *arr = [sections objectForKey:key];
		for (AlbumPhoto *photo in arr) {
			if (section == indexPath.section && item == indexPath.item) {
				canBreak = YES;
				break;
			}
			else {
				i++;
			}
			item ++;
		}
		section ++;
		if (canBreak) {
			break;
		}
	}
	RCLog(@"didSelectItemAtIndexPath %@ %i", indexPath, i);
	
	SVPhotoViewerController *detailController = [[SVPhotoViewerController alloc] init];
    detailController.albumId = self.albumId;
	detailController.albumManager = self.albumManager;
	detailController.photos = [NSMutableArray arrayWithArray:albumContents.photos];
	detailController.index = i;
	detailController.title = albumContents.name;
	detailController.wantsFullScreenLayout = YES;
	
	navigatingNext = YES;
    [self.navigationController pushViewController:detailController animated:YES];
	self.menuContainerViewController.panMode = MFSideMenuPanModeNone;
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

- (void)setAlbumContents:(AlbumContents *)album
{
	RCLog(@"---------------------setAlbumContents after refresh %i", album.photos.count);
    albumContents = album;
	
	((SVSidebarManagementController*)self.menuContainerViewController.leftMenuViewController).albumContents = albumContents;
	((SVSidebarMemberController*)self.menuContainerViewController.rightMenuViewController).albumContents = albumContents;
	
    self.title = albumContents.name;
	
	[self sortThumbsBy:sort];
    [self.gridView reloadData];
	[self updateEmptyState];
}
- (void)sortThumbsBy:(SortType)sortType {
	
	sort = sortType;
	[sectionsKeys removeAllObjects];
	[sections removeAllObjects];
	
	for (AlbumPhoto *photo in albumContents.photos) {
		
		NSString *key = @"Uploading now";
		
		switch (sortType) {
			case SortByDate:
			{
				if (photo.serverPhoto) {
					key = [NSDateFormatter localizedStringFromDate:photo.serverPhoto.dateAdded
														 dateStyle:NSDateFormatterLongStyle
														 timeStyle:NSDateFormatterNoStyle];
				}
			}break;
				
			case SortByAuthor:
			{
				if (photo.serverPhoto) {
					key = photo.serverPhoto.authorNickname;
				}
			}break;
		}
		
		NSMutableArray *arr = [sections objectForKey:key];
		
		if (arr == nil) {
			arr = [NSMutableArray array];
			//[sectionsKeys insertObject:key atIndex:0];
			[sectionsKeys addObject:key];
		}
		//[arr insertObject:photo atIndex:0];
		[arr addObject:photo];
		[sections setObject:arr forKey:key];
	}
	//RCLog(@"__________Keys after sorting %@", sectionsKeys);
}
- (void)switchSortHandler:(UISegmentedControl*)control {
	sort = control.selectedSegmentIndex;
	[self sortThumbsBy:sort];
	[self.gridView reloadData];
	[[NSUserDefaults standardUserDefaults] setInteger:sort forKey:@"sort_photos"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)onAlbumContentsBeginRefresh:(int64_t)albumId
{
	RCLog(@"begin refresh");
}

- (void)onAlbumContentsRefreshComplete:(int64_t)albumId albumContents:(AlbumContents *)album
{
	RCLog(@"end refresh");
	if (refreshManualy) {
		[self endRefreshing];
	}
    [self setAlbumContents:album];
}

- (void)onAlbumContentsRefreshError:(int64_t)albumId error:(NSError *)error
{
	RCLog(@"error refresh");
    [refresh endRefreshing];
	refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
	
    // TODO ...
}

- (void)onAlbumContentsPhotoUploadProgress:(int64_t)albumId
{
	// Iterate over visible cells and find the cell with the albumId
	
	for (SVAlbumGridViewCell *cell in self.gridView.visibleCells) {
		NSIndexPath *indexPath = [self.gridView indexPathForCell:cell];
		NSArray *arr = [sections objectForKey:sectionsKeys[indexPath.section]];
		AlbumPhoto *photo = [arr objectAtIndex:indexPath.item];
		
		if (photo.uploadingPhoto) {
			cell.uploadProgressView.hidden = [photo.uploadingPhoto isUploadComplete];
			cell.uploadProgressView.progress = [photo.uploadingPhoto getUploadProgress];
		}
	}
}




#pragma mark UIRefreshView

- (void)beginRefreshing
{
	refreshManualy = YES;
    [self.albumManager refreshAlbumContents:self.albumId];
	[refresh beginRefreshing];
	refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing photos..."];
}
- (void)endRefreshing
{
	refreshManualy = NO;
	[refresh endRefreshing];
	refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
}

@end
