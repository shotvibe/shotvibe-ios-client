//
//  GLPublicFeedViewController.m
//  shotvibe
//
//  Created by Tsah Kashkash on 24/11/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import "GLPublicFeedViewController.h"
#import "GLPublicFeedPostViewController.h"
#import "ShotVibeAPI.h"
#import "ShotVibeAPITask.h"
#import "ShotVibeAppDelegate.h"
#import "UIImageView+WebCache.h"
#import "AlbumPhoto.h"
#import "AlbumServerPhoto.h"
#import "ArrayList.h"
#import "YYWebImage.h"
#import "SL/AlbumServerVideo.h"
#import "SL/MediaType.h"
#import "GLContainersViewController.h"
@interface GLPublicFeedViewController ()

@end

@implementation GLPublicFeedViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
        NSLog(@"");
        
        SLAlbumManager * al = [ShotVibeAppDelegate sharedDelegate].albumManager;
        
        [ShotVibeAPITask runTask:self withAction:^id{
            //        [[al getShotVibeAPI] getPublic];
            return [[al getShotVibeAPI] getPublicAlbumContents];
        } onTaskComplete:^(SLAlbumContents *album) {
            //        NSLog(@"Public feed name: %@", [album getName]);
            
            //        self.publicFeed = [[GLPublicFeedViewController alloc] init];
            NSMutableArray * photosArray = [[NSMutableArray alloc] init];
            
            for(SLAlbumPhoto * photo in [album getPhotos]){
                [photosArray addObject:photo];
            }
            
            NSArray* reversedArray = [[photosArray reverseObjectEnumerator] allObjects];
            
            self.photosArray = [reversedArray copy];
            [self.collectionView reloadData];
            
            //        self.publicFeed.albumId = [[al getShotVibeAPI] getPublicAlbumId];
            // TODO ...
        } onTaskFailure:^(id success) {
            
            //        [];
            
        } withLoaderIndicator:NO];

        
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.page
    
    self.view.backgroundColor = [UIColor whiteColor];
    ADLivelyCollectionView * livelyCollectionView = (ADLivelyCollectionView *)self.collectionView;
    [livelyCollectionView registerNib:[UINib nibWithNibName:@"LDCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"Cell"];
    livelyCollectionView.initialCellTransformBlock = ADLivelyTransformFade;
    // Do any additional setup after loading the view from its nib.
    livelyCollectionView.clipsToBounds = YES;

}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    
//    [publicFeedAlertTimer invalidate];
//    [[GLContainersViewController sharedInstance] goToPublicFeed:YES];
    [[GLContainersViewController sharedInstance] disablePublicFeedPushAlerter];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"kUserSawPulicFeed"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
    SLAlbumManager * al = [ShotVibeAppDelegate sharedDelegate].albumManager;
    
    [ShotVibeAPITask runTask:self withAction:^id{
        //        [[al getShotVibeAPI] getPublic];
        return [[al getShotVibeAPI] getPublicAlbumContents];
    } onTaskComplete:^(SLAlbumContents *album) {
        
        
        self.albumContents = album;
        
        //        NSLog(@"Public feed name: %@", [album getName]);
        
        //        self.publicFeed = [[GLPublicFeedViewController alloc] init];
        NSMutableArray * photosArray = [[NSMutableArray alloc] init];
        
        for(SLAlbumPhoto * photo in [album getPhotos]){
            [photosArray addObject:photo];
        }
        
        NSArray* reversedArray = [[photosArray reverseObjectEnumerator] allObjects];
        
        self.photosArray = [reversedArray copy];
//        [self.collectionView reloadData];
        
        //        self.publicFeed.albumId = [[al getShotVibeAPI] getPublicAlbumId];
        // TODO ...
    } onTaskFailure:^(id success) {
        
        //        [];
        
    } withLoaderIndicator:NO];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.photosArray.count;
}

//-(void)coll

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Adjust cell size for orientation
    return CGSizeMake(self.view.frame.size.width/3.3, (self.view.frame.size.height/1.17)/3.3);
}

// Layout: Set Edges
- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0,8,0,8);  // top, left, bottom, right
}

- (CGFloat)collectionView:(UICollectionView *) collectionView
                   layout:(UICollectionViewLayout *) collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger) section {
    return 0.0;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    GLPublicFeedPostViewController * singlePostVc = [[GLPublicFeedPostViewController alloc] init];
    singlePostVc.albumId = 0;
    singlePostVc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    singlePostVc.albumContentsTwo = self.albumContents;
    
    LDCollectionViewCell * cell = (LDCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    singlePostVc.singleAlbumPhoto = cell.cellSlPhoto;
    singlePostVc.onClose = ^(id responseObject) {
        [UIView animateWithDuration:0.3 animations:^{
            cell.alpha = 1;
            cell.transform = CGAffineTransformIdentity;
        }];
    };
    [UIView animateWithDuration:0.3 animations:^{
        cell.transform = CGAffineTransformScale(cell.transform, 2.0, 2.0);
        cell.alpha = 0;
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.15);
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            // do work in the UI thread here
            [self presentViewController:singlePostVc animated:YES completion:nil];
        });
    }];
    
    
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * cellIdentifier = @"Cell";
    
    LDCollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.cellImage.frame = CGRectMake(cell.cellImage.frame.origin.x, cell.cellImage.frame.origin.y, cell.frame.size.width, cell.frame.size.height);
    cell.cellImage.contentMode = UIViewContentModeScaleAspectFill;
    
    if (!cell.backgroundView) {
        UIView * backgroundView = [[UIView alloc] initWithFrame:cell.bounds];
        cell.backgroundView = backgroundView;
    }

    SLAlbumPhoto * photo = [self.photosArray objectAtIndex:indexPath.row];
    if([[photo getServerPhoto] getMediaType] == [SLMediaTypeEnum VIDEO]){
        SLAlbumServerVideo * video = [[photo getServerPhoto] getVideo];
        
        cell.cellSlPhoto = photo;
        [cell.cellImage yy_setImageWithURL:[NSURL URLWithString:[video getVideoThumbnailUrl]] placeholder:[UIImage imageNamed:@""] options:YYWebImageOptionProgressiveBlur | YYWebImageOptionShowNetworkActivity | YYWebImageOptionSetImageWithFadeAnimation completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
        }];
        cell.videoBadge.alpha = 1;
    } else {
        SLAlbumPhoto * photo = [self.photosArray objectAtIndex:indexPath.row];
        cell.cellSlPhoto = photo;
        cell.videoBadge.alpha = 0;
        NSString * thumUrl = [[photo getServerPhoto] getUrl];
        NSString *new = [thumUrl stringByReplacingOccurrencesOfString:@".jpg" withString:@"_thumb75.jpg"];
        
        [cell.cellImage yy_setImageWithURL:[NSURL URLWithString:new] placeholder:[UIImage imageNamed:@""] options:YYWebImageOptionProgressiveBlur | YYWebImageOptionShowNetworkActivity | YYWebImageOptionSetImageWithFadeAnimation completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
            
        }];
        
//        cell.album
        
    }
    
    cell.backgroundView.backgroundColor = [indexPath row] % 2 == 0 ? UIColorFromRGB(0x3eb4b6) : UIColorFromRGB(0xF07380);
    cell.textLabel.backgroundColor = cell.backgroundView.backgroundColor;
    
    return cell;
}

@end
