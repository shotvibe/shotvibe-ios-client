//
//  SVAlbumGridSection.h
//  shotvibe
//
//  Created by Baluta Cristian on 29/09/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCImageView.h"


@interface SVAlbumGridSection : UICollectionReusableView

@property(nonatomic, retain) UILabel *dateLabel;
@property(nonatomic, retain) RCImageView *imageView;

- (void)setType:(int)type;

@end
