//
//  UIImage+Crop.m
//  shotvibe
//
//  Created by Baluta Cristian on 16/11/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "UIImage+Crop.h"

@implementation UIImage (Crop)

- (UIImage*)imageByCroppingForSize:(CGSize)targetSize {
	
	
	int x_ = (self.size.width - targetSize.width) / 2;
	int y_ = (self.size.height - targetSize.height) / 2;
	
	CGAffineTransform rectTransform;
	
	switch (self.imageOrientation) {
		case UIImageOrientationLeft:
			rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(90)), 0, -self.size.height);
			break;
		case UIImageOrientationRight:
			rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-90)), -self.size.width, 0);
			break;
		case UIImageOrientationDown:
			rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-180)), -self.size.width, -self.size.height);
			break;
		default:
			rectTransform = CGAffineTransformIdentity;
	};
	rectTransform = CGAffineTransformScale(rectTransform, self.scale, self.scale);
	
	CGRect rect = CGRectMake (x_, y_, targetSize.width, targetSize.height);
	CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, CGRectApplyAffineTransform(rect, rectTransform));
	UIImage *scaledImage = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:self.imageOrientation];
	CGImageRelease(imageRef);
	
	return scaledImage;
}

@end
