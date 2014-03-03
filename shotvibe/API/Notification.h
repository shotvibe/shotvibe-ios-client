//
//  Notification.h
//
//
//  Created by Oblosys on 30-11-10.
//  Copyright (c) 2010 Oblomov Systems. All rights reserved.
//

@interface Notification : UIView {
    float _yPercentage;
    float _width;
    UILabel *_titleLabel;
    UITextView *_textView;
    UIViewController *_parentViewController; // retains parent to prevent problems on rotate, but it's only temporary
    NSTimer *_timer;
    BOOL _cancelRemove; // to cancel removing when a new notification is started during fade out, since the animation cannot be stopped easily
}

@property (nonatomic, assign) float yPercentage;
@property (nonatomic, assign) float width;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) IBOutlet UIViewController *parentViewController;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, assign, getter = isCancelRemove) BOOL cancelRemove;

+ (void)notifyError:(NSString *)title withMessage:(NSString *)message;
+ (void)notify:(NSString *)title;
+ (void)notify:(NSString *)title withMessage:(NSString *)message;
@end
