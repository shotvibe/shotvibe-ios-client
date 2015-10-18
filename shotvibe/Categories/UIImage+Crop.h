//
//  UIImage+Crop.h
//  shotvibe
//
//  Created by Baluta Cristian on 16/11/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#define rad(deg) deg / 180.0 * M_PI

@interface UIImage (Crop)
- (UIImage*)imageByCroppingForSize:(CGSize)targetSize;
@end
