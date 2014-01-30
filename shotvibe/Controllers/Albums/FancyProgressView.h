//
//  FancyProgressView.h
//  shotvibe
//
//  Created by martijn on 30-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FancyProgressView : UIView

- (void)start;

- (void)stop;

@property (nonatomic) float progress; // between 0.0 and 1.0, values outside are clipped

@end
