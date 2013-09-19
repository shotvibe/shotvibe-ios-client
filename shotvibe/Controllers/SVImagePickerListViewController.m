//
//  SVImagePickerListViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 5/2/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import "SVImagePickerListViewController.h"
#import "SVAssetRetrievalWS.h"
#import "SVAlbumListViewCell.h"
#import "SVImagePickerSelector.h"

@interface SVImagePickerListViewController ()

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *albums;
@property (nonatomic, strong) IBOutlet UIView *viewContainer;

- (IBAction)cancelButtonPressed:(id)sender;
- (void)gatherLocalAlbums;
- (SVAlbumListViewCell *)configureCell:(SVAlbumListViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;


@end

@implementation SVImagePickerListViewController

#pragma mark - Actions

- (IBAction)cancelButtonPressed:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)backButtonPressed:(id)sender
{
	// When we leave the album set all the photos as viewed
	
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    NSLog(@"SVImagePickerListViewController viewdidload");
	
    // Setup back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(backButtonPressed:)];
    NSDictionary *att = @{UITextAttributeFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:16.0], UITextAttributeTextShadowColor:[UIColor clearColor]};
	[backButton setTitleTextAttributes:att forState:UIControlStateNormal];
	[backButton setTitlePositionAdjustment:UIOffsetMake(15,0) forBarMetrics:UIBarMetricsDefault];
	
	if (self.oneImagePicker) {
		//self.navigationItem.leftBarButtonItem = nil;
	}
	
    [self gatherLocalAlbums];
}


#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.albums.count;
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
    
    __block ALAssetsGroup *selectedGroup = [self.albums objectAtIndex:indexPath.row];
    
    // Grab relevant album asset urls
    [SVAssetRetrievalWS loadAllAssetsForAlbumGroup:selectedGroup WithCompletion:^(NSArray *assets, NSError *error) {
		
        SVImagePickerSelector *selector = [[SVImagePickerSelector alloc] initWithNibName:@"SVImagePickerSelector" bundle:[NSBundle mainBundle]];

        selector.albumId = self.albumId;
        selector.albumManager = self.albumManager;
        selector.libraryPhotos = [[NSArray alloc] initWithArray:assets];
        selector.selectedAlbum = self.selectedAlbum;
        selector.selectedGroup = selectedGroup;
		selector.oneImagePicker = self.oneImagePicker;
		selector.cropDelegate = self.delegate;
        [self.navigationController pushViewController:selector animated:YES];
    }];
}


#pragma mark - Private Methods

- (void)gatherLocalAlbums
{
    [SVAssetRetrievalWS loadAllLocalAlbumsOnDeviceWithCompletion:^(NSArray *albums, NSError *error) {
        if (!error) {
            NSLog(@"Grabbed %i Albums", albums.count);
            self.albums = [[NSArray alloc] initWithArray:albums];
            [self.tableView reloadData];
        }
        else
        {
            // TODO: Present an error telling the user that their albums couldn't be retrieved.
        }
    }];
}


- (SVAlbumListViewCell *)configureCell:(SVAlbumListViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    ALAssetsGroup *anAlbum = [self.albums objectAtIndex:indexPath.row];
    
    cell.networkImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    cell.networkImageView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
    cell.networkImageView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.1].CGColor;
    cell.networkImageView.layer.borderWidth = 1;
    cell.networkImageView.contentMode = UIViewContentModeScaleAspectFill;
    cell.networkImageView.clipsToBounds = YES;
    cell.networkImageView.image = [UIImage imageWithCGImage:anAlbum.posterImage];
    
    cell.title.text = [anAlbum valueForProperty:ALAssetsGroupPropertyName];
    [cell.numberNotViewedIndicator setTitle:[NSString stringWithFormat:@"%i", anAlbum.numberOfAssets] forState:UIControlStateNormal];
    [cell.numberNotViewedIndicator sizeToFit];
    return cell;
}


@end
