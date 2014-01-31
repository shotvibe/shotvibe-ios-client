//
//  FancyProgressView.h
//  shotvibe
//
//  Created by martijn on 30-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FancyProgressView : UIView

- (void)appear;

- (void)flyIn;

- (void)setProgress:(float)progress animated:(BOOL)animated;

- (void)flyOut;

@property (nonatomic) float progress; // between 0.0 and 1.0, values outside are clipped
// Setting progress with property is not animated.

@end
