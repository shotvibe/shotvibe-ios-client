//
//  SVPictureConfirmViewController.h
//  test
//
//  Created by Salvatore Balzano on 20/01/14.
//  Copyright (c) 2014 MobiApps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVPickerCell.h"
#import "AlbumManager.h"

@interface SVPictureConfirmViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) NSMutableArray *images;
@property (nonatomic) int64_t albumId;
@property (nonatomic, strong) AlbumManager *albumManager;

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;

@end
