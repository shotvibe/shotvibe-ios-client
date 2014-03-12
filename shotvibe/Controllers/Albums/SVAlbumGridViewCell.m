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
    _fancyUploadProgressView = [[FancyProgressView alloc] initWithFrame:self.networkImageView.bounds];

    [self.networkImageView addSubview:_fancyUploadProgressView];
}


- (void)prepareForReuse
{
    RCLog(@"Preparing for reuse");
    [super prepareForReuse];
    [self.fancyUploadProgressView reset];
}


@end
