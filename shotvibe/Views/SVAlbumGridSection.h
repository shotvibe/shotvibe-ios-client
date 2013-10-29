//
//  SVAlbumGridSection.h
//  shotvibe
//
//  Created by Baluta Cristian on 29/09/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SVAlbumGridSection : UICollectionReusableView

@property(nonatomic, retain) UIImageView *imageView;
@property(nonatomic, retain) UILabel *nameLabel;
@property(nonatomic, retain) UIButton *dateButtonLabel;

- (void)setType:(int)type section:(int)section;

@end
