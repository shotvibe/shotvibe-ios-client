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
        self.backgroundColor = [UIColor whiteColor];

        UIView *selectedView = [[UIView alloc] initWithFrame:self.bounds];
        selectedView.backgroundColor = [UIColor blueColor];
        self.selectedBackgroundView = selectedView;

        self.imageView = [[UIImageView alloc] initWithFrame:CGRectInset(self.bounds, 4, 4)];
        self.imageView.clipsToBounds = YES;
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.imageView];
    }
    return self;
}


@end
