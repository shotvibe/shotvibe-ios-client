//
//  SVAlbumListViewController.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "Album.h"
#import "NINetworkImageView.h"
#import "SVAlbumListViewCell.h"
#import "SVAlbumListViewController.h"
#import "SVAlbumGridViewController.h"
#import "SVOfflineStorageWS.h"
#import "SVDefines.h"
#import "SVEntityStore.h"
#import "NSDate+Formatting.h"
#import "Member.h"
#import "AlbumPhoto.h"
#import "SVBusinessDelegate.h"
#import "CaptureViewfinderController.h"
#import "CaptureNavigationController.h"
#import "MagicalRecordShorthand.h"
#import "MagicalRecord+Actions.h"
#import "NSManagedObjectContext+MagicalRecord.h"
#import "SVEntityStore.h"
#import <Crashlytics/Crashlytics.h>

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

@property (nonatomic, strong) NSOperationQueue *imageLoadingQueue;


- (void)configureViews;
- (SVAlbumListViewCell *)configureCell:(SVAlbumListViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)updateCell:(SVAlbumListViewCell *)cell AtIndexPath:(NSIndexPath *)indexPath;
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
}

#pragma mark - Actions

- (void)profilePressed
{
	[self performSegueWithIdentifier:@"ProfileSegue" sender:nil];
}


- (void)settingsPressed
{
    [self performSegueWithIdentifier:@"SettingsSegue" sender:nil];
}


- (IBAction)newAlbumButtonPressed:(id)sender
{
    [self showDropDown];
}


- (IBAction)newAlbumClose:(id)sender
{
    [self hideDropDown];
}


- (IBAction)newAlbumDone:(id)sender
{
	NSString *name = self.albumField.text.length == 0 ? self.albumField.placeholder : self.albumField.text;
    [self createNewAlbumWithTitle:name];
    [self hideDropDown];
}


- (IBAction)takePicturePressed:(id)sender
{
    // Max of 9 albums wat
    NSUInteger albumCount = 0;
    
    NSMutableArray *albumsForCapture = [[NSMutableArray alloc] init];
    
    for (Album *anAlbum in self.fetchedResultsController.fetchedObjects) {
        [albumsForCapture addObject:anAlbum];
        
        albumCount++;
        
        if (albumCount > 9) {
            break;
        }
    }
    
    
    CaptureViewfinderController *cameraController = [[CaptureViewfinderController alloc] initWithNibName:@"CaptureViewfinder" bundle:[NSBundle mainBundle]];
    cameraController.albums = albumsForCapture;
    
    CaptureNavigationController *cameraNavController = [[CaptureNavigationController alloc] initWithRootViewController:cameraController];
    
    [self presentViewController:cameraNavController animated:YES completion:nil];
}


#pragma mark - UIViewController Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    // When we get to the album list view we no longer need to worry about rotation blocks from logging in, switch it to allowing rotation.
    CaptureNavigationController *navController = (CaptureNavigationController *)self.navigationController;
    navController.allowsRotation = YES;
    
    self.albumPhotoInfo = [[NSMutableDictionary alloc] init];
    self.imageLoadingQueue = [[NSOperationQueue alloc] init];
    self.imageLoadingQueue.maxConcurrentOperationCount = 1;
    
    thumbnailCache = [[NSMutableDictionary alloc] init];

    [self configureViews];
	
	//[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
	[self.tableView setContentOffset:CGPointMake(0,44)];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        SVAlbumListViewCell *listCell = (SVAlbumListViewCell *)cell;
        
        [self updateCell:listCell AtIndexPath:[self.tableView indexPathForCell:cell]];
    }
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncCompleted:) name:kSVSyncEngineSyncCompletedNotification object:nil];
   // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumUpdateReceived:) name:kSVSyncEngineSyncAlbumCompletedNotification object:nil];
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
        NSLog(@"selectedAlbum %@", selectedAlbum);
        // Get the destination controller
        SVAlbumGridViewController *destinationController = segue.destinationViewController;
        
        // Send the selected ablum to the destination controller
        destinationController.selectedAlbum = selectedAlbum;
        
    }
	else if ([segue.identifier isEqualToString:@"ProfileSegue"]) {
		
		
	}
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}


- (BOOL)shouldAutorotate
{
    return YES;
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
    return [sectionInfo numberOfObjects];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SVAlbumListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SVAlbumListCell"];
    
    cell = [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}


#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark NSFetchedResultsControllerDelegate methods

- (NSFetchedResultsController *)fetchedResultsController
{
	NSLog(@"- (NSFetchedResultsController *)fetchedResultsController %@", _fetchedResultsController);
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
	_fetchedResultsController = [[SVEntityStore sharedStore] allAlbumsForCurrentUserWithDelegate:self];
	NSLog(@"- (NSFetchedResultsController *)fetchedResultsController %@", _fetchedResultsController);
    
	return _fetchedResultsController;
}


- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    
    SVAlbumListViewCell *cell = (SVAlbumListViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:newIndexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeUpdate:
            if (cell) {
                [self updateCell:cell AtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0] ];
            }
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


#pragma mark - NINetworkImageViewDelegate

- (void)networkImageView:(NINetworkImageView *)imageView didFailWithError:(NSError *)error
{

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
	self.tableOverlayView.hidden = NO;
	self.tableOverlayView.alpha = 0.5;
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
	self.tableOverlayView.hidden = YES;
	self.tableOverlayView.alpha = 0;
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
    
	self.searchbar.backgroundImage = [UIImage imageNamed:@"searchFieldBg.png"];
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


- (SVAlbumListViewCell *)configureCell:(SVAlbumListViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{

      
    // Configure thumbnail
    [cell.networkImageView prepareForReuse];
    cell.networkImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    cell.networkImageView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
    cell.networkImageView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.1].CGColor;
    cell.networkImageView.layer.borderWidth = 1;
    cell.networkImageView.contentMode = UIViewContentModeScaleAspectFill;
    cell.networkImageView.clipsToBounds = YES;
    cell.networkImageView.sizeForDisplay = YES;
    cell.networkImageView.scaleOptions = NINetworkImageViewScaleToFitCropsExcess;
    cell.networkImageView.interpolationQuality = kCGInterpolationHigh;
    cell.networkImageView.initialImage = [UIImage imageNamed:@"placeholderImage.png"];
    cell.networkImageView.delegate = self;
    cell.networkImageView.tag = indexPath.row; 

    Album *anAlbum = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"album.albumId == %@", anAlbum.albumId];
    NSDate *maxDate  = (NSDate *)[AlbumPhoto aggregateOperation:@"max:" onAttribute:@"date_created" withPredicate:predicate];
    
    __block AlbumPhoto *recentPhoto = [AlbumPhoto findFirstWithPredicate:[NSPredicate predicateWithFormat:@"album.albumId == %@ AND date_created == %@", anAlbum.albumId, maxDate]];
    
    if (recentPhoto) {
        
        UIImage *image = [thumbnailCache objectForKey:recentPhoto.photo_id];
        
        if (!image) {
            // Holding onto the tag index so that when our block returns we can check if we're still even looking at the same cell... This should prevent the roulette wheel
            __block NSIndexPath *tagIndex = indexPath;
            __block NSString *photoId = recentPhoto.photo_id;
            [[SVEntityStore sharedStore] getImageForPhoto:recentPhoto WithCompletion:^(UIImage *image) {
                if (image && cell.networkImageView.tag == tagIndex.row) {
                    [cell.networkImageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
                    
                    [thumbnailCache setObject:image forKey:photoId];
                }
            }];
        }
        else
        {
            [cell.networkImageView setImage:image];
        }
        
        
        NSString *lastAddedBy = NSLocalizedString(@"Last added by", @"");
        cell.author.text = [NSString stringWithFormat:@"%@ %@", lastAddedBy, recentPhoto.author.nickname];
    }
    else
    {
        UIImage *thumbnail = [SVBusinessDelegate getRandomThumbnailPlaceholder];
        [cell.networkImageView setImage:thumbnail];
    }
    
    
    cell.title.text = anAlbum.name;
    
    NSString *distanceOfTimeInWords = [anAlbum.last_updated distanceOfTimeInWords];
    [cell.timestamp setTitle:NSLocalizedString(distanceOfTimeInWords, @"") forState:UIControlStateNormal];
    
    NSInteger numberNew = [AlbumPhoto countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"album.albumId == %@ AND hasViewed == NO", anAlbum.albumId]];
    [cell.numberNotViewedIndicator setUserInteractionEnabled:NO];
    if (numberNew > 0 ) {
        [cell.numberNotViewedIndicator setHidden:NO];
        [cell.numberNotViewedIndicator setTitle:[NSString stringWithFormat:@"%i", numberNew] forState:UIControlStateNormal];
    }else{
        [cell.numberNotViewedIndicator setHidden:YES];
    }
    
    
    return cell;
}


- (void)updateCell:(SVAlbumListViewCell *)cell AtIndexPath:(NSIndexPath *)indexPath
{
    Album *anAlbum = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    //NSArray *photos = [[NSArray alloc] initWithArray:[[SVEntityStore sharedStore] allPhotosForAlbum:anAlbum WithDelegate:nil].fetchedObjects];
    
    NSArray *allPhotos = [anAlbum.albumPhotos allObjects];
    AlbumPhoto *recentPhoto = nil;
    if (allPhotos) {
        recentPhoto = [[allPhotos sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date_created" ascending:YES]]] lastObject];
    }
    
    if (recentPhoto) {
        // Holding onto the tag index so that when our block returns we can check if we're still even looking at the same cell... This should prevent the roulette wheel
        UIImage *image = [thumbnailCache objectForKey:recentPhoto.photo_id];
        
        if (!image) {
            // Holding onto the tag index so that when our block returns we can check if we're still even looking at the same cell... This should prevent the roulette wheel
            __block NSIndexPath *tagIndex = indexPath;
            __block NSString *photoId = recentPhoto.photo_id;
            [[SVEntityStore sharedStore] getImageForPhoto:recentPhoto WithCompletion:^(UIImage *image) {
                if (image && cell.networkImageView.tag == tagIndex.row) {
                    [cell.networkImageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
                    
                    [thumbnailCache setObject:image forKey:photoId];
                }
            }];
        }
        else
        {
            [cell.networkImageView setImage:image];
        }
        
        NSString *lastAddedBy = NSLocalizedString(@"Last added by", @"");
        cell.author.text = [NSString stringWithFormat:@"%@ %@", lastAddedBy, recentPhoto.author.nickname];
    }
    else
    {
        [cell.networkImageView setImage:[SVBusinessDelegate getRandomThumbnailPlaceholder]];
    }
    
    
    cell.title.text = anAlbum.name;
    
    NSString *distanceOfTimeInWords = [anAlbum.last_updated distanceOfTimeInWords];
    [cell.timestamp setTitle:NSLocalizedString(distanceOfTimeInWords, @"") forState:UIControlStateNormal];
    
    NSInteger numberNew = [AlbumPhoto countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"album.albumId == %@ AND hasViewed == NO", anAlbum.albumId]];
    [cell.numberNotViewedIndicator setUserInteractionEnabled:NO];
    if (numberNew > 0) {
        [cell.numberNotViewedIndicator setHidden:NO];
        [cell.numberNotViewedIndicator setTitle:[NSString stringWithFormat:@"%i", numberNew] forState:UIControlStateNormal];
    }else{
        [cell.numberNotViewedIndicator setHidden:YES];
    }
    
}


- (void)showDropDown
{
	
	//[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
	[self.tableView setContentOffset:CGPointMake(0,44)];
	
	//[self.sectionHeader insertSubview:self.dropDownContainer atIndex:0];
	
    self.tableOverlayView.hidden = NO;
    self.dropDownContainer.hidden = NO;
    
    NSString *currentDateString = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle];
    self.albumField.text = @"";
	self.albumField.placeholder = currentDateString;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.tableOverlayView.alpha = 0.3;
        self.dropDownContainer.frame = CGRectMake(8, 44, self.dropDownContainer.frame.size.width, 134);
    } completion:^(BOOL finished) {
        [self.albumField becomeFirstResponder];
    }];
}


- (void)hideDropDown
{
    
	[UIView animateWithDuration:0.3 animations:^{
        self.tableOverlayView.alpha = 0.0;
        self.dropDownContainer.frame = CGRectMake(6, -134, self.dropDownContainer.frame.size.width, 134);
    } completion:^(BOOL finished) {
        self.tableOverlayView.hidden = YES;
        self.dropDownContainer.hidden = YES;
		[self.albumField resignFirstResponder];
    }];
}



- (void)searchForAlbumWithTitle:(NSString *)title
{

    self.fetchedResultsController = nil;
    self.fetchedResultsController = [[SVEntityStore sharedStore] allAlbumsMatchingSearchTerm:title WithDelegate:self];
    [self.tableView reloadData];
}


- (void)createNewAlbumWithTitle:(NSString *)title
{
    if (title && title.length > 0) {        
        [[SVEntityStore sharedStore] newAlbumWithName:title andUserID:[[NSUserDefaults standardUserDefaults] objectForKey:kApplicationUserId]];
    } else {
        //TODO: Alert the user that they can not create an album with no title.
    }
}


- (void)albumUpdateReceived:(NSNotification *)notification
{
    Album *updatedAlbum = (Album *)notification.object;
    
    NSIndexPath *albumIndex = [self.fetchedResultsController indexPathForObject:updatedAlbum];
    
    if (albumIndex) {
        SVAlbumListViewCell *albumCell = (SVAlbumListViewCell *)[self.tableView cellForRowAtIndexPath:albumIndex];
        
        if (albumCell) {
            if (albumCell.networkImageView.initialImage == albumCell.networkImageView.image) {
                [self.tableView reloadRowsAtIndexPaths:@[albumIndex] withRowAnimation:UITableViewRowAnimationNone];
            }
        }
    }
}


- (void)syncCompleted:(NSNotification *)notification
{
    [self.fetchedResultsController performFetch:nil];
    [self.tableView reloadData];
}


- (AlbumPhoto *)findMostRecentPhotoInPhotoSet:(NSArray *)photos
{
    AlbumPhoto *lastPhoto = [photos lastObject];
    
    if (lastPhoto) {
        NSArray *nextSet = [photos filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"date_created > %@", lastPhoto.date_created]];
        
        if (nextSet.count > 0) {
            return [self findMostRecentPhotoInPhotoSet:nextSet];
        }
        else
        {
            return lastPhoto;
        }
    }
    else
    {
        return nil;
    }
}
@end
