//
//  SVPickerCell.m
//  shotvibe
//
//  Created by Salvatore Balzano on 20/01/14.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVPickerCell.h"

@implementation SVPickerCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];

        UIImageView *selectedView = [[UIImageView alloc] initWithFrame:self.bounds];
        selectedView.image = [UIImage imageNamed:@"frame_selected"];
        self.selectedBackgroundView = selectedView;

        self.imageView = [[UIImageView alloc] initWithFrame:CGRectInset(self.bounds, 1, 1)];
        self.imageView.layer.cornerRadius = 2.0;
        self.imageView.clipsToBounds = YES;
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.imageView];
    }
    return self;
}


- (void)prepareForReuse
{
    self.imageView.frame = CGRectInset(self.bounds, 1, 1);
    self.imageView.image = nil;
    self.tag = 0;
    self.selected = NO;
}


@end
