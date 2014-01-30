//
//  FancyProgressView.m
//  shotvibe
//
//  Created by martijn on 30-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "FancyProgressView.h"

@implementation FancyProgressView {
    UILabel *label_;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _progress = 0.0;

        self.backgroundColor = [UIColor blackColor];
        self.alpha = 0.5;

        NSLog(@"FancyProgressView Frame %f %f %f %f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
        label_ = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];

        label_.textColor = [UIColor whiteColor];
        label_.font = [UIFont fontWithName:@"Trebuchet MS" size:7.0f];
        label_.text = @"Progress not started";
        [self addSubview:label_];
        
        self.hidden = YES;
    }
    return self;
}


- (void)start
{
    label_.text = @"Progress started";
    self.hidden = NO;
}


- (void)stop
{
    label_.text = @"Progress stopped";
    self.hidden = YES;
}


- (void)setProgress:(float)progress
{
    _progress = MAX(0.0, MIN(progress, 1.0)); // keep progress between 0.0 and 1.0

    label_.text = [NSString stringWithFormat:@"Progress at: %f", progress];
}


@end
