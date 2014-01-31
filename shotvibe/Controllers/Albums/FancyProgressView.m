//
//  FancyProgressView.m
//  shotvibe
//
//  Created by martijn on 30-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "FancyProgressView.h"


@interface AnimationDelegate : NSObject

- (id)initWithCompletion:(void (^)(void))completion;

@end


@implementation AnimationDelegate {
    void (^ completion_)();
}

- (id)initWithCompletion:(void (^)(void))completion
{
    self = [super init];
    if (self) {
        completion_ = [completion copy];
    }
    return self;
}


- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    NSLog(@"Animation finished");
    completion_();
}


@end

typedef NS_ENUM (NSInteger, FancyProgressViewStatus) {
    FancyProgressViewBeforeFlyIn,
    FancyProgressViewDuringFlyIn,
    FancyProgressViewAfterFlyIn,
    FancyProgressViewAfterFlyOut
};

@implementation FancyProgressView {
    CAShapeLayer *progressLayer_;
    FancyProgressViewStatus status_;
}

static float const kAlpha = 0.5;
static float const kRadius = 25;
static float const kInset = 4; // space around the progress pie chart

static float const kAppearanceTime = 0.2;
static float const kFlyInTime = 0.3;
static float const kProgressSpeed = 0.4; // max progress increase per second
static float const kFlyOutTime = 0.2;

- (id)initWithFrame:(CGRect)frame
{
    NSLog(@"Init fancy progress view");
    self = [super initWithFrame:frame];
    if (self) {
        _progress = 0.0;
        status_ = FancyProgressViewBeforeFlyIn;

        progressLayer_ = [CAShapeLayer layer];
        progressLayer_.fillRule = kCAFillRuleEvenOdd;
        progressLayer_.fillColor = [UIColor blackColor].CGColor;
        progressLayer_.backgroundColor = [UIColor whiteColor].CGColor;
        progressLayer_.opacity = 0.0;
        progressLayer_.frame = self.bounds;
        [self.layer addSublayer:progressLayer_];


        // Use a mask to hide the growing circle on the disappear animation
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        CGRect maskRect = makeCenteredRect(self.bounds, self.bounds.size.width, self.bounds.size.height);
        CGPathRef path = CGPathCreateWithRect(maskRect, NULL);
        maskLayer.path = path;
        CGPathRelease(path);
        self.layer.mask = maskLayer;

        [self appear]; // todo: get this animation (but not if the progress view was created from a refresh)
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
    [self flyInWithCompletion:nil];
}


- (void)flyInWithCompletion:(void (^)(void))completion
{
    NSLog(@"Flying in");
    [self animateLayer:progressLayer_ fromPath:[self createDisksPathWithRadius:0 hasInnerDisk:YES] toPath:[self createDisksPathWithRadius:kRadius hasInnerDisk:YES] duration:kFlyInTime timingFunctionName:kCAMediaTimingFunctionEaseInEaseOut completion:completion];
}


- (void)setProgress:(float)progress
{
    [self setProgress:progress animated:NO];
}

// tricky bits:
// - queueing the different animations when events come quickly
// - the fact that on a refresh the progress view is recreated due to the architecture of update notifications
// Perhaps we can make things a bit more elegant by adding more events.
- (void)setProgress:(float)progress animated:(BOOL)animated
{
    progress = MAX(0.0, MIN(progress, 1.0)); // keep progress between 0.0 and 1.0
    float oldProgress = _progress;
    _progress = progress;
    NSLog(@"SetProgress from %.2f to %.2f (%@animated)", oldProgress, progress, animated ? @"" : @"not ");

    // TODO synchronize
    if (animated) {
        if (progress < 0.00001) {
            //
        } else if (progress < 0.99999) {
            if (status_ == FancyProgressViewBeforeFlyIn) {
                status_ = FancyProgressViewDuringFlyIn;
                [self flyInWithCompletion:^{
                    if (status_ != FancyProgressViewAfterFlyOut) { // otherwise the view is flying out already
                        status_ = FancyProgressViewAfterFlyIn;
                        [self keyFrameAnimateLayer:progressLayer_ fromProgress:oldProgress toProgress:_progress];
                    }
                }


                ];
            } else { // we ignore updates during fly in (they won't be 100% anyway)
                NSLog(@"Progress from %.2f to %.2f", oldProgress, _progress);
                if (status_ != FancyProgressViewDuringFlyIn) {
                    [self keyFrameAnimateLayer:progressLayer_ fromProgress:oldProgress toProgress:_progress];
                }
            }
        } else {
            NSLog(@"Fly out");
            if (status_ != FancyProgressViewAfterFlyOut) {
                status_ = FancyProgressViewAfterFlyOut;
                [self flyOut];
            }
        }
    } else { // not animated
        if (progress < 0.00001) {
            status_ = FancyProgressViewBeforeFlyIn;
        } else if (progress < 0.99999) {
            status_ = FancyProgressViewAfterFlyIn;
            progressLayer_.path = [self createProgressPathWithProgress:_progress];
        } else {
            status_ = FancyProgressViewAfterFlyOut;
            progressLayer_.opacity = kAlpha;
            // hide
        }
    }
}


- (void)flyOut
{
    NSLog(@"Flying out");
    //[progressLayer_ removeAllAnimations];
    float width = self.bounds.size.width;
    float height = self.bounds.size.height;
    float surroundingRadius = sqrt(width * width + height * height) / 2 + 1;
    [self animateLayer:progressLayer_ fromPath:[self createDisksPathWithRadius:kRadius hasInnerDisk:NO] toPath:[self createDisksPathWithRadius:surroundingRadius hasInnerDisk:NO] duration:kFlyOutTime timingFunctionName:kCAMediaTimingFunctionEaseIn completion:nil];

    [CATransaction begin];
    [CATransaction setAnimationDuration:kFlyOutTime * 3];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
    progressLayer_.opacity = 0.0;
    [CATransaction commit];
}


- (void)test
{
    CAAnimation *currentAnimation = [progressLayer_ animationForKey:@"progress"];
    NSLog(@"%f %f ", CACurrentMediaTime(), currentAnimation.beginTime);
    [self animateLayer:progressLayer_ fromPath:[self createDisksPathWithRadius:0 hasInnerDisk:YES] toPath:[self createDisksPathWithRadius:kRadius hasInnerDisk:YES] duration:kFlyInTime timingFunctionName:kCAMediaTimingFunctionEaseInEaseOut completion:nil];
}


// only need to call this if we want to reuse the progress view
- (void)disappear
{
    progressLayer_.opacity = kAlpha; // no need to animate, as nothing is visible after flyOut
}


- (void)animateLayer:(CAShapeLayer *)layer fromPath:(CGPathRef)fromPath toPath:(CGPathRef)toPath duration:(float)duration timingFunctionName:(NSString *)timingFunctionName completion:(void (^)(void))completion
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.duration = duration;
    animation.fromValue = (__bridge id)fromPath;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:timingFunctionName];
    if (completion) {
        animation.delegate = [[AnimationDelegate alloc] initWithCompletion:completion];
    }
    [layer addAnimation:animation forKey:nil];

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
