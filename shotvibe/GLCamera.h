//
//  PushHandler.h
//  Vanywhere
//
//  Created by Tsah Kashkash on 8/31/15.
//  Copyright (c) 2015 Tsah Kashkash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPUImage/GPUImage.h>

@interface GLCamera : NSObject

@property(nonatomic, retain) GPUImageStillCamera * videoCamera;
@property(nonatomic) BOOL flashIsOn;
@property(nonatomic) BOOL inEditMode;


+ (GLCamera *)sharedInstance;
- (UIImage*) drawText:(NSString*) text
             inImage:(UIImage*)  image
             atPoint:(CGPoint)   point
          viewToPast:(UIImage*)viewToEmbed;

- (void) playCaptureSound;
- (UIImage *) imageWithView:(UIView *)view;
- (UIImage *) imageWithText:(UIView *)view;
- (UIImage *) resizeLabelImage:(UIImage*)image location:(CGPoint)location;
- (UIImage *)imageByCroppingImage:(UIImage *)image toSize:(CGSize)size;
- (void)toggleFlash;
@end
