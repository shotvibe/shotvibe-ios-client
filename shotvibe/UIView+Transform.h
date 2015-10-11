//
//  UIView+Transform.h
//  GlanceCamera
//
//  Created by Tsah Kashkash on 07/10/2015.
//  Copyright © 2015 Tsah Kashkash. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Transform)

- (CGPoint)offsetPointToParentCoordinates:(CGPoint)point;
- (CGPoint)pointInViewCenterTerms:(CGPoint)point;
- (CGPoint)pointInTransformedView:(CGPoint)point;
- (CGRect)originalFrame;
- (CGPoint)transformedTopLeft;
- (CGPoint)transformedTopRight;
- (CGPoint)transformedBottomRight;
- (CGPoint)transformedBottomLeft;
- (CGPoint)transformedRotateHandle;
- (void)setAnchorPoint:(CGPoint)anchorPoint;

@end
