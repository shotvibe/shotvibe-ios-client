//
//  PushHandler.m
//  Vanywhere
//
//  Created by Tsah Kashkash on 8/31/15.
//  Copyright (c) 2015 Tsah Kashkash. All rights reserved.
//

#import "GLCamera.h"

//static GLCamera* SharedInstance;

@implementation GLCamera

+ (instancetype)sharedInstance {
    static GLCamera *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[GLCamera alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.flashIsOn = NO;
        self.inEditMode = NO;
        
        self.videoCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetInputPriority cameraPosition:AVCaptureDevicePositionBack];
        
        //    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
        //        self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
        //        self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1920x1080 cameraPosition:AVCaptureDevicePositionBack];
        
        self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
        self.videoCamera.horizontallyMirrorRearFacingCamera = NO;
        
    }
    return self;
}

-(void)toggleFlash {
    self.flashIsOn = !self.flashIsOn;
    // check if flashlight available
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]){
            
            [device lockForConfiguration:nil];
            if (self.flashIsOn) {
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeOn];
                //torchIsOn = YES; //define as a variable/property if you need to know status
            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
                [device setFlashMode:AVCaptureFlashModeOff];
                //torchIsOn = NO;
            }
            [device unlockForConfiguration];
        }
    }
}

-(void) playCaptureSound {
    //Get the filename of the sound file:
    //
    NSString *path = [NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] resourcePath], @"/camera-shutter-click-01.wav"];
    //
    SystemSoundID soundID;
    //
    NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
    //
    //        //Use audio sevices to create the sound
    //
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &soundID);
    
    //Use audio services to play the sound
    
    AudioServicesPlaySystemSound(soundID);
}

//static inline double radians (double degrees) {
//    return degrees * M_PI/180;
//}

- (UIImage *) resizeLabelImage:(UIImage*)image {

    
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(image.size.width*2.06, image.size.height*2.06), NO, 0.0);
    
    
//    CGContextRef context = UIGraphicsGetCurrentContext();
    
//        CGContextRotateCTM (UIGraphicsGetCurrentContext(), radians(90));
    
    
//    CGContextTranslateCTM( context, 0.5f * (image.size.width*1.7), 0.5f * (image.size.height*1.7) ) ;
//    CGContextRotateCTM( context, 0.3 ) ;
    
//    [ image drawInRect:(CGRect){ { -(image.size.width*1.7) * 0.5f, -(image.size.height*1.7) * 0.5f }, CGSizeMake(image.size.width*1.7, image.size.height*1.7) } ] ;
    
    
        [image drawInRect:CGRectMake(0, 0, image.size.width*2.06, image.size.height*2.06)];
    
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
        UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *) imageWithText:(UIView *)view
{
//    view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width*2, view.frame.size.height*2);
    
    
//    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
//    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
//    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
    
    
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0.0);

    
    
    
    [view.layer renderInContext:UIGraphicsGetCurrentContext() ];

    
//    [ drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImage *) imageWithView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0.0f);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    UIImage * snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return snapshotImage;
}

- (UIImage *)imageByCroppingImage:(UIImage *)image toSize:(CGSize)size
{
    // not equivalent to image.size (which depends on the imageOrientation)!
    double refWidth = CGImageGetWidth(image.CGImage);
    double refHeight = CGImageGetHeight(image.CGImage);
    
    double x = (refWidth - size.width) / 2.0;
    double y = (refHeight - size.height) / 2.0;
    
    CGRect cropRect = CGRectMake(x, y, size.height, size.width);
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);
    
    UIImage *cropped = [UIImage imageWithCGImage:imageRef scale:0.0 orientation:UIImageOrientationUp];
    CGImageRelease(imageRef);
    
    return cropped;
}


-(UIImage*) drawText:(NSString*) text
             inImage:(UIImage*)  image
             atPoint:(CGPoint)   point
          viewToPast:(UIImage*)viewToEmbed
{

//    UIImage * ttt = [self imageWithView:viewToEmbed];
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0);
    
//     UIGraphicsBeginImageContext(image.size);
    
//    CGContextSetFillColorWithColor( context, [UIColor clearColor].CGColor );
//    CGContextSetBlendMode(context, kCGBlendModeClear);
    
    
    [image drawAtPoint:CGPointMake(0,0)];
    [viewToEmbed drawAtPoint:CGPointMake(0,0)];
    

    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
//    UIFont *font = [UIFont boldSystemFontOfSize:12];
//    UIGraphicsBeginImageContext(image.size);
//    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];
//    CGRect rect = CGRectMake(point.x, point.y, image.size.width, image.size.height);
//    [[UIColor whiteColor] set];
//    [text drawInRect:CGRectIntegral(rect) withFont:font];
//    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
    
    return newImage;
}

@end

