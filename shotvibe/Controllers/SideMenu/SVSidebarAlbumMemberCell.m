//
//  SVSidebarAlbumMemberCell.m
//  shotvibe
//
//  Created by John Gabelmann on 4/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVSidebarAlbumMemberCell.h"

@implementation SVSidebarAlbumMemberCell

-(void)awakeFromNib {
//    self.backgroundColor = [UIColor greenColor];
    
    self.adminBadge = [[UIImageView alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width-85, 18, 25, 25)];
    self.adminBadge.image = [UIImage imageNamed:@"adminBadge"];
    self.adminBadge.alpha = 0;
    [self.contentView addSubview:self.adminBadge];
}

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
//    self.adminBadge.image = nil;
//    self.backgroundColor = [UIColor redColor];
}


@end
