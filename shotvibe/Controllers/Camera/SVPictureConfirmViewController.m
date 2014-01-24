//
//  SVPictureConfirmViewController.m
//  test
//
//  Created by Salvatore Balzano on 20/01/14.
//  Copyright (c) 2014 MobiApps. All rights reserved.
//

#import "SVPictureConfirmViewController.h"
#import "SVPickerController.h"
#import "PhotoUploadRequest.h"

@interface SVPictureConfirmViewController ()

@property (nonatomic) BOOL scrolling;

@end

@implementation SVPictureConfirmViewController

- (void)setImages:(NSArray *)images
{
    _images = images;
    [self.collectionView reloadData];
    [self populateScrollView];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.navigationController.navigationBar setBarTintColor:[UIColor blackColor]];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setTranslucent:NO];

    UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithTitle:@"Share" style:UIBarButtonItemStyleDone target:self action:@selector(share:)];
    share.tintColor = [UIColor yellowColor];
    self.navigationItem.rightBarButtonItem = share;

    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = cancel;

    [self.collectionView registerClass:[SVPickerCell class] forCellWithReuseIdentifier:@"PickerCell"];

    self.title = [NSString stringWithFormat:@"%d/%d", 1, self.images.count];

    [self populateScrollView];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)populateScrollView
{
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    int i = 0;
    int x = 0;
    for (UIImage *image in self.images) {
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(x + 60, 20, 200, 200)];
        iv.image = [UIImage imageWithContentsOfFile:self.images[i]];
        [self.scrollView addSubview:iv];

        //"Remove" top left button
        UIButton *button1 = [UIButton buttonWithType:UIButtonTypeCustom];
        button1.frame = CGRectMake(x + 41, 0, 40, 40);
        button1.tag = i;
        button1.backgroundColor = [UIColor whiteColor];
        [button1 setTitle:@"x" forState:UIControlStateNormal];
        [button1 setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
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
        [self.scrollView setContentOffset:CGPointMake(self.scrollView.frame.size.width * ([self.images count] - 1), 0) animated:NO];
        [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:[self.images count] - 1 inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
}


- (IBAction)cancel:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
//    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)share:(id)sender
{
    NSLog(@"share");
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];

    RCLog(@"====================== 1. Upload selected photos to albumId %lli", self.albumId);

    // Upload the taken photos
    NSMutableArray *photoUploadRequests = [[NSMutableArray alloc] init];
    for (NSString *selectedPhotoPath in self.images) {
        PhotoUploadRequest *photoUploadRequest = [[PhotoUploadRequest alloc] initWithPath:selectedPhotoPath];
        [photoUploadRequests addObject:photoUploadRequest];
    }
    [self.albumManager.photoUploadManager uploadPhotos:self.albumId photoUploadRequests:photoUploadRequests];
}


- (void)deletePicture:(id)sender
{
    if ([self.images count] > 1) {
        NSMutableArray *array = [self.images mutableCopy];
        [array removeObjectAtIndex:[sender tag]];
        self.images = array;
    } else {
        [self cancel:nil];
    }
}


//- (void)approvePicture:(id)sender
//{
//    NSLog(@"close and go ahead");
//}


#pragma mark UIScrollViewDelegate
//To sync the collectionView and the scrollView

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.scrolling) {
        CGFloat pageWidth = self.scrollView.frame.size.width;
        float fractionalPage = self.scrollView.contentOffset.x / pageWidth;
        NSInteger page = lround(fractionalPage);
        [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:page inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionNone];
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

    if (indexPath.row < self.images.count) {
        NSMutableString *thumbPath = [NSMutableString stringWithString:self.images[indexPath.row]];
        [thumbPath replaceOccurrencesOfString:@".jpg"
                                   withString:@"_thumb.jpg"
                                      options:NSLiteralSearch
                                        range:NSMakeRange(0, [thumbPath length])];
        UIImage *thumbImage = [UIImage imageWithContentsOfFile:thumbPath];

        cell.imageView.image = thumbImage;
    } else {
        cell.imageView.image = [UIImage imageNamed:@"plus"];
    }
    return cell;
}


#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < [self.images count]) {
        //Scroll to the selected image
        self.scrolling = YES;
        [self.scrollView setContentOffset:CGPointMake(self.scrollView.frame.size.width * indexPath.row, 0) animated:YES];
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
