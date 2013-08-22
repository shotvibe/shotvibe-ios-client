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
		swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeUp:)];
		swipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
		[self addGestureRecognizer:gesture];
		[self addGestureRecognizer:swipeGesture];
    }
    return self;
}

- (void)setD:(id)deleg {
    d = deleg;
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    return YES;
}



#pragma mark scrollview delegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([d respondsToSelector:@selector(scrollViewDidEndDecelerating)]) {
		[d performSelector:@selector(scrollViewDidEndDecelerating) withObject:nil];
	}
}




#pragma mark Touches

- (void)tap:(UITapGestureRecognizer *)tapGesture {
	if ([d respondsToSelector:@selector(areaTouched)]) {
		[d performSelector:@selector(areaTouched) withObject:nil];
	}
}
- (void)swipeUp:(UISwipeGestureRecognizer *)tapGesture {
	if ([d respondsToSelector:@selector(areaTouchedForExit)]) {
		[d performSelector:@selector(areaTouchedForExit) withObject:nil];
	}
}

@end
