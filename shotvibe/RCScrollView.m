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
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	touched = YES;
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    touched = NO;
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([d respondsToSelector:@selector(areaTouched)] && touched) {
		[d performSelector:@selector(areaTouched) withObject:nil];
	}
}
//- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//	NSLog(@"touchesMoved");
//}


@end
