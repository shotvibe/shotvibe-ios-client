//
//  SVAlbumListViewController.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import "SVAlbumListViewController.h"
#import "SVSettingsViewController.h"
#import "SVProfileViewController.h"
#import "UIImageView+WebCache.h"
#import "SVDefines.h"

#import "SVCameraNavController.h"
#import "SVPickerController.h"

#import "SVImagePickerListViewController.h"
#import "NSDate+Formatting.h"
#import "MFSideMenu.h"
#import "MBProgressHUD.h"
#import "SVNavigationController.h"
#import "NetworkLogViewController.h"

#import "SL/AlbumSummary.h"
#import "SL/AlbumPhoto.h"
#import "SL/AlbumServerPhoto.h"
#import "SL/ArrayList.h"
#import "SL/DateTime.h"
#import "SL/APIException.h"
#import "ShotVibeAppDelegate.h"
#import "UserSettings.h"

#import "SVMultiplePicturesViewController.h"
#import "SVNonRotatingNavigationControllerViewController.h"

@interface SVAlbumListViewController ()
{
    BOOL searchShowing;
	BOOL creatingAlbum;
	BOOL refreshManualy;
    NSMutableArray *albumList;
	NSArray *allAlbums;
    NSMutableDictionary *thumbnailCache;
	UIView *sectionView;
	NSIndexPath *tappedCell;
	SVCameraNavController *cameraNavController;
	int table_content_offset_y;
	int total_header_h;
	int status_bar_h;
	int dropdown_origin_y;

    BOOL networkOnline_;
}

@property (nonatomic, strong) IBOutlet UIView *sectionHeader;
@property (nonatomic, strong) IBOutlet UIView *tableOverlayView;
@property (nonatomic, strong) IBOutlet UIView *dropDownContainer;
@property (nonatomic, strong) IBOutlet UIView *noPhotosView;
@property (nonatomic, strong) IBOutlet UITextField *albumField;
@property (nonatomic, strong) IBOutlet UISearchBar *searchbar;
@property (nonatomic, strong) IBOutlet UIButton *butAlbum;
@property (nonatomic, strong) IBOutlet UIButton *butTakePicture;

@property (nonatomic, strong) UINavigationController *pickerController;

- (IBAction)newAlbumPressed:(id)sender;
- (IBAction)newAlbumClosed:(id)sender;
- (IBAction)newAlbumDone:(id)sender;
- (IBAction)takePicturePressed:(id)sender;

@end


@implementation SVAlbumListViewController


#pragma mark - Controller lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setAlbumList:[self.albumManager addAlbumListListener:self]];

    //RCLog(@"##### Initial albumList: %@", albumList);

    table_content_offset_y = IS_IOS7 ? 44 : 44;
    total_header_h = IS_IOS7 ? 0 : 64;
    status_bar_h = IS_IOS7 ? 0 : 20;
    dropdown_origin_y = IS_IOS7 ? (45 + 44) : (45 + 44);

    //self.tableView.contentInset = UIEdgeInsetsMake(44, 0, 0, 0);
    self.tableView.contentOffset = CGPointMake(0, 44);

    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.butTakePicture.enabled = NO;
    }

    thumbnailCache = [[NSMutableDictionary alloc] init];
    self.searchbar.placeholder = NSLocalizedString(@"Search album", nil);
    self.dropDownContainer.frame = CGRectMake(8, -134, self.dropDownContainer.frame.size.width, 134);

    // Setup titleview
//    UIImageView *titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
//    UIView *titleContainer = [[UIView alloc] initWithFrame:titleView.frame];
//    [titleContainer addSubview:titleView];
//    titleContainer.backgroundColor = [UIColor clearColor];
//    titleView.frame = CGRectMake(0, -1, titleView.frame.size.width, titleView.frame.size.height);
//    self.navigationItem.titleView = titleContainer;

    // Setup menu button

    UIImage *profileImg = [UIImage imageNamed:@"IconProfile.png"];

    if ([profileImg respondsToSelector:@selector(imageWithRenderingMode:)]) {
        profileImg = [profileImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }

    UIBarButtonItem *butProfile = [[UIBarButtonItem alloc] initWithImage:profileImg
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(profilePressed)];
    self.navigationItem.leftBarButtonItem = butProfile;

    self.refreshControl = [[UIRefreshControl alloc] init];
    if (!IS_IOS7) {
        self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
    }
    [self.refreshControl addTarget:self action:@selector(beginRefreshing) forControlEvents:UIControlEventValueChanged];

    [self updateEmptyState];

    // Set required taps and number of touches
    UITapGestureRecognizer *touchOnView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(releaseOverlay)];
    [touchOnView setNumberOfTapsRequired:1];
    [touchOnView setNumberOfTouchesRequired:1];
    [self.tableOverlayView addGestureRecognizer:touchOnView];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(somethingChangedInAlbumwithId:)
                                                 name:NOTIFICATIONCENTER_ALBUM_CHANGED
                                               object:nil];

    ShotVibeAppDelegate *app = (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];
    networkOnline_ = [app.networkStatusManager registerListenerWithSLNetworkStatusManager_Listener:self];
    [self updateNetworkStatusNavBar];

    RCLogTimestamp();

    if (IS_IOS7) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
}


- (void)updateNetworkStatusNavBar
{
    UIImage *managementButtonImg = [UIImage imageNamed:@"IconSettings.png"];
    
    if ([managementButtonImg respondsToSelector:@selector(imageWithRenderingMode:)]) {
        managementButtonImg = [managementButtonImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }

    UIBarButtonItem *managementButton = [[UIBarButtonItem alloc] initWithImage:managementButtonImg
                                                                         style:UIBarButtonItemStyleBordered
                                                                        target:self
                                                                        action:@selector(settingsPressed)];

    UIImage *networkButtonImg = [UIImage imageNamed:@"IconNotConnected.png"];

    if ([networkButtonImg respondsToSelector:@selector(imageWithRenderingMode:)]) {
        networkButtonImg = [networkButtonImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }

    if (networkOnline_) {
        self.navigationItem.rightBarButtonItems = [[NSArray alloc] initWithObjects:
                                                   managementButton,
                                                   nil];
    } else {
        UIBarButtonItem *notConnectedButton = [[UIBarButtonItem alloc] initWithImage:networkButtonImg
                                                                               style:UIBarButtonItemStyleBordered
                                                                              target:self
                                                                              action:@selector(notConnectedPressed)];

        self.navigationItem.rightBarButtonItems = [[NSArray alloc] initWithObjects:
                                                   managementButton,
                                                   notConnectedButton,
                                                   nil];
    }

    if (IS_IOS7) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
}


- (void)viewWillAppear:(BOOL)animated {
	
	[super viewWillAppear:animated];
	[self.albumManager refreshAlbumList];
	
	// Update the cell that was last tapped and maybe edited
	if (tappedCell != nil) {
		[self.tableView reloadRowsAtIndexPaths:@[tappedCell] withRowAnimation:UITableViewRowAnimationNone];
		tappedCell = nil;
	}
}

- (void)viewDidAppear:(BOOL)animated {
	
	[super viewDidAppear:animated];
	
	self.menuContainerViewController.panMode = MFSideMenuPanModeNone;
	cameraNavController = nil;

    [self promptNickChange];
}

- (void)viewWillDisappear:(BOOL)animated {
	
    [super viewWillDisappear:animated];
    
    [thumbnailCache removeAllObjects];
    
    if (self.albumField.isFirstResponder) {
        [self.albumField resignFirstResponder];
    }
    else if (self.searchbar.isFirstResponder) {
        [self.searchbar resignFirstResponder];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}


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


#pragma mark - Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [thumbnailCache removeAllObjects];
}


#pragma mark - Actions


- (void)notConnectedPressed
{
    [NetworkLogViewController showNetworkErrorDialog:self];
}


- (void)profilePressed {
	tappedCell = nil;
	[self performSegueWithIdentifier:@"ProfileSegue" sender:nil];
}

- (void)settingsPressed {
	tappedCell = nil;
    [self performSegueWithIdentifier:@"SettingsSegue" sender:nil];
}

- (IBAction)newAlbumPressed:(id)sender {
    [self showDropDown];
	//	ShotVibeAppDelegate *app = [ShotVibeAppDelegate sharedDelegate];
	//	NSDictionary *dic = @{@"aps":@{@"alert":@"Just added few pics to your album"}};
	//	[app application:nil didReceiveRemoteNotification:dic];
}

- (IBAction)newAlbumClosed:(id)sender {
    [self hideDropDown];
}

- (IBAction)newAlbumDone:(id)sender {
	NSString *name = self.albumField.text.length == 0 ? self.albumField.placeholder : self.albumField.text;
    [self createNewAlbumWithTitle:name];
    [self hideDropDown];
}

- (IBAction)takePicturePressed:(id)sender
{
//	int capacity = 8;
//	int i = 0;
//
//	NSMutableArray *albums = [[NSMutableArray alloc] initWithCapacity:capacity];
//
//	for (AlbumSummary *album in albumList) {
//		[albums addObject:album];
//		i++;
//		if (i>=capacity) {
//			break;
//		}
//	}

    SVPickerController *manager = [[SVPickerController alloc] init];
    manager.albumManager = self.albumManager;
    SVNonRotatingNavigationControllerViewController *nc = [[SVNonRotatingNavigationControllerViewController alloc] initWithRootViewController:manager];
    [self presentViewController:nc animated:NO completion:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showAlbumSelector:) name:@"kSVPickAlbumToUpload" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelAlbumSelector:) name:@"kSVPickAlbumCancel" object:nil];

    self.pickerController = nc;
//    cameraNavController = [[SVCameraNavController alloc] init];
//	cameraNavController.cameraDelegate = self;
//	cameraNavController.albums = albums;
//	cameraNavController.albumManager = self.albumManager;
//    cameraNavController.nav = (SVNavigationController*)self.navigationController;// this is set last
}


- (void)cancelAlbumSelector:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showAlbumSelector:) name:@"kSVPickAlbumToUpload" object:nil];

    if (![self.pickerController presentingViewController]) {
        [self presentViewController:self.pickerController animated:NO completion:^{
            self.view.hidden = NO;
        }];
    }
}


- (void)showAlbumDetails:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"kSVShowAlbum" object:nil];

    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    SVAlbumGridViewController *controller = (SVAlbumGridViewController *)[mainStoryboard instantiateViewControllerWithIdentifier:@"SVAlbumGridViewController"];
    controller.albumManager = self.albumManager;
    controller.albumId = [[notification userInfo][@"albumId"] integerValue];
    controller.scrollToTop = YES;
    [self.navigationController pushViewController:controller animated:YES];
}


- (void)showAlbumSelector:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"kSVPickAlbumToUpload" object:nil];

    NSArray *images = [notification userInfo][@"images"];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    SVMultiplePicturesViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"MultiplePicturesViewController"];
    controller.images = images;
    controller.albumManager = self.albumManager;
    controller.albums = albumList;
    [self.navigationController pushViewController:controller animated:YES];
}


#pragma mark Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"AlbumGridViewSegue"]) {
        // Get the selected Album
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        SLAlbumSummary *album = [albumList objectAtIndex:indexPath.row];

        // Get the destination controller
        SVAlbumGridViewController *destinationController = segue.destinationViewController;
        destinationController.albumManager = self.albumManager;
        destinationController.albumId = [album getId];
    } else if ([segue.identifier isEqualToString:@"SettingsSegue"]) {
        SVSettingsViewController *destinationController = segue.destinationViewController;
        destinationController.albumManager = self.albumManager;
    } else if ([segue.identifier isEqualToString:@"ProfileSegue"]) {
        SVProfileViewController *destinationController = segue.destinationViewController;
        destinationController.albumManager = self.albumManager;
    } else if ([segue.identifier isEqualToString:@"PromptNickChangeSegue"]) {
        SVProfileViewController *destinationController = segue.destinationViewController;
        destinationController.shouldPrompt = YES;
        destinationController.albumManager = self.albumManager;
    } else if ([segue.identifier isEqualToString:@"AlbumsToImagePickerSegue"]) {
		
        SLAlbumSummary *album = (SLAlbumSummary *)sender;
		
        SVNavigationController *destinationNavigationController = (SVNavigationController *)segue.destinationViewController;
        SVImagePickerListViewController *destination = [destinationNavigationController.viewControllers objectAtIndex:0];
        destination.albumId = [album getId];
        destination.albumManager = self.albumManager;
        destination.nav = self.navigationController;
    }
}


#pragma mark AlbumGrid delegate

- (void)somethingChangedInAlbumwithId:(NSNotification *)notification {
	
	RCLog(@"somethingChangedInAlbumwithId %@", notification.userInfo);
	NSDictionary *userInfo = notification.userInfo;
    int64_t albumId = [[userInfo objectForKey:@"albumId"] longLongValue];
	
	int i = 0;
    for (SLAlbumSummary *album in albumList) {
        RCLog(@"album.albumId == albumId %lli %lli", [album getId], albumId);
        if ([album getId] == albumId) {
			break;
		}
		i++;
	}
	
	if (i >= albumList.count) {
		RCLog(@"Fatal error, no album with the selected id was found. It might be 0 which means a bug in the code that sent the notification");
		return;
	}
	
    SLAlbumSummary *album = [albumList objectAtIndex:i];

    // TODO:
    SLDateTime *dummyDateCreated = [SLDateTime ParseISO8601WithNSString:@"2000-01-01T00:00:00Z"];

    SLAlbumSummary *newAlbum = [[SLAlbumSummary alloc] initWithLong:[album getId]
                                                       withNSString:[album getEtag]
                                                       withNSString:[album getName]
                                                     withSLDateTime:[album getDateCreated]
                                                     withSLDateTime:dummyDateCreated
                                                           withLong:[album getNumNewPhotos]
                                                     withSLDateTime:[album getLastAccess]
                                                    withSLArrayList:[album getLatestPhotos]];

	//album.dateUpdated = [NSDate date];
	[albumList removeObjectAtIndex:i];
	[albumList insertObject:newAlbum atIndex:0];
	
	[self.tableView beginUpdates];
	[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
	[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
	[self.tableView endUpdates];
}


#pragma mark Cell delegate

- (void)cameraButtonTapped:(UITableViewCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    SLAlbumSummary *album = [albumList objectAtIndex:indexPath.row];

    SVPickerController *manager = [[SVPickerController alloc] init];
    manager.albumManager = self.albumManager;
    manager.albumId = [album getId];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showAlbumDetails:) name:@"kSVShowAlbum" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelAlbumSelector:) name:@"kSVPickAlbumCancel" object:nil];

    SVNonRotatingNavigationControllerViewController *nc = [[SVNonRotatingNavigationControllerViewController alloc] initWithRootViewController:manager];
    [self presentViewController:nc animated:NO completion:nil];

    //	cameraNavController = [[SVCameraNavController alloc] init];
    //	cameraNavController.cameraDelegate = self;
    //	cameraNavController.albumId = album.albumId;
    //	cameraNavController.albumManager = self.albumManager;
    //    cameraNavController.nav = (SVNavigationController*)self.navigationController;// this is set last
}


- (void)libraryButtonTapped:(UITableViewCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    SLAlbumSummary *album = [albumList objectAtIndex:indexPath.row];

    [self performSegueWithIdentifier:@"AlbumsToImagePickerSegue" sender:album];
}

- (void)selectCell:(UITableViewCell*)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    [self performSegueWithIdentifier: @"AlbumGridViewSegue" sender: cell];
}

#pragma mark camera delegate

- (void)cameraExit {
	RCLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> cameraExit");
	
}


- (void)cameraWasDismissedWithAlbum:(SLAlbumSummary *)selectedAlbum
{
    RCLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> cameraWasDismissedWithAlbum %@", [selectedAlbum getName]);
}



#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	self.sectionHeader.frame = CGRectMake(0, 0, 320, 45);
	return self.sectionHeader;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 45;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return albumList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SVAlbumListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SVAlbumListCell"];
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.delegate = self;
	cell.parentTableView = self.tableView;

    SLAlbumSummary *album = [albumList objectAtIndex:indexPath.row];

    if ([album getNumNewPhotos] > 0) {
        NSString *title = [album getNumNewPhotos] > 99 ? @"99+" : [NSString stringWithFormat:@"%lld", [album getNumNewPhotos]];
        [cell.numberNotViewedIndicator setTitle:title forState:UIControlStateNormal];
        cell.numberNotViewedIndicator.hidden = NO;
    } else
        cell.numberNotViewedIndicator.hidden = YES;


    long long seconds = [[album getDateUpdated] getTimeStamp] / 1000000LL;
    NSDate *dateUpdated = [[NSDate alloc] initWithTimeIntervalSince1970:seconds];
    NSString *distanceOfTimeInWords = [dateUpdated distanceOfTimeInWords];

    cell.tag = indexPath.row;
    cell.title.text = [album getName];
    cell.author.text = @"";
    cell.timestamp.hidden = YES;

    [cell.networkImageView setImage:nil];
	// TODO: ltestPhotos might be nil if we insert an AlbumContents instead AlbumSummary
    if ([album getLatestPhotos].array.count > 0) {
        SLAlbumPhoto *latestPhoto = [[album getLatestPhotos].array objectAtIndex:0];
        if ([latestPhoto getServerPhoto]) {
            cell.author.text = [NSString stringWithFormat:@"Last added by %@", [[[latestPhoto getServerPhoto] getAuthor] getMemberNickname]];

            [cell.networkImageView setPhoto:[[latestPhoto getServerPhoto] getId]
                                   photoUrl:[[latestPhoto getServerPhoto] getUrl]
                                  photoSize:[PhotoSize Thumb75]
                                    manager:self.albumManager.photoFilesManager];
            [cell.timestamp setTitle:distanceOfTimeInWords forState:UIControlStateNormal];
            cell.timestamp.hidden = NO;
        }
    }
	else {
		[cell.networkImageView setImage:[UIImage imageNamed:@"placeholderImage"]];
        cell.author.text = [NSString stringWithFormat:@"Empty album"];
	}

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	cell.backgroundColor = [UIColor whiteColor];

    if (creatingAlbum) // Navigate to the newly created album
        [self performSegueWithIdentifier: @"AlbumGridViewSegue" sender: cell];
}


#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.searchbar resignFirstResponder];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    tappedCell = [indexPath copy];
    // The rest of the actions are made through the segue in IB
}


#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	
	if (textField == self.albumField) {
		[self newAlbumDone:nil];
	}
    return YES;
}


#pragma mark - UISearchbarDelegate Methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
	
	[searchBar setShowsCancelButton:YES animated:YES];
	
//	[UIView animateWithDuration:0.4 animations:^{
//		self.tableView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-KEYBOARD_H-status_bar_h);
//	}];
	
	searchShowing = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:NO animated:YES];

//	self.tableView.frame = CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-total_header_h);

    [self.tableView setContentOffset:CGPointMake(0, 44) animated:YES];

    searchShowing = NO;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self searchForAlbumWithTitle:searchBar.text];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    [self searchForAlbumWithTitle:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	[searchBar resignFirstResponder];
	searchBar.text = @"";
	[self searchForAlbumWithTitle:nil];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)bar {
    return YES;
}

- (void)searchForAlbumWithTitle:(NSString *)title
{
	albumList = [NSMutableArray arrayWithCapacity:[allAlbums count]];

    for (SLAlbumSummary *album in allAlbums) {
        if (title == nil || [title isEqualToString:@""] || [[[album getName] lowercaseString] rangeOfString:title].location != NSNotFound) {
			[albumList addObject:album];
		}
    }
    [self.tableView reloadData];
}





#pragma mark - Private Methods

- (void) updateEmptyState
{
	if (albumList.count == 0) {
		self.noPhotosView.frame = CGRectMake(0, 88, 320, 548);
		[self.view addSubview:self.noPhotosView];
		self.butTakePicture.enabled = NO;
	} else {
		[self.noPhotosView removeFromSuperview];
		self.butTakePicture.enabled = YES;
	}
}

- (void) releaseOverlay {
	
	if (searchShowing) {
		[self.searchbar resignFirstResponder];
		self.tableOverlayView.hidden = YES;
		self.tableOverlayView.alpha = 0;
	}
}


#pragma mark drop down stuffs

- (void)showDropDown
{
	[self.tableView setContentOffset:CGPointMake(0,table_content_offset_y) animated:YES];
	[self.view addSubview:self.tableOverlayView];
	
	CGRect r = self.tableOverlayView.frame;
	r.origin.y = dropdown_origin_y;
	self.tableOverlayView.frame = r;
	self.tableOverlayView.alpha = 0;
    self.tableOverlayView.hidden = NO;
    self.dropDownContainer.hidden = NO;
	self.butAlbum.enabled = NO;
	self.butTakePicture.enabled = NO;
	self.tableView.scrollEnabled = NO;
    
    NSString *currentDateString = [NSDateFormatter localizedStringFromDate:[NSDate date]
																 dateStyle:NSDateFormatterLongStyle
																 timeStyle:NSDateFormatterNoStyle];
    self.albumField.text = @"";
	self.albumField.placeholder = currentDateString;
    
    [UIView animateWithDuration:0.5 animations:^{
        self.tableOverlayView.alpha = 1;
        self.dropDownContainer.frame = CGRectMake(8, -4, self.dropDownContainer.frame.size.width, 134);
    } completion:^(BOOL finished) {
        [self.albumField becomeFirstResponder];
    }];
}


- (void)hideDropDown
{
	[self.albumField resignFirstResponder];
	
	[UIView animateWithDuration:0.3 animations:^{
        self.tableOverlayView.alpha = 0.0;
        self.dropDownContainer.frame = CGRectMake(8, -134, self.dropDownContainer.frame.size.width, 134);
    } completion:^(BOOL finished) {
        self.tableOverlayView.hidden = YES;
        self.dropDownContainer.hidden = YES;
		self.butAlbum.enabled = YES;
		self.butTakePicture.enabled = YES;
		self.tableView.scrollEnabled = YES;
    }];
}


- (void)createNewAlbumWithTitle:(NSString *)title {
	
	RCLog(@"createNewAlbumWithTitle %@", title);
	[MBProgressHUD showHUDAddedTo:self.view animated:YES];
	
	// Write the album to server
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		
		creatingAlbum = YES;
        SLAlbumContents *albumContents = nil;
        SLAPIException *apiException = nil;
        @try {
            albumContents = [[self.albumManager getShotVibeAPI] createNewBlankAlbum:title];
        } @catch (SLAPIException *exception) {
            apiException = exception;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (apiException) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Creating Album"
                                                                message:apiException.description
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            else {
                SLAlbumSummary *album = [[SLAlbumSummary alloc] initWithLong:[albumContents getId]
                                                                withNSString:[albumContents getEtag]
                                                                withNSString:[albumContents getName]
                                                              withSLDateTime:[albumContents getDateCreated]
                                                              withSLDateTime:[albumContents getDateUpdated]
                                                                    withLong:[albumContents getNumNewPhotos]
                                                              withSLDateTime:[albumContents getLastAccess]
                                                             withSLArrayList:[[SLArrayList alloc] init]];

				[albumList insertObject:album atIndex:0];
				
				[self.tableView beginUpdates];
				[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
									  withRowAnimation:UITableViewRowAnimationAutomatic];
				[self.tableView endUpdates];
				[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
									  atScrollPosition:UITableViewScrollPositionTop
											  animated:YES];
				[self updateEmptyState];
            }
			[MBProgressHUD hideHUDForView:self.view animated:YES];
			creatingAlbum = NO;
        });
    });
}



- (void)setAlbumList:(NSArray *)albums {
	
	allAlbums = albums;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // Set all the album thumbnails to download at high priority
        for (SLAlbumSummary *a in albums) {
            if ([a getLatestPhotos].array.count > 0) {
                SLAlbumPhoto *p = [[a getLatestPhotos].array objectAtIndex:0];
                if ([p getServerPhoto]) {
                    [self.albumManager.photoFilesManager queuePhotoDownload:[[p getServerPhoto] getId]
                                                                   photoUrl:[[p getServerPhoto] getUrl]
                                                                  photoSize:[PhotoSize Thumb75]
                                                               highPriority:YES];
                }
            }
        }
    });

    [self searchForAlbumWithTitle:self.searchbar.text];
}

#pragma Prompt nickname change

// Check if the user has already set their nickname, and if not, prompt them to do this.
- (void)promptNickChange
{
    if ([UserSettings isNicknameSet]) {
        RCLog(@"Nickname was already set");
    } else {
        // TODO: Check with the server if the nickname really was not set yet, since now we will prompt also after a reinstall.
        if ([self.navigationController.viewControllers count] <= 1) {
            [self performSegueWithIdentifier:@"PromptNickChangeSegue" sender:nil];
        }
    }
}

#pragma mark UIRefreshView

- (void)beginRefreshing
{
	if (!creatingAlbum) {
		refreshManualy = YES;
		[self.albumManager refreshAlbumList];
		[self.refreshControl beginRefreshing];
		if (!IS_IOS7) self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing albums..."];
        // Need to call this whenever we scroll our table view programmatically
        [[NSNotificationCenter defaultCenter] postNotificationName:SVSwipeForOptionsCellEnclosingTableViewDidBeginScrollingNotification object:self.tableView];
	}
}
- (void)endRefreshing
{
	refreshManualy = NO;
	[self.refreshControl endRefreshing];
	if (!IS_IOS7) self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
	//[self.tableView setContentOffset:CGPointMake(0,44) animated:YES];
}



- (void)onAlbumListBeginRefresh
{
	
}

- (void)onAlbumListRefreshComplete:(NSArray *)albums
{
	creatingAlbum = NO;
	[self setAlbumList:albums];
	[self updateEmptyState];
	if (refreshManualy) {
		[self endRefreshing];
	}
}

- (void)onAlbumListRefreshError:(SLAPIException *)exception
{
    creatingAlbum = NO;
    if (refreshManualy) {
        [self endRefreshing];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    // Need to do this to keep the view in a consistent state (layoutSubviews in the cell expects itself to be "closed")
    [[NSNotificationCenter defaultCenter] postNotificationName:SVSwipeForOptionsCellEnclosingTableViewDidBeginScrollingNotification object:self.tableView];
}


#pragma UIScrollViewDelegate Methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SVSwipeForOptionsCellEnclosingTableViewDidBeginScrollingNotification object:scrollView];
}

#pragma SLNetworkStatusManager_Listener Methods


- (void)networkStatusChangedWithBoolean:(BOOL)networkOnline
{
    dispatch_async(dispatch_get_main_queue(), ^{
        networkOnline_ = networkOnline;

        [self updateNetworkStatusNavBar];
    });
}


@end
