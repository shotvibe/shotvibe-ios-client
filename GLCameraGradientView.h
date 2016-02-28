//
//  GLCameraGradientView.h
//  shotvibe
//
//  Created by Tsah Kashkash on 20/01/2016.
//  Copyright © 2016 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GLCameraGradientView : UIView

- (instancetype)initWithFrame:(CGRect)frame colorsArrayInHex:(NSArray*)hexStringArray;
- (void)updateGradientWithColors:(NSArray*)colors;

@end
