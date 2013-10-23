//
//  SVSelectionGridCell.m
//  shotvibe
//
//  Created by John Gabelmann on 7/11/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVSelectionGridCell.h"

@implementation SVSelectionGridCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CGRect r = CGRectMake(self.bounds.size.width - 30,
							  self.bounds.size.height - 30,
							  30,
							  30);
		
		self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
		
		self.selectionButton = [[UIButton alloc] initWithFrame:r];
		[self.selectionButton setImage:[UIImage imageNamed:@"imageUnselected.png"] forState:UIControlStateNormal];
		[self.selectionButton addTarget:self action:@selector(checkmarkTouched:) forControlEvents:UIControlEventTouchUpInside];
		
		[self.contentView addSubview:self.imageView];
		[self.contentView addSubview:self.selectionButton];
    }
    return self;
}

- (void)checkmarkTouched:(id)sender {
	[self.delegate cellDidCheck:self];
}

@end
