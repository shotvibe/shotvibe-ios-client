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
#import "SVPhotoViewerController.h"
#import "SVSidebarMemberController.h"
#import "SVSidebarManagementController.h"
#import "SVSettingsViewController.h"

#import "SVCameraNavController.h"
#import "SVPickerController.h"

#import "SVCameraPickerController.h"
#import "SVImagePickerListViewController.h"
#import "SVAlbumGridViewCell.h"
#import "SVAddFriendsViewController.h"
#import "SVNavigationController.h"
#import "SL/AlbumPhoto.h"
#import "UIImageView+WebCache.h"
#import "SVAlbumGridSection.h"
#import "NSDate+Formatting.h"
#import "SVNonRotatingNavigationControllerViewController.h"
#import "SL/AlbumServerPhoto.h"
#import "SL/AlbumMember.h"
#import "SL/ArrayList.h"
#import "AlbumUploadingPhoto.h"
#import "SL/DateTime.h"

@interface SVAlbumGridViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
{
    SLAlbumContents *albumContents;
    BOOL isMenuShowing;
	BOOL refreshManualy;
	BOOL navigatingNext;
	NSMutableArray *sectionsKeys;
	NSMutableDictionary *sections;
    UIRefreshControl *refresh;
	SVCameraNavController *cameraNavController;
	SortType sort;
	
	int collection_content_offset_y;
}

@property (nonatomic, strong) MFSideMenuContainerViewController *sideMenu;
@property (nonatomic, strong) IBOutlet UIView *collectionViewContainer;
@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) IBOutlet UIView *headerViewContainer;
@property (nonatomic, strong) IBOutlet UIView *noPhotosView;
//@property (nonatomic, strong) IBOutlet UIButton *butTakeVideo;
@property (nonatomic, strong) IBOutlet UIButton *butTakePicture;
//@property (nonatomic, strong) IBOutlet UIButton *butTakeVideo2;
@property (nonatomic, strong) IBOutlet UIButton *butTakePicture2;
@property (nonatomic, strong) IBOutlet UIView *switchView;
@property (nonatomic, strong) IBOutlet UISegmentedControl *switchSort;

@property (nonatomic, strong) UIImage *userPicture;
@property (nonatomic, strong) NSString *userNickName;

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
	
	NSAssert(self.albumId, @"SVAlbumGridViewController can't be initialized without albumId");
	
	self.collectionView.alwaysBounceVertical = YES;
	//self.collectionView.contentInset = UIEdgeInsetsMake(44, 0, 0, 0);
	
	sections = [[NSMutableDictionary alloc] init];
	sectionsKeys = [[NSMutableArray alloc] init];
	sort = [[NSUserDefaults standardUserDefaults] integerForKey:@"sort_photos"];
	
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		self.butTakePicture.enabled = NO;
		self.butTakePicture2.enabled = NO;
//		self.butTakeVideo.enabled = NO;
//		self.butTakeVideo2.enabled = NO;
	}
    
    // Setup tabbar right button
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"userIcon.png"]
																   style:UIBarButtonItemStyleBordered
																  target:self
																  action:@selector(toggleMenu)];
    self.navigationItem.rightBarButtonItem = menuButton;
	
	
    // Setup back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(backButtonPressed:)];
    NSDictionary *att = @{UITextAttributeFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:16.0], UITextAttributeTextShadowColor:[UIColor clearColor]};
	[backButton setTitleTextAttributes:att forState:UIControlStateNormal];
	[backButton setTitlePositionAdjustment:UIOffsetMake(15,0) forBarMetrics:UIBarMetricsDefault];
	self.navigationItem.backBarButtonItem = backButton;
	
	// CollectionView
	[self.collectionView registerClass:[SVAlbumGridSection class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"SVAlbumGridSection"];
	[self.collectionView addSubview:self.switchView];
	
	self.switchView.frame = CGRectMake(0, 0, 320, 45);
	self.switchSort.frame = CGRectMake(50, 10, 220, 30);
	[self.switchSort addTarget:self action:@selector(switchSortHandler:) forControlEvents:UIControlEventValueChanged];
	self.switchSort.selectedSegmentIndex = sort;
	
	//UICollectionViewFlowLayout *flow = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
	//[flow setSectionInset:UIEdgeInsetsMake(45, 0, 0, 0)];
	
	((SVSidebarManagementController*)self.menuContainerViewController.leftMenuViewController).parentController = self;
	((SVSidebarMemberController*)self.menuContainerViewController.rightMenuViewController).parentController = self;
	
    SLAlbumContents *contents = [self.albumManager addAlbumContentsListener:self.albumId listener:self];
	[self setAlbumContents:contents];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
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
		if (!IS_IOS7) refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
		[refresh addTarget:self action:@selector(beginRefreshing) forControlEvents:UIControlEventValueChanged];
		[self.collectionView addSubview:refresh];
		
		// Remove the previous controller from the stack if it's SVCameraPickerController
		NSMutableArray *allViewControllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
		id lastController = allViewControllers[allViewControllers.count-2];
		if ([lastController isKindOfClass:[SVCameraPickerController class]])
			[allViewControllers removeObject:lastController];
		self.navigationController.viewControllers = allViewControllers;
	}
	if (self.scrollToBottom) {
		self.scrollToBottom = NO;
		RCLogSize(self.collectionView.contentSize);
		RCLogRect(self.collectionView.bounds);
		[self.collectionView scrollRectToVisible:CGRectMake(0,
													  self.collectionView.contentSize.height - self.collectionView.bounds.size.height,
													  self.collectionView.bounds.size.width,
													  self.collectionView.bounds.size.height)
								  animated:NO];
	}
	else if (self.scrollToTop) {
		self.scrollToTop = NO;
		[self.collectionView scrollRectToVisible:CGRectMake(0, -15,
															self.collectionView.bounds.size.width,
															self.collectionView.bounds.size.height)
										animated:NO];
	}
	
	self.menuContainerViewController.panMode = MFSideMenuPanModeCenterViewController;
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    [self.albumManager markAlbumAsViewed:albumContents];

	if (!navigatingNext) {
		
		[self.albumManager removeAlbumContentsListener:self.albumId listener:self];
		albumContents = nil;
		
		RCLog(@"clean everything");
		self.albumManager = nil;
		((SVSidebarManagementController*)self.menuContainerViewController.leftMenuViewController).parentController = nil;
		((SVSidebarMemberController*)self.menuContainerViewController.rightMenuViewController).parentController = nil;
		self.sideMenu = nil;
		self.collectionViewContainer = nil;
		self.collectionView = nil;
		self.noPhotosView = nil;
//		self.butTakeVideo = nil;
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

//- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
//	
//	if (IS_IOS7) {
//		if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
//			self.headerViewContainer.frame = CGRectMake(0, 57, 320, 45);
//		}
//		else {
//			self.headerViewContainer.frame = CGRectMake(0, 64, 320, 45);
//		}
//	}
//}


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
	//self.scrollToBottom = YES;
	self.scrollToTop = YES;
	
    SVPickerController *manager = [[SVPickerController alloc] init];
    manager.albumManager = self.albumManager;
    manager.albumId = self.albumId;

    SVNonRotatingNavigationControllerViewController *nc = [[SVNonRotatingNavigationControllerViewController alloc] initWithRootViewController:manager];
    [self presentViewController:nc animated:NO completion:nil];

//	cameraNavController = [[SVCameraNavController alloc] init];
//	cameraNavController.cameraDelegate = self;
//	cameraNavController.albumId = self.albumId;
//	cameraNavController.albumManager = self.albumManager;
//    cameraNavController.nav = (SVNavigationController*)self.navigationController;// this is set last
}

- (void)backButtonPressed:(id)sender
{
    // TODO: apparently this method is not called when pressing Back
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	navigatingNext = YES;

    if ([segue.identifier isEqualToString:@"ImagePickerSegue"]) {
		
        SVNavigationController *destinationNavigationController = (SVNavigationController *)segue.destinationViewController;
        
        SVImagePickerListViewController *destination = [destinationNavigationController.viewControllers objectAtIndex:0];
        destination.albumId = self.albumId;
        destination.albumManager = self.albumManager;
		//self.scrollToBottom = YES;
		self.scrollToTop = YES;
    }
	else if ([segue.identifier isEqualToString:@"AddFriendsSegue"]) {
        // TODO: Not called when going to AddFriends
		SVNavigationController *destinationNavigationController = (SVNavigationController *)segue.destinationViewController;
        SVAddFriendsViewController *destination = [destinationNavigationController.viewControllers objectAtIndex:0];
        destination.albumManager = self.albumManager;
		destination.albumId = self.albumId;
    }
}




- (void) updateEmptyState
{
    if ([albumContents getPhotos].array.count == 0) {
		[self.collectionView addSubview:self.noPhotosView];
		self.switchView.hidden = YES;
	}
	else if ([self.noPhotosView isDescendantOfView:self.collectionView] || [self.noPhotosView isDescendantOfView:self.view]) {
		[self.noPhotosView removeFromSuperview];
		self.switchView.hidden = NO;
	}
}



#pragma mark camera delegate

- (void)cameraExit
{
    //cameraNavController = nil;
	self.scrollToBottom = NO;
	self.scrollToTop = NO;
}


- (void)cameraWasDismissedWithAlbum:(SLAlbumSummary *)selectedAlbum
{
	
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

    SLAlbumPhoto *photo = [arr objectAtIndex:indexPath.row];

    if ([photo getServerPhoto]) {
        [cell.networkImageView setPhoto:[[photo getServerPhoto] getId]
                               photoUrl:[[photo getServerPhoto] getUrl]
                              photoSize:[PhotoSize Thumb75]
                                manager:self.albumManager.photoFilesManager];
        cell.uploadProgressView.hidden = YES;

        //RCLog(@"cellForItemAtPath url:%@ added:%@ access:%@", photo.serverPhoto.url, photo.serverPhoto.dateAdded, photo.serverPhoto.lastAccess);

        cell.labelNewView.hidden = ![[photo getServerPhoto] isNewWithSLDateTime:[albumContents getLastAccess]
                                                                       withLong:self.albumManager.getShotVibeAPI.authData.userId];
    } else if ([photo getUploadingPhoto]) {
        AlbumUploadingPhoto *uploadingPhoto = (AlbumUploadingPhoto *)[photo getUploadingPhoto];

        [cell.networkImageView setImage:[uploadingPhoto getThumbnail]];

        cell.uploadProgressView.hidden = [uploadingPhoto isUploadComplete];
        [cell.uploadProgressView setProgress:[uploadingPhoto getUploadProgress] animated:NO];

        cell.labelNewView.hidden = YES;
    }

    return cell;
}


// Section headers

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath
{
    if (kind == UICollectionElementKindSectionHeader) {
        SVAlbumGridSection *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                        withReuseIdentifier:@"SVAlbumGridSection"
                                                                               forIndexPath:indexPath];

        // Modify the header
        [header setType:sort section:indexPath.section];

        header.dateButtonLabel.backgroundColor = [UIColor clearColor];
        header.nameLabel.backgroundColor = [UIColor clearColor];

        switch (sort) {
            case SortFeedAlike: {
                NSArray *arr = [sectionsKeys[indexPath.section] componentsSeparatedByString:@"--^--"];
                NSString *key = [NSString stringWithFormat:@" %@", [arr objectAtIndex:0]];

                [header.dateButtonLabel setTitle:key forState:UIControlStateNormal];
                break;
            }

            case SortByDate:
                header.nameLabel.text = sectionsKeys[indexPath.section];
                break;

            case SortByUser:

                break;
        }

        if (sort == SortByUser || sort == SortFeedAlike) {
            NSArray *arr = [sections objectForKey:sectionsKeys[indexPath.section]];
            SLAlbumPhoto *photo = [arr objectAtIndex:indexPath.row];

            ShotVibeAPI *shotvibeAPI = [self.albumManager getShotVibeAPI];

            if ([photo getServerPhoto]) {
                //Search through the members
                for (SLAlbumMember *member in [albumContents getMembers].array) {
                    if ([[[photo getServerPhoto] getAuthor] getMemberId] == [[member getUser] getMemberId]) {
                        [header.imageView setImageWithURL:[[NSURL alloc] initWithString:[[member getUser] getMemberAvatarUrl]] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                            if ([[member getUser] getMemberId] == shotvibeAPI.authData.userId) {
                                self.userPicture = image;
                                self.userNickName = [[member getUser] getMemberNickname];
                            }
                        }];
                        header.nameLabel.text = [[member getUser] getMemberNickname];
                        break;
                    }
                }
            } else {
                int64_t userId = shotvibeAPI.authData.userId;

                header.nameLabel.text = self.userNickName;
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    NSError *error;
                    SLAlbumUser *userProfile = [shotvibeAPI getUserProfile:userId withError:&error];

                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (userProfile) {
                            header.nameLabel.text = [userProfile getMemberNickname];
                            self.userNickName = [userProfile getMemberNickname];
                            [header.imageView setImageWithURL:[NSURL URLWithString:[userProfile getMemberAvatarUrl]] placeholderImage:self.userPicture completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                self.userPicture = image;
                            }];
                        }
                    }


                                   );
                }


                               );
            }
        }

        return header;
    }
    return nil;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
						layout:(UICollectionViewLayout*)collectionViewLayout
		insetForSectionAtIndex:(NSInteger)section
{
	if (section == 0) return UIEdgeInsetsMake(45, 5, 5, 5);
	return UIEdgeInsetsMake(5, 5, 5, 5);
}



#pragma mark - UICollectionViewDelegate Methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
	
    NSMutableArray *photos = [NSMutableArray arrayWithCapacity:[albumContents getPhotos].array.count];
	int i = 0;
	int section = 0;
	BOOL found = NO;
	
	// Iterate over sections
	for (NSString *key in sectionsKeys) {
		int item = 0;
		NSArray *arr = [sections objectForKey:key];
		
		// Iterate over photos in section
        for (SLAlbumPhoto *photo in arr) {
			if (section == indexPath.section && item == indexPath.item) {
				found = YES;
			}
			else {
				if (!found) i++;
			}
			item ++;
			[photos addObject:photo];
		}
		section ++;
	}
	
	SVPhotoViewerController *detailController = [[SVPhotoViewerController alloc] init];
    detailController.albumId = self.albumId;
	detailController.photos = photos;
    detailController.albumManager = self.albumManager;
	detailController.index = i;
    detailController.title = [albumContents getName];
	
    navigatingNext = YES;
    [self.navigationController pushViewController:detailController animated:YES];
	self.menuContainerViewController.panMode = MFSideMenuPanModeNone;
}


#pragma mark - Private Methods

- (void)toggleMenu
{
	[(SVSidebarMemberController*)self.menuContainerViewController.rightMenuViewController resignFirstResponder];
    [self.menuContainerViewController toggleRightSideMenuCompletion:^{
		
	}];
}

- (void)toggleManagement
{
    [self.menuContainerViewController toggleLeftSideMenuCompletion:^{
		
	}];
}

- (void)setAlbumContents:(SLAlbumContents *)album
{
    albumContents = album;
	
	((SVSidebarManagementController*)self.menuContainerViewController.leftMenuViewController).albumContents = albumContents;
	((SVSidebarMemberController*)self.menuContainerViewController.rightMenuViewController).albumContents = albumContents;
	
    self.title = [albumContents getName];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // First set all the fullscreen photos to download at high priority
        for (SLAlbumPhoto *p in [albumContents getPhotos]) {
            if ([p getServerPhoto]) {
                [self.albumManager.photoFilesManager queuePhotoDownload:[[p getServerPhoto] getId]
                                                               photoUrl:[[p getServerPhoto] getUrl]
                                                              photoSize:self.albumManager.photoFilesManager.DeviceDisplayPhotoSize
                                                           highPriority:YES];
            }
        }

        // Now set all the thumbnails to download at high priority, these will now be pushed to download before all of the previously queued fullscreen photos
        for (SLAlbumPhoto *p in [albumContents getPhotos].array) {
            if ([p getServerPhoto]) {
                [self.albumManager.photoFilesManager queuePhotoDownload:[[p getServerPhoto] getId]
                                                               photoUrl:[[p getServerPhoto] getUrl]
                                                              photoSize:[PhotoSize Thumb75]
                                                           highPriority:YES];
            }
        }
    });

	[self sortThumbsBy:sort];
    [self.collectionView reloadData];
	[self updateEmptyState];
}


#pragma mark Sorting

- (void)sortThumbsBy:(SortType)sortType {
	
	sort = sortType;
	[sectionsKeys removeAllObjects];
	[sections removeAllObjects];
	
	// This are used by the feed alike sorting
	NSDate *previousDate = nil;
	NSString *previousUser = nil;
	
    for (SLAlbumPhoto *photo in [albumContents getPhotos].array) {
		
		NSString *key = @"Uploading now";
		
        if ([photo getServerPhoto]) {
            long long seconds = [[[photo getServerPhoto] getDateAdded] getTimeStamp] / 1000000LL;
            NSDate *photoDateAdded = [[NSDate alloc] initWithTimeIntervalSince1970:seconds];

            switch (sortType) {
                case SortFeedAlike:
                    if (previousDate == nil) {
                        previousDate = photoDateAdded;
                    }
                    if (previousUser == nil) {
                        previousUser = [[[photo getServerPhoto] getAuthor] getMemberNickname];
                    }

                    if ([photoDateAdded timeIntervalSinceDate:previousDate] < 60 &&
                        [[[[photo getServerPhoto] getAuthor] getMemberNickname] isEqualToString:previousUser]) {
                        key = [NSString stringWithFormat:@"%@--^--%@", [previousDate distanceOfTimeInWords:[NSDate date] shortStyle:YES], previousUser];
                    } else {
                        key = [NSString stringWithFormat:@"%@--^--%@", [photoDateAdded distanceOfTimeInWords:[NSDate date] shortStyle:YES], [[[photo getServerPhoto] getAuthor] getMemberNickname]];
                    }

                    previousDate = photoDateAdded;
                    previousUser = [[[photo getServerPhoto] getAuthor] getMemberNickname];
                    break;

                case SortByUser:
                    key = [[[photo getServerPhoto] getAuthor] getMemberNickname];
                    break;

                case SortByDate:
                    key = [NSDateFormatter localizedStringFromDate:photoDateAdded
                                                         dateStyle:NSDateFormatterLongStyle
                                                         timeStyle:NSDateFormatterNoStyle];
                    break;
            }
		}
		
		NSMutableArray *arr = [sections objectForKey:key];
		
		if (arr == nil) {
			arr = [NSMutableArray array];
			if ([key isEqualToString:@"Uploading now"] && sortType != SortByUser) {
				[sectionsKeys addObject:key];
			}
			else {
				[sectionsKeys insertObject:key atIndex:0];
			}
		}
		//[arr insertObject:photo atIndex:0];
		[arr addObject:photo];
		[sections setObject:arr forKey:key];
	}
	
	// Move 'Uploading now' key to top
	NSString *lastKey = [sectionsKeys lastObject];
	if ([lastKey isEqualToString:@"Uploading now"] && sortType != SortByUser) {
		[sectionsKeys removeObject:lastKey];
		[sectionsKeys insertObject:lastKey atIndex:0];
	}
}

- (void)switchSortHandler:(UISegmentedControl*)control {
	sort = control.selectedSegmentIndex;
	[self sortThumbsBy:sort];
	[self.collectionView reloadData];
	[[NSUserDefaults standardUserDefaults] setInteger:sort forKey:@"sort_photos"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)onAlbumContentsBeginRefresh:(int64_t)albumId {
	
}

- (void)onAlbumContentsRefreshComplete:(int64_t)albumId albumContents:(SLAlbumContents *)album
{
	if (refreshManualy) {
		[self endRefreshing];
	}
    [self setAlbumContents:album];
}

- (void)onAlbumContentsRefreshError:(int64_t)albumId error:(SLAPIException *)error
{
    [refresh endRefreshing];
	if (!IS_IOS7) refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
}

- (void)onAlbumContentsPhotoUploadProgress:(int64_t)albumId {
	
	// Iterate over visible cells and find the cell with the albumId
	
	for (SVAlbumGridViewCell *cell in self.collectionView.visibleCells) {
		NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
		NSArray *arr = [sections objectForKey:sectionsKeys[indexPath.section]];
        SLAlbumPhoto *photo = [arr objectAtIndex:indexPath.item];

        if ([photo getUploadingPhoto]) {
            AlbumUploadingPhoto *uploadingPhoto = (AlbumUploadingPhoto *)[photo getUploadingPhoto];
            cell.uploadProgressView.hidden = [uploadingPhoto isUploadComplete];
            cell.uploadProgressView.progress = [uploadingPhoto getUploadProgress];
            cell.fancyUploadProgressView.hidden = [uploadingPhoto isUploadComplete];
            cell.fancyUploadProgressView.progress = [uploadingPhoto getUploadProgress];
		}
	}
}




#pragma mark UIRefreshView

- (void)beginRefreshing {
	refreshManualy = YES;
    [self.albumManager refreshAlbumContents:self.albumId];
	[refresh beginRefreshing];
	if (!IS_IOS7) refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing photos..."];
}
- (void)endRefreshing {
	refreshManualy = NO;
	[refresh endRefreshing];
	if (!IS_IOS7) refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
}

@end
