//
//  UILabel+AnimatedTransition.m
//  shotvibe
//
//  Created by Tsah Kashkash on 16/11/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import "UILabel+AnimatedTransition.h"

@implementation UILabel (AnimatedTransition)

-(void)willMoveToSuperview:(UIView *)newSuperview {
    
    CATransition *animation = [CATransition animation];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.type = kCATransitionFade;
    animation.duration = 2.75;
    [self.layer addAnimation:animation forKey:@"kCATransitionFade"];
    
}

@end
