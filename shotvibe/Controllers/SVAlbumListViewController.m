//
//  SVAlbumListViewController.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVAlbumListViewController.h"
#import "SVSettingsViewController.h"
#import "SVProfileViewController.h"
#import "UIImageView+WebCache.h"
#import "SVDefines.h"
#import "CaptureNavigationController.h"
#import "SVAlbumListViewCell.h"
#import "SVAlbumGridViewController.h"
#import "NSDate+Formatting.h"
#import "MFSideMenu.h"
#import "MBProgressHUD.h"

#import "AlbumSummary.h"
#import "AlbumPhoto.h"
#import "ShotVibeAppDelegate.h"

@interface SVAlbumListViewController ()
{
    NSMutableArray *albumList;
    BOOL searchShowing;
	BOOL creatingAlbum;
	BOOL refreshManualy;
    NSMutableDictionary *thumbnailCache;
	UIView *sectionView;
	NSIndexPath *tappedCell;
	CaptureNavigationController *cameraNavController;
	NSArray *allAlbums;
}

@property (nonatomic, strong) IBOutlet UIView *sectionHeader;
@property (nonatomic, strong) IBOutlet UIView *tableOverlayView;
@property (nonatomic, strong) IBOutlet UIView *dropDownContainer;
@property (nonatomic, strong) IBOutlet UIView *noPhotosView;
@property (nonatomic, strong) IBOutlet UITextField *albumField;
@property (nonatomic, strong) IBOutlet UISearchBar *searchbar;
@property (nonatomic, strong) IBOutlet UIButton *albumButton;
@property (nonatomic, strong) IBOutlet UIButton *takePictureButton;


- (void)configureViews;
- (void)profilePressed;
- (void)settingsPressed;
- (void)showDropDown;
- (void)hideDropDown;
- (void)searchForAlbumWithTitle:(NSString *)title;
- (void)createNewAlbumWithTitle:(NSString *)title;
- (IBAction)newAlbumButtonPressed:(id)sender;
- (IBAction)newAlbumClose:(id)sender;
- (IBAction)newAlbumDone:(id)sender;
- (IBAction)takePicturePressed:(id)sender;

@end


@implementation SVAlbumListViewController


#pragma mark - Actions

- (void)profilePressed {
	tappedCell = nil;
	[self performSegueWithIdentifier:@"ProfileSegue" sender:nil];
}
- (void)settingsPressed {
	tappedCell = nil;
    [self performSegueWithIdentifier:@"SettingsSegue" sender:nil];
}
- (IBAction)newAlbumClose:(id)sender {
    [self hideDropDown];
}
- (IBAction)newAlbumDone:(id)sender {
	NSString *name = self.albumField.text.length == 0 ? self.albumField.placeholder : self.albumField.text;
    [self createNewAlbumWithTitle:name];
    [self hideDropDown];
}
//
- (IBAction)newAlbumButtonPressed:(id)sender {
    [self showDropDown];
//	ShotVibeAppDelegate *app = [ShotVibeAppDelegate sharedDelegate];
//	NSDictionary *dic = @{@"aps":@{@"alert":@"Just added few pics to your album"}};
//	[app application:nil didReceiveRemoteNotification:dic];
}
- (IBAction)takePicturePressed:(id)sender {
	NSLog(@"takePicturePressed");
	int capacity = 8;
	NSMutableArray *albums = [[NSMutableArray alloc] initWithCapacity:capacity];
	int i = 0;
	for (AlbumSummary *album in albumList) {
		[albums addObject:album];
		i++;
		if (i>=capacity) {
			break;
		}
	}
	
    cameraNavController = [[CaptureNavigationController alloc] init];
	cameraNavController.cameraDelegate = self;
	cameraNavController.albums = albums;
    cameraNavController.nav = self.navigationController;// this is set last
}

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
}


#pragma mark camera delegate

- (void)cameraExit {
	cameraNavController = nil;
}

- (void) cameraWasDismissedWithAlbum:(AlbumSummary*)selectedAlbum {
	
	NSLog(@"CAMERA WAS DISMISSED %@", selectedAlbum);
	NSLog(@"navigate to gridview");
	
	int i = 0;
	NSIndexPath *indexPath;
	for (AlbumSummary *a in albumList) {
		
		if (a.albumId == selectedAlbum.albumId) {
			indexPath = [NSIndexPath indexPathForRow:i inSection:0];
			NSLog(@"found at indexPath %@", indexPath);
			[self performSegueWithIdentifier:@"AlbumGridViewSegue" sender:[self.tableView cellForRowAtIndexPath:indexPath]];
			
			break;
		}
		i ++;
	}
}


#pragma mark - UIViewController Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    NSLog(@"##### albumManager: %@", self.albumManager);

    [self setAlbumList:[self.albumManager addAlbumListListener:self]];

    NSLog(@"##### Initial albumList: %@", albumList);
	
	if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		self.takePictureButton.enabled = NO;
	}
	
    thumbnailCache = [[NSMutableDictionary alloc] init];
	self.searchbar.placeholder = NSLocalizedString(@"Search album", nil);
	self.dropDownContainer.frame = CGRectMake(8, -134, self.dropDownContainer.frame.size.width, 134);
	
    [self configureViews];
	
	self.refreshControl = [[UIRefreshControl alloc] init];
	self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
	[self.refreshControl addTarget:self action:@selector(beginRefreshing) forControlEvents:UIControlEventValueChanged];
	
	[self updateEmptyState];
	
}


- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.albumManager refreshAlbumList];
	if (tappedCell != nil) {
		[self.tableView reloadRowsAtIndexPaths:@[tappedCell] withRowAnimation:UITableViewRowAnimationNone];
	}
}

- (void)viewDidAppear:(BOOL)animated {
	
	[super viewDidAppear:animated];
	
	cameraNavController = nil;
	self.menuContainerViewController.panMode = MFSideMenuPanModeNone;
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [thumbnailCache removeAllObjects];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (self.albumField.isFirstResponder) {
        [self.albumField resignFirstResponder];
    }
    else if (self.searchbar.isFirstResponder) {
        [self.searchbar resignFirstResponder];
    }
}



- (BOOL)shouldAutorotate
{
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


#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
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
    AlbumSummary *album = [albumList objectAtIndex:indexPath.row];
	NSString *distanceOfTimeInWords = [album.dateUpdated distanceOfTimeInWords];
    
    cell.tag = indexPath.row;
	cell.title.text = album.name;
	[cell.timestamp setTitle:distanceOfTimeInWords forState:UIControlStateNormal];

    [cell.networkImageView setImage:nil];
	// TODO: ltestPhotos might be nil if we insert an AlbumContents instead AlbumSummary
    if (album.latestPhotos.count > 0) {
        AlbumPhoto *latestPhoto = [album.latestPhotos objectAtIndex:0];
        if (latestPhoto.serverPhoto) {
			cell.author.text = [NSString stringWithFormat:@"Last added by %@", latestPhoto.serverPhoto.authorNickname];
            NSString *fullsizePhotoUrl = latestPhoto.serverPhoto.url;
            NSString *thumbnailSuffix = @"_thumb75.jpg";
            NSString *thumbnailUrl = [[fullsizePhotoUrl stringByDeletingPathExtension] stringByAppendingString:thumbnailSuffix];

            // TODO Temporarily using SDWebImage library for a quick and easy way to display photos
            [cell.networkImageView setImageWithURL:[NSURL URLWithString:thumbnailUrl]];
        }
    }
	else {
		[cell.networkImageView setImage:[UIImage imageNamed:@"placeholderImage"]];
		cell.author.text = @"";
	}

    return cell;
}

//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//	cell.backgroundColor = [UIColor whiteColor];
//}


#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
	tappedCell = [indexPath copy];
}


#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self createNewAlbumWithTitle:textField.text];
    [self textFieldDidEndEditing:textField];
    return YES;
}

#pragma mark - UISearchbarDelegate Methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
	[self.view addSubview:self.tableOverlayView];
	CGRect r = self.tableOverlayView.frame;
	r.origin.y = 44;
	self.tableOverlayView.frame = r;
	
	[UIView animateWithDuration:0.3 animations:^{
		self.tableOverlayView.alpha = 1;
		self.tableOverlayView.hidden = NO;
	}];
	searchShowing = YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self searchForAlbumWithTitle:searchBar.text];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self searchForAlbumWithTitle:searchBar.text];
    [searchBar resignFirstResponder];
	
	[UIView animateWithDuration:0.3 animations:^{
		
		self.tableOverlayView.alpha = 0;
		self.tableOverlayView.hidden = YES;
	}];
	
	searchShowing = NO;
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
	[self.view addSubview:self.tableOverlayView];
}



#pragma mark - Private Methods

- (void)configureViews
{
    // Setup titleview
    UIImageView *titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
    UIView *titleContainer = [[UIView alloc] initWithFrame:titleView.frame];
    [titleContainer addSubview:titleView];
    titleContainer.clipsToBounds = NO;
    titleContainer.backgroundColor = [UIColor clearColor];
    titleView.frame = CGRectMake(0, -1, titleView.frame.size.width, titleView.frame.size.height);
    self.navigationItem.titleView = titleContainer;
    
    // Setup menu button
    UIBarButtonItem *butProfile = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"IconProfile.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(profilePressed)];
    self.navigationItem.leftBarButtonItem = butProfile;
    
    // Setup menu button
    UIBarButtonItem *managementButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"IconSettings.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(settingsPressed)];
    self.navigationItem.rightBarButtonItem = managementButton;
    
	
	// Set required taps and number of touches
	UITapGestureRecognizer *touchOnView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(releaseOverlay)];
	[touchOnView setNumberOfTapsRequired:1];
	[touchOnView setNumberOfTouchesRequired:1];
	[self.tableOverlayView addGestureRecognizer:touchOnView];
}

- (void) updateEmptyState
{
	if (albumList.count == 0) {
		self.noPhotosView.frame = CGRectMake(0, 88, 320, 548);
		[self.view addSubview:self.noPhotosView];
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
		self.takePictureButton.enabled = NO;
	}
	else {
		if ([self.noPhotosView isDescendantOfView:self.view]) {
			[self.noPhotosView removeFromSuperview];
			self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
			self.takePictureButton.enabled = YES;
		}
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
	[self.tableView setContentOffset:CGPointMake(0,44) animated:YES];
	[self.view addSubview:self.tableOverlayView];
	
	CGRect r = self.tableOverlayView.frame;
	r.origin.y = 45+44;
	self.tableOverlayView.frame = r;
	self.tableOverlayView.alpha = 0;
    self.tableOverlayView.hidden = NO;
    self.dropDownContainer.hidden = NO;
	self.albumButton.enabled = NO;
	self.takePictureButton.enabled = NO;
	self.tableView.scrollEnabled = NO;
    
    NSString *currentDateString = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle];
    self.albumField.text = @"";
	self.albumField.placeholder = currentDateString;
    
    [UIView animateWithDuration:0.4 animations:^{
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
		self.albumButton.enabled = YES;
		self.takePictureButton.enabled = YES;
		self.tableView.scrollEnabled = YES;
    }];
}


- (void)createNewAlbumWithTitle:(NSString *)title
{
	
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
				[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
				[self.tableView endUpdates];
				[self updateEmptyState];
            }
			[MBProgressHUD hideHUDForView:self.view animated:YES];
			creatingAlbum = NO;
        });
    });
}



- (void)setAlbumList:(NSArray *)albums
{
	allAlbums = albums;
    [self searchForAlbumWithTitle:nil];
}


#pragma mark UIRefreshView

- (void)beginRefreshing
{
    [self.albumManager refreshAlbumList];
	if (!creatingAlbum) {
		refreshManualy = YES;
		[self.refreshControl beginRefreshing];
		self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing albums..."];
	}
}
- (void)endRefreshing
{
	refreshManualy = NO;
	[self.refreshControl endRefreshing];
	self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
	[self.tableView setContentOffset:CGPointMake(0,44) animated:YES];
}



- (void)onAlbumListBeginRefresh
{
	NSLog(@"Albums begin refresh");
}

- (void)onAlbumListRefreshComplete:(NSArray *)albums
{
	NSLog(@"Albums end refresh");
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
