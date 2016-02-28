//
//  SVAlbumCell.m
//  shotvibe
//
//  Created by Salvatore Balzano on 27/01/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "SVAlbumCell.h"

@implementation SVAlbumCell


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.networkImageView = [[PhotoView alloc] initWithFrame:CGRectInset(self.bounds, 4, 4)];
        self.networkImageView.clipsToBounds = YES;
        self.networkImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.networkImageView];
    }
    return self;
}


@end
