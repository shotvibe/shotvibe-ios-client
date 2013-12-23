//
//  SVAlbumGridViewCell.h
//  shotvibe
//
//  Created by John Gabelmann on 6/27/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PhotoView.h"

@interface SVAlbumGridViewCell : UICollectionViewCell

@property (nonatomic, strong) IBOutlet PhotoView *networkImageView;
@property (nonatomic, strong) IBOutlet UIView *labelNewView;
@property (nonatomic, strong) IBOutlet UILabel *labelNewLabel;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityView;
@property (nonatomic, strong) IBOutlet UIProgressView *uploadProgressView;

@end
