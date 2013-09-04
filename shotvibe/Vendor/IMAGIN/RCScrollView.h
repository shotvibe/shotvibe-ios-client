//
//  RCScrollView.h
//  IMAGIN
//
//  Created by Baluta Cristian on 6/17/10.
//  Copyright 2010 ralcr. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RCScrollView : UIScrollView <UIScrollViewDelegate> {
	id d;
	UITapGestureRecognizer *gesture;
	UISwipeGestureRecognizer *swipeGesture;
}

- (void)setD:(id)deleg;

@end
