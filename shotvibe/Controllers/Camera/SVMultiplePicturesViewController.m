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
#import "MBProgressHUD.h"

@interface SVMultiplePicturesViewController ()

@property (nonatomic) int64_t albumId;

@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) IBOutlet UIView *createNewAlbumTitleView;
@property (nonatomic, strong) IBOutlet UITextField *albumField;

- (IBAction)newAlbumClosed:(id)sender;
- (IBAction)newAlbumDone:(id)sender;

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


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self hideDropDown:NO];
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
    if (indexPath.row == 0) {
        [self showDropDown];
    } else {
        AlbumSummary *album = self.albums[indexPath.row - 1];
        self.albumId = album.albumId;

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"are you sure you want to upload/move/copy the photos to this album?" delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
        [alert show];
    }
}


- (void)uploadPhotos
{
    NSMutableArray *controllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
    if (controllers.count == 2) {
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        SVAlbumGridViewController *controller = (SVAlbumGridViewController *)[mainStoryboard instantiateViewControllerWithIdentifier:@"SVAlbumGridViewController"];
        controller.albumManager = self.albumManager;
        controller.albumId = self.albumId;
        controller.scrollToTop = YES;
        [controllers replaceObjectAtIndex:1 withObject:controller];
        [self.navigationController setViewControllers:controllers];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }

    RCLog(@"====================== 1. Upload selected photos to albumId %lli", self.albumId);

    // Upload the taken photos
    NSMutableArray *photoUploadRequests = [[NSMutableArray alloc] init];
    for (NSString *selectedPhotoPath in self.images) {
        PhotoUploadRequest *photoUploadRequest = [[PhotoUploadRequest alloc] initWithPath:selectedPhotoPath];
        [photoUploadRequests addObject:photoUploadRequest];
    }
    [self.albumManager.photoUploadManager uploadPhotos:self.albumId photoUploadRequests:photoUploadRequests];

    NSDictionary *userInfo = @{
        @"albumId" : [NSNumber numberWithLongLong:self.albumId]
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATIONCENTER_ALBUM_CHANGED object:nil userInfo:userInfo];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self uploadPhotos];
    }
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


- (IBAction)newAlbumClosed:(id)sender
{
    [self hideDropDown:YES];
}


- (IBAction)newAlbumDone:(id)sender
{
    NSString *name = self.albumField.text.length == 0 ? self.albumField.placeholder : self.albumField.text;
    [self createNewAlbumWithTitle:name];
}


- (void)createNewAlbumWithTitle:(NSString *)title
{
    RCLog(@"createNewAlbumWithTitle %@", title);
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    // Write the album to server
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
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
            } else {
                self.albumId = albumContents.albumId;
            }
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [self hideDropDown:NO];
            [self uploadPhotos];

        }


                       );
    }


                   );
}


#pragma mark drop down stuffs

- (void)showDropDown
{
    NSString *currentDateString = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                                 dateStyle:NSDateFormatterLongStyle
                                                                 timeStyle:NSDateFormatterNoStyle];
    self.albumField.text = @"";
    self.albumField.placeholder = currentDateString;

    self.collectionView.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.3 animations:^{
        CGRect frame = self.createNewAlbumTitleView.frame;
        frame.origin.y = self.navigationController.navigationBar.frame.size.height + 20;
        self.createNewAlbumTitleView.frame = frame;
    }


                     completion:^(BOOL finished) {
        [self.albumField becomeFirstResponder];
    }


    ];
}


- (void)hideDropDown:(BOOL)animated
{
    [self.albumField resignFirstResponder];

    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            CGRect frame = self.createNewAlbumTitleView.frame;
            frame.origin.y = self.navigationController.navigationBar.frame.size.height + 20 - frame.size.height;
            self.createNewAlbumTitleView.frame = frame;
        }
         
         
                         completion:^(BOOL finished) {
                             self.collectionView.userInteractionEnabled = YES;
                         }
         
         
         ];
    } else {
        CGRect frame = self.createNewAlbumTitleView.frame;
        frame.origin.y = self.navigationController.navigationBar.frame.size.height + 20 - frame.size.height;
        self.createNewAlbumTitleView.frame = frame;
        self.collectionView.userInteractionEnabled = YES;
    }
}


#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.albumField) {
        [self newAlbumDone:nil];
    }
    return YES;
}


@end
