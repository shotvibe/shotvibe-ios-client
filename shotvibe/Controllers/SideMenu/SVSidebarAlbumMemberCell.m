//
//  SVSidebarAlbumMemberCell.m
//  shotvibe
//
//  Created by John Gabelmann on 4/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVSidebarAlbumMemberCell.h"

@implementation SVSidebarAlbumMemberCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse
{
    self.profileImageView.layer.cornerRadius = roundf(self.profileImageView.frame.size.width / 2.0);
    self.profileImageView.layer.masksToBounds = YES;

    self.profileImageView.image = nil;
    self.memberLabel.text = nil;
    self.statusImageView.image = nil;
    self.statusLabel.text = nil;
}


@end
