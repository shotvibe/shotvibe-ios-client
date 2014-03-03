//
//  Notification.m
//
//
//  Created by Oblosys on 30-11-10.
//  Copyright (c) 2010 Oblomov Systems. All rights reserved.
//

#import "Notification.h"

const float kDefaultWidth = 160.0; // standard width of notification view (not used for ShotVibe)
const float kDefaultShowTime = 1.0; // (not used for ShotVibe)

#define CENTERX 160
#define RADIUS 10
#define LINE 1
#define ALPHA 0.8
#define FADEINTIME 0.2
#define FADEOUTTIME 2
#define hidingAnimationID @"HidingNotificationAnimation"


@implementation UIView (Util)

- (void)setFrameOrigin:(CGPoint)newOrigin
{
    CGRect newFrame = self.frame;
    newFrame.origin = newOrigin;
    self.frame = newFrame;
}


- (void)setFrameSize:(CGSize)newSize
{
    CGRect newFrame = self.frame;
    newFrame.size = newSize;
    self.frame = newFrame;
}


@end


@implementation Notification

@synthesize yPercentage = _yPercentage, width = _width, titleLabel = _titleLabel, textView = _textView, parentViewController = _parentViewController, timer = _timer, cancelRemove = _cancelRemove;


+ (id)sharedNotification
{
    static dispatch_once_t onceQueue;
    static Notification *notification = nil;

    dispatch_once(&onceQueue, ^{ notification = [[self alloc] init]; });
    return notification;
}


+ (void)notifyError:(NSString *)title withMessage:(NSString *)message
{
    [Notification notify:title withMessage:message isError:YES onViewController:[Notification topViewController] atYPercentage:0.05 withShowtime:5.0 withWidth:220.0];
}


// For logging
+ (void)notify:(NSString *)title
{
    [Notification notify:title withMessage:@""];
}


+ (void)notify:(NSString *)title withMessage:(NSString *)message
{
    [Notification notify:title withMessage:message isError:NO onViewController:[Notification topViewController] atYPercentage:0.05 withShowtime:5.0 withWidth:220.0];
}


+ (void)notify:(NSString *)notificationStr withMessage:(NSString *)message isError:(BOOL)isError onViewController:(UIViewController *)viewController atYPercentage:(float)y withShowtime:(float)aShowtime withWidth:(float)width
{
    dispatch_async(dispatch_get_main_queue(), ^{
        Notification *notification = [Notification sharedNotification];
        notification.yPercentage = y;
        notification.width = width;
        notification.titleLabel.text = notificationStr;
        notification.textView.text = message;
        notification.parentViewController = viewController; // for determining correct interfaceOrientation


        RCLog(@"%@: %@\n%@", isError ? @"ERROR" : @"Notify", notificationStr, message);

        [notification.textView setFrameSize:CGSizeMake(width, 1000.0)]; // set the width (and dummy height), so it is taken into account by the height computation

        // TODO: first time the height is computed wrong. iOS >= 6 issue.
        float textHeight = notification.textView.contentSize.height > 0 ? notification.textView.contentSize.height : 100;
        [notification.textView setFrameSize:CGSizeMake(width, textHeight)];
        //RCLog(@"Computed height %f", notification.textView.contentSize.height);
        [notification.titleLabel setFrameSize:CGSizeMake(width, notification.titleLabel.frame.size.height)];

        [Notification rotateNotification]; // this sets the frame of the notification itself

        [viewController.view addSubview:notification];
        [notification setNeedsDisplay];

        notification.cancelRemove = YES;
        [notification.timer invalidate];
        notification.timer = [NSTimer timerWithTimeInterval:aShowtime target:notification selector:@selector(hideNotification) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:notification.timer forMode:NSDefaultRunLoopMode];

        notification.alpha = 0.0;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:FADEINTIME];
        notification.alpha = ALPHA;
        [UIView commitAnimations];
    });
}


+ (void)notify:(NSString *)notificationStr withMessage:(NSString *)message onViewController:(UIViewController *)viewController atYPercentage:(float)y withShowtime:(float)aShowtime
{
    Notification *notification = [Notification sharedNotification];

    float width;
    if (message != nil) {
        width = kDefaultWidth;
    } else {
        width = [notificationStr sizeWithFont:[UIFont fontWithName:notification.titleLabel.font.fontName size:notification.titleLabel.font.pointSize]].width + 20;
    }
    [self.class notify:notificationStr withMessage:message isError:NO onViewController:viewController atYPercentage:y withShowtime:aShowtime withWidth:width];
}


// extra constructor, in case we want to specify the time but not the width
+ (void)notify:(NSString *)notificationStr withMessage:(NSString *)message onViewController:(UIViewController *)viewController atYPercentage:(float)y withWidth:(float)aWidth
{
    [self.class notify:notificationStr withMessage:message isError:NO onViewController:viewController atYPercentage:y withShowtime:kDefaultShowTime withWidth:aWidth];
}


+ (void)notify:(NSString *)notificationStr withMessage:(NSString *)message isError:(BOOL)isError onViewController:(UIViewController *)viewController atYPercentage:(float)y
{
    [self.class notify:notificationStr withMessage:message onViewController:viewController atYPercentage:y withShowtime:kDefaultShowTime];
}


+ (void)rotateNotification
{
    Notification *notification = [Notification sharedNotification];
    float textViewHeight = notification.textView.frame.size.height;
    CGRect frame = notification.frame;
    frame.size.width = notification.width;
    frame.size.height = 20 + (notification.textView.text == nil || [notification.textView.text isEqualToString:@""] ? 12 : textViewHeight);
    // if message is empty, the margins disappear so we need to add some height

    // Need to get the interfacerientation from controller, since [UIDevice currentDevice].orientation gives the wrong value when
    // the phone is lying flat. Probably because it doesn't take into account whether the view has rotated yet.
    if (UIInterfaceOrientationIsPortrait(notification.parentViewController.interfaceOrientation)) {
        frame.origin.x = round(Util.screenWidth / 2.0 - notification.width / 2.0);
        frame.origin.y = round(notification.yPercentage * Util.screenHeight);
    } else {
        frame.origin.x = round(Util.screenHeight / 2.0 - notification.width / 2.0);
        frame.origin.y = round(notification.yPercentage * Util.screenWidth);
    }
    notification.frame = frame;
}


+ (NSTimeInterval)remainingShowTime
{
    Notification *notification = [Notification sharedNotification];

    return [notification.timer isValid] ? [notification.timer.fireDate timeIntervalSinceNow] : -1;
}


- (id)init
{
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, 0, kDefaultWidth, 0); // x, y, and height are set by notify: ..
        self.backgroundColor = UIColor.clearColor;
        self.userInteractionEnabled = NO;

        self.titleLabel = [UILabel new];
        self.titleLabel.frame = CGRectMake(0, 5, kDefaultWidth, 20);

        self.titleLabel.backgroundColor = UIColor.clearColor;
        self.titleLabel.textColor = UIColor.whiteColor;
        self.titleLabel.textAlignment = NSTextAlignmentCenter;

        [self addSubview:self.titleLabel];

        self.textView = [UITextView new];
        self.textView.frame = CGRectMake(0, 20, kDefaultWidth, 0); // height is determined by notify: ..
        self.textView.backgroundColor = UIColor.clearColor;
        self.textView.textColor = UIColor.whiteColor;
        self.textView.textAlignment = NSTextAlignmentCenter;

        self.textView.editable = NO;
        [self addSubview:self.textView];
    }
    return self;
}


- (void)hideNotification
{
    self.cancelRemove = NO;
    self.alpha = ALPHA;
    [UIView beginAnimations:hidingAnimationID context:nil];
    [UIView setAnimationDuration:FADEOUTTIME];
    self.alpha = 0;

    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:
     @selector(removeNotification:finished:context:)];

    [UIView commitAnimations];
}


- (void)removeNotification:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    Notification *notification = [Notification sharedNotification];

    if ([animationID isEqualToString:hidingAnimationID]) {
        if (!self.cancelRemove) {
            [notification removeFromSuperview];
            notification.parentViewController = nil;
        } else {
            self.cancelRemove = NO;
        }
    }
}


- (void)drawRect:(CGRect)rect
{
    float width = self.frame.size.width - LINE;
    float height = self.frame.size.height - LINE;

//    RCLog(@"drawing with size: %@", showSize(self.frame.size));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, LINE);

    CGRect rectBounds = CGRectMake(LINE / 2.0, LINE / 2.0, width, height);
    CGContextAddRoundedRect(context, rectBounds, RADIUS);
    CGContextSetStrokeColorWithColor(context, [UIColor grayColor].CGColor);
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextDrawPath(context, kCGPathFillStroke);
}


static void CGContextAddRoundedRect(CGContextRef c, CGRect rect, float corner_radius)
{
    float x_left = rect.origin.x;
    float x_left_center = rect.origin.x + corner_radius;
    float x_right_center = rect.origin.x + rect.size.width - corner_radius;
    float x_right = rect.origin.x + rect.size.width;
    float y_top = rect.origin.y;
    float y_top_center = rect.origin.y + corner_radius;
    float y_bottom_center = rect.origin.y + rect.size.height - corner_radius;
    float y_bottom = rect.origin.y + rect.size.height;


    CGContextBeginPath(c);
    CGContextMoveToPoint(c, x_left, y_top_center);

    // First corner
    CGContextAddArcToPoint(c, x_left, y_top, x_left_center, y_top, corner_radius);
    CGContextAddLineToPoint(c, x_right_center, y_top);

    // Second corner
    CGContextAddArcToPoint(c, x_right, y_top, x_right, y_top_center, corner_radius);
    CGContextAddLineToPoint(c, x_right, y_bottom_center);

    // Third corner
    CGContextAddArcToPoint(c, x_right, y_bottom, x_right_center, y_bottom, corner_radius);
    CGContextAddLineToPoint(c, x_left_center, y_bottom);

    // Fourth corner
    CGContextAddArcToPoint(c, x_left, y_bottom, x_left, y_bottom_center, corner_radius);
    CGContextAddLineToPoint(c, x_left, y_top_center);

    CGContextClosePath(c);
}


// Grabbed from: https://gist.github.com/snikch/3661188
+ (UIViewController *)topViewController
{
    return [Notification topViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}


+ (UIViewController *)topViewController:(UIViewController *)rootViewController
{
    if (rootViewController.presentedViewController == nil) {
        return rootViewController;
    }
    if ([rootViewController.presentedViewController isMemberOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return [Notification topViewController:lastViewController];
    }
    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [Notification topViewController:presentedViewController];
}


@end
