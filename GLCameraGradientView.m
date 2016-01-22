//
//  GLCameraGradientView.m
//  shotvibe
//
//  Created by Tsah Kashkash on 20/01/2016.
//  Copyright © 2016 PicsOnAir Ltd. All rights reserved.
//

#import "GLCameraGradientView.h"

@implementation GLCameraGradientView

+ (Class)layerClass
{
    return [CAGradientLayer class];
}

//- (instancetype)initWithCoder:(NSCoder *)aDecoder {
//    self = [super initWithCoder:aDecoder];
//    if(self) {
//        [self initGradientLayerWithHex];
//    }
//    return self;
//}

- (instancetype)initWithFrame:(CGRect)frame colorsArrayInHex:(NSArray*)hexStringArray {
    self = [super initWithFrame:frame];
    if(self) {
        [self initGradientLayerWithHex:hexStringArray];
    }
    return self;
}

- (void)updateGradientWithColors:(NSArray*)colors {
    


    CAGradientLayer *gLayer = (CAGradientLayer *)self.layer;
    gLayer.colors = [NSArray arrayWithObjects:(id)[[colors objectAtIndex:0] CGColor], (id)[[colors objectAtIndex:1] CGColor], nil];

}

- (void)initGradientLayerWithHex:(NSArray*)hexStringArray {
    
    unsigned colorIntOne = 0;
    unsigned colorIntTwo = 0;
    [[NSScanner scannerWithString:[hexStringArray objectAtIndex:0]] scanHexInt:&colorIntOne];
    [[NSScanner scannerWithString:[hexStringArray objectAtIndex:1]] scanHexInt:&colorIntTwo];
    
    UIColor * colorOne = UIColorFromRGB(colorIntOne);
    UIColor * colorTwo = UIColorFromRGB(colorIntTwo);
    
    
    CAGradientLayer *gLayer = (CAGradientLayer *)self.layer;
    gLayer.colors = [NSArray arrayWithObjects:(id)[colorOne CGColor], (id)[colorTwo CGColor], nil];
    
}

@end
