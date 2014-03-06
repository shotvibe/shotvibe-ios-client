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
    static dispatch_once_t onceToken;
    static NSMapTable *progressCache = nil;

    dispatch_once(&onceToken, ^{
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


@interface  FancyProgressView ()

@property (nonatomic, getter = isDisabled) BOOL disabled;

@end

/*
 Why this is so complicated:
 - When grid view reloads during an animation, it is cut off -> Need to keep track of animation durations and provide delay
   Not even guaranteed to work, but good enough
 - View controller creates new cells all the time with new progress views. Cannot keep track of animation state (which are nec.?) -> Need to cache progress. Also need to guarantee that progress objects are kept the same (single AlbumUploadingPhoto for the lifetime of the upload) Can't use PhotoId's because they don't exist in the beginning
 */
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
static float const kProgressThreshold = 0.01; // Minimum required progress before animation is triggered
static float const kFlyOutTime = 0.3; // Time for the outer disk to disappear to the edges
static float const kFadeOutTime = 3 * kFlyOutTime; // Time for the white background to fade out


// contains all active progress views, for stopping animations
+ (id)sharedAllProgressViews
{
    static dispatch_once_t onceToken;
    static NSHashTable *allProgressViews = nil;

    dispatch_once(&onceToken, ^{
        allProgressViews = [NSHashTable weakObjectsHashTable];
    });
    return allProgressViews;
}

// Disables all progress views until animations have finished, after which completionBlock is executed on the main thread.
+ (void)disableProgressViewsWithCompletion:(void (^)())completionBlock
{
    RCLog(@"Disabling all progress views");
    CFTimeInterval animationsEndMediaTime = 0.0;

    @synchronized(self) {
        for (FancyProgressView *fpv in [FancyProgressView sharedAllProgressViews]) {
            fpv.disabled = YES;

            animationsEndMediaTime = MAX(animationsEndMediaTime, [fpv currentAnimationsEndTime]);
        }
    }

    CFTimeInterval animationsEndTime = MAX(0, animationsEndMediaTime - CACurrentMediaTime());
    RCLog(@"Disabled all progress views, animations end in %.2fs", animationsEndTime);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, animationsEndTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        completionBlock();
    });
}


#pragma mark - Progress cache


- (CachedProgressModel *)getCachedProgressModel
{
    @synchronized(self) {
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
// are not albumUploadingPhotos anymore. Is this really a problem? Maybe we can keep track of the photoId for a while
// NOTE: probably won't happen often, animations are short and adding to album takes some time.

// TODO: Check if appearance on init always works, or we need to call a specific appear method from the controller. (test in Button 12 doesn't seem to allow animation (even though we don't need one there)

// TODO: we may miss a few progress update while out of view. Ok? (causes animations when scrolled back into view) Maybe we don't want to animate progress between view instances, only appear and flyout
// this means we need to pass the current upload status on appear

// TODO: check weak property and cover case that it is null/nil (shouldn't occur)
// TODO: explain that we assume one active view controller. otherwise need to group progress views on controller
// TODO: check if weak hash table works as expected (objects are removed after releasing them)
// TODO: check if removed unterminated transaction in keyframe animation is okay
// TODO: figure out speed: too fast looks bad for small steps. Too slow looks bad for large steps. Maybe let speed depend on step size, but not constant time

// TODO: comment logs

// TODO BEFORE MERGING WITH PARALLEL UPLOAD: on completion in uploader, set to 100% (check if still necessary)
//  Remove addingToAlbums notification. Causes an impossibled double reload where the animation is started just after the second reload is initiated, so there won't be a delay and the appear animation will be interrupted and not restored.
//  NOTE: Maybe not possible, sometimes uploading photos don't show up then...


// get old progress from ProgressCache use it to compute animation. No need for oldProgress anymore?
// probably could use this to do flyin flyout on init (flyout is whan view was disabled just before animation)

// Issues:
// what is fp.progress  Return cached progress, or do we need to keep a property as well?


/*

 TODO
 Look at cell init again. Apparently I changed it to awakeFromNib in commit 360f6e5e56dc88376b0709761a2f48fa25c46094

 Idea progressCache: PhotoID -> shownProgress   to survive new views for same photo and missed events
 Use instead of oldProgress
 purgeCache  (Set PhotoID)    remove all photos except ones in set

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
        RCLog(@"Init progress view");
        progressLayer_ = [CAShapeLayer layer];
        progressLayer_.fillRule = kCAFillRuleEvenOdd;
        progressLayer_.fillColor = [UIColor blackColor].CGColor;
        progressLayer_.backgroundColor = [UIColor whiteColor].CGColor;
        progressLayer_.frame = self.bounds;
        [self.layer addSublayer:progressLayer_];

        [self reset];

        // Use a mask to hide the growing circle on the disappear animation
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        CGRect maskRect = makeCenteredRect(self.bounds, self.bounds.size.width, self.bounds.size.height);
        CGPathRef path = CGPathCreateWithRect(maskRect, NULL);
        maskLayer.path = path;
        CGPathRelease(path);
        self.layer.mask = maskLayer;

        @synchronized(self) {
            [[FancyProgressView sharedAllProgressViews] addObject:self];
        }
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
    RCLog(@"Reset progress view");
    [self.layer removeAllAnimations];
    self.layer.opacity = 1.0;
    [progressLayer_ removeAllAnimations];
    progressLayer_.opacity = 0.0;
    progressLayer_.path = [self createBackgroundRectangle].CGPath;

    uniqueAnimationKeyCounter_ = 0;
    progressObject_ = nil;
    _disabled = NO;
    _progress = 0.0;
}


// TODO: call this one setup or something, maybe combine with reset
- (void)appearWithProgress:(float)progress object:(id)progressObject
{
    progressObject_ = progressObject;
    RCLog(@"Appear with progress %f progressObject:\n%@ didAppear %@ opacity %f", progress, progressObject_, showBool([self didAppear]), progressLayer_.opacity);
    if (progress > 0.999999) { // What can we break here?
        RCLog(@"Setting opacity to transparent");
        progressLayer_.opacity = 0.0;
        return;
    }
    if (![self didAppear]) {
        //progressLayer_.opacity = 0.0;
        RCLog(@"AnimateAppear");
        [self animateAppear];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kAppearanceTime / 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self setDidAppear:YES];
            // Rather hacky way to deal with multiple successive reload events at the start.
            // May lead to partially double appear animations in rare cases.
        });
        //return;
    } else {
        RCLog(@"Setting opacity to non-transparent");
        progressLayer_.opacity = kOpacity;
    }

    if ([self getCachedProgress] < 0.999999 && [self didFlyIn]) {
        progressLayer_.opacity = kOpacity;
        progressLayer_.path = [self createProgressPathWithProgress:[self getCachedProgress]];
    }
    // Photos keep getting setProgress:100% until the last one finishes, so no need to flyOut here.
}


- (void)setProgress:(float)progress
{
    //RCLog(@"SetProgress%@ from %.2f to %.2f for progressObject %@", [self isDisabled] ? @" (disabled)" : @"", [self getCachedProgress], progress, progressObject_);
    if (![self isDisabled]) {
        if (progress - [self getCachedProgress] > 0.000001) {
            progress = MAX(0.0, MIN(progress, 1.0)); // keep progress between 0.0 and 1.0
            //RCLog(@"didAppear %@ didFlyIn %@ didFlyOut %@", showBool([self didAppear]), showBool([self didFlyIn]), showBool([self didFlyOut]));

            if (![self didFlyIn]) {
                [self animateFlyIn];
                [self setDidFlyIn:YES];
            }

            if (![self didFlyOut]) {
                //progressLayer_.backgroundColor = [UIColor colorWithHue:progress saturation:1.0 brightness:1.0 alpha:1.0].CGColor; // for testing if the view we see is the one we're updating

                // animate and store progress in cache only if above threshold, otherwise we may get lots of queued animations that cause delays
                if (progress - [self getCachedProgress] > kProgressThreshold) {
                    [self animateProgressFrom:[self getCachedProgress] to:progress];
                    [self setCachedProgress:progress];
                }
                if (progress > 0.999999) {
                    [self animateFlyOut];
                    [self setDidFlyOut:YES];
                }
            }
        }
        //RCLog(@"End setProgress");
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
    RCLog(@"Flying out");
    float surroundingRadius = sqrt(square(self.bounds.size.width) + square(self.bounds.size.height)) / 2 + 1;
    [self animateLayer:progressLayer_ fromPath:[self createDisksPathWithRadius:kRadius hasInnerDisk:NO] toPath:[self createDisksPathWithRadius:surroundingRadius hasInnerDisk:NO] duration:kFlyOutTime timingFunctionName:kCAMediaTimingFunctionEaseIn];

    // fade out the entire view, otherwise the white background remains visible
    CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.duration = kFadeOutTime;
    opacityAnimation.beginTime = [self currentAnimationsEndTime];
    opacityAnimation.fromValue = @1.0; // 1.0 instead of kOpacity, since we do it on self.layer (see below)
    opacityAnimation.toValue = @0.0;
    opacityAnimation.fillMode = kCAFillModeBoth;
    opacityAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];

    // Do this on self.layer instead of progressLayer, because otherwise it interferes with appearAnimation
    [self.layer addAnimation:opacityAnimation forKey:[self createUniqueAnimationKey]];
    self.layer.opacity = 0.0;
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
    return MAX(getCurrentAnimationsEndTimeForLayer(self.layer), getCurrentAnimationsEndTimeForLayer(progressLayer_));
}


static CFTimeInterval getCurrentAnimationsEndTimeForLayer(CALayer *layer)
{
    CFTimeInterval endTime = 0.0;
    NSArray *allAnimationKeys = layer.animationKeys;

    for (NSString *key in allAnimationKeys) {
        CAAnimation *anim = [layer animationForKey:key];
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
