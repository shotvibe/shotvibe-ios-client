//
//  FancyProgressView.m
//  shotvibe
//
//  Created by Oblosys on 30-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "FancyProgressView.h"

@implementation FancyProgressView {
    CAShapeLayer *progressLayer_;

    long long uniqueAnimationKeyCounter_;
}

static float const kOpacity = 0.5;
static float const kRadius = 17; // radius of the progress pie chart
static float const kBounceRadius = kRadius + 3; // radius before bouncing back
static float const kInset = 4; // space around the progress pie chart

static float const kAppearanceTime = 0.5; // Time for the grey background to appear
static float const kFlyInTime = 0.3; // Time for the disks to appear from the center
static float const kBounceTime = 0.10; // Time for the disks to bounce back
static float const kProgressSpeed = 0.8; // Max progress increase per second
static float const kFlyOutTime = 0.3; // Time for the outer disk to disappear to the edges
static float const kFadeOutTime = 3 * kFlyOutTime; // Time for the white background to fade out


// NOTE: For ShotVibe photo uploads, new progress views may cut off animations,
//       see issue 278: https://github.com/shotvibe/shotvibe-ios-client/issues/278
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        progressLayer_ = [CAShapeLayer layer];
        progressLayer_.fillRule = kCAFillRuleEvenOdd;
        progressLayer_.fillColor = [UIColor blackColor].CGColor;
        progressLayer_.backgroundColor = [UIColor whiteColor].CGColor;

        progressLayer_.frame = self.bounds;
        [self.layer addSublayer:progressLayer_];

        // Use a mask to hide the growing circle on the disappear animation
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        CGRect maskRect = makeCenteredRect(self.bounds, self.bounds.size.width, self.bounds.size.height);
        CGPathRef path = CGPathCreateWithRect(maskRect, NULL);
        maskLayer.path = path;
        CGPathRelease(path);
        self.layer.mask = maskLayer;

        [self reset];
    }
    return self;
}


/* Implement this if we want to support resizing the view
 - (void)layoutSubviews
 {
 }
 */


// Clear everything, for init or reuse.
- (void)reset
{
    [progressLayer_ removeAllAnimations];
    progressLayer_.opacity = 0.0;
    progressLayer_.path = [self createBackgroundRectangle].CGPath;

    uniqueAnimationKeyCounter_ = 0;

    _progress = 0.0;
}


// Let the dark foreground fade in.
// NOTE: Cannot be called for ShotVibe photo uploads,
//       see issue 278: https://github.com/shotvibe/shotvibe-ios-client/issues/278
- (void)appear
{
    CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.duration = kAppearanceTime;
    opacityAnimation.fromValue = @0.0;
    opacityAnimation.toValue = @(kOpacity);
    opacityAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    progressLayer_.opacity = kOpacity;
    [progressLayer_ addAnimation:opacityAnimation forKey:[self createUniqueAnimationKey]];

    // Need to animate the path as well, or the next animation interferes. Not exactly clear why.
    CABasicAnimation *constantBackgroundAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    constantBackgroundAnimation.duration = kAppearanceTime;
    constantBackgroundAnimation.fromValue = (__bridge id)[self createBackgroundRectangle].CGPath;
    constantBackgroundAnimation.toValue = (__bridge id)[self createBackgroundRectangle].CGPath;
    [progressLayer_ addAnimation:constantBackgroundAnimation forKey:[self createUniqueAnimationKey]];
    progressLayer_.path = [self createBackgroundRectangle].CGPath;
}


- (void)setProgress:(float)progress
{
    [self setProgress:progress animated:NO];
}


- (void)setProgress:(float)progress animated:(BOOL)animated
{
    progress = MAX(0.0, MIN(progress, 1.0)); // keep progress between 0.0 and 1.0
    float oldProgress = _progress;
    _progress = progress;
    //RCLog(@"SetProgress from %.2f to %.2f (%@animated)", oldProgress, progress, animated ? @"" : @"not ");


    if (animated) {
        if (fequal(progress, oldProgress)) {
            return;
        }

        // 0.0 will not occur, since oldProgress will also be 0.0
        if (oldProgress < 0.000001) {
            [self flyIn];
        }
        [self progressFrom:oldProgress to:progress];
        if (progress > 0.999999) {
            [self flyOut];
        }
    } else { // not animated
        [progressLayer_ removeAllAnimations];

        if (progress < 0.000001) {
            [self executeWithoutImplicitAnimation:^{
                progressLayer_.opacity = kOpacity;
                progressLayer_.path = [self createBackgroundRectangle].CGPath;
            }];
        } else if (progress < 0.999999) {
            [self executeWithoutImplicitAnimation:^{
                progressLayer_.opacity = kOpacity;
                progressLayer_.path = [self createProgressPathWithProgress:_progress];
            }];
        } else {
            [self executeWithoutImplicitAnimation:^{
                progressLayer_.opacity = 0.0;
            }];
        }
    }
}


#pragma mark - Animations



- (void)flyIn
{
    //RCLog(@"Flying in");
    // start with inner of kInset so the line doesn't get too thin
    [self animateLayer:progressLayer_ fromPath:[self createDisksPathWithRadius:0 hasInnerDisk:YES] toPath:[self createDisksPathWithRadius:kBounceRadius hasInnerDisk:YES] duration:kFlyInTime timingFunctionName:kCAMediaTimingFunctionDefault];
    [self animateLayer:progressLayer_ fromPath:[self createDisksPathWithRadius:kBounceRadius hasInnerDisk:YES] toPath:[self createDisksPathWithRadius:kRadius hasInnerDisk:YES] duration:kBounceTime timingFunctionName:kCAMediaTimingFunctionDefault];
}


- (void)progressFrom:(float)fromProgress to:(float)toProgress
{
    //RCLog(@"Progressing from %.2f to %.2f", fromProgress, toProgress);
    [self keyFrameAnimateLayer:progressLayer_ fromProgress:fromProgress toProgress:toProgress];
}


- (void)flyOut
{
    //RCLog(@"Flying out");
    float surroundingRadius = sqrt(square(self.bounds.size.width) + square(self.bounds.size.height)) / 2 + 1;
    [self animateLayer:progressLayer_ fromPath:[self createDisksPathWithRadius:kRadius hasInnerDisk:NO] toPath:[self createDisksPathWithRadius:surroundingRadius hasInnerDisk:NO] duration:kFlyOutTime timingFunctionName:kCAMediaTimingFunctionEaseIn];

    // fade out the entire view, otherwise the white background remains visible
    CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.duration = kFadeOutTime;
    opacityAnimation.beginTime = [self currentAnimationsEndTime];
    opacityAnimation.fromValue = @(kOpacity);
    opacityAnimation.toValue = @0.0;
    opacityAnimation.fillMode = kCAFillModeBackwards;
    opacityAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    [progressLayer_ addAnimation:opacityAnimation forKey:[self createUniqueAnimationKey]];
    progressLayer_.opacity = 0.0;
}


- (void)animateLayer:(CAShapeLayer *)layer fromPath:(CGPathRef)fromPath toPath:(CGPathRef)toPath duration:(float)duration timingFunctionName:(NSString *)timingFunctionName
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.beginTime = [self currentAnimationsEndTime];
    animation.duration = duration;
    // animation.fillMode = kCAFillModeBoth;
    animation.fromValue = (__bridge id)fromPath;
    animation.toValue = (__bridge id)toPath;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:timingFunctionName];

    [progressLayer_ addAnimation:animation forKey:[self createUniqueAnimationKey]];

    layer.path = toPath;
}


// For the pie chart, we cannot use a basic animation, as the interpolation doesn't work very well here.
// A key-frame animation solves the problem.
- (void)keyFrameAnimateLayer:(CAShapeLayer *)layer fromProgress:(float)fromProgress toProgress:(float)toProgress
{
    float progressDelta = toProgress - fromProgress;
    int nrOfFrames = MAX(4, progressDelta / 0.01);
    // nr of frames needs to be at least 1 per 4 degrees animated, so we take 1 per 0.01 progress (= 3.6 degrees), but at least 4, to prevent problems on small changes

    NSMutableArray *values = [NSMutableArray array];
    for (int i = 0; i < nrOfFrames + 1; i++) {
        float progress = fromProgress + i * progressDelta / nrOfFrames;

        [values addObject:(__bridge id)[self createProgressPathWithProgress:progress]];
    }

    [CATransaction begin];
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"path"];
    animation.values = values;
    animation.duration = progressDelta / kProgressSpeed;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.beginTime = [self currentAnimationsEndTime];
    animation.fillMode = kCAFillModeForwards;

    [layer addAnimation:animation forKey:[self createUniqueAnimationKey]];
    layer.path = (__bridge CGPathRef)[values lastObject];
}


#pragma mark - Path creation

- (UIBezierPath *)createBackgroundRectangle
{
    UIBezierPath *path = [UIBezierPath bezierPath];

    // outer rectangle
    [path appendPath:[UIBezierPath bezierPathWithRect:makeCenteredRect(self.bounds, self.bounds.size.width, self.bounds.size.height)]];

    return path;
}


// Used for flying the disks in and out.
- (CGPathRef)createDisksPathWithRadius:(float)radius hasInnerDisk:(BOOL)hasInnerDisk
{
    UIBezierPath *path = [self createBackgroundRectangle];

    // outer disk
    [path appendPath:[UIBezierPath bezierPathWithOvalInRect:makeCenteredRect(self.bounds, (radius + kInset) * 2, (radius + kInset) * 2)]];

    if (hasInnerDisk) {
        [path appendPath:[UIBezierPath bezierPathWithOvalInRect:makeCenteredRect(self.bounds, radius * 2, radius * 2)]];
    }
    return path.CGPath;
}


// Used for drawing the progress pie.
- (CGPathRef)createProgressPathWithProgress:(float)progress
{
    UIBezierPath *path = [self createBackgroundRectangle];

    [path appendPath:[UIBezierPath bezierPathWithOvalInRect:makeCenteredRect(self.bounds, (kRadius + kInset) * 2, (kRadius + kInset) * 2)]];

    if (progress < 0.999999) { // an arc of length 2*M_PI has length 0, so we don't draw in that case
        float angle = progress * 2 * M_PI;

        CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        [path moveToPoint:center];
        [path addArcWithCenter:center radius:kRadius startAngle:angle - M_PI_2 endAngle:3 * M_PI_2 clockwise:YES];
        [path addLineToPoint:center];
    }

    return path.CGPath;
}


#pragma mark - Util


// Unfortunately, the only way to access all animations is through a list of keys, so every animation needs a unique key.
- (NSString *)createUniqueAnimationKey
{
    return [NSString stringWithFormat:@"animation-%lld", uniqueAnimationKeyCounter_++];
}


// Return the time at which all current animations end.
- (CFTimeInterval)currentAnimationsEndTime
{
    CFTimeInterval endTime = 0.0;

    for (NSString *key in progressLayer_.animationKeys) {
        CAAnimation *anim = [progressLayer_ animationForKey:key];
        CFTimeInterval beginTime = anim.beginTime ? : CACurrentMediaTime(); // if there's no begin time, the animation is about to be started
        //RCLog(@"Animation Key:%@ begin:%f duration:%f ends in:%.2fs", key, anim.beginTime, anim.duration, anim.duration - (CACurrentMediaTime() - anim.beginTime));
        endTime = MAX(endTime, beginTime + anim.duration);
    }

    return endTime;
}


// Opacity is animated by default, and there seems no easy way to disable it without also disabling any other animations we set on it.
- (void)executeWithoutImplicitAnimation:(void (^)(void))layerChange
{
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
    layerChange();
    [CATransaction commit];
}


CGRect makeCenteredRect(CGRect rect, float width, float height)
{
    CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    return CGRectMake(center.x - width / 2, center.y - height / 2, width, height);
}


@end
