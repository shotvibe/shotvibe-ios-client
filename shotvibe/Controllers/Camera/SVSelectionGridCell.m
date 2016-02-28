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
        CGRect r = CGRectMake(self.bounds.size.width - 28, self.bounds.size.height - 28, 22, 22);
		
		self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
		
		self.selectionImage = [[UIImageView alloc] initWithFrame:r];
		[self.selectionImage setImage:[UIImage imageNamed:@"imageUnselected.png"]];
		
		[self.contentView addSubview:self.imageView];
		[self.contentView addSubview:self.selectionImage];
		
		UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self
																						   action:@selector(handleLongPress:)];
		lpgr.minimumPressDuration = 0.3; //seconds
		lpgr.delegate = self;
		[self addGestureRecognizer:lpgr];
    }
    return self;
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
	
	// only when gesture was recognized, not when ended
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan){
		[self.delegate cellDidLongPress:self];
	}
}


@end
