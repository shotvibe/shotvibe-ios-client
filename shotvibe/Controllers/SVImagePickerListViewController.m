//
//  SVImagePickerListViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 5/2/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import "SVImagePickerListViewController.h"
#import "SVBusinessDelegate.h"
#import "SVAlbumListViewCell.h"
#import "CaptureSelectImagesViewController.h"

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


#pragma mark - Initializers

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"") style:UIBarButtonItemStyleBordered target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;
    
    [self gatherLocalAlbums];
}


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
    [SVBusinessDelegate loadAllAssetsForAlbumGroup:selectedGroup WithCompletion:^(NSArray *assets, NSError *error) {
        CaptureSelectImagesViewController *selectImagesViewController = [[CaptureSelectImagesViewController alloc] initWithNibName:@"CaptureSelectImagesViewController" bundle:[NSBundle mainBundle]];
        
        selectImagesViewController.takenPhotos = [[NSArray alloc] initWithArray:assets];
        selectImagesViewController.selectedAlbum = self.selectedAlbum;
        selectImagesViewController.selectedGroup = selectedGroup;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController pushViewController:selectImagesViewController animated:YES];
        });
    }];
}


#pragma mark - Private Methods

- (void)gatherLocalAlbums
{
    [SVBusinessDelegate loadAllLocalAlbumsOnDeviceWithCompletion:^(NSArray *albums, NSError *error) {
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