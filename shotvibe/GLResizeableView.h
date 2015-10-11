//
//  GLResizeableView.h
//  GLResizeableView
//
//  Created by Stephen Poletto on 7/10/15.
//
//  SPUserResizableView is a user-resizable, user-repositionable
//  UIView subclass.

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

typedef struct GLResizeableViewAnchorPoint {
    CGFloat adjustsX;
    CGFloat adjustsY;
    CGFloat adjustsH;
    CGFloat adjustsW;
} GLResizeableViewAnchorPoint;

@protocol GLResizeableViewDelegate;
@class GLGripViewBorderView;

@interface GLResizeableView : UIView <UIGestureRecognizerDelegate> {
    GLGripViewBorderView *borderView;
//    UIView *contentView;
    CGPoint touchStart;
    CGFloat minWidth;
    CGFloat minHeight;
    
    // Used to determine which components of the bounds we'll be modifying, based upon where the user's touch started.
    GLResizeableViewAnchorPoint anchorPoint;
    
//    id <GLResizeableViewDelegate> delegate;
}

@property (nonatomic, assign) id <GLResizeableViewDelegate> delegate;

// Will be retained as a subview.
@property (nonatomic, assign) UIView *contentView;

// Default is 48.0 for each.
@property (nonatomic) CGFloat minWidth;
@property (nonatomic) CGFloat minHeight;

@property(nonatomic, retain) UIView * parentView;

@property(nonatomic) CGPoint previousLocation;

// Defaults to YES. Disables the user from dragging the view outside the parent view's bounds.
@property (nonatomic) BOOL preventsPositionOutsideSuperview;

- (void)hideEditingHandles;
- (void)showEditingHandles;

@end

@protocol GLResizeableViewDelegate <NSObject>

@optional

// Called when the resizable view receives touchesBegan: and activates the editing handles.
- (void)userResizableViewDidBeginEditing:(GLResizeableView *)userResizableView;

// Called when the resizable view receives touchesEnded: or touchesCancelled:
- (void)userResizableViewDidEndEditing:(GLResizeableView *)userResizableView;

- (void)viewIsResizing:(CGRect)frame;

@end
