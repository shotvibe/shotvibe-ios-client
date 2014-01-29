//
//  SVMultiplePicturesViewController.m
//  shotvibe
//
//  Created by Salvatore Balzano on 27/01/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "SVMultiplePicturesViewController.h"
#import "SVAlbumCell.h"
#import "AlbumSummary.h"
#import "AlbumPhoto.h"
#import "SVDefines.h"
#import "SVAlbumGridViewController.h"

@interface SVMultiplePicturesViewController ()

@property (nonatomic) int64_t albumId;

@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;

@end

@implementation SVMultiplePicturesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.collectionView registerClass:[SVAlbumCell class] forCellWithReuseIdentifier:@"AlbumCell"];

    // Setup titleview
    UIImageView *titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
    UIView *titleContainer = [[UIView alloc] initWithFrame:titleView.frame];
    [titleContainer addSubview:titleView];
    titleContainer.backgroundColor = [UIColor clearColor];
    titleView.frame = CGRectMake(0, -1, titleView.frame.size.width, titleView.frame.size.height);
    self.navigationItem.titleView = titleContainer;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    return [self.albums count] + 1;
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SVAlbumCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"AlbumCell" forIndexPath:indexPath];
    //    cell.delegate = self;

    if (indexPath.row == 0) {
        [cell.networkImageView setImage:[UIImage imageNamed:@"plus"]];
    } else {
        AlbumSummary *album = self.albums[indexPath.row - 1];

        [cell.networkImageView setImage:nil];
        // TODO: latestPhotos might be nil if we insert an AlbumContents instead AlbumSummary
        if (album.latestPhotos.count > 0) {
            AlbumPhoto *latestPhoto = [album.latestPhotos objectAtIndex:0];
            if (latestPhoto.serverPhoto) {
                [cell.networkImageView setPhoto:latestPhoto.serverPhoto.photoId photoUrl:latestPhoto.serverPhoto.url photoSize:[PhotoSize Thumb75] manager:self.albumManager.photoFilesManager];
            }
        } else {
            [cell.networkImageView setImage:[UIImage imageNamed:@"placeholderImage"]];
        }
    }
    return cell;
}


#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{

}


- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Deselect item
}


#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(100, 100);
}


- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, 4, 0, 4);
}


@end
