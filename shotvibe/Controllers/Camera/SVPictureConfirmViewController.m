//
//  SVPictureConfirmViewController.m
//  shotvibe
//
//  Created by Salvatore Balzano on 20/01/14.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVPictureConfirmViewController.h"
#import "SVPickerController.h"
#import "SVDefines.h"
#import "SL/AlbumSummary.h"
#import "SVAlbumGridViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "TmpFilePhotoUploadRequest.h"
#import "ShotVibeAppDelegate.h"
#import "SL/ArrayList.h"

@interface SVPictureConfirmViewController ()

@property (nonatomic) BOOL scrolling;
@property (nonatomic) BOOL currentPage;

@end

#define kMostRecentTag 12345

@implementation SVPictureConfirmViewController
{
    SLAlbumManager *albumManager_;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    albumManager_ = [ShotVibeAppDelegate sharedDelegate].albumManager;

    if (IS_IOS7) {
        [self.navigationController.navigationBar setBarTintColor:[UIColor blackColor]];
    }
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setTranslucent:NO];

    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = cancel;

    [self.collectionView registerClass:[SVPickerCell class] forCellWithReuseIdentifier:@"PickerCell"];

    if (IS_IOS7) {
        [self prefersStatusBarHidden];
        [self setNeedsStatusBarAppearanceUpdate];
    }
}


- (void)pickedImageSaved:(NSNotification *)notification
{
    self.waitingForMostRecentImage = NO;
    UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithTitle:(self.albumId == 0) ? @"Choose Album":@"Share" style:UIBarButtonItemStylePlain target:self action:@selector(share:)];
//    share.tintColor = [UIColor yellowColor];
    self.navigationItem.rightBarButtonItem = share;

    UIImageView *iv = (UIImageView *)[self.scrollView viewWithTag:kMostRecentTag];
    if (iv) {
        iv.tag = 0;
        [self populateImageView:iv atIndex:self.images.count - 1];
        UIActivityIndicatorView *av = (UIActivityIndicatorView *)[iv viewWithTag:kMostRecentTag + 1];
        [av stopAnimating];
        [av removeFromSuperview];
    }

    SVPickerCell *cell = (SVPickerCell *)[self.collectionView viewWithTag:kMostRecentTag];
    if (cell) {
        cell.tag = 0;
        [self populateCell:cell atIndex:self.images.count - 1];
        UIActivityIndicatorView *av = (UIActivityIndicatorView *)[cell viewWithTag:kMostRecentTag + 1];
        [av stopAnimating];
        [av removeFromSuperview];
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    self.currentPage = [self.images count];
    [self.collectionView reloadData];

    NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:[self.images count] inSection:0];
    [self.collectionView scrollToItemAtIndexPath:lastIndexPath atScrollPosition:UICollectionViewScrollPositionRight animated:YES];

    [self populateScrollView];
    [self fixTitle];

    if (self.waitingForMostRecentImage) {
        self.navigationItem.rightBarButtonItem = nil;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pickedImageSaved:) name:@"kPickedImageSaved" object:nil];
    } else {
        [self pickedImageSaved:nil];
    }
}


- (BOOL)prefersStatusBarHidden
{
    return YES; // setNeedsStatusBarAppearanceUpdate
}


- (UIViewController *)childViewControllerForStatusBarHidden
{
    return nil;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (UIImage *)resizedImage:(UIImage *)image toSize:(CGSize)size
{
    CGSize newSize = CGSizeMake(size.width * image.scale, size.height * image.scale);
    float oldWidth = image.size.width;
    float scaleFactor = newSize.width / oldWidth;
    float newHeight = image.size.height * scaleFactor;
    float newWidth = oldWidth * scaleFactor;

    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [image drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *thumbImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return thumbImage;
}


- (CGSize)constrainedSize:(UIImage *)image toSize:(CGSize)constraint
{
    float widthRatio = constraint.width / image.size.width;
    float heightRatio = constraint.height / image.size.height;
    float scale = MIN(widthRatio, heightRatio);
    float imageWidth = scale * image.size.width;
    float imageHeight = scale * image.size.height;
    return CGSizeMake(imageWidth, imageHeight);
}


- (void)populateImageView:(UIImageView *)iv atIndex:(int)i
{
    if ((self.waitingForMostRecentImage) && (self.images.count - 1 == i)) {
        iv.tag = kMostRecentTag;

        UIActivityIndicatorView *av = [[UIActivityIndicatorView alloc] initWithFrame:iv.bounds];
        [av startAnimating];
        av.tag = kMostRecentTag + 1;
        [iv addSubview:av];
    } else {
        //imageWithContentsOfFile hangs the CPU, see http://stackoverflow.com/questions/10149165/uiimage-decompression-causing-scrolling-lag
        NSData *imageFileData = [[NSData alloc] initWithContentsOfFile:self.images[i]];
        UIImage *image = [self resizedImage:[[UIImage alloc] initWithData:imageFileData] toSize:iv.bounds.size];

        if (image) {
            iv.image = image;

            CGSize constrainedSize = [self constrainedSize:image toSize:iv.bounds.size];

            iv.superview.frame = CGRectMake((self.scrollView.frame.size.width - constrainedSize.width) / 2 + i * self.scrollView.frame.size.width, (self.scrollView.frame.size.height - constrainedSize.height) / 2, constrainedSize.width, constrainedSize.height);
            iv.frame = iv.superview.bounds;

            UIButton *deletePhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
            deletePhotoButton.frame = CGRectMake(iv.superview.frame.origin.x - 20, iv.superview.frame.origin.y - 20, 40, 40);
            deletePhotoButton.tag = i;
            [deletePhotoButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
            [deletePhotoButton addTarget:self action:@selector(deletePicture:) forControlEvents:UIControlEventTouchUpInside];
            [self.scrollView addSubview:deletePhotoButton];

            UIButton *editPhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
            editPhotoButton.frame = CGRectMake(iv.superview.frame.origin.x + iv.superview.frame.size.width - 20, iv.superview.frame.origin.y - 20, 40, 40);
            editPhotoButton.tag = i;
            [editPhotoButton setImage:[UIImage imageNamed:@"edit"] forState:UIControlStateNormal];
            [editPhotoButton addTarget:self action:@selector(editPicture:) forControlEvents:UIControlEventTouchUpInside];
            [self.scrollView addSubview:editPhotoButton];
        }
    }
}


- (void)populateScrollView
{
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        self.scrollView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.tapLabel.frame.origin.y);
    } else {
        self.scrollView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.tapLabel.frame.origin.y);
    }

    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    int i = 0;
    int x = 20;
    for (UIImage *image in self.images) {
        int imageWidth = self.view.frame.size.width - 2 * 20;
        int imageHeight = self.tapLabel.frame.origin.y;
        //UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(x + (self.scrollView.frame.size.width - imageHeight) / 2, 20, imageWidth, imageHeight)];

        UIView *v = [[UIView alloc] initWithFrame:CGRectMake(x, 20, imageWidth, imageHeight - 20 * 2)];
        UIImageView *iv = [[UIImageView alloc] initWithFrame:v.bounds];
        v.backgroundColor = [UIColor clearColor];
        iv.contentMode = UIViewContentModeScaleAspectFit;
        v.layer.cornerRadius = 4.0;
        v.clipsToBounds = YES;
        [v addSubview:iv];
        [self.scrollView addSubview:v];

        [self populateImageView:iv atIndex:i];

        i++;

        x += self.scrollView.frame.size.width;
    }
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * i, self.scrollView.frame.size.height);
    if (self.images.count > 0) {
        [self.scrollView setContentOffset:CGPointMake(self.scrollView.frame.size.width * (self.currentPage - 1), 0) animated:NO];
        [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:self.currentPage - 1 inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self populateScrollView];
}


- (IBAction)cancel:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Are you sure? The photos will be deleted." delegate:self cancelButtonTitle:NSLocalizedString(@"No", @"") otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
    [alert show];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        //    [self.navigationController popViewControllerAnimated:YES];
    }
}


- (IBAction)share:(id)sender
{
    if (self.albumId != 0) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kSVShowAlbum" object:nil userInfo:@{ @"albumId" : @(self.albumId) }
            ];
        }


        ];

        RCLog(@"====================== 1. Upload selected photos to albumId %lli", self.albumId);

        // Upload the taken photos
        NSMutableArray *photoUploadRequests = [[NSMutableArray alloc] init];
        for (NSString *selectedPhotoPath in self.images) {
            TmpFilePhotoUploadRequest *photoUploadRequest = [[TmpFilePhotoUploadRequest alloc] initWithTmpFile:selectedPhotoPath];
            [photoUploadRequests addObject:photoUploadRequest];
        }
        [albumManager_ uploadPhotosWithLong:self.albumId
                           withJavaUtilList:[[SLArrayList alloc] initWithInitialArray:photoUploadRequests]];
    } else {
        [self.presentingViewController dismissViewControllerAnimated:NO completion:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kSVPickAlbumToUpload" object:nil userInfo:@{ @"images" : self.images }
            ];
        }


        ];
    }
}


#pragma mark Aviary sdk
#pragma mark Photo editing tool

- (void)editPicture:(id)sender
{
    NSData *imageFileData = [[NSData alloc] initWithContentsOfFile:self.images[[sender tag]]];
    UIImage *imageToEdit = [[UIImage alloc] initWithData:imageFileData];
    RCLogO(imageToEdit);

    AFPhotoEditorController *editorController = [[AFPhotoEditorController alloc] initWithImage:imageToEdit];
    [editorController setDelegate:self];

    [self presentViewController:editorController animated:YES completion:nil];
}


- (void)photoEditor:(AFPhotoEditorController *)editor finishedWithImage:(UIImage *)image
{
    // Save the image to disk
    NSString *imagePath = [NSHomeDirectory() stringByAppendingString:@"/Library/Caches/AviaryPhoto.jpg"];
    NSString *thumbPath = [NSHomeDirectory() stringByAppendingString:@"/Library/Caches/AviaryPhoto_thumb.jpg"];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if ([UIImageJPEGRepresentation(image, 0.9) writeToFile:imagePath atomically:YES]) {
            CGSize newSize = CGSizeMake(200, 200);

            float oldWidth = image.size.width;
            float scaleFactor = newSize.width / oldWidth;

            float newHeight = image.size.height * scaleFactor;
            float newWidth = oldWidth * scaleFactor;

            UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
            [image drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
            UIImage *thumbImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();

            [UIImageJPEGRepresentation(thumbImage, 0.5) writeToFile:thumbPath atomically:YES];

            [self.images replaceObjectAtIndex:self.currentPage - 1 withObject:imagePath];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView reloadData];
                [self populateScrollView];
                [self fixTitle];
            }


                           );
        }
    }


                   );


    [editor dismissViewControllerAnimated:YES completion:^{
        [editor setDelegate:nil];
    }


    ];
}


- (void)photoEditorCanceled:(AFPhotoEditorController *)editor
{
    [editor dismissViewControllerAnimated:YES completion:^{
    }


    ];
}


- (void)deletePicture:(id)sender
{
    if ([self.images count] > 1) {
        [self.images removeObjectAtIndex:[sender tag]];
        self.waitingForMostRecentImage = NO;
        if (self.currentPage > [self.images count]) {
            self.currentPage = self.currentPage - 1;
        }
        [self.collectionView reloadData];
        [self populateScrollView];
        [self fixTitle];
    } else {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}


#pragma mark UIScrollViewDelegate
//To sync the collectionView and the scrollView

- (void)fixTitle
{
    self.title = [NSString stringWithFormat:@"%d of %d", self.currentPage, self.images.count];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.scrolling) {
        CGFloat pageWidth = self.scrollView.frame.size.width;
        float fractionalPage = self.scrollView.contentOffset.x / pageWidth;
        NSInteger page = lround(fractionalPage);
        [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:page inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        self.currentPage = page + 1;
        [self fixTitle];
    }
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.scrolling = NO;
}


#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    return [self.images count] + 1;
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


- (void)populateCell:(SVPickerCell *)cell atIndex:(int)i
{
    NSMutableString *thumbPath = [NSMutableString stringWithString:self.images[i]];
    [thumbPath replaceOccurrencesOfString:@".jpg"
                               withString:@"_thumb.jpg"
                                  options:NSLiteralSearch
                                    range:NSMakeRange(0, [thumbPath length])];

    //imageWithContentsOfFile hangs the CPU, see http://stackoverflow.com/questions/10149165/uiimage-decompression-causing-scrolling-lag
    NSData *imageFileData = [[NSData alloc] initWithContentsOfFile:thumbPath];
    UIImage *thumbImage = [[UIImage alloc] initWithData:imageFileData];

    cell.imageView.image = thumbImage;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SVPickerCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"PickerCell" forIndexPath:indexPath];
//    cell.delegate = self;

    if ((indexPath.row == self.images.count - 1) && self.waitingForMostRecentImage) {
        cell.tag = kMostRecentTag;

        UIActivityIndicatorView *av = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        av.frame = cell.contentView.bounds;
        [av startAnimating];
        av.tag = kMostRecentTag + 1;
        [cell.contentView addSubview:av];
    } else if (indexPath.row < self.images.count) {
        [self populateCell:cell atIndex:indexPath.row];
    } else {
        //cell.imageView.frame = cell.imageView.superview.bounds;
        cell.imageView.image = [UIImage imageNamed:@"camera"];
    }
    return cell;
}


#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < [self.images count]) {
        //Scroll to the selected image
        self.scrolling = YES;
        [UIView animateWithDuration:0.3f delay:0.0f options:0 animations:^{
            [self.scrollView setContentOffset:CGPointMake(self.scrollView.frame.size.width * indexPath.row, 0) animated:NO];
        }


                         completion:nil];
        self.currentPage = indexPath.row + 1;
        [self fixTitle];
    } else {
        //Add a new image
        SVPickerController *manager = [[SVPickerController alloc] init];
        manager.container = self;
        manager.albumId = self.albumId;

        [self presentViewController:manager animated:NO completion:nil];
    }
}


- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Deselect item
}


#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(50, 50);
}


- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, 4, 0, 4);
}


@end
