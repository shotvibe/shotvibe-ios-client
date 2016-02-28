//
//  UIImage+Scale.h
//  shotvibe
//
//  Created by Baluta Cristian on 09/09/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Scale)

- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize;

@end
