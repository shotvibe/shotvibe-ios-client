//
//  SVAlbumGridViewCell.m
//  shotvibe
//
//  Created by John Gabelmann on 6/27/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVAlbumGridViewCell.h"
#import "FancyProgressView.h"

@implementation SVAlbumGridViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    _fancyUploadProgressView = [[FancyProgressView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];


    [self.networkImageView addSubview:_fancyUploadProgressView];
}

@end
