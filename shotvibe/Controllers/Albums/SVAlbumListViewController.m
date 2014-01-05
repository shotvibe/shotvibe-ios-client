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
#import "SVImagePickerListViewController.h"
#import "NSDate+Formatting.h"
#import "MFSideMenu.h"
#import "MBProgressHUD.h"
#import "SVAddressBook.h"
#import "SVRecord.h"
#import "SVNavigationController.h"

#import "AlbumSummary.h"
#import "AlbumPhoto.h"
#import "ShotVibeAppDelegate.h"

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
	SVAddressBook *ab;
	
	int table_content_offset_y;
	int total_header_h;
	int status_bar_h;
	int dropdown_origin_y;
}

@property (nonatomic, strong) IBOutlet UIView *sectionHeader;
@property (nonatomic, strong) IBOutlet UIView *tableOverlayView;
@property (nonatomic, strong) IBOutlet UIView *dropDownContainer;
@property (nonatomic, strong) IBOutlet UIView *noPhotosView;
@property (nonatomic, strong) IBOutlet UITextField *albumField;
@property (nonatomic, strong) IBOutlet UISearchBar *searchbar;
@property (nonatomic, strong) IBOutlet UIButton *butAlbum;
@property (nonatomic, strong) IBOutlet UIButton *butTakePicture;


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
	
	table_content_offset_y = IS_IOS7 ? -20 : 44;
	total_header_h = IS_IOS7 ? 0 : 64;
	status_bar_h = IS_IOS7 ? 0 : 20;
	dropdown_origin_y = IS_IOS7 ? (45+44) : (45+44);
	
	//self.tableView.contentInset = UIEdgeInsetsMake(44, 0, 0, 0);
	self.tableView.contentOffset = CGPointMake(0, 44);
	
	if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		self.butTakePicture.enabled = NO;
	}
	
    thumbnailCache = [[NSMutableDictionary alloc] init];
	self.searchbar.placeholder = NSLocalizedString(@"Search album", nil);
	self.dropDownContainer.frame = CGRectMake(8, -134, self.dropDownContainer.frame.size.width, 134);
	
	// Setup titleview
    UIImageView *titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
    UIView *titleContainer = [[UIView alloc] initWithFrame:titleView.frame];
    [titleContainer addSubview:titleView];
    titleContainer.backgroundColor = [UIColor clearColor];
    titleView.frame = CGRectMake(0, -1, titleView.frame.size.width, titleView.frame.size.height);
    self.navigationItem.titleView = titleContainer;
    
    // Setup menu button
    UIBarButtonItem *butProfile = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"IconProfile.png"]
																   style:UIBarButtonItemStyleBordered
																  target:self
																  action:@selector(profilePressed)];
    self.navigationItem.leftBarButtonItem = butProfile;
    
    // Setup menu button
    UIBarButtonItem *managementButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"IconSettings.png"]
																		 style:UIBarButtonItemStyleBordered
																		target:self
																		action:@selector(settingsPressed)];
    self.navigationItem.rightBarButtonItem = managementButton;
    
	
	self.refreshControl = [[UIRefreshControl alloc] init];
	if (!IS_IOS7) self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
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
	
	// Upload the contacts to the server
	
	RCLogTimestamp();
	
	ab = [SVAddressBook sharedBook];
	[ab requestAccessWithCompletion:^(BOOL granted, NSError *error) {
		if (granted) {
			[self submitAddressBook];
		}
		else {
			RCLog(@"You have no access to the addressbook");
		}
	}];
	
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

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}


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
    [thumbnailCache removeAllObjects];
}





- (void)submitAddressBook {
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		
		NSMutableArray *contacts = [NSMutableArray arrayWithCapacity:ab.allContacts.count*9];
		
		for (SVRecord *record in ab.allContacts) {
			
			NSString *name = record.fullname;
			NSString *phoneNumber = record.phone;
			
			NSDictionary *person = @{ @"phone_number": phoneNumber, @"contact_nickname": name };
			[contacts addObject:person];
		}
		
		__block NSError *error = nil;
		ShotVibeAPI *api = [self.albumManager getShotVibeAPI];
		NSDictionary *body = @{ @"phone_numbers": contacts, @"default_country": api.authData.defaultCountryCode };
		
		
		NSDictionary *response = [api submitAddressBook:body error:&error];
		RCLog(@"response uploaded %i, received %i", contacts.count, [response[@"phone_number_details"] count]);
		
		RCLogTimestamp();
		
		int i = 0;
		for (NSDictionary *r in (NSArray*)response[@"phone_number_details"]) {
			//RCLogO(r);
			if ([r[@"phone_type"] isEqualToString:@"invalid"]) {
				SVRecord *record = [ab.allContacts objectAtIndex:i];
				record.invalid = YES;
			}
			else {
				SVRecord *record = [ab.allContacts objectAtIndex:i];
				record.iconRemotePath = r[@"avatar_url"];
				
				NSString *user_id = r[@"user_id"];
				//RCLog(@"%lli", record.phoneId);
				
				if (user_id != nil && ![user_id isKindOfClass:[NSNull class]]) {
					record.memberId = [user_id longLongValue];
				}
			}
			i++;
		}
	});
}


#pragma mark - Actions

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

- (IBAction)takePicturePressed:(id)sender {
	
	int capacity = 8;
	int i = 0;
	
	NSMutableArray *albums = [[NSMutableArray alloc] initWithCapacity:capacity];
	
	for (AlbumSummary *album in albumList) {
		[albums addObject:album];
		i++;
		if (i>=capacity) {
			break;
		}
	}
	
    cameraNavController = [[SVCameraNavController alloc] init];
	cameraNavController.cameraDelegate = self;
	cameraNavController.albums = albums;
	cameraNavController.albumManager = self.albumManager;
    cameraNavController.nav = (SVNavigationController*)self.navigationController;// this is set last
}


#pragma mark Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"AlbumGridViewSegue"]) {
        
        // Get the selected Album
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        AlbumSummary *album = [albumList objectAtIndex:indexPath.row];
		
        // Get the destination controller
        SVAlbumGridViewController *destinationController = segue.destinationViewController;
        destinationController.albumManager = self.albumManager;
        destinationController.albumId = album.albumId;
    }
    else if ([segue.identifier isEqualToString:@"SettingsSegue"]) {
        SVSettingsViewController *destinationController = segue.destinationViewController;
        destinationController.albumManager = self.albumManager;
    }
	else if ([segue.identifier isEqualToString:@"ProfileSegue"]) {
		SVProfileViewController *destinationController = segue.destinationViewController;
        destinationController.albumManager = self.albumManager;
	}
	else if ([segue.identifier isEqualToString:@"AlbumsToImagePickerSegue"]) {
		
		AlbumSummary *album = (AlbumSummary*)sender;
		
        SVNavigationController *destinationNavigationController = (SVNavigationController *)segue.destinationViewController;
        SVImagePickerListViewController *destination = [destinationNavigationController.viewControllers objectAtIndex:0];
        destination.albumId = album.albumId;
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
	for (AlbumSummary *album in albumList) {
		RCLog(@"album.albumId == albumId %lli %lli", album.albumId, albumId);
		if (album.albumId == albumId) {
			break;
		}
		i++;
	}
	
	if (i >= albumList.count) {
		RCLog(@"Fatal error, no album with the selected id was found. It might be 0 which means a bug in the code that sent the notification");
		return;
	}
	
	AlbumSummary *album = [albumList objectAtIndex:i];
	AlbumSummary *newAlbum = [[AlbumSummary alloc] initWithAlbumId:album.albumId
															  etag:album.etag
															  name:album.name
													   dateCreated:album.dateCreated
													   dateUpdated:[NSDate date]
													  latestPhotos:album.latestPhotos];
	//album.dateUpdated = [NSDate date];
	[albumList removeObjectAtIndex:i];
	[albumList insertObject:newAlbum atIndex:0];
	
	[self.tableView beginUpdates];
	[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
	[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
	[self.tableView endUpdates];
}


#pragma mark Cell delegate

- (void)releaseOnCamera:(UITableViewCell*)cell {
	
	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	AlbumSummary *album = [albumList objectAtIndex:indexPath.row];
	
	cameraNavController = [[SVCameraNavController alloc] init];
	cameraNavController.cameraDelegate = self;
	cameraNavController.albumId = album.albumId;
	cameraNavController.albumManager = self.albumManager;
    cameraNavController.nav = (SVNavigationController*)self.navigationController;// this is set last
}
- (void)releaseOnLibrary:(UITableViewCell*)cell {
	
	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	AlbumSummary *album = [albumList objectAtIndex:indexPath.row];
	
	[self performSegueWithIdentifier:@"AlbumsToImagePickerSegue" sender:album];
}


#pragma mark camera delegate

- (void)cameraExit {
	RCLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> cameraExit");
	
}

- (void) cameraWasDismissedWithAlbum:(AlbumSummary*)selectedAlbum {
	
	RCLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> cameraWasDismissedWithAlbum %@", selectedAlbum.name);
	
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
	
    AlbumSummary *album = [albumList objectAtIndex:indexPath.row];
	NSString *distanceOfTimeInWords = [album.dateUpdated distanceOfTimeInWords];
    
    cell.tag = indexPath.row;
	cell.title.text = album.name;
    cell.author.text = @"";
    cell.timestamp.hidden = YES;

    [cell.networkImageView setImage:nil];
	// TODO: ltestPhotos might be nil if we insert an AlbumContents instead AlbumSummary
    if (album.latestPhotos.count > 0) {
        AlbumPhoto *latestPhoto = [album.latestPhotos objectAtIndex:0];
        if (latestPhoto.serverPhoto) {
			cell.author.text = [NSString stringWithFormat:@"Last added by %@", latestPhoto.serverPhoto.author.nickname];

            [cell.networkImageView setPhoto:latestPhoto.serverPhoto.photoId photoUrl:latestPhoto.serverPhoto.url photoSize:[PhotoSize Thumb75] manager:self.albumManager.photoFilesManager];
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
	
	[UIView animateWithDuration:0.4 animations:^{
		self.tableView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-KEYBOARD_H-status_bar_h);
	}];
	
	searchShowing = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
	
	[searchBar setShowsCancelButton:NO animated:YES];
	
	self.tableView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-total_header_h);
	
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
	
    for (AlbumSummary *album in [allAlbums reverseObjectEnumerator]) {
		if (title == nil || [title isEqualToString:@""] || [[album.name lowercaseString] rangeOfString:title].location != NSNotFound) {
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
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
		self.butTakePicture.enabled = NO;
	}
	else if ([self.noPhotosView isDescendantOfView:self.view]) {
		[self.noPhotosView removeFromSuperview];
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
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
        NSError *error;
        AlbumContents *albumContents = [[self.albumManager getShotVibeAPI] createNewBlankAlbum:title withError:&error];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Creating Album"
                                                                message:[error description]
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            else {
				AlbumSummary *album = [[AlbumSummary alloc] initWithAlbumId:albumContents.albumId
																	   etag:albumContents.etag
																	   name:albumContents.name
																dateCreated:albumContents.dateCreated
																dateUpdated:albumContents.dateUpdated
															   latestPhotos:[NSArray array]];
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
        for (AlbumSummary *a in albums) {
            if (a.latestPhotos.count > 0) {
                AlbumPhoto *p = [a.latestPhotos objectAtIndex:0];
                if (p.serverPhoto) {
                    [self.albumManager.photoFilesManager queuePhotoDownload:p.serverPhoto.photoId
                                                                   photoUrl:p.serverPhoto.url
                                                                  photoSize:[PhotoSize Thumb75]
                                                               highPriority:YES];
                }
            }
        }
    });

    [self searchForAlbumWithTitle:self.searchbar.text];
}


#pragma mark UIRefreshView

- (void)beginRefreshing
{
	if (!creatingAlbum) {
		refreshManualy = YES;
		[self.albumManager refreshAlbumList];
		[self.refreshControl beginRefreshing];
		if (!IS_IOS7) self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing albums..."];
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

- (void)onAlbumListRefreshError:(NSError *)error
{
    // TODO ...
}

@end
