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

#import "ShotVibeAppDelegate.h"

#import "SVCameraNavController.h"
#import "SVPickerController.h"
#import "SVAlbumListViewController.h"

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
#import "SL/AlbumUser.h"
#import "SL/ArrayList.h"
#import "AlbumUploadingPhoto.h"
#import "SL/DateTime.h"
#import "SL/AuthData.h"
#import "SL/ShotVibeAPI.h"
#import "SVInitialization.h"
#import "ShotVibeAPITask.h"
#import "ImageDiskCache.h"

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

@property (nonatomic, strong) UIView *sheetView;

- (void)toggleMenu;
- (void)toggleManagement;
- (IBAction)takeVideoPressed:(id)sender;
- (IBAction)takePicturePressed:(id)sender;

@end

@implementation SVAlbumGridViewController
{
    SLAlbumManager *albumManager_;
    PhotoFilesManager *photoFilesManager_;

    // TODO Should use a global ImageDiskCache
    ImageDiskCache *imageDiskCache_;
}


static NSString *const kCellReuseIdentifier = @"SVAlbumGridViewCell"; // registered in the storyboard
static NSString *const kSectionReuseIdentifier = @"SVAlbumGridViewSection";


#pragma mark - UIViewController Methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSLog(@"SVAlbumGridViewController %@: viewDidLoad", self);

    NSAssert(self.albumId, @"SVAlbumGridViewController can't be initialized without albumId");

    photoFilesManager_ = [ShotVibeAppDelegate sharedDelegate].photoFilesManager;

    albumManager_ = [ShotVibeAppDelegate sharedDelegate].albumManager;

    imageDiskCache_ = [[ImageDiskCache alloc] initWithRefreshHandler:^{
        [self.collectionView reloadData];
    }];

    [[Mixpanel sharedInstance] track:@"Album Viewed"
                          properties:@{ @"album_id" : [NSString stringWithFormat:@"%lld", self.albumId] }];

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

    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 68, 40)];

    UIButton *sortButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [sortButton addTarget:self action:@selector(sortBy:) forControlEvents:UIControlEventTouchUpInside];
    [sortButton setImage:[UIImage imageNamed:@"MoreButton"] forState:UIControlStateNormal];
    sortButton.frame = CGRectMake(0, 2, 28, 40);
    [v addSubview:sortButton];

    UIButton *menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [menuButton addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [menuButton setImage:[UIImage imageNamed:@"FriendsButton"] forState:UIControlStateNormal];
    menuButton.frame = CGRectMake(35, 2, 33, 30);
    [v addSubview:menuButton];

//    UIBarButtonItem *sortButton = [[UIBarButtonItem alloc] initWithImage:[imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
//																   style:UIBarButtonItemStylePlain
//																  target:self
//																  action:@selector(sortBy)];
//    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"FriendsButton"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
//																   style:UIBarButtonItemStylePlain
//																  target:self
//																  action:@selector(toggleMenu)];
//    self.navigationItem.rightBarButtonItems = @[menuButton,sortButton];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:v];

    // Setup back button
//    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(backButtonPressed:)];
//    NSDictionary *att = @{UITextAttributeFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:16.0], UITextAttributeTextShadowColor:[UIColor clearColor]};
//	[backButton setTitleTextAttributes:att forState:UIControlStateNormal];
//	[backButton setTitlePositionAdjustment:UIOffsetMake(15,0) forBarMetrics:UIBarMetricsDefault];
//	self.navigationItem.backBarButtonItem = backButton;

    // CollectionView
    [self.collectionView registerClass:[SVAlbumGridSection class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kSectionReuseIdentifier];
    [self.collectionView addSubview:self.switchView];

    self.switchView.frame = CGRectMake(0, 0, 320, 45);
    self.switchSort.frame = CGRectMake(50, 10, 220, 30);
    [self.switchSort addTarget:self action:@selector(switchSortHandler:) forControlEvents:UIControlEventValueChanged];
    self.switchSort.selectedSegmentIndex = sort;

    //UICollectionViewFlowLayout *flow = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    //[flow setSectionInset:UIEdgeInsetsMake(45, 0, 0, 0)];

    ((SVSidebarManagementController *)self.menuContainerViewController.leftMenuViewController).parentController = self;
    ((SVSidebarMemberController *)self.menuContainerViewController.rightMenuViewController).parentController = self;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSLog(@"SVAlbumGridViewController %@: viewWillAppear: %d", self, animated);

    SLAlbumContents *contents = [albumManager_ addAlbumContentsListenerWithLong:self.albumId withSLAlbumManager_AlbumContentsListener:self];
    [self setAlbumContents:contents];

    [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"SVAlbumGridViewController: viewDidAppear: %d", animated);

    if (refresh == nil) {
        refresh = [[UIRefreshControl alloc] init];
        if (!IS_IOS7) {
            refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
        }
        [refresh addTarget:self action:@selector(onUserRefreshed) forControlEvents:UIControlEventValueChanged];
        [self.collectionView addSubview:refresh];

        // Remove the previous controller from the stack if it's SVCameraPickerController
        NSMutableArray *allViewControllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
        id lastController = allViewControllers[allViewControllers.count - 2];
        if ([lastController isKindOfClass:[SVCameraPickerController class]]) {
            [allViewControllers removeObject:lastController];
        }
        self.navigationController.viewControllers = allViewControllers;
    }
    if (self.scrollToBottom) {
        self.scrollToBottom = NO;
        [self.collectionView scrollRectToVisible:CGRectMake(0,
                                                            self.collectionView.contentSize.height - self.collectionView.bounds.size.height,
                                                            self.collectionView.bounds.size.width,
                                                            self.collectionView.bounds.size.height)
                                        animated:NO];
    } else if (self.scrollToTop) {
        self.scrollToTop = NO;
        [self.collectionView scrollRectToVisible:CGRectMake(0, -15,
                                                            self.collectionView.bounds.size.width,
                                                            self.collectionView.bounds.size.height)
                                        animated:NO];
    }

    self.menuContainerViewController.panMode = MFSideMenuPanModeCenterViewController;
}


- (void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"SVAlbumGridViewController %@: viewWillDisappear: %d", self, animated);
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    NSLog(@"SVAlbumGridViewController %@: viewDidDisappear: %d", self, animated);

    [self clearNewPhotoBadges:albumContents];

    [albumManager_ removeAlbumContentsListenerWithLong:self.albumId withSLAlbumManager_AlbumContentsListener:self];

    if (!navigatingNext) {
        ((SVSidebarManagementController *)self.menuContainerViewController.leftMenuViewController).parentController = nil;
        ((SVSidebarMemberController *)self.menuContainerViewController.rightMenuViewController).parentController = nil;
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


- (void)dealloc
{
    RCLog(@"dealloc SVAlbumGridViewController %lli", self.albumId);
}


#pragma mark Rotation

- (BOOL)shouldAutorotate
{
    return NO;
}


- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
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
    [[Mixpanel sharedInstance] track:@"Add Photo from Camera Pressed"
                          properties:@{ @"album_id" : [NSString stringWithFormat:@"%lld", self.albumId] }];

    navigatingNext = YES;
    //self.scrollToBottom = YES;
    self.scrollToTop = YES;

    SVPickerController *manager = [[SVPickerController alloc] init];
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
        [[Mixpanel sharedInstance] track:@"Add Photo from Gallery Pressed"
                              properties:@{ @"album_id" : [NSString stringWithFormat:@"%lld", self.albumId] }];

        SVNavigationController *destinationNavigationController = (SVNavigationController *)segue.destinationViewController;

        SVImagePickerListViewController *destination = [destinationNavigationController.viewControllers objectAtIndex:0];
        destination.albumId = self.albumId;
        //self.scrollToBottom = YES;
        self.scrollToTop = YES;
    } else if ([segue.identifier isEqualToString:@"AddFriendsSegue"]) {
        // TODO: Not called when going to AddFriends
        SVNavigationController *destinationNavigationController = (SVNavigationController *)segue.destinationViewController;
        SVAddFriendsViewController *destination = [destinationNavigationController.viewControllers objectAtIndex:0];
        destination.albumId = self.albumId;
    }
}


- (void)updateEmptyState
{
    if ([albumContents getPhotos].array.count == 0) {
        [self.collectionView addSubview:self.noPhotosView];
        self.switchView.hidden = YES;
    } else if ([self.noPhotosView isDescendantOfView:self.collectionView] || [self.noPhotosView isDescendantOfView:self.view]) {
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
    SVAlbumGridViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellReuseIdentifier forIndexPath:indexPath];

    //RCLog(@"Dequeued cell: %@", cell);
    __block NSArray *arr = [sections objectForKey:sectionsKeys[indexPath.section]];

    [cell.networkImageView setImage:nil];

    SLAlbumPhoto *photo = [arr objectAtIndex:indexPath.row];

    [cell.uploadingOriginalView setHidden:YES];

    if ([photo getServerPhoto]) {
        if ([[photo getServerPhoto] getUploadingOriginal]) {
            [cell.uploadingOriginalView setHidden:NO];
        }

        [cell.networkImageView setPhoto:[[photo getServerPhoto] getId]
                               photoUrl:[[photo getServerPhoto] getUrl]
                              photoSize:[PhotoSize Thumb75]
                                manager:photoFilesManager_];
        cell.uploadProgressView.hidden = YES;

        [cell.activityView stopAnimating];

        //RCLog(@"cellForItemAtPath url:%@ added:%@ access:%@", photo.serverPhoto.url, photo.serverPhoto.dateAdded, photo.serverPhoto.lastAccess);

        if ([[photo getServerPhoto] isNewWithSLDateTime:[albumContents getLastAccess]
                                               withLong:[[[albumManager_ getShotVibeAPI] getAuthData] getUserId]]) {
            NSString *org = [SVAlbumListViewController getAlbumOrg:albumContents];
            if (org) {
                cell.labelNewView.hidden = YES;
                cell.albumOrgNewOverlay.hidden = NO;
                cell.albumOrgNewOverlay.image = [UIImage imageNamed:[org stringByAppendingString:@"_new"]];
            } else {
                cell.labelNewView.hidden = NO;
                cell.albumOrgNewOverlay.hidden = YES;
            }
        } else {
            cell.labelNewView.hidden = YES;
            cell.albumOrgNewOverlay.hidden = YES;
        }
    } else if ([photo getUploadingPhoto]) {
        SLAlbumUploadingPhoto *uploadingPhoto = [photo getUploadingPhoto];

        if ([uploadingPhoto getState] == [SLAlbumUploadingPhoto_StateEnum Saving]) {
            [cell.networkImageView setImage:nil];
        } else if ([uploadingPhoto getState] == [SLAlbumUploadingPhoto_StateEnum PreparingFiles]) {
            [cell.networkImageView setImage:[UIImage imageNamed:@"camera"]];
        } else {
            UIImage *thumb = [imageDiskCache_ getImage:[uploadingPhoto getBitmapThumbPath]];
            [cell.networkImageView setImage:thumb];
        }


        if ([uploadingPhoto getState] == [SLAlbumUploadingPhoto_StateEnum Saving] ||
            [uploadingPhoto getState] == [SLAlbumUploadingPhoto_StateEnum PreparingFiles]) {
            [cell.activityView startAnimating];

            cell.uploadProgressView.hidden = YES;
        } else if ([uploadingPhoto getState] == [SLAlbumUploadingPhoto_StateEnum Uploading]) {
            double progress = [uploadingPhoto getUploadProgress];
            if (progress > 0.0) {
                [cell.activityView stopAnimating];

                cell.uploadProgressView.hidden = NO;
                cell.uploadProgressView.progressTintColor = [UIColor blueColor];
                [cell.uploadProgressView setProgress:progress animated:NO];
            } else {
                [cell.activityView startAnimating];

                cell.uploadProgressView.hidden = YES;
            }
        } else if ([uploadingPhoto getState] == [SLAlbumUploadingPhoto_StateEnum Uploaded]) {
            [cell.activityView stopAnimating];

            cell.uploadProgressView.hidden = NO;
            cell.uploadProgressView.progressTintColor = [UIColor greenColor];
            [cell.uploadProgressView setProgress:1.0 animated:NO];
        } else if ([uploadingPhoto getState] == [SLAlbumUploadingPhoto_StateEnum AddingToAlbum]) {
            [cell.activityView stopAnimating];

            cell.uploadProgressView.hidden = NO;
            cell.uploadProgressView.progressTintColor = [UIColor whiteColor];
            [cell.uploadProgressView setProgress:1.0 animated:NO];
        }

        cell.labelNewView.hidden = YES;
        cell.albumOrgNewOverlay.hidden = YES;
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
                                                                        withReuseIdentifier:kSectionReuseIdentifier
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

            SLShotVibeAPI *shotvibeAPI = [albumManager_ getShotVibeAPI];

            if ([photo getServerPhoto]) {
                //Search through the members
                for (SLAlbumMember *member in [albumContents getMembers].array) {
                    if ([[[photo getServerPhoto] getAuthor] getMemberId] == [[member getUser] getMemberId]) {
                        [header.imageView setImageWithURL:[[NSURL alloc] initWithString:[[member getUser] getMemberAvatarUrl]] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                            if ([[member getUser] getMemberId] == [[shotvibeAPI getAuthData] getUserId]) {
                                self.userPicture = image;
                                self.userNickName = [[member getUser] getMemberNickname];
                            }
                        }


                        ];
                        header.nameLabel.text = [[member getUser] getMemberNickname];
                        break;
                    }
                }
            } else {
                int64_t userId = [[shotvibeAPI getAuthData] getUserId];

                header.nameLabel.text = self.userNickName;
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    SLAlbumUser *userProfile = nil;
                    @try {
                        userProfile = [shotvibeAPI getUserProfileWithLong:userId];
                    } @catch (SLAPIException *exception) {
                        // Ignore...
                    }

                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (userProfile) {
                            header.nameLabel.text = [userProfile getMemberNickname];
                            self.userNickName = [userProfile getMemberNickname];
                            [header.imageView setImageWithURL:[NSURL URLWithString:[userProfile getMemberAvatarUrl]] placeholderImage:self.userPicture completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                self.userPicture = image;
                            }


                            ];
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
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
    //if (section == 0) return UIEdgeInsetsMake(5, 5, 5, 5);
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
            } else {
                if (!found) {
                    i++;
                }
            }
            item++;
            [photos addObject:photo];
        }
        section++;
    }

    SVPhotoViewerController *detailController = [[SVPhotoViewerController alloc] init];
    detailController.albumId = self.albumId;
    detailController.photos = photos;
    detailController.index = i;
    detailController.title = [albumContents getName];

    navigatingNext = YES;
    [self.navigationController pushViewController:detailController animated:YES];
    self.menuContainerViewController.panMode = MFSideMenuPanModeNone;
}


#pragma mark - Private Methods

- (void)onAlbumContentsUploadsProgressedWithLong:(long long int)albumId
{
    [self.collectionView reloadData];
}


- (void)toggleMenu
{
    [(SVSidebarMemberController *)self.menuContainerViewController.rightMenuViewController resignFirstResponder];
    [self.menuContainerViewController toggleRightSideMenuCompletion:^{
    }


    ];
}


- (void)toggleManagement
{
    [self.menuContainerViewController toggleLeftSideMenuCompletion:^{
    }


    ];
}


- (void)setAlbumContents:(SLAlbumContents *)album
{
    albumContents = album;

    ((SVSidebarManagementController *)self.menuContainerViewController.leftMenuViewController).albumContents = albumContents;
    ((SVSidebarMemberController *)self.menuContainerViewController.rightMenuViewController).albumContents = albumContents;

    self.title = [albumContents getName];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // First set all the fullscreen photos to download at high priority
        for (SLAlbumPhoto *p in [albumContents getPhotos]) {
            if ([p getServerPhoto]) {
                [photoFilesManager_ queuePhotoDownload:[[p getServerPhoto] getId]
                                              photoUrl:[[p getServerPhoto] getUrl]
                                             photoSize:photoFilesManager_.DeviceDisplayPhotoSize
                                          highPriority:YES];
            }
        }

        // Now set all the thumbnails to download at high priority, these will now be pushed to download before all of the previously queued fullscreen photos
        for (SLAlbumPhoto *p in [albumContents getPhotos].array) {
            if ([p getServerPhoto]) {
                [photoFilesManager_ queuePhotoDownload:[[p getServerPhoto] getId]
                                              photoUrl:[[p getServerPhoto] getUrl]
                                             photoSize:[PhotoSize Thumb75]
                                          highPriority:YES];
            }
        }
    }


                   );

    [self sortThumbsBy:sort];
    [self.collectionView reloadData];
    [self updateEmptyState];
}


#pragma mark Sorting

// TODO: messy code with silly name
// NOTE: after calling sortThumbsBy, make sure to call [self.collectionView reloadData]
- (void)sortThumbsBy:(SortType)sortType
{
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
            } else {
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


static const int SHEETVIEW_MENU_NUM_ITEMS = 4;


- (void)sortBy:(id)sender
{
//    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Feed",@"User",@"Date", nil];
//
//    [actionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];


    UIButton * (^ addButton)(int) = ^UIButton *(int pos) {
        UIButton *but = [UIButton buttonWithType:UIButtonTypeCustom];
        but.frame = CGRectMake(0, 40 * pos, 320, 40);
        [but setTitleColor:[UIColor colorWithRed:26.0 / 255.0 green:97.0 / 255.0 blue:211.0 / 255.0 alpha:1] forState:UIControlStateNormal];
        but.imageEdgeInsets = UIEdgeInsetsMake(0, -164, 0, 0);
        but.titleEdgeInsets = UIEdgeInsetsMake(0, -134, 0, 0);
        [self.sheetView addSubview:but];
        return but;
    };

    void (^ addLine)(int) = ^void (int pos) {
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(47, 39 + 40 * pos, 320, .5)];
        line.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
        [self.sheetView addSubview:line];
    };

    void (^ addBottomBorder)(int) = ^void (int pos) {
        UIImageView *border = [[UIImageView alloc] initWithFrame:CGRectMake(0, 39.5 + 40 * pos, 320, .5)];
        UIImage *black = [SVInitialization imageWithColor:[UIColor lightGrayColor]];
        border.image = black;
        [self.sheetView addSubview:border];
    };

    if (!self.sheetView) {
        self.sheetView = [[UIView alloc] initWithFrame:CGRectMake(0, -(40 * SHEETVIEW_MENU_NUM_ITEMS), 320, [UIScreen mainScreen].bounds.size.height)];

        UIView *innerSheetView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40 * SHEETVIEW_MENU_NUM_ITEMS)];
        innerSheetView.backgroundColor = [UIColor colorWithWhite:.95 alpha:1];
        [self.sheetView addSubview:innerSheetView];

        UIButton *changeName = addButton(0);
        [changeName addTarget:self action:@selector(albumChangeNamePressed:) forControlEvents:UIControlEventTouchUpInside];
        [changeName setTitle:@"Change Album Name" forState:UIControlStateNormal];
        addLine(0);

        UIButton *feed = addButton(1);
        [feed addTarget:self action:@selector(sortByType:) forControlEvents:UIControlEventTouchUpInside];
        [feed setTitle:@"Sort by Feed" forState:UIControlStateNormal];
        [feed setImage:[UIImage imageNamed:@"sortType1"] forState:UIControlStateNormal];
        feed.tag = 1;
        addLine(1);

        UIButton *user = addButton(2);
        [user addTarget:self action:@selector(sortByType:) forControlEvents:UIControlEventTouchUpInside];
        [user setTitle:@"Sort by User" forState:UIControlStateNormal];
        [user setImage:[UIImage imageNamed:@"sortType2"] forState:UIControlStateNormal];
        user.tag = 2;
        addLine(2);

        UIButton *date = addButton(3);
        [date addTarget:self action:@selector(sortByType:) forControlEvents:UIControlEventTouchUpInside];
        [date setTitle:@"Sort by Date" forState:UIControlStateNormal];
        [date setImage:[UIImage imageNamed:@"sortType3"] forState:UIControlStateNormal];
        date.tag = 3;
        addBottomBorder(3);

//        UIImageView *triangle = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"triangle"]];
//        triangle.frame = CGRectMake(240, 0, 22, 12);
//        [self.sheetView addSubview:triangle];
    }

    if (!self.sheetView.superview) {
        [self.view addSubview:self.sheetView];
        [UIView animateWithDuration:.3 animations:^{
            self.sheetView.frame = CGRectMake(0, 0, 320, 40 * SHEETVIEW_MENU_NUM_ITEMS);
        }


        ];
    } else {
        [self hideSheetViewMenu];
    }
}


- (void)hideSheetViewMenu
{
    [UIView animateWithDuration:.3 animations:^{
        self.sheetView.frame = CGRectMake(0, -(40 * SHEETVIEW_MENU_NUM_ITEMS), 320, 40 * SHEETVIEW_MENU_NUM_ITEMS);
    }


                     completion:^(BOOL finished) {
        [self.sheetView removeFromSuperview];
    }


    ];
}


static const NSInteger ALERT_VIEW_TAG_CHANGE_NAME = 0;


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case ALERT_VIEW_TAG_CHANGE_NAME:
            if (buttonIndex == 1) {
                NSString *newAlbumName = [alertView textFieldAtIndex:0].text;
                [self setAlbumName:newAlbumName];
            }
            break;
    }
}


- (void)setAlbumName:(NSString *)newAlbumName
{
    [[Mixpanel sharedInstance] track:@"Change Album Name Initiated"
                          properties:@{ @"album_id" : [NSString stringWithFormat:@"%lld", self.albumId] }];

    [ShotVibeAPITask runTask:self
                  withAction:^id {
        BOOL success = [[albumManager_ getShotVibeAPI] albumChangeNameWithLong:self.albumId
                                                                  withNSString:newAlbumName];
        if (success) {
            [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:YES];
        }
        return [NSNumber numberWithBool:success];
    }


              onTaskComplete:^(id result) {
        NSNumber *success = result;
        if (![success boolValue]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't Change Album Name"
                                                            message:@"This album was not created by you"
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }];
}


- (void)albumChangeNamePressed:(id)sender
{
    [[Mixpanel sharedInstance] track:@"Change Album Name Pressed"
                          properties:@{ @"album_id" : [NSString stringWithFormat:@"%lld", self.albumId] }];

    [self hideSheetViewMenu];

    if (albumContents == nil) {
        // Album not yet loaded from server
        return;
    }

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New Album Name"
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Ok", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert textFieldAtIndex:0].text = [[albumContents getName] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    alert.tag = ALERT_VIEW_TAG_CHANGE_NAME;
    [alert show];
}

- (void)clearNewPhotoBadges:(SLAlbumContents *)album
{
    SLDateTime *mostRecentPhotoDate = nil;

    for (SLAlbumPhoto *photo in [album getPhotos]) {
        if ([photo getServerPhoto]) {
            if (!mostRecentPhotoDate) {
                mostRecentPhotoDate = [[photo getServerPhoto] getDateAdded];
            } else {
                long long photoTimestamp = [[[photo getServerPhoto] getDateAdded] getTimeStamp];
                if ([mostRecentPhotoDate getTimeStamp] < photoTimestamp) {
                    mostRecentPhotoDate = [[photo getServerPhoto] getDateAdded];
                }
            }
        }
    }

    SLDateTime *lastAccess = mostRecentPhotoDate;
    [albumManager_ updateLastAccessWithLong:self.albumId withSLDateTime:lastAccess];
}


- (void)sortByType:(id)sender
{
    sort = [sender tag] - 1;
    [[NSUserDefaults standardUserDefaults] setInteger:sort forKey:@"sort_photos"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [self sortThumbsBy:sort];
    [self.collectionView reloadData];
    [self updateEmptyState];

    [self hideSheetViewMenu];
}


- (void)switchSortHandler:(UISegmentedControl *)control
{
    sort = control.selectedSegmentIndex;
    [[NSUserDefaults standardUserDefaults] setInteger:sort forKey:@"sort_photos"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [self sortThumbsBy:sort];
    [self.collectionView reloadData];
    [self updateEmptyState];
}


- (void)onAlbumContentsNewContentWithLong:(long long int)albumId
                      withSLAlbumContents:(SLAlbumContents *)album
{
    [self setAlbumContents:album];
}


- (void)onAlbumContentsEndUserRefreshWithSLAPIException:(SLAPIException *)error
{
    [self hideRefreshSpinner];

    if (error) {
        // TODO Show "Toast" message
    }
}


#pragma mark UIRefreshView


- (void)onUserRefreshed
{
    [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:YES];
}


- (void)showRefreshSpinner
{
    [refresh beginRefreshing];
    if (!IS_IOS7) {
        refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing photos..."];
    }
}


- (void)hideRefreshSpinner
{
    [refresh endRefreshing];
    if (!IS_IOS7) {
        refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
    }
}


- (void)onAlbumContentsBeginUserRefreshWithLong:(long long int)albumId
{
    [self showRefreshSpinner];
}


@end
