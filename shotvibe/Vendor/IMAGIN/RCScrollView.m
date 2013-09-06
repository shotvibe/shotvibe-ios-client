//
//  RCScrollView.m
//  IMAGIN
//
//  Created by Baluta Cristian on 6/17/10.
//  Copyright 2010 ralcr. All rights reserved.
//

#import "RCScrollView.h"


@implementation RCScrollView


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
        self.delegate = self;
		gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
		[self addGestureRecognizer:gesture];
    }
    return self;
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    return YES;
}



#pragma mark scrollview delegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([self.scrollDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating)]) {
		[self.scrollDelegate performSelector:@selector(scrollViewDidEndDecelerating) withObject:nil];
	}
}




#pragma mark Touches

- (void)tap:(UITapGestureRecognizer *)tapGesture {
	if ([self.scrollDelegate respondsToSelector:@selector(areaTouched)]) {
		[self.scrollDelegate performSelector:@selector(areaTouched) withObject:nil];
	}
}
- (void)swipeUp:(UISwipeGestureRecognizer *)tapGesture {
	if ([self.scrollDelegate respondsToSelector:@selector(areaTouchedForExit)]) {
		[self.scrollDelegate performSelector:@selector(areaTouchedForExit) withObject:nil];
	}
}

@end
