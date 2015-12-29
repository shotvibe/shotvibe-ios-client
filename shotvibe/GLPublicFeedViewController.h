//
//  GLPublicFeedViewController.h
//  shotvibe
//
//  Created by Tsah Kashkash on 24/11/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LDCollectionViewCell.h"
#import "ADLivelyCollectionView.h"
#import "AlbumContents.h"



@interface GLPublicFeedViewController : UIViewController <UICollectionViewDataSource,UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet ADLivelyCollectionView *collectionView;
@property (nonatomic, retain) SLAlbumContents * albumContents;
@property (nonatomic, retain) NSMutableArray * photosArray;
@property (weak, nonatomic) IBOutlet UIImageView *glanceLogo;
@property (nonatomic) int indexNumber;
@end
