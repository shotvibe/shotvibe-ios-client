//
//  SVAlbumGridViewCell.h
//  shotvibe
//
//  Created by John Gabelmann on 6/27/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "PhotoView.h"

@interface SVAlbumGridViewCell : UICollectionViewCell

@property (nonatomic, strong) IBOutlet PhotoView *networkImageView;
@property (nonatomic, strong) IBOutlet UIView *labelNewView;
@property (nonatomic, strong) IBOutlet UILabel *labelNewLabel;
@property (weak, nonatomic) IBOutlet UIImageView *albumOrgNewOverlay;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet UIView *uploadingOriginalView;
@property (nonatomic, strong) IBOutlet UIProgressView *uploadProgressView;

@end
