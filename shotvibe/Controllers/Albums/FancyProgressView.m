//
//  FancyProgressView.m
//  shotvibe
//
//  Created by martijn on 30-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "FancyProgressView.h"

@implementation FancyProgressView {
    CAShapeLayer *progressLayer_;
    CAShapeLayer *progress2Layer_;
}

static float const kAlpha = 0.5;
static float const kRadius = 25;
static float const kInset = 4; // space around the progress pie chart

static float const kAppearanceTime = 0.3;
static float const kFlyInTime = 0.3;
static float const kProgressSpeed = 0.3; // progress increase animation per second
static float const kFlyOutTime = 0.2;

- (id)initWithFrame:(CGRect)frame
{
    NSLog(@"Init fancy progress view");
    self = [super initWithFrame:frame];
    if (self) {
        _progress = 0.0;

        progressLayer_ = [CAShapeLayer layer];
        progressLayer_.fillRule = kCAFillRuleEvenOdd;
        progressLayer_.fillColor = [UIColor blackColor].CGColor;
        progressLayer_.opacity = 0.0;
        [self.layer addSublayer:progressLayer_];


        // Use a mask to hide the growing circle on the disappear animation
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        CGRect maskRect = makeCenteredRect(self.bounds, self.bounds.size.width, self.bounds.size.height);
        CGPathRef path = CGPathCreateWithRect(maskRect, NULL);
        maskLayer.path = path;
        CGPathRelease(path);
        self.layer.mask = maskLayer;

        [self appear];
        [self flyIn];
    }
    return self;
}


/* Implement this if we want to support resizing the view
 - (void)layoutSubviews
 {
 }
 */


- (void)appear
{
    progressLayer_.path = [self createDisksPathWithRadius:0 hasInnerDisk:YES];

    [CATransaction begin];
    [CATransaction setAnimationDuration:kAppearanceTime];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    progressLayer_.opacity = kAlpha;
    [CATransaction commit];
}


- (void)flyIn
{
    [self animateLayer:progressLayer_ fromPath:[self createDisksPathWithRadius:0 hasInnerDisk:YES] toPath:[self createDisksPathWithRadius:kRadius hasInnerDisk:YES] duration:kFlyInTime timingFunctionName:kCAMediaTimingFunctionEaseInEaseOut];
}


- (void)setProgress:(float)progress
{
    [self setProgress:progress animated:NO];
}


// TODO: take animated into account
- (void)setProgress:(float)progress animated:(BOOL)animated
{
    float oldProgress = _progress;
    _progress = MAX(0.0, MIN(progress, 1.0)); // keep progress between 0.0 and 1.0

    NSLog(@"Progress from %.2f to %.2f", oldProgress, _progress);
    [self keyFrameAnimateLayer:progressLayer_ fromProgress:oldProgress toProgress:_progress];
}


- (void)flyOut
{
    float width = self.bounds.size.width;
    float height = self.bounds.size.height;
    float surroundingRadius = sqrt(width * width + height * height) / 2 + 1;
    [self animateLayer:progressLayer_ fromPath:[self createDisksPathWithRadius:kRadius hasInnerDisk:NO] toPath:[self createDisksPathWithRadius:surroundingRadius hasInnerDisk:NO] duration:kFlyOutTime timingFunctionName:kCAMediaTimingFunctionEaseIn];
}


// only need to call this if we want to reuse the progress view
- (void)disappear
{
    progressLayer_.opacity = kAlpha; // no need to animate, as nothing is visible after flyOut
}


- (void)animateLayer:(CAShapeLayer *)layer fromPath:(CGPathRef)fromPath toPath:(CGPathRef)toPath duration:(float)duration timingFunctionName:(NSString *)timingFunctionName
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.duration = duration;
    animation.fromValue = (__bridge id)fromPath;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:timingFunctionName];
    [layer addAnimation:animation forKey:animation.keyPath];

    layer.path = toPath;
}


// For the pie chart, we cannot use a basic animation, as the interpolation doesn't work very well here.
// A key-frame animation solves the problem.
- (void)keyFrameAnimateLayer:(CAShapeLayer *)layer fromProgress:(float)fromProgress toProgress:(float)toProgress
{
    float progressDelta = toProgress - fromProgress;
    int nrOfFrames = progressDelta / 0.01;
    // nr of frames needs to be at least 1 per 4 degrees animated, so we take 1 per 0.01 progress (= 3.6 degrees)

    NSMutableArray *values = [NSMutableArray array];
    for (int i = 0; i < nrOfFrames + 1; i++) {
        float progress = fromProgress + i * progressDelta / nrOfFrames;

        [values addObject:(__bridge id)[self createProgressPathWithProgress:progress]];
    }

    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"path"];
    animation.values = values;
    animation.duration = progressDelta / kProgressSpeed;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [layer addAnimation:animation forKey:nil];

    layer.path = [self createProgressPathWithProgress:toProgress];
}


// Used for flying the disks in and out.
- (CGPathRef)createDisksPathWithRadius:(float)radius hasInnerDisk:(BOOL)hasInnerDisk
{
    UIBezierPath *path = [UIBezierPath bezierPath];

    // outer rectangle
    [path appendPath:[UIBezierPath bezierPathWithRect:makeCenteredRect(self.bounds, self.bounds.size.width, self.bounds.size.height)]];

    // outer disk
    [path appendPath:[UIBezierPath bezierPathWithOvalInRect:makeCenteredRect(self.bounds, radius * 2, radius * 2)]];

    if (hasInnerDisk) {
        float innerRadius = MAX(0.0, 2 * (radius - kInset));
        [path appendPath:[UIBezierPath bezierPathWithOvalInRect:makeCenteredRect(self.bounds, innerRadius, innerRadius)]];
    }
    return path.CGPath;
}


// Used for drawing the progress pie.
- (CGPathRef)createProgressPathWithProgress:(float)progress
{
    UIBezierPath *progressPath = [UIBezierPath bezierPath];
    [progressPath appendPath:[UIBezierPath bezierPathWithRect:makeCenteredRect(self.bounds, self.bounds.size.width, self.bounds.size.height)]];
    [progressPath appendPath:[UIBezierPath bezierPathWithOvalInRect:makeCenteredRect(self.bounds, kRadius * 2, kRadius * 2)]];


    if (progress < 1.0) { // an arc of length 2*M_PI has length 0, so we don't draw in that case
        float radius = MAX(0.0, kRadius - kInset);
        float angle = progress * 2 * M_PI;

        CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        [progressPath moveToPoint:center];
        [progressPath addArcWithCenter:center radius:radius startAngle:angle - M_PI_2 endAngle:3 * M_PI_2 clockwise:YES];
        [progressPath addLineToPoint:center];
    }

    return progressPath.CGPath;
}


CGRect makeCenteredRect(CGRect rect, float width, float height)
{
    CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    return (CGRect) {
               {
                   center.x - width / 2, center.y - height / 2
               }, {
                   width, height
               }
    };
}


@end
