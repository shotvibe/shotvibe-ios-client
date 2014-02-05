//
//  SVPictureConfirmViewController.m
//  shotvibe
//
//  Created by Salvatore Balzano on 20/01/14.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVPictureConfirmViewController.h"
#import "SVPickerController.h"
#import "PhotoUploadRequest.h"
#import "SVDefines.h"

@interface SVPictureConfirmViewController ()

@property (nonatomic) BOOL scrolling;
@property (nonatomic) BOOL currentPage;

@end

@implementation SVPictureConfirmViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

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


- (void)showShare:(NSNotification *)notification
{
    UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithTitle:@"Share" style:UIBarButtonItemStyleDone target:self action:@selector(share:)];
    share.tintColor = [UIColor yellowColor];
    self.navigationItem.rightBarButtonItem = share;
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

    if (self.waitForImageToBeSaved) {
        self.navigationItem.rightBarButtonItem = nil;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showShare:) name:@"kPickedImageSaved" object:nil];
    } else {
        [self showShare:nil];
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
    CGSize newSize = CGSizeMake(size.width*[[UIScreen mainScreen] scale], size.height*[[UIScreen mainScreen] scale]);
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


- (void)populateScrollView
{
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        self.scrollView.frame = CGRectMake(0, 0, self.view.frame.size.width, 320);
    } else {
        self.scrollView.frame = CGRectMake(0, 0, self.view.frame.size.width, 200);
    }

    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    int i = 0;
    int x = 0;
    for (UIImage *image in self.images) {
        int imageHeight = self.scrollView.frame.size.height - 40;
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(x + (self.scrollView.frame.size.width - imageHeight) / 2, 20, imageHeight, imageHeight)];
        UIImage *image = nil;
        if ((self.mostRecentImage) && (self.images.count - 1 == i)) {
            image = self.mostRecentImage;
        } else {
            image = [UIImage imageWithContentsOfFile:self.images[i]];
        }
        iv.image = [self resizedImage:image toSize:iv.frame.size];

        [self.scrollView addSubview:iv];

        //"Remove" top left button
        UIButton *button1 = [UIButton buttonWithType:UIButtonTypeCustom];
        button1.frame = CGRectMake(iv.frame.origin.x - 15, 5, 30, 30);
        button1.tag = i;
//        button1.backgroundColor = [UIColor whiteColor];
//        [button1 setTitle:@"x" forState:UIControlStateNormal];
//        [button1 setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [button1 setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
        [button1 addTarget:self action:@selector(deletePicture:) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:button1];

//        UIButton *button2 = [UIButton buttonWithType:UIButtonTypeCustom];
//        button2.frame = CGRectMake(x + 239, 0, 40, 40);
//        button2.tag = i;
//        button2.backgroundColor = [UIColor whiteColor];
//        [button2 setTitle:@"v" forState:UIControlStateNormal];
//        [button2 setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
//        [button2 addTarget:self action:@selector(approvePicture:) forControlEvents:UIControlEventTouchUpInside];
//        [self.scrollView addSubview:button2];

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
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"are you sure? The photos will be deleted" delegate:self cancelButtonTitle:NSLocalizedString(@"No", @"") otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
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
    NSLog(@"share");

    if (self.albumId != 0) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];

        RCLog(@"====================== 1. Upload selected photos to albumId %lli", self.albumId);

        // Upload the taken photos
        NSMutableArray *photoUploadRequests = [[NSMutableArray alloc] init];
        for (NSString *selectedPhotoPath in self.images) {
            PhotoUploadRequest *photoUploadRequest = [[PhotoUploadRequest alloc] initWithPath:selectedPhotoPath];
            [photoUploadRequests addObject:photoUploadRequest];
        }
        [self.albumManager.photoUploadManager uploadPhotos:self.albumId photoUploadRequests:photoUploadRequests];
    } else {
        [self.presentingViewController dismissViewControllerAnimated:NO completion:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kSVPickAlbumToUpload" object:nil userInfo:@{ @"images" : self.images }
            ];
        }


        ];
    }
}


- (void)deletePicture:(id)sender
{
    if ([self.images count] > 1) {
        [self.images removeObjectAtIndex:[sender tag]];
        self.mostRecentImage = nil;
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
    self.title = [NSString stringWithFormat:@"%d/%d", self.currentPage, self.images.count];
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


- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SVPickerCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"PickerCell" forIndexPath:indexPath];
//    cell.delegate = self;

    if ((indexPath.row == self.images.count - 1) && self.mostRecentImage) {
        cell.imageView.image = self.mostRecentImage;
    } else if (indexPath.row < self.images.count) {
        NSMutableString *thumbPath = [NSMutableString stringWithString:self.images[indexPath.row]];
        [thumbPath replaceOccurrencesOfString:@".jpg"
                                   withString:@"_thumb.jpg"
                                      options:NSLiteralSearch
                                        range:NSMakeRange(0, [thumbPath length])];
        UIImage *thumbImage = [self resizedImage:[UIImage imageWithContentsOfFile:thumbPath] toSize:CGSizeMake(50, 50)];
        //UIImage *thumbImage = [UIImage imageWithContentsOfFile:thumbPath];

        cell.imageView.image = thumbImage;
    } else {
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
        manager.albumManager = self.albumManager;
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
