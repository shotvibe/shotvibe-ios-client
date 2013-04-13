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
#import "SVCameraViewController.h"

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

- (void)configureViews;
- (void)loadData;
- (SVAlbumListViewCell *)configureCell:(SVAlbumListViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)searchPressed;
- (void)settingsPressed;
- (void)configureNumberNotViewed:(NSNotification *)notification;
- (void)fetchAlbumPhotoInfo;
- (void)showDropDown;
- (void)hideDropDown;
- (void)showSearch;
- (void)hideSearch;
- (void)searchForAlbumWithTitle:(NSString *)title;
- (void)createNewAlbumWithTitle:(NSString *)title;
- (IBAction)newAlbumButtonPressed:(id)sender;
- (IBAction)newAlbumClose:(id)sender;
- (IBAction)newAlbumDone:(id)sender;

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


#pragma mark - UIViewController Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.albumPhotoInfo = [[NSMutableDictionary alloc] init];

    [self configureViews];
    

    // Set debug logging level. Set to 'RKLogLevelTrace' to see JSON payload
    RKLogConfigureByName("ShotVibe/Albums", RKLogLevelDebug);
    
    // Listen for our RestKit loads to finish
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configureNumberNotViewed:) name:@"SVPhotosLoadedForIndexPath" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchAlbumPhotoInfo) name:@"SVAlbumsLoaded" object:nil];
    
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Album"];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO];
    fetchRequest.sortDescriptors = @[descriptor];
    NSError *error = nil;
    
    // Setup fetched results
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
    [self.fetchedResultsController setDelegate:self];
    if (![self.fetchedResultsController performFetch:&error]) {
        RKLogError(@"There was an error loading the fetched result controller: %@", error);
    }
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
    Album *anAlbum = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:imageView.tag inSection:0]];

    NSArray *photos = [anAlbum.albumPhotos allObjects];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:YES];
    
    NSArray *sortedPhotos = [photos sortedArrayUsingDescriptors:@[descriptor]];
    
    AlbumPhoto *recentPhoto = [sortedPhotos lastObject];
    
    UIImage *offlineImage = [SVBusinessDelegate loadImageFromAlbum:anAlbum withPath:recentPhoto.photoUrl];
    
    if (offlineImage) {
        [imageView setImage:offlineImage];
    }
}


#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self textFieldDidEndEditing:textField];
    return YES;
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self createNewAlbumWithTitle:textField.text];
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


- (void)loadData
{
    [[SVEntityStore sharedStore] userAlbums];
}


- (SVAlbumListViewCell *)configureCell:(SVAlbumListViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    // TODO: We need to configure our cell's views
    //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    Album *anAlbum = [self.fetchedResultsController objectAtIndexPath:indexPath];

    
    NSArray *photos = [anAlbum.albumPhotos allObjects];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:YES];

    NSArray *sortedPhotos = [photos sortedArrayUsingDescriptors:@[descriptor]];
    
    
    AlbumPhoto *recentPhoto = [sortedPhotos lastObject];
    
    // Configure thumbnail
    [cell.networkImageView prepareForReuse];
    NSString *thumbnailUrl = [[recentPhoto.photoUrl stringByDeletingPathExtension] stringByAppendingString:kPhotoThumbExtension];
    cell.networkImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    cell.networkImageView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
    cell.networkImageView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.1].CGColor;
    cell.networkImageView.layer.borderWidth = 1;
    cell.networkImageView.contentMode = UIViewContentModeScaleAspectFill;
    cell.networkImageView.sizeForDisplay = YES;
    cell.networkImageView.scaleOptions = NINetworkImageViewScaleToFitCropsExcess;
    cell.networkImageView.interpolationQuality = kCGInterpolationHigh;
    cell.networkImageView.initialImage = [UIImage imageNamed:@"placeholderImage.png"];
    cell.networkImageView.delegate = self;
    cell.networkImageView.tag = indexPath.row;
    [cell.networkImageView setPathToNetworkImage:thumbnailUrl];
    
    
    cell.title.text = anAlbum.name;
    
    NSString *lastAddedBy = NSLocalizedString(@"Last Added By", @"");
    cell.author.text = [NSString stringWithFormat:@"%@ %@", lastAddedBy, recentPhoto.author.nickname];
    
    NSString *distanceOfTimeInWords = [anAlbum.lastUpdated distanceOfTimeInWords];
    [cell.timestamp setTitle:NSLocalizedString(distanceOfTimeInWords, @"") forState:UIControlStateNormal];
    
    NSNumber *numberNew = [self.albumPhotoInfo objectForKey:indexPath];
    if (numberNew) {
        [cell.numberNotViewedIndicator setTitle:[NSString stringWithFormat:@"%@", numberNew] forState:UIControlStateNormal];
    }
    else
    {
        [cell.numberNotViewedIndicator setTitle:[NSString stringWithFormat:@"%i", 0] forState:UIControlStateNormal];
    }
    
    return cell;
}


- (void)configureNumberNotViewed:(NSNotification *)notification
{
    NSIndexPath *indexPath = [notification object];
    
    if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
        Album *anAlbum = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        SVAlbumListViewCell *cell = (SVAlbumListViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        
        NSInteger numberViewed = [SVBusinessDelegate numberOfViewedImagesInAlbum:anAlbum];
        
        NSInteger numberNew = anAlbum.photos.count - numberViewed;
        
        [self.albumPhotoInfo setObject:[NSNumber numberWithInteger:numberNew] forKey:indexPath];
        [cell.numberNotViewedIndicator setTitle:[NSString stringWithFormat:@"%i", numberNew] forState:UIControlStateNormal];
    }
}


- (void)fetchAlbumPhotoInfo
{
    // Start figuring out how many new photos we have
    NSArray *fetchedObjects = self.fetchedResultsController.fetchedObjects;
    
    for (Album *anAlbum in fetchedObjects) {
        if (anAlbum) {
            [[SVEntityStore sharedStore] photosForAlbumWithID:anAlbum.albumId atIndexPath:[NSIndexPath indexPathForRow:[fetchedObjects indexOfObject:anAlbum] inSection:0]];
        }    }
}


- (void)showDropDown
{
    self.tableOverlayView.hidden = NO;
    self.dropDownContainer.hidden = NO;
    
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
    
    [UIView animateWithDuration:0.15 animations:^{
        self.searchbar.frame = CGRectMake(0, 0, self.searchbar.frame.size.width, self.searchbar.frame.size.height);
        self.viewContainer.frame = CGRectMake(0, 40, self.view.frame.size.width, self.view.frame.size.height -40);
    } completion:^(BOOL finished) {
        [self.searchbar becomeFirstResponder];
    }];
}


- (void)hideSearch
{
    searchShowing = NO;

    [UIView animateWithDuration:0.15 animations:^{
        self.searchbar.frame = CGRectMake(0, -44, self.searchbar.frame.size.width, self.searchbar.frame.size.height);
        self.viewContainer.frame = CGRectMake(0, -4, self.view.frame.size.width, self.view.frame.size.height+4);
    } completion:^(BOOL finished) {
        [self.searchbar resignFirstResponder];
        self.searchbar.hidden = YES;
    }];
    
    // Reset to all albums
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Album"];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO];
    fetchRequest.sortDescriptors = @[descriptor];
    NSError *error = nil;
    
    // Setup fetched results
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
    [self.fetchedResultsController setDelegate:self];
    if (![self.fetchedResultsController performFetch:&error]) {
        RKLogError(@"There was an error loading the fetched result controller: %@", error);
    }
    
    [self.tableView reloadData];
    [self fetchAlbumPhotoInfo];
}


- (void)searchForAlbumWithTitle:(NSString *)title
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Album"];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name BEGINSWITH[cd] %@", title];
    fetchRequest.sortDescriptors = @[descriptor];
    fetchRequest.predicate = predicate;
    NSError *error = nil;
    
    // Setup fetched results
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
    [self.fetchedResultsController setDelegate:self];
    if (![self.fetchedResultsController performFetch:&error]) {
        RKLogError(@"There was an error loading the fetched result controller: %@", error);
    }
    [self.tableView reloadData];
    [self fetchAlbumPhotoInfo];
}


- (void)createNewAlbumWithTitle:(NSString *)title
{
    // TODO: Handle creation of a new album with the given title.
    
}
@end
