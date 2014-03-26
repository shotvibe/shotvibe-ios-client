//
//  SVContactCell.m
//  shotvibe
//
//  Created by Baluta Cristian on 20/08/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVContactCell.h"

@implementation SVContactCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse
{
    self.contactIcon.layer.cornerRadius = roundf(self.contactIcon.frame.size.width / 2.0);
    self.contactIcon.layer.masksToBounds = YES;
}


@end
