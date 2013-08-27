//
//  SVAlbumListViewController.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVAlbumListViewController.h"

@interface SVAlbumListViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
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
//- (SVAlbumListViewCell *)configureCell:(SVAlbumListViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
//- (void)updateCell:(SVAlbumListViewCell *)cell AtIndexPath:(NSIndexPath *)indexPath;
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
{
    BOOL searchShowing;
    NSMutableDictionary *thumbnailCache;
	UIView *sectionView;
	NSIndexPath *tappedCell;
	NSOperationQueue *_queue;
	CaptureNavigationController *cameraNavController;
}

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
    // Max of 9 albums wat
    NSUInteger albumCount = 0;
    
    NSMutableArray *albumsForCapture = [[NSMutableArray alloc] init];
    
    for (Album *anAlbum in self.fetchedResultsController.fetchedObjects) {
        [albumsForCapture addObject:anAlbum];
        
        albumCount++;
        
        if (albumCount > 20) {
            break;
        }
    }
    
    cameraNavController = [[CaptureNavigationController alloc] init];
	cameraNavController.cameraDelegate = self;
	cameraNavController.albums = albumsForCapture;
    cameraNavController.nav = self.navigationController;// this is set last
}


#pragma mark camera delegate

- (void)cameraExit {
	
	NSLog(@"CAMERA EXIT, do nothing");
	cameraNavController = nil;
}

- (void) cameraWasDismissedWithAlbum:(Album*)selectedAlbum {
	
	NSLog(@"CAMERA WAS DISMISSED %@", selectedAlbum);
	
	if (self.navigationController.visibleViewController == self) {
		NSLog(@"navigate to gridview");
		
		int i = 0;
		NSIndexPath *indexPath;
		id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:0];
		for (Album *a in [sectionInfo objects]) {
			
			if ([a.albumId isEqualToString:selectedAlbum.albumId]) {
				indexPath = [NSIndexPath indexPathForRow:i inSection:0];
				NSLog(@"found at indexPath %@", indexPath);
				[self performSegueWithIdentifier:@"AlbumGridViewSegue" sender:[self.tableView cellForRowAtIndexPath:indexPath]];
				
				break;
			}
			i ++;
		}
	}
}


#pragma mark - UIViewController Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	_queue = [[NSOperationQueue alloc] init];
	
    self.albumPhotoInfo = [[NSMutableDictionary alloc] init];
    self.imageLoadingQueue = [[NSOperationQueue alloc] init];
    self.imageLoadingQueue.maxConcurrentOperationCount = 1;
    thumbnailCache = [[NSMutableDictionary alloc] init];
	self.searchbar.placeholder = NSLocalizedString(@"Search an album", nil);
	
    [self configureViews];
	
	[self.tableView setContentOffset:CGPointMake(0,44) animated:YES];
	
	UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
	refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
	[refresh addTarget:self action:@selector(refreshView:) forControlEvents:UIControlEventValueChanged];
	[self.tableView addSubview:refresh];
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadCompleted:) name:kSVSyncEngineDownloadCompletedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumUpdateReceived:) name:kSVSyncEngineAlbumProcessedNotification object:nil];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (tappedCell != nil) {
		[self.tableView reloadRowsAtIndexPaths:@[tappedCell] withRowAnimation:UITableViewRowAnimationNone];
	}

	[[SVDownloadManager sharedManager] download];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if (cameraNavController != nil) {
		[self cameraWasDismissedWithAlbum:cameraNavController.selectedAlbum];
		cameraNavController = nil;
	}
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [thumbnailCache removeAllObjects];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (self.albumField.isFirstResponder) {
        [self.albumField resignFirstResponder];
    }
    else if (self.searchbar.isFirstResponder)
    {
        [self.searchbar resignFirstResponder];
    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"AlbumGridViewSegue"]) {
        
        // Get the selected Album
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        Album *selectedAlbum = [self.fetchedResultsController objectAtIndexPath:indexPath];
		
        // Get the destination controller
        SVAlbumGridViewController *destinationController = segue.destinationViewController;
        
        // Send the selected album to the destination controller
        destinationController.selectedAlbum = selectedAlbum;
        
    }
	else if ([segue.identifier isEqualToString:@"ProfileSegue"]) {
		
		
	}
}


- (BOOL)shouldAutorotate
{
	//UIViewController *visibleController = self.navigationController.visibleViewController;
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
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
	NSLog(@"fetch albums %@", sectionInfo);
    return [sectionInfo numberOfObjects];
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
	__block NSIndexPath *tagIndex = indexPath;
	__block Album *anAlbum = [self.fetchedResultsController objectAtIndexPath:indexPath];
	
	NSString *distanceOfTimeInWords = [anAlbum.last_updated distanceOfTimeInWords];
	
	cell.title.text = anAlbum.name;
	[cell.timestamp setTitle:distanceOfTimeInWords forState:UIControlStateNormal];
	
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0),^{
		
	if (cell.tag == tagIndex.row) {
			
		NSSortDescriptor *datecreatedDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date_created" ascending:YES];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"album.albumId == %@ AND objectSyncStatus != %i", anAlbum.albumId, SVObjectSyncDeleteNeeded];
		NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"AlbumPhoto"];
		fetchRequest.sortDescriptors = @[datecreatedDescriptor];
		fetchRequest.predicate = predicate;
		
		NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																								   managedObjectContext:[NSManagedObjectContext defaultContext]
																									 sectionNameKeyPath:nil
																											  cacheName:nil];
		[fetchedResultsController performFetch:nil];
		NSArray *photos = [fetchedResultsController fetchedObjects];
			
		if (photos.count > 0) {
			
			__block AlbumPhoto *firstPhoto = [photos objectAtIndex:0];
			UIImage *image = [thumbnailCache objectForKey:firstPhoto.photo_id];
			
			if (!image) {
				__block NSString *photoId = firstPhoto.photo_id;
				[[SVEntityStore sharedStore] getImageForPhoto:firstPhoto WithCompletion:^(UIImage *network_image) {
					
					if (network_image) {
						
						dispatch_async(dispatch_get_main_queue(),^{
							cell.networkImageView.image = network_image;
							[thumbnailCache setObject:network_image forKey:photoId];
						});
					}
				}];
			}
			else {
				dispatch_async(dispatch_get_main_queue(),^{
					[cell.networkImageView setImage:image];
				});
			}
			
			dispatch_async(dispatch_get_main_queue(),^{
				@try {
				cell.author.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Last added by", @""), firstPhoto.author.nickname];
				}
				@catch (NSException *exc) {
					NSLog(@"%@", exc);
				}
			});
		}
		else {
			dispatch_async(dispatch_get_main_queue(),^{
				[cell.networkImageView setImage:[UIImage imageNamed:@"placeholderImage"]];
			});
		}
		
		// Set the number of unviewed photos
			
		//NSInteger numberNew = [AlbumPhoto countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"album.albumId == %@ AND isNew == YES", anAlbum.albumId]];
		NSInteger numberNew = [AlbumPhoto countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"album.albumId == %@ AND hasViewed == NO", anAlbum.albumId]];
		
		dispatch_async(dispatch_get_main_queue(),^{
			if (numberNew > 0 ) {
				[cell.numberNotViewedIndicator setHidden:NO];
				[cell.numberNotViewedIndicator setTitle:[NSString stringWithFormat:@"%i", numberNew] forState:UIControlStateNormal];
			}else{
				[cell.numberNotViewedIndicator setHidden:YES];
			}
		});
		
	}
	});
	
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
	
	[_queue addOperationWithBlock:^{
		
		Album *anAlbum = [self.fetchedResultsController objectAtIndexPath:indexPath];
		[[SVEntityStore sharedStore] setPhotosInAlbumToNotNew:anAlbum];
		//[[SVEntityStore sharedStore] setAllPhotosToNotNew];
	}];
}


#pragma mark NSFetchedResultsControllerDelegate methods

- (NSFetchedResultsController *)fetchedResultsController
{
	if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
	_fetchedResultsController = [[SVEntityStore sharedStore] allAlbumsForCurrentUserWithDelegate:self];
	
	return _fetchedResultsController;
}


- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath
	 forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath
{
    //NSLog(@"didChangeObject type:%i %@", type, indexPath);
    //SVAlbumListViewCell *cell = (SVAlbumListViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:newIndexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeUpdate:
			[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:newIndexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        default:
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}


#pragma mark - RCImageViewDelegate

- (void)imageView:(RCImageView*)imageView didFailWithError:(NSError *)error
{
	NSLog(@"networkImageView didFailWithError %@", error);
}


#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self createNewAlbumWithTitle:textField.text];
    [self textFieldDidEndEditing:textField];
    return YES;
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self hideDropDown];
	
}


#pragma mark - UISearchbarDelegate Methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [self searchForAlbumWithTitle:searchBar.text];
	
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
	
	UITapGestureRecognizer *touchOnView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(releaseOverlay)];
	
	// Set required taps and number of touches
	[touchOnView setNumberOfTapsRequired:1];
	[touchOnView setNumberOfTouchesRequired:1];
	
	// Add the gesture to the view
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
	[[SVEntityStore sharedStore] newAlbumWithName:title andUserID:[[NSUserDefaults standardUserDefaults] objectForKey:kApplicationUserId]];
	[[SVUploadManager sharedManager] upload];
}



- (void)searchForAlbumWithTitle:(NSString *)title
{

    self.fetchedResultsController = nil;
    self.fetchedResultsController = [[SVEntityStore sharedStore] allAlbumsMatchingSearchTerm:title WithDelegate:self];
    [self.tableView reloadData];
}





#pragma mark DownloadManager Ntifications

- (void)albumUpdateReceived:(NSNotification *)notification
{
    Album *updatedAlbum = (Album *)notification.object;
    
    NSIndexPath *albumIndex = [self.fetchedResultsController indexPathForObject:updatedAlbum];
    
    if (albumIndex) {
        SVAlbumListViewCell *albumCell = (SVAlbumListViewCell *)[self.tableView cellForRowAtIndexPath:albumIndex];
        
        if (albumCell) {
            //if (albumCell.networkImageView.initialImage == albumCell.networkImageView.image) {
			[self.tableView reloadRowsAtIndexPaths:@[albumIndex] withRowAnimation:UITableViewRowAnimationNone];
            //}
        }
    }
}


- (void)downloadCompleted:(NSNotification *)notification
{
	NSLog(@"DOWNLOAD COMPLETE, start the upload process");
    //[self.fetchedResultsController performFetch:nil];
    //[self.tableView reloadData];
	
	[[SVUploadManager sharedManager] upload];
}



-(void)refreshView:(UIRefreshControl *)refresh {
	
	refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing albums..."];
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"MMM d, h:mm a"];
	NSString *lastUpdated = [NSString stringWithFormat:@"Last updated on %@", [formatter stringFromDate:[NSDate date]]];
	refresh.attributedTitle = [[NSAttributedString alloc] initWithString:lastUpdated];
	[refresh endRefreshing];
	[[SVDownloadManager sharedManager] download];
}

@end
