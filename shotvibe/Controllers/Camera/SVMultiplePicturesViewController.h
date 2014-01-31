//
//  SVMultiplePicturesViewController.h
//  shotvibe
//
//  Created by Salvatore Balzano on 27/01/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AlbumManager.h"
#import "SVAlbumListViewCell.h"

@interface SVMultiplePicturesViewController : UIViewController <SVAlbumListViewCellDelegate>

@property (nonatomic, strong) NSArray *images;
@property (nonatomic, strong) AlbumManager *albumManager;
@property (nonatomic, strong) NSArray *albums;

@end
