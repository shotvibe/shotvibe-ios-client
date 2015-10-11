//
//  SPUserResizableView.m
//  SPUserResizableView
//
//  Created by Stephen Poletto on 12/10/11.
//

#import "GLResizeableView.h"

/* Let's inset everything that's drawn (the handles and the content view)
   so that users can trigger a resize from a few pixels outside of
   what they actually see as the bounding box. */
#define kSPUserResizableViewGlobalInset 5.0

#define kSPUserResizableViewDefaultMinWidth 48.0
#define kSPUserResizableViewDefaultMinHeight 48.0
#define kSPUserResizableViewInteractiveBorderSize 10.0

static GLResizeableViewAnchorPoint SPUserResizableViewNoResizeAnchorPoint = { 0.0, 0.0, 0.0, 0.0 };
static GLResizeableViewAnchorPoint SPUserResizableViewUpperLeftAnchorPoint = { 1.0, 1.0, -1.0, 1.0 };
static GLResizeableViewAnchorPoint SPUserResizableViewMiddleLeftAnchorPoint = { 1.0, 0.0, 0.0, 1.0 };
static GLResizeableViewAnchorPoint SPUserResizableViewLowerLeftAnchorPoint = { 1.0, 0.0, 1.0, 1.0 };
static GLResizeableViewAnchorPoint SPUserResizableViewUpperMiddleAnchorPoint = { 0.0, 1.0, -1.0, 0.0 };
static GLResizeableViewAnchorPoint SPUserResizableViewUpperRightAnchorPoint = { 0.0, 1.0, -1.0, -1.0 };
static GLResizeableViewAnchorPoint SPUserResizableViewMiddleRightAnchorPoint = { 0.0, 0.0, 0.0, -1.0 };
static GLResizeableViewAnchorPoint SPUserResizableViewLowerRightAnchorPoint = { 0.0, 0.0, 1.0, -1.0 };
static GLResizeableViewAnchorPoint SPUserResizableViewLowerMiddleAnchorPoint = { 0.0, 0.0, 1.0, 0.0 };

@interface GLGripViewBorderView : UIView
@end

@implementation GLGripViewBorderView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Clear background to ensure the content view shows through.
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    // (1) Draw the bounding box.
    CGContextSetLineWidth(context, 1.0);
    CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
    CGContextAddRect(context, CGRectInset(self.bounds, kSPUserResizableViewInteractiveBorderSize/2, kSPUserResizableViewInteractiveBorderSize/2));
    CGContextStrokePath(context);
    
    // (2) Calculate the bounding boxes for each of the anchor points.
    CGRect upperLeft = CGRectMake(0.0, 0.0, kSPUserResizableViewInteractiveBorderSize, kSPUserResizableViewInteractiveBorderSize);
    CGRect upperRight = CGRectMake(self.bounds.size.width - kSPUserResizableViewInteractiveBorderSize, 0.0, kSPUserResizableViewInteractiveBorderSize, kSPUserResizableViewInteractiveBorderSize);
    CGRect lowerRight = CGRectMake(self.bounds.size.width - kSPUserResizableViewInteractiveBorderSize, self.bounds.size.height - kSPUserResizableViewInteractiveBorderSize, kSPUserResizableViewInteractiveBorderSize, kSPUserResizableViewInteractiveBorderSize);
    CGRect lowerLeft = CGRectMake(0.0, self.bounds.size.height - kSPUserResizableViewInteractiveBorderSize, kSPUserResizableViewInteractiveBorderSize, kSPUserResizableViewInteractiveBorderSize);
    CGRect upperMiddle = CGRectMake((self.bounds.size.width - kSPUserResizableViewInteractiveBorderSize)/2, 0.0, kSPUserResizableViewInteractiveBorderSize, kSPUserResizableViewInteractiveBorderSize);
    CGRect lowerMiddle = CGRectMake((self.bounds.size.width - kSPUserResizableViewInteractiveBorderSize)/2, self.bounds.size.height - kSPUserResizableViewInteractiveBorderSize, kSPUserResizableViewInteractiveBorderSize, kSPUserResizableViewInteractiveBorderSize);
    CGRect middleLeft = CGRectMake(0.0, (self.bounds.size.height - kSPUserResizableViewInteractiveBorderSize)/2, kSPUserResizableViewInteractiveBorderSize, kSPUserResizableViewInteractiveBorderSize);
    CGRect middleRight = CGRectMake(self.bounds.size.width - kSPUserResizableViewInteractiveBorderSize, (self.bounds.size.height - kSPUserResizableViewInteractiveBorderSize)/2, kSPUserResizableViewInteractiveBorderSize, kSPUserResizableViewInteractiveBorderSize);
    
    // (3) Create the gradient to paint the anchor points.
    CGFloat colors [] = { 
        0.4, 0.8, 1.0, 1.0, 
        0.0, 0.0, 1.0, 1.0
    };
    CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(baseSpace, colors, NULL, 2);
    CGColorSpaceRelease(baseSpace), baseSpace = NULL;
    
    // (4) Set up the stroke for drawing the border of each of the anchor points.
    CGContextSetLineWidth(context, 1);
    CGContextSetShadow(context, CGSizeMake(0.5, 0.5), 1);
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    
    // (5) Fill each anchor point using the gradient, then stroke the border.
    CGRect allPoints[8] = { upperLeft, upperRight, lowerRight, lowerLeft, upperMiddle, lowerMiddle, middleLeft, middleRight };
    for (NSInteger i = 0; i < 8; i++) {
        CGRect currPoint = allPoints[i];
        CGContextSaveGState(context);
        CGContextAddEllipseInRect(context, currPoint);
        CGContextClip(context);
        CGPoint startPoint = CGPointMake(CGRectGetMidX(currPoint), CGRectGetMinY(currPoint));
        CGPoint endPoint = CGPointMake(CGRectGetMidX(currPoint), CGRectGetMaxY(currPoint));
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
        CGContextRestoreGState(context);
        CGContextStrokeEllipseInRect(context, CGRectInset(currPoint, 1, 1));
    }
    CGGradientRelease(gradient), gradient = NULL;
    CGContextRestoreGState(context);
}

@end

@implementation GLResizeableView  {
    UIView * rotateHandle;
    CGFloat lastRotation;
}

@synthesize contentView, minWidth, minHeight, preventsPositionOutsideSuperview, delegate;

- (void)setupDefaultAttributes {
    borderView = [[GLGripViewBorderView alloc] initWithFrame:CGRectInset(self.bounds, kSPUserResizableViewGlobalInset, kSPUserResizableViewGlobalInset)];
    [borderView setHidden:YES];
    [self addSubview:borderView];
    self.minWidth = kSPUserResizableViewDefaultMinWidth;
    self.minHeight = kSPUserResizableViewDefaultMinHeight;
    self.preventsPositionOutsideSuperview = YES;
    
   
    
    
//    UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotate:)];
//    //    [self.rotateHandle addGestureRecognizer:pan];
//    rotateHandle = [[UIView alloc] initWithFrame:CGRectMake(-50, -50, 50, 50)];
//    rotateHandle.userInteractionEnabled = YES;
//    rotateHandle.backgroundColor = [UIColor purpleColor];
//    [rotateHandle addGestureRecognizer:pan];
//    [self addSubview:rotateHandle];

}

//- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
//{
//    for (UIView *subview in self.subviews) {
//        if (CGRectContainsPoint(subview.frame, point)) {
//            return subview;
//        }
//    }
//    
//    // use this to pass the 'touch' onward in case no subviews trigger the touch
//    return [super hitTest:point withEvent:event];
//}

//- (void)handleRotate:(UIPanGestureRecognizer*)gesture {
//    
//    switch (gesture.state) {
//        case UIGestureRecognizerStateBegan:
//            self.previousLocation = rotateHandle.center;
////            [self drawRotateLine:CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2) toPoint:CGPointMake(self.bounds.size.width + 20, self.bounds.size.height/2)];
//            break;
//            
//        case UIGestureRecognizerStateEnded:
////            self.rotateLine.opacity = 0.0;
//            break;
//        default:
//            break;
//    }
//    
//    CGPoint location = [gesture locationInView:self.superview];
//    CGFloat angle = [self angleBetweenPoints:self.previousLocation endPoint:location];
//    self.transform = CGAffineTransformRotate(self.transform, angle);
//    self.previousLocation = location;
////    [self updateDragHandles];
//    
//}

-(double)angleBetweenPoints:(CGPoint)startPoint endPoint:(CGPoint)endPoint {
    double a = startPoint.x - self.center.x;
    double b = startPoint.y - self.center.y;
    double c = endPoint.x - self.center.x;
    double d = endPoint.y - self.center.y;
    
    double atanA = atan2(a,b);
    double atanB = atan2(c, d);
    
    return  atanA - atanB;
    
}

//- (void)handleRotate:(UIRotationGestureRecognizer*)gesture {
//    
//    
////    if(gesture.numberOfTouches == 2){
//    if(![self isResizing] && gesture.numberOfTouches == 2){
//        if([gesture state] == UIGestureRecognizerStateEnded) {
//            lastRotation = 0.0;
//            return;
//        }
//        
//        CGFloat rotation = 0.0 - (lastRotation - [gesture rotation]);
//        
//        CGAffineTransform currentTransform = self.transform;
//        CGAffineTransform newTransform = CGAffineTransformRotate(currentTransform,rotation);
//        
//        [self setTransform:newTransform];
//        lastRotation = [gesture rotation];
//    }
//    
//
////    }
//    
//    
//    
//    
////    if([(UIRotationGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
////        lastRotation = 0.0;
////        return;
////    }
////    
////    CGFloat rotation = 0.0 - (lastRotation - [(UIRotationGestureRecognizer*)sender rotation]);
////    
////    CGAffineTransform currentTransform = self.imageview.transform;
////    CGAffineTransform newTransform = CGAffineTransformRotate(currentTransform,rotation);
////    
////    [self.imageview setTransform:newTransform];
////    lastRotation = [(UIRotationGestureRecognizer*)sender rotation];
//    
////    switch (gesture.state) {
////        case UIGestureRecognizerStateBegan:
////            self.previousLocation = self.rotateHandle.center;
////            [self drawRotateLine:CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2) toPoint:CGPointMake(self.bounds.size.width + 20, self.bounds.size.height/2)];
////            break;
////            
////        case UIGestureRecognizerStateEnded:
////            self.rotateLine.opacity = 0.0;
////            break;
////        default:
////            break;
////    }
////    
////    CGPoint location = [gesture locationInView:self.superview];
////    CGFloat angle = [self angleBetweenPoints:self.previousLocation endPoint:location];
////    self.transform = CGAffineTransformRotate(self.transform, angle);
////    self.previousLocation = location;
////    [self updateDragHandles];
//    
//}

//-(void)resizeableDragged:(UIPanGestureRecognizer*)panGest {
//
//    if([self isResizing]){
//    
//        [self.delegate viewIsResizing:panGest];
//        
//    }
//    
//}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self setupDefaultAttributes];
         self.clipsToBounds = NO;
        
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self setupDefaultAttributes];
    }
    return self;
}

- (void)setContentView:(UIView *)newContentView {
    [contentView removeFromSuperview];
    contentView = newContentView;
    contentView.frame = CGRectInset(self.bounds, kSPUserResizableViewGlobalInset + kSPUserResizableViewInteractiveBorderSize/2, kSPUserResizableViewGlobalInset + kSPUserResizableViewInteractiveBorderSize/2);
    [self addSubview:contentView];
    
    // Ensure the border view is always on top by removing it and adding it to the end of the subview list.
    [borderView removeFromSuperview];
    [self addSubview:borderView];
}

- (void)setFrame:(CGRect)newFrame {
    [super setFrame:newFrame];
    contentView.frame = CGRectInset(self.bounds, kSPUserResizableViewGlobalInset + kSPUserResizableViewInteractiveBorderSize/2, kSPUserResizableViewGlobalInset + kSPUserResizableViewInteractiveBorderSize/2);
    borderView.frame = CGRectInset(self.bounds, kSPUserResizableViewGlobalInset, kSPUserResizableViewGlobalInset);
    [borderView setNeedsDisplay];
}

static CGFloat SPDistanceBetweenTwoPoints(CGPoint point1, CGPoint point2) {
    CGFloat dx = point2.x - point1.x;
    CGFloat dy = point2.y - point1.y;
    return sqrt(dx*dx + dy*dy);
};

typedef struct CGPointGLResizeableViewAnchorPointPair {
    CGPoint point;
    GLResizeableViewAnchorPoint anchorPoint;
} CGPointGLResizeableViewAnchorPointPair;

- (GLResizeableViewAnchorPoint)anchorPointForTouchLocation:(CGPoint)touchPoint {
    // (1) Calculate the positions of each of the anchor points.
    CGPointGLResizeableViewAnchorPointPair upperLeft = { CGPointMake(0.0, 0.0), SPUserResizableViewUpperLeftAnchorPoint };
    CGPointGLResizeableViewAnchorPointPair upperMiddle = { CGPointMake(self.bounds.size.width/2, 0.0), SPUserResizableViewUpperMiddleAnchorPoint };
    CGPointGLResizeableViewAnchorPointPair upperRight = { CGPointMake(self.bounds.size.width, 0.0), SPUserResizableViewUpperRightAnchorPoint };
    CGPointGLResizeableViewAnchorPointPair middleRight = { CGPointMake(self.bounds.size.width, self.bounds.size.height/2), SPUserResizableViewMiddleRightAnchorPoint };
    CGPointGLResizeableViewAnchorPointPair lowerRight = { CGPointMake(self.bounds.size.width, self.bounds.size.height), SPUserResizableViewLowerRightAnchorPoint };
    CGPointGLResizeableViewAnchorPointPair lowerMiddle = { CGPointMake(self.bounds.size.width/2, self.bounds.size.height), SPUserResizableViewLowerMiddleAnchorPoint };
    CGPointGLResizeableViewAnchorPointPair lowerLeft = { CGPointMake(0, self.bounds.size.height), SPUserResizableViewLowerLeftAnchorPoint };
    CGPointGLResizeableViewAnchorPointPair middleLeft = { CGPointMake(0, self.bounds.size.height/2), SPUserResizableViewMiddleLeftAnchorPoint };
    CGPointGLResizeableViewAnchorPointPair centerPoint = { CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2), SPUserResizableViewNoResizeAnchorPoint };
    
    // (2) Iterate over each of the anchor points and find the one closest to the user's touch.
    CGPointGLResizeableViewAnchorPointPair allPoints[9] = { upperLeft, upperRight, lowerRight, lowerLeft, upperMiddle, lowerMiddle, middleLeft, middleRight, centerPoint };
    CGFloat smallestDistance = MAXFLOAT; CGPointGLResizeableViewAnchorPointPair closestPoint = centerPoint;
    for (NSInteger i = 0; i < 9; i++) {
        CGFloat distance = SPDistanceBetweenTwoPoints(touchPoint, allPoints[i].point);
        if (distance < smallestDistance) { 
            closestPoint = allPoints[i];
            smallestDistance = distance;
        }
    }
    return closestPoint.anchorPoint;
}

- (BOOL)isResizing {
    return (anchorPoint.adjustsH || anchorPoint.adjustsW || anchorPoint.adjustsX || anchorPoint.adjustsY);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    // Notify the delegate we've begun our editing session.
//    [borderView setHidden:NO];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(userResizableViewDidBeginEditing:)]) {
        [self.delegate userResizableViewDidBeginEditing:self];
    }
    
    
    UITouch *touch = [touches anyObject];
    anchorPoint = [self anchorPointForTouchLocation:[touch locationInView:self]];
    
    // When resizing, all calculations are done in the superview's coordinate space.
    touchStart = [touch locationInView:self.superview];
    if (![self isResizing]) {
        // When translating, all calculations are done in the view's coordinate space.
        touchStart = [touch locationInView:self];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    // Notify the delegate we've ended our editing session.
    if (self.delegate && [self.delegate respondsToSelector:@selector(userResizableViewDidEndEditing:)]) {
        [self.delegate userResizableViewDidEndEditing:self];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    // Notify the delegate we've ended our editing session.
    if (self.delegate && [self.delegate respondsToSelector:@selector(userResizableViewDidEndEditing:)]) {
        [self.delegate userResizableViewDidEndEditing:self];
    }
}

- (void)showEditingHandles {
    [borderView setHidden:NO];
}

- (void)hideEditingHandles {
    [borderView setHidden:YES];
}

- (void)resizeUsingTouchLocation:(CGPoint)touchPoint {
    // (1) Update the touch point if we're outside the superview.
    if (self.preventsPositionOutsideSuperview) {
        CGFloat border = kSPUserResizableViewGlobalInset + kSPUserResizableViewInteractiveBorderSize/2;
        if (touchPoint.x < border) {
            touchPoint.x = border;
        }
        if (touchPoint.x > self.superview.bounds.size.width - border) {
            touchPoint.x = self.superview.bounds.size.width - border;
        }
        if (touchPoint.y < border) {
            touchPoint.y = border;
        }
        if (touchPoint.y > self.superview.bounds.size.height - border) {
            touchPoint.y = self.superview.bounds.size.height - border;
        }
    }
    
    // (2) Calculate the deltas using the current anchor point.
    CGFloat deltaW = anchorPoint.adjustsW * (touchStart.x - touchPoint.x);
    CGFloat deltaX = anchorPoint.adjustsX * (-1.0 * deltaW);
    CGFloat deltaH = anchorPoint.adjustsH * (touchPoint.y - touchStart.y);
    CGFloat deltaY = anchorPoint.adjustsY * (-1.0 * deltaH);
    
    // (3) Calculate the new frame.
    CGFloat newX = self.frame.origin.x + deltaX;
    CGFloat newY = self.frame.origin.y + deltaY;
    CGFloat newWidth = self.frame.size.width + deltaW;
    CGFloat newHeight = self.frame.size.height + deltaH;
    
    // (4) If the new frame is too small, cancel the changes.
    if (newWidth < self.minWidth) {
        newWidth = self.frame.size.width;
        newX = self.frame.origin.x;
    }
    if (newHeight < self.minHeight) {
        newHeight = self.frame.size.height;
        newY = self.frame.origin.y;
    }
    
    // (5) Ensure the resize won't cause the view to move offscreen.
    if (self.preventsPositionOutsideSuperview) {
        if (newX < self.superview.bounds.origin.x) {
            // Calculate how much to grow the width by such that the new X coordintae will align with the superview.
            deltaW = self.frame.origin.x - self.superview.bounds.origin.x;
            newWidth = self.frame.size.width + deltaW;
            newX = self.superview.bounds.origin.x;
        }
        if (newX + newWidth > self.superview.bounds.origin.x + self.superview.bounds.size.width) {
            newWidth = self.superview.bounds.size.width - newX;
        }
        if (newY < self.superview.bounds.origin.y) {
            // Calculate how much to grow the height by such that the new Y coordintae will align with the superview.
            deltaH = self.frame.origin.y - self.superview.bounds.origin.y;
            newHeight = self.frame.size.height + deltaH;
            newY = self.superview.bounds.origin.y;
        }
        if (newY + newHeight > self.superview.bounds.origin.y + self.superview.bounds.size.height) {
            newHeight = self.superview.bounds.size.height - newY;
        }
    }
    
//    CGPoint location = [[touches anyObject] locationInView:self.superview];
    
//    NSLog(@"is resizing");
    
    self.frame = CGRectMake(newX, newY, newWidth, newHeight);
    [self.delegate viewIsResizing:self.bounds];
    touchStart = touchPoint;
}

- (void)translateUsingTouchLocation:(CGPoint)touchPoint {
    CGPoint newCenter = CGPointMake(self.center.x + touchPoint.x - touchStart.x, self.center.y + touchPoint.y - touchStart.y);
    if (self.preventsPositionOutsideSuperview) {
        // Ensure the translation won't cause the view to move offscreen.
        CGFloat midPointX = CGRectGetMidX(self.bounds);
        if (newCenter.x > self.superview.bounds.size.width - midPointX) {
            newCenter.x = self.superview.bounds.size.width - midPointX;
        }
        if (newCenter.x < midPointX) {
            newCenter.x = midPointX;
        }
        CGFloat midPointY = CGRectGetMidY(self.bounds);
        if (newCenter.y > self.superview.bounds.size.height - midPointY) {
            newCenter.y = self.superview.bounds.size.height - midPointY;
        }
        if (newCenter.y < midPointY) {
            newCenter.y = midPointY;
        }
    }
    self.center = newCenter;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([self isResizing]) {
        [self resizeUsingTouchLocation:[[touches anyObject] locationInView:self.superview]];
    } else {
        [self translateUsingTouchLocation:[[touches anyObject] locationInView:self]];
    }
}

//- (void)dealloc {
//    [contentView removeFromSuperview];
//    [borderView release];
//    [super dealloc];
//}

@end
