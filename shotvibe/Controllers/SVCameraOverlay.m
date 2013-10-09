//
//  SVCameraOverlay.m
//  shotvibe
//
//  Created by Baluta Cristian on 01/09/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVCameraOverlay.h"

@implementation SVCameraOverlay

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		focusRect = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
		focusRect.backgroundColor = [UIColor clearColor];
		focusRect.layer.borderColor = [UIColor colorWithWhite:1 alpha:1].CGColor;
		focusRect.layer.borderWidth = 1;
		focusRect.alpha = 0;
				
		[self addSubview:focusRect];
	}
	return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
	
	//RCLog(@"tap %@", NSStringFromCGPoint(point));
	
//	if(CGRectContainsPoint(infoButton.frame, point) || CGRectContainsPoint(snapButton.frame, point)) {
//		// touched button
//		return YES;
//	}
	
	return YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	RCLog(@"touches began");
    [super touchesBegan:touches withEvent:event];
	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self];
	CGRect rect = focusRect.frame;
	rect.origin.x = location.x - rect.size.width/2;
	rect.origin.y = location.y - rect.size.height/2;
	focusRect.frame = rect;
	focusRect.transform = CGAffineTransformMakeScale(1.5, 1.5);
	
	[UIView animateWithDuration:0.2 animations:^{
		focusRect.transform = CGAffineTransformIdentity;
		focusRect.alpha = 1;
	} completion:^(BOOL c){
		[UIView animateWithDuration:0.2
							  delay:1
							options:UIViewAnimationOptionCurveEaseIn
						 animations:^{
							 focusRect.transform = CGAffineTransformMakeScale(0.5, 0.5);
							 focusRect.alpha = 0;
		}
						 completion:^(BOOL c){
			
		}];
	}];
}

@end
