//
//  SVAlbumListViewController.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVAlbumListViewController.h"
#import "UIImageView+WebCache.h"

#import "AlbumSummary.h"
#import "AlbumPhoto.h"

@interface SVAlbumListViewController ()
{
    NSMutableArray *albumList;
    BOOL searchShowing;
	BOOL creatingAlbum;
    NSMutableDictionary *thumbnailCache;
	UIView *sectionView;
	NSIndexPath *tappedCell;
	NSOperationQueue *_queue;
    UIRefreshControl *refresh;
	CaptureNavigationController *cameraNavController;
	NSArray *allAlbums;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIView *sectionHeader;
@property (nonatomic, strong) NSMutableDictionary *albumPhotoInfo;
@property (nonatomic, strong) IBOutlet UIView *tableOverlayView;
@property (nonatomic, strong) IBOutlet UIView *dropDownContainer;
@property (nonatomic, strong) IBOutlet UIImageView *dropDownBackground;
@property (nonatomic, strong) IBOutlet UITextField *albumField;
@property (nonatomic, strong) IBOutlet UISearchBar *searchbar;
@property (nonatomic, strong) IBOutlet UIView *viewContainer;
@property (nonatomic, strong) IBOutlet UIButton *albumButton;
@property (nonatomic, strong) IBOutlet UIButton *takePictureButton;

@property (nonatomic, strong) NSOperationQueue *imageLoadingQueue;


- (void)configureViews;
- (void)profilePressed;
- (void)settingsPressed;
- (void)showDropDown;
- (void)hideDropDown;
- (void)searchForAlbumWithTitle:(NSString *)title;
- (void)createNewAlbumWithTitle:(NSString *)title;
- (void)albumUpdateReceived:(NSNotification *)notification;
- (void)syncCompleted:(NSNotification *)notification;
- (IBAction)newAlbumButtonPressed:(id)sender;
- (IBAction)newAlbumClose:(id)sender;
- (IBAction)newAlbumDone:(id)sender;
- (IBAction)takePicturePressed:(id)sender;
- (AlbumPhoto *)findMostRecentPhotoInPhotoSet:(NSArray *)photos;

@end


@implementation SVAlbumListViewController


#pragma mark - Actions

- (void)profilePressed {
	[self performSegueWithIdentifier:@"ProfileSegue" sender:nil];
}
- (void)settingsPressed {
    [self performSegueWithIdentifier:@"SettingsSegue" sender:nil];
}
- (IBAction)newAlbumButtonPressed:(id)sender {
    [self showDropDown];
}
- (IBAction)newAlbumClose:(id)sender {
    [self hideDropDown];
}
- (IBAction)newAlbumDone:(id)sender {
	NSString *name = self.albumField.text.length == 0 ? self.albumField.placeholder : self.albumField.text;
    [self createNewAlbumWithTitle:name];
    [self hideDropDown];
}
- (IBAction)takePicturePressed:(id)sender {
	
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
	else if ([segue.identifier isEqualToString:@"ProfileSegue"]) {
		
		
	}
}


#pragma mark camera delegate

- (void)cameraExit {
	cameraNavController = nil;
}

- (void) cameraWasDismissedWithAlbum:(AlbumSummary*)selectedAlbum {
	
	NSLog(@"CAMERA WAS DISMISSED %@", selectedAlbum);
	/*
	if (self.navigationController.visibleViewController == self) {
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
	}*/
}


#pragma mark - UIViewController Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	_queue = [[NSOperationQueue alloc] init];

    NSLog(@"##### albumManager: %@", self.albumManager);

    [self setAlbumList:[self.albumManager addAlbumListListener:self]];

    NSLog(@"##### Initial albumList: %@", albumList);
	
	if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		self.takePictureButton.enabled = NO;
	}
	
    self.albumPhotoInfo = [[NSMutableDictionary alloc] init];
    self.imageLoadingQueue = [[NSOperationQueue alloc] init];
    self.imageLoadingQueue.maxConcurrentOperationCount = 1;
    thumbnailCache = [[NSMutableDictionary alloc] init];
	self.searchbar.placeholder = NSLocalizedString(@"Search album", nil);
	
    [self configureViews];
	
	refresh = [[UIRefreshControl alloc] init];
	refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
	[refresh addTarget:self action:@selector(refreshView) forControlEvents:UIControlEventValueChanged];
	[self.tableView addSubview:refresh];
	
	// Get the instance of the UITextField of the search bar
	//UITextField *searchField = [self.searchbar valueForKey:@"_searchField"];
	// Change the search bar placeholder text color
	//[searchField setValue:[UIColor darkGrayColor] forKeyPath:@"_placeholderLabel.textColor"];
	
    [self.albumManager refreshAlbumList];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (tappedCell != nil) {
		[self.tableView reloadRowsAtIndexPaths:@[tappedCell] withRowAnimation:UITableViewRowAnimationNone];
	}
}

- (void)viewDidAppear:(BOOL)animated {
	
	[super viewDidAppear:animated];
	
	if (cameraNavController != nil) {
		
		int i = 0;
		NSIndexPath *indexPath;
		for (AlbumSummary *a in albumList) {
			
			if (a.albumId == cameraNavController.selectedAlbum.albumId) {
				indexPath = [NSIndexPath indexPathForRow:i inSection:0];
				NSLog(@"found at indexPath %@", indexPath);
				[self performSegueWithIdentifier:@"AlbumGridViewSegue" sender:[self.tableView cellForRowAtIndexPath:indexPath]];
				
				break;
			}
			i ++;
		}
		//[self cameraWasDismissedWithAlbum:cameraNavController.selectedAlbum];
		cameraNavController = nil;
	}
	
	self.menuContainerViewController.panMode = MFSideMenuPanModeNone;
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [thumbnailCache removeAllObjects];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (self.albumField.isFirstResponder)
	{
        [self.albumField resignFirstResponder];
    }
    else if (self.searchbar.isFirstResponder)
    {
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	return self.sectionHeader;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 45;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return albumList.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SVAlbumListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SVAlbumListCell"];
    //NSLog(@"++++++++++++++++++++++++++++ config table cell at row %i", indexPath.row);
	
	// Configure thumbnail
	
    [cell.networkImageView setImage:nil];
	//cell.networkImageView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.1].CGColor;
	//cell.networkImageView.layer.borderWidth = 1;
	
    cell.tag = indexPath.row;
	//__block NSIndexPath *tagIndex = indexPath;
    AlbumSummary *album = [albumList objectAtIndex:indexPath.row];
	
	NSString *distanceOfTimeInWords = [album.dateUpdated distanceOfTimeInWords];
	
	cell.title.text = album.name;
	[cell.timestamp setTitle:distanceOfTimeInWords forState:UIControlStateNormal];

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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	cell.backgroundColor = [UIColor whiteColor];
}


#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
	tappedCell = [indexPath copy];
	
	/*[_queue addOperationWithBlock:^{

		
		AlbumSummary *anAlbum = [self.fetchedResultsController objectAtIndexPath:indexPath];
		[[SVEntityStore sharedStore] setPhotosInAlbumToNotNew:anAlbum];
     
		//[[SVEntityStore sharedStore] setAllPhotosToNotNew];
	}];*/
}

/*
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:newIndexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:newIndexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];

*/


#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self createNewAlbumWithTitle:textField.text];
    [self textFieldDidEndEditing:textField];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    //[self hideDropDown];
	// this is causing the dropdown to be called twice
}


#pragma mark - UISearchbarDelegate Methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
	CGRect r = self.tableOverlayView.frame;
	r.origin.y = 44;
	
	[UIView animateWithDuration:0.3 animations:^{
		
		self.tableOverlayView.frame = r;
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
    UIBarButtonItem *butProfile = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"contactsIcon.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(profilePressed)];
    self.navigationItem.leftBarButtonItem = butProfile;
    
    // Setup menu button
    UIBarButtonItem *managementButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settingsIcon.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(settingsPressed)];
    self.navigationItem.rightBarButtonItem = managementButton;
    
	UIImage *search_bg = [UIImage imageNamed:@"searchFieldBg.png"];
	UIEdgeInsets insets = UIEdgeInsetsMake(5, 20, 5, 20);
	UIImage *resizableImage = [search_bg resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
	
	self.searchbar.backgroundImage = resizableImage;
	[self.searchbar setSearchFieldBackgroundImage:[UIImage imageNamed:@"butTransparent.png"] forState:UIControlStateNormal];
	[self.searchbar setImage:[UIImage imageNamed:@"searchFieldIcon.png"] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
	
    // Configure the dropdown background image
    {
        UIImage *baseImage = [UIImage imageNamed:@"dropDownField.png"];
        UIEdgeInsets insets = UIEdgeInsetsMake(0, 50, 0, 50);
        
        UIImage *resizableImage = nil;
        if (IS_IOS6_OR_GREATER) {
            resizableImage = [baseImage resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
        }
        else
        {
            resizableImage = [baseImage resizableImageWithCapInsets:insets];
        }
        
        [self.dropDownBackground setImage:resizableImage];
    }
	
	// Set required taps and number of touches
	UITapGestureRecognizer *touchOnView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(releaseOverlay)];
	[touchOnView setNumberOfTapsRequired:1];
	[touchOnView setNumberOfTouchesRequired:1];
	[self.tableOverlayView addGestureRecognizer:touchOnView];
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
	
	CGRect r = self.tableOverlayView.frame;
	r.origin.y = 45;
	self.tableOverlayView.frame = r;
	self.tableOverlayView.alpha = 0;
    self.tableOverlayView.hidden = NO;
    self.dropDownContainer.hidden = NO;
	self.albumButton.enabled = NO;
	self.takePictureButton.enabled = NO;
    
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
    }];
}


- (void)createNewAlbumWithTitle:(NSString *)title
{
	// Add a placeholder album till the real one is created on server
	AlbumSummary *album = [[AlbumSummary alloc] initWithAlbumId:0
														   etag:@""
														   name:title
													dateCreated:[NSDate date]
													dateUpdated:[NSDate date]
												   latestPhotos:[NSArray array]];
	[albumList insertObject:album atIndex:0];
	[self.tableView beginUpdates];
	[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
	[self.tableView endUpdates];
	
	// Write the album to server
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error;
        AlbumContents *albumContents = [[self.albumManager getShotVibeAPI] createNewBlankAlbum:title withError:&error];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (!albumContents) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Creating Album"
                                                                message:[error description]
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
				// Remove temporary album
				[albumList removeObjectAtIndex:0];
				[self.tableView beginUpdates];
				[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
				[self.tableView endUpdates];
            }
            else {
				creatingAlbum = YES;
                [self.albumManager refreshAlbumList];
            }
        });
    });
}



- (void)setAlbumList:(NSArray *)albums
{
	allAlbums = albums;
    [self searchForAlbumWithTitle:nil];
}


#pragma mark UIRefreshView

-(void)refreshView
{
    [self.albumManager refreshAlbumList];
}

- (void)onAlbumListBeginRefresh
{
	if (!creatingAlbum) {
		[refresh beginRefreshing];
		refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing albums..."];
	}
}

- (void)onAlbumListRefreshComplete:(NSArray *)albums
{
	[refresh endRefreshing];
	refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
	
	[self setAlbumList:albums];
	[self.tableView setContentOffset:CGPointMake(0,44) animated:YES];
	
	creatingAlbum = NO;
}

- (void)onAlbumListRefreshError:(NSError *)error
{
    [refresh endRefreshing];
	refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];

    // TODO ...
}

@end
