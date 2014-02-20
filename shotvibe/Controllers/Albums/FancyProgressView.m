//
//  FancyProgressView.m
//  shotvibe
//
//  Created by Oblosys on 30-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "FancyProgressView.h"

@interface CachedProgressModel : NSObject

@property (nonatomic, assign) BOOL didAppear;
@property (nonatomic, assign) BOOL didFlyIn;
@property (nonatomic, assign) BOOL didFlyOut;
@property (nonatomic, assign) float progress;

@end

@implementation CachedProgressModel

// TODO: explain
+ (id)sharedProgressCache
{
    static dispatch_once_t onceQueue;
    static NSMapTable *progressCache = nil;

    dispatch_once(&onceQueue, ^{
        progressCache = [NSMapTable weakToStrongObjectsMapTable];
    });
    return progressCache;
}


- (id)init
{
    self = [super init];
    if (self) {
        _didAppear = NO;
        _didFlyIn = NO;
        _didFlyOut = NO;
        _progress = 0.0;
    }
    return self;
}
@end


@interface  FancyProgressView()

@property (nonatomic, getter = isDisabled) BOOL disabled;

@end


@implementation FancyProgressView {
    long long uniqueAnimationKeyCounter_;
    CAShapeLayer *progressLayer_;

    __weak id progressObject_;
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


// contains all active progress views, for stopping animations
+ (id)sharedAllProgressViews
{
    static dispatch_once_t onceQueue;
    static NSHashTable *allProgressViews = nil;

    dispatch_once(&onceQueue, ^{
        allProgressViews = [NSHashTable weakObjectsHashTable];
    });
    return allProgressViews;
}


+ (void)disableProgressViewsWithCompletion:(void (^)())completionBlock
{
    CFTimeInterval animationsEndMediaTime = 0.0;

    for (FancyProgressView *fpv in [FancyProgressView sharedAllProgressViews]) {
        fpv.disabled = YES;

        animationsEndMediaTime = MAX(animationsEndMediaTime, [fpv currentAnimationsEndTime]);
    }

    CFTimeInterval animationsEndTime = MAX(0, animationsEndMediaTime - CACurrentMediaTime());
    RCLog(@"Animations end in %.2fs", animationsEndTime);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, animationsEndTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        completionBlock();
    });
}


#pragma mark - Progress cache


- (CachedProgressModel *)getCachedProgressModel
{
    CachedProgressModel *cachedProgress = [[CachedProgressModel sharedProgressCache] objectForKey:progressObject_];
    if (!cachedProgress) {
        cachedProgress = [[CachedProgressModel alloc] init];
        if (progressObject_) {
            [[CachedProgressModel sharedProgressCache] setObject:cachedProgress forKey:progressObject_];
        } else {
            RCLog(@"No progress object has been set.");
        }
    }
    return cachedProgress;
}


- (BOOL)didAppear
{
    return [self getCachedProgressModel].didAppear;
}


- (void)setDidAppear:(BOOL)didAppear
{
    [self getCachedProgressModel].didAppear = didAppear;
}


- (BOOL)didFlyIn
{
    return [self getCachedProgressModel].didFlyIn;
}


- (void)setDidFlyIn:(BOOL)didFlyIn
{
    [self getCachedProgressModel].didFlyIn = didFlyIn;
}


- (BOOL)didFlyOut
{
    return [self getCachedProgressModel].didFlyOut;
}


- (void)setDidFlyOut:(BOOL)didFlyOut
{
    [self getCachedProgressModel].didFlyOut = didFlyOut;
}

- (float)getCachedProgress
{
    return [self getCachedProgressModel].progress;
}


- (void)setCachedProgress:(float)cachedProgress
{
    [self getCachedProgressModel].progress = cachedProgress;
}

// PROBLEM: waiting for animation, everything is blocked, and then certain items complete and on reload they
// are not albumUploadingPhotos anymore.

// TODO: Check if appearance on init always works, or we need to call a specific appear method from the controller. (test in Button 12 doesn't seem to allow animation (even though we don't need one there)


// TODO: check weak property and cover case that it is null/nil (shouldn't occur)
// TODO: remove NSSet from gridviewcontroller
// TODO: explain that we assume one active view controller. otherwise need to group progress views on controller
// TODO: check if weak hash table works as expected (objects are removed after releasing them)
// TODO: check reuse and reset

// TODO: on completion in uploader, set to 100%

// on setProgress, check appear and flyIn

// get old progress from ProgressCache use it to compute animation. No need for oldProgress anymore?
// probably could use this to do flyin flyout on init (flyout is whan view was disabled just before animation)

// Issues:
// need didFlyIn?
// what is fp.progress  Return cached progress, or do we need to keep a property as well?


/*

 TODO
 Set progress at 1.0 on complete
 Look at cell init again. Apparently I changed it to awakeFromNib in commit 360f6e5e56dc88376b0709761a2f48fa25c46094

 maybe upload is complete before progress is 1.0?

 Difference with Omer is that he has many album and lots of pictures that produce download traffic. Still weird that the refresh comes exactly when the animation should finish.

 Idea progressCache: PhotoID -> shownProgress   to survive new views for same photo and missed events
 Use instead of oldProgress
 purgeCache  (Set PhotoID)    remove all photos except ones in set

 +stop
 for each progressview: animationEndTime = stop progressView
 return max animationEndTime

 Global, only one viewcontroller is possible, otherwise use dictionary

 ViewController
 on reloadData: purge
 endtime <- stop
 wait until endtime to [super reload]
 if already waiting, compute new endtime (maybe with some max)

 Crappy: p1 is < 100% on reload but was finished after reload and is removed from cache
 -- solvable by always finishing animations for elements disappearing from cache


 */


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _disabled = NO;

        uniqueAnimationKeyCounter_ = 0;
        progressObject_ = nil;

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

        // TODO: thread safe
        [[FancyProgressView sharedAllProgressViews] addObject:self];
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

    RCLog(@"\n\n\n\n\nRESET\n\n");
    [progressLayer_ removeAllAnimations];
    progressLayer_.opacity = 0.0;
    progressLayer_.path = [self createBackgroundRectangle].CGPath;

    uniqueAnimationKeyCounter_ = 0;

    _progress = 0.0;
}

// TODO: call this one setup or something, maybe combine with reset
- (void)appearWithProgressObject:(id)progressObject
{
    progressObject_ = progressObject;
    RCLog(@"Appear:\n%@ %d", progressObject_, [self didAppear]);
    if (![self didAppear]) {
        [self animateAppear];
        [self setDidAppear:YES];
    }
    else {
        progressLayer_.opacity = kOpacity;
        progressLayer_.path = [self createProgressPathWithProgress:[self getCachedProgress]];
    }
    // TODO: no flyin, only do that on setProgress
    // what happens if there's no flyin, but progress was set to 1 already?

    // Maybe need to keep setting cachedProgress even when disabled, otherwise we may miss updates to 1.0

    /*
     Possible situations:
     notAppear (fresh)
     appeared, no progress (so no flyin)
     progress between 0 and 0.999
     ..
     flown out

     */
    if ([self getCachedProgress] < 0.999999 && [self didFlyIn]) {
        progressLayer_.opacity = kOpacity;
        progressLayer_.path = [self createProgressPathWithProgress:[self getCachedProgress]];
    } else if ([self getCachedProgress] > 0.999999 && ![self didFlyOut]) {
        [self animateFlyOut];
        [self setDidFlyOut:YES];
    }
}


- (void)setProgress:(float)progress
{
    if (![ self isDisabled]) {
        progress = MAX(0.0, MIN(progress, 1.0)); // keep progress between 0.0 and 1.0
        RCLog(@"SetProgress from %.2f to %.2f", [self getCachedProgress], progress);
        RCLog(@"%d %d %d",[self didAppear],[self didFlyIn],[self didFlyOut]);
        if (![self didAppear]) {
            [self animateAppear];
            [self setDidAppear:YES];
        }
        if (![self didFlyIn]) {
            [self animateFlyIn];
            [self setDidFlyIn:YES];
        }

        if (![self didFlyOut]) {
            [self animateProgressFrom:[self getCachedProgress] to:progress];
            [self setCachedProgress:progress];

            if (progress > 0.999999) {
                [self animateFlyOut];
                [self setDidFlyOut:YES];
            }
        }


        /*
         float oldProgress = _progress;
         _progress = progress;
         if (animated) {
         if (fequal(progress, oldProgress)) {
         return;
         }

         // 0.0 will not occur, since oldProgress will also be 0.0
         if (oldProgress < 0.000001) {
         [self animateFlyIn];
         }
         [self animateProgressFrom:oldProgress to:progress];
         if (progress > 0.999999) {
         [self animateFlyOut];
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
         */
    }
}


#pragma mark - Animations


// Let the dark foreground fade in.
- (void)animateAppear
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


- (void)animateFlyIn
{
    //RCLog(@"Flying in");
    // start with inner of kInset so the line doesn't get too thin
    [self animateLayer:progressLayer_ fromPath:[self createDisksPathWithRadius:0 hasInnerDisk:YES] toPath:[self createDisksPathWithRadius:kBounceRadius hasInnerDisk:YES] duration:kFlyInTime timingFunctionName:kCAMediaTimingFunctionDefault];
    [self animateLayer:progressLayer_ fromPath:[self createDisksPathWithRadius:kBounceRadius hasInnerDisk:YES] toPath:[self createDisksPathWithRadius:kRadius hasInnerDisk:YES] duration:kBounceTime timingFunctionName:kCAMediaTimingFunctionDefault];
}


- (void)animateProgressFrom:(float)fromProgress to:(float)toProgress
{
    //RCLog(@"Progressing from %.2f to %.2f", fromProgress, toProgress);
    [self keyFrameAnimateLayer:progressLayer_ fromProgress:fromProgress toProgress:toProgress];
}


- (void)animateFlyOut
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
