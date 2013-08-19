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
        // Initialization code
		self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
		self.selectionIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"imageUnselected.png"]];
		self.selectionIcon.userInteractionEnabled = NO;
		self.selectionIcon.frame = CGRectMake(self.imageView.frame.size.width - self.selectionIcon.bounds.size.width - 5, self.imageView.frame.size.height - self.selectionIcon.bounds.size.height - 5, self.selectionIcon.frame.size.width, self.selectionIcon.frame.size.height);
		
		[self.contentView addSubview:self.imageView];
		[self.contentView addSubview:self.selectionIcon];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
