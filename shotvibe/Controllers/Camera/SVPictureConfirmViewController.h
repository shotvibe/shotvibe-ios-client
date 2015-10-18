//
//  SVPictureConfirmViewController.h
//  shotvibe
//
//  Created by Salvatore Balzano on 20/01/14.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVPickerCell.h"
#import "SL/AlbumManager.h"
#import "AFPhotoEditorController.h"

@interface SVPictureConfirmViewController : UIViewController <AFPhotoEditorControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) NSMutableArray *images;
@property (nonatomic) BOOL waitingForMostRecentImage;
@property (nonatomic) int64_t albumId;

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) IBOutlet UILabel *tapLabel;

@end
