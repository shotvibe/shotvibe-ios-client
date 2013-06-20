//
//  SVAlbumListViewController.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "Album.h"
#import "NINetworkImageView.h"
#import "Photo.h"
#import "SVAlbumListViewCell.h"
#import "SVAlbumListViewController.h"
#import "SVAlbumGridViewController.h"
#import "SVDefines.h"
#import "SVEntityStore.h"
#import "NSDate+Formatting.h"
#import "Member.h"
#import "AlbumPhoto.h"
#import "SVBusinessDelegate.h"
#import "CaptureViewfinderController.h"
#import "CaptureNavigationController.h"
#import "SyncEngine.h"

@interface SVAlbumListViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableDictionary *albumPhotoInfo;
@property (nonatomic, strong) IBOutlet UIView *tableOverlayView;
@property (nonatomic, strong) IBOutlet UIView *dropDownContainer;
@property (nonatomic, strong) IBOutlet UIImageView *dropDownBackground;
@property (nonatomic, strong) IBOutlet UITextField *albumField;
@property (nonatomic, strong) IBOutlet UISearchBar *searchbar;
@property (nonatomic, strong) IBOutlet UIView *viewContainer;
@property (nonatomic, strong) IBOutlet NSMutableArray *updatedAlbums;
@property (nonatomic, strong) IBOutlet NSMutableArray *albumIds;


- (void)configureViews;
- (void)loadData;
- (SVAlbumListViewCell *)configureCell:(SVAlbumListViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)searchPressed;
- (void)settingsPressed;
- (void)configureNumberNotViewed:(NSNotification *)notification;
- (void)fetchAlbumPhotoInfo  :(NSNotification *) albumDetail;
- (void)showDropDown;
- (void)hideDropDown;
- (void)showSearch;
- (void)hideSearch;
- (void)searchForAlbumWithTitle:(NSString *)title;
- (void)createNewAlbumWithTitle:(NSString *)title;
- (IBAction)newAlbumButtonPressed:(id)sender;
- (IBAction)newAlbumClose:(id)sender;
- (IBAction)newAlbumDone:(id)sender;
- (IBAction)takePicturePressed:(id)sender;

@end


@implementation SVAlbumListViewController
{
    BOOL searchShowing;
}

#pragma mark - Actions

- (void)searchPressed
{
    if (searchShowing) {
        [self hideSearch];
    }
    else
    {
        [self showSearch];
    }
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
    [self createNewAlbumWithTitle:self.albumField.text];
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

    [self configureViews];
    

    // Set debug logging level. Set to 'RKLogLevelTrace' to see JSON payload
    RKLogConfigureByName("ShotVibe/Albums", RKLogLevelDebug);
    
    // Listen for our RestKit loads to finish
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configureNumberNotViewed:) name:kPhotosLoadedForIndexPathNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchAlbumPhotoInfo:) name:kUserAlbumsLoadedNotification object:nil];

// // Reset to all albums
//    [self albumSearch:nil];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self loadData];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

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
        
        // Send the selected ablum to the destination controller
        destinationController.selectedAlbum = selectedAlbum;
        
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
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
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


#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark NSFetchedResultsControllerDelegate methods

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView reloadData];
}


#pragma mark - NINetworkImageViewDelegate

- (void)networkImageView:(NINetworkImageView *)imageView didFailWithError:(NSError *)error
{
    __block Album *anAlbum = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:imageView.tag inSection:0]];

    NSArray *photos = [anAlbum.albumPhotos allObjects];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:YES];
    
    NSArray *sortedPhotos = [photos sortedArrayUsingDescriptors:@[descriptor]];
    
    __block AlbumPhoto *recentPhoto = [sortedPhotos lastObject];
    
    [SVBusinessDelegate loadImageFromAlbum:anAlbum withPath:recentPhoto.photoId WithCompletion:^(UIImage *image, NSError *error) {
        if (image) {
            [imageView setImage:image];
        }
    }];
}


#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
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
}


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self searchForAlbumWithTitle:searchBar.text];
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self searchForAlbumWithTitle:searchBar.text];
    [searchBar resignFirstResponder];
}


#pragma mark - Private Methods

- (void)configureViews
{
    // Setup titleview
    UIImageView *titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"shotvibeLogo.png"]];
    UIView *titleContainer = [[UIView alloc] initWithFrame:titleView.frame];
    [titleContainer addSubview:titleView];
    titleContainer.clipsToBounds = NO;
    titleContainer.backgroundColor = [UIColor clearColor];
    titleView.frame = CGRectMake(0, -1, titleView.frame.size.width, titleView.frame.size.height);
    self.navigationItem.titleView = titleContainer;
    
    // Setup menu button
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"searchIcon.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(searchPressed)];
    self.navigationItem.leftBarButtonItem = menuButton;
    
    // Setup menu button
    UIBarButtonItem *managementButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settingsIcon.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(settingsPressed)];
    self.navigationItem.rightBarButtonItem = managementButton;
    
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
}


/*
 * load data, via bg sync
 */
- (void)loadData
{
 [[SyncEngine sharedEngine] startSync];
}


- (SVAlbumListViewCell *)configureCell:(SVAlbumListViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    // TODO: We need to configure our cell's views
    //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    __block Album *anAlbum = [self.fetchedResultsController objectAtIndexPath:indexPath];

    NSArray *photos = [anAlbum.albumPhotos allObjects];

 NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:YES];

    NSArray *sortedPhotos = [photos sortedArrayUsingDescriptors:@[descriptor]];
    
    
    __block AlbumPhoto *recentPhoto = [sortedPhotos lastObject];
 
    NSString *thumbnailUrl = [[recentPhoto.photoUrl stringByDeletingPathExtension] stringByAppendingString:kPhotoThumbExtension];
 
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
    [cell.networkImageView setPathToNetworkImage:thumbnailUrl];
 
    NSLog(@"album, album id, photo id, image, path: %@, %@, %@, %@, %@", anAlbum.name, anAlbum.albumId,  recentPhoto.photoId, recentPhoto.photoUrl, thumbnailUrl);
 
    [SVBusinessDelegate loadImageFromAlbum:anAlbum withPath:recentPhoto.photoId WithCompletion:^(UIImage *image, NSError *error) {
        if (image)
        {
            [cell.networkImageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
        }
    }];
    
    
    
    cell.title.text = anAlbum.name;
    
    NSString *lastAddedBy = NSLocalizedString(@"Last Added By", @"");
    cell.author.text = [NSString stringWithFormat:@"%@ %@", lastAddedBy, recentPhoto.author.nickname];
    
    NSString *distanceOfTimeInWords = [anAlbum.lastUpdated distanceOfTimeInWords];
    [cell.timestamp setTitle:NSLocalizedString(distanceOfTimeInWords, @"") forState:UIControlStateNormal];
    
    NSNumber *numberNew = [self.albumPhotoInfo objectForKey:indexPath];
 
    if (numberNew)
    {
        [cell.numberNotViewedIndicator setTitle:[NSString stringWithFormat:@"%@", numberNew] forState:UIControlStateNormal];
    }
    else
    {
        [cell.numberNotViewedIndicator setTitle:[NSString stringWithFormat:@"%i", 0] forState:UIControlStateNormal];
    }
    
    return cell;
}


/*
 * this is the notification handler for the album list
 */
- (void)configureNumberNotViewed:(NSNotification *)notification
{
 NSMutableArray *data = [notification object];

 NSIndexPath *indexPath = [data objectAtIndex:0];

 Album *anAlbum = [data objectAtIndex:1];

 NSNumber *albumId = anAlbum.albumId;

 //
 // 20130519 - download all photos (thumbnails) for an album.  this provides the user with a better UX as the photos
 //            will be on the device after the initial launch, and any updates.  the initial load will take time depending
 //            on the number of photos
 //
 
 BOOL photoDoesNotExist = NO;
 
 for(Photo *photo in anAlbum.photos)
 {
  if(photoDoesNotExist)
  {
   dispatch_async(dispatch_get_global_queue(0,0), ^{
    
    NSData * imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: photo.photoUrl]];
    UIImage *image = [UIImage imageWithData: imageData];
    
    if ( image == nil )
     return;
    
    [SVBusinessDelegate saveImage:image forPhoto:photo];
   });
  }
 }
 
 
 //
 // this was initially to determine which photos were new, and only download those, but currently it is used to
 // flag the 'number not viewed' tag in the cell (assuming the etag is accurate)
 //
 for(NSDictionary *albumWork in self.updatedAlbums)
 {
  if([albumId intValue] == [[albumWork objectForKey:@"albumId"] intValue])
  {
   SVAlbumListViewCell *cell = (SVAlbumListViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
   
//   NSLog(@"updated count:  %i", [[albumWork objectForKey:@"count"] intValue]);
   
   [self.albumPhotoInfo setObject:[NSNumber numberWithInteger:[[albumWork objectForKey:@"count"] intValue]] forKey:indexPath];
   [cell.numberNotViewedIndicator setTitle:[NSString stringWithFormat:@"%i", [[albumWork objectForKey:@"count"] intValue]] forState:UIControlStateNormal];
   
   break;
  }
 }
}


/*
 * get all album info
 */
- (void)fetchAlbumPhotoInfo :(NSNotification *) albumDetail
{
  self.updatedAlbums = [albumDetail object];
 
 // search and retrieve all albums
 [self albumSearch:nil];
 
 self.albumIds = [[NSMutableArray alloc] init];
 
 // Start figuring out how many new photos we have
 NSArray *fetchedObjects = self.fetchedResultsController.fetchedObjects;

 for (Album *anAlbum in fetchedObjects)
 {
  NSLog(@"album:  %@", anAlbum.name);
  
  if (anAlbum)
  {
   [self.albumIds addObject:anAlbum.albumId];    // cache the name
   
   [[SVEntityStore sharedStore] photosForAlbumWithID:anAlbum atIndexPath:[NSIndexPath indexPathForRow:[fetchedObjects indexOfObject:anAlbum] inSection:0]];
  }
 }

 
 [[SyncEngine sharedEngine] setInitialSyncCompleted];
 
 [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


- (void)showDropDown
{
    self.tableOverlayView.hidden = NO;
    self.dropDownContainer.hidden = NO;
    
    NSString *currentDateString = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];
    [self.albumField setText:currentDateString];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.tableOverlayView.alpha = 0.3;
        self.dropDownContainer.frame = CGRectMake(6, 34, self.dropDownContainer.frame.size.width, 134);
    } completion:^(BOOL finished) {
        [self.albumField becomeFirstResponder];
    }];
    
}


- (void)hideDropDown
{
    
    [UIView animateWithDuration:0.3 animations:^{
        self.tableOverlayView.alpha = 0.0;
        self.dropDownContainer.frame = CGRectMake(6, -80, self.dropDownContainer.frame.size.width, 134);
    } completion:^(BOOL finished) {
        self.tableOverlayView.hidden = YES;
        self.dropDownContainer.hidden = YES;
        [self.albumField resignFirstResponder];
    }];
}


- (void)showSearch
{
    searchShowing = YES;
    self.searchbar.hidden = NO;
    
    [self.searchbar becomeFirstResponder];

    [UIView animateWithDuration:0.15 animations:^{
        self.searchbar.frame = CGRectMake(0, 0, self.searchbar.frame.size.width, self.searchbar.frame.size.height);
        self.searchbar.alpha = 1.0;
        self.viewContainer.frame = CGRectMake(0, 40, self.view.frame.size.width, self.view.frame.size.height -40);
    } completion:^(BOOL finished) {
    }];
}


- (void)hideSearch
{
    searchShowing = NO;

    [self.searchbar resignFirstResponder];
    [UIView animateWithDuration:0.15 animations:^{
        self.searchbar.frame = CGRectMake(0, -44, self.searchbar.frame.size.width, self.searchbar.frame.size.height);
        self.searchbar.alpha = 0.0;
        self.viewContainer.frame = CGRectMake(0, -4, self.view.frame.size.width, self.view.frame.size.height+4);
    } completion:^(BOOL finished) {
        self.searchbar.hidden = YES;
    }];

 
 // Reset to all albums
 [self albumSearch:nil];
 
 [self fetchAlbumPhotoInfo:nil];
}



- (void)searchForAlbumWithTitle:(NSString *)title
{
 NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name BEGINSWITH[cd] %@", title];

 [self albumSearch:predicate];
 
 [self fetchAlbumPhotoInfo:nil];
}


/*
 * single method to retrieve album content
 */
- (void) albumSearch :(NSPredicate *) predicate
{
 NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Album"];
 NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"lastUpdated" ascending:NO];  // dateCreated
 fetchRequest.sortDescriptors = @[descriptor];
 
 if(predicate != nil)
 {
  fetchRequest.predicate = predicate;
 }

 NSError *error = nil;
 
 // Setup fetched results
 self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
 
 [self.fetchedResultsController setDelegate:self];
 
 if (![self.fetchedResultsController performFetch:&error]) {
  RKLogError(@"There was an error loading the fetched result controller: %@", error);
 }
 
 [self.tableView reloadData];
}





- (void)createNewAlbumWithTitle:(NSString *)title
{
    if (title && title.length > 0) {
        [[SVEntityStore sharedStore] newAlbumWithName:title];
    } else {
        //TODO: Alert the user that they can not create an album with no title.
    }
}
@end
