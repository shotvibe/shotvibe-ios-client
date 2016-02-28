//
//  UIView+Transform.m
//  GlanceCamera
//
//  Created by Tsah Kashkash on 07/10/2015.
//  Copyright © 2015 Tsah Kashkash. All rights reserved.
//

#import "UIView+Transform.h"

@implementation UIView (Transform)

- (CGPoint)offsetPointToParentCoordinates:(CGPoint)point {
    return CGPointMake(point.x + self.center.x, point.y + self.center.y);
}

- (CGPoint)pointInViewCenterTerms:(CGPoint)point {
    return CGPointMake(point.x - self.center.x, point.y - self.center.y);
}

- (CGPoint)pointInTransformedView:(CGPoint)point {
    
    CGPoint offsetItem = [self pointInViewCenterTerms:point];
    CGPoint updatedItem = CGPointApplyAffineTransform(offsetItem, self.transform);
    CGPoint finalItem = [self offsetPointToParentCoordinates:updatedItem];
    return finalItem;
    
}

- (CGRect)originalFrame {
    CGAffineTransform currentTransform = self.transform;
    self.transform = CGAffineTransformIdentity;
    CGRect originalFrame = self.frame;
    self.transform = currentTransform;
    return originalFrame;
}

- (CGPoint)transformedTopLeft {
    CGRect frame = [self originalFrame];
    CGPoint point = frame.origin;
    return [self pointInTransformedView:point];
}

- (CGPoint)transformedTopRight {
    CGRect frame = [self originalFrame];
    CGPoint point = frame.origin;
    point.x += frame.size.width;
    return [self pointInTransformedView:point];
}

- (CGPoint)transformedBottomRight {
    CGRect frame = [self originalFrame];
    CGPoint point = frame.origin;
    point.x += frame.size.width;
    point.y += frame.size.height;
    return [self pointInTransformedView:point];
}

- (CGPoint)transformedBottomLeft {
    CGRect frame = [self originalFrame];
    CGPoint point = frame.origin;
    point.y += frame.size.height;
    return [self pointInTransformedView:point];
}

- (CGPoint)transformedRotateHandle {
    CGRect frame = [self originalFrame];
    CGPoint point = frame.origin;
    point.x += frame.size.width + 40;
    point.y += frame.size.height / 2;
    return [self pointInTransformedView:point];
}

- (void)setAnchorPoint:(CGPoint)anchorPoint {

    CGPoint newPoint = CGPointMake(self.bounds.size.width * anchorPoint.x, self.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(self.bounds.size.width * self.layer.anchorPoint.x, self.bounds.size.height * self.layer.anchorPoint.y);
    
    newPoint = CGPointApplyAffineTransform(newPoint, self.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, self.transform);
    
    CGPoint position = self.layer.position;
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    position.y -= oldPoint.y;
    position.y += newPoint.y;
    
    self.layer.position = position;
    self.layer.anchorPoint = anchorPoint;
    
}

@end
