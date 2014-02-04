//
//  SVPictureConfirmViewController.h
//  shotvibe
//
//  Created by Salvatore Balzano on 20/01/14.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVPickerCell.h"
#import "AlbumManager.h"

@interface SVPictureConfirmViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) NSMutableArray *images;
@property (nonatomic, strong) UIImage *mostRecentImage;
@property (nonatomic) BOOL waitForImageToBeSaved;
@property (nonatomic) int64_t albumId;
@property (nonatomic, strong) AlbumManager *albumManager;

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;

@end
