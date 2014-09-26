//
//  IosBitmapProcessor.m
//  shotvibe
//
//  Created by raptor on 9/18/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "IosBitmapProcessor.h"

#import "SL/UploadManager.h"

@implementation IosBitmapProcessor

// Returns an affine transform that takes into account the image orientation when drawing a scaled image
static CGAffineTransform transformForOrientation(UIImageOrientation orientation, int newWidth, int newHeight)
{
    CGAffineTransform transform = CGAffineTransformIdentity;

    switch (orientation) {
        case UIImageOrientationDown:
            transform = CGAffineTransformTranslate(transform, newWidth, newHeight);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;

        case UIImageOrientationLeft:
            transform = CGAffineTransformTranslate(transform, newWidth, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;

        case UIImageOrientationRight:
            transform = CGAffineTransformTranslate(transform, 0, newHeight);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;

        default:
            break;
    }

    return transform;
}


static UIImage * resizeUIImage(UIImage *image, int newWidth, int newHeight)
{
    // TODO Check for errors throughout this function

    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newWidth, newHeight));
    CGRect transposedRect = CGRectMake(0, 0, newRect.size.height, newRect.size.width);
    CGImageRef imageRef = image.CGImage;

    CGColorSpaceRef colorSpace;

    colorSpace = CGColorSpaceCreateDeviceRGB();

    // Build a context that's the same dimensions as the new size
    CGContextRef bitmap = CGBitmapContextCreate(0,
                                                newRect.size.width,
                                                newRect.size.height,
                                                8,
                                                0,
                                                colorSpace,
                                                (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);

    BOOL drawTransposed;

    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            drawTransposed = YES;
            break;

        default:
            drawTransposed = NO;
    }

    CGAffineTransform transform = transformForOrientation(image.imageOrientation, newWidth, newHeight);

    // Rotate and/or flip the image if required by its orientation
    CGContextConcatCTM(bitmap, transform);

    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(bitmap, kCGInterpolationHigh);

    // Draw into the context; this scales the image
    CGContextDrawImage(bitmap, drawTransposed ? transposedRect : newRect, imageRef);


    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];

    // Clean up
    CGContextRelease(bitmap);
    CGImageRelease(newImageRef);

    CGColorSpaceRelease(colorSpace);

    return newImage;
}


struct ImageSize {
    int width;
    int height;
};

static struct ImageSize boxFitExpanded(int sourceWidth, int sourceHeight, int targetWidth, int targetHeight)
{
    int newWidth;
    int newHeight;
    if ((long)sourceWidth * targetHeight > (long)targetWidth * sourceHeight) {
        newHeight = targetHeight;
        newWidth = newHeight * sourceWidth / sourceHeight;
    } else {
        newWidth = targetWidth;
        newHeight = newWidth * sourceHeight / sourceWidth;
    }

    struct ImageSize result;
    result.width = newWidth;
    result.height = newHeight;
    return result;
}


static struct ImageSize boxFit(int sourceWidth, int sourceHeight, int targetWidth, int targetHeight)
{
    int newWidth;
    int newHeight;
    if ((long)sourceWidth * targetHeight > (long)targetWidth * sourceHeight) {
        newWidth = targetWidth;
        newHeight = newWidth * sourceHeight / sourceWidth;
    } else {
        newHeight = targetHeight;
        newWidth = newHeight * sourceWidth / sourceHeight;
    }

    struct ImageSize result;
    result.width = newWidth;
    result.height = newHeight;
    return result;
}


static struct ImageSize boxFitWithRotation(int sourceWidth, int sourceHeight, int targetWidth, int targetHeight)
{
    struct ImageSize landscape = boxFit(sourceWidth, sourceHeight, targetWidth, targetHeight);
    struct ImageSize portrait = boxFit(sourceHeight, sourceWidth, targetWidth, targetHeight);

    if (landscape.width > portrait.height || landscape.height > portrait.width) {
        return landscape;
    } else {
        struct ImageSize result;
        result.width = portrait.height;
        result.height = portrait.width;
        return result;
    }
}


static struct ImageSize boxFitWithRotationOnlyShrink(int sourceWidth, int sourceHeight, int targetWidth, int targetHeight)
{
    struct ImageSize result = boxFitWithRotation(sourceWidth, sourceHeight, targetWidth, targetHeight);
    if (result.width <= sourceWidth && result.height <= sourceHeight) {
        return result;
    } else {
        struct ImageSize result;
        result.width = sourceWidth;
        result.height = sourceHeight;
        return result;
    }
}


- (SLBitmapProcessor_ResizedResult *)createResizedAndThumbnailWithNSString:(NSString *)originalPath
                                                              withNSString:(NSString *)resizedSavePath
                                                              withNSString:(NSString *)thumbSavePath
{
    // TODO Should use better values suitable for density of the currently running device
    const int THUMB_WIDTH = 128;
    const int THUMB_HEIGHT = 128;

    const CGFloat RESIZED_SAVE_QUALITY = 0.9f;
    const CGFloat THUMB_SAVE_QUALITY = 0.9f;

    UIImage *image = [[UIImage alloc] initWithContentsOfFile:originalPath];

    if (!image) {
        NSLog(@"Error opening image: %@", originalPath);
    }

    NSLog(@"file: %@ size:%fx%f", originalPath, image.size.width, image.size.height);

    struct ImageSize thumbSize = boxFitExpanded(image.size.width, image.size.height, THUMB_WIDTH, THUMB_HEIGHT);
    UIImage *thumb = resizeUIImage(image, thumbSize.width, thumbSize.height);

    NSLog(@"thumb size:%fx%f", thumb.size.width, thumb.size.height);

    [UIImageJPEGRepresentation(thumb, THUMB_SAVE_QUALITY) writeToFile:thumbSavePath atomically:NO];

    // Let ARC free the memory:
    thumb = nil;

    struct ImageSize resizedSize = boxFitWithRotationOnlyShrink(
            image.size.width,
            image.size.height,
            SLUploadManager_RESIZED_IMAGE_TARGET_WIDTH,
            SLUploadManager_RESIZED_IMAGE_TARGET_HEIGHT);

    UIImage *resized = resizeUIImage(image, resizedSize.width, resizedSize.height);

    [UIImageJPEGRepresentation(resized, RESIZED_SAVE_QUALITY) writeToFile:resizedSavePath atomically:NO];

    return [[SLBitmapProcessor_ResizedResult alloc] initWithBoolean:YES
                                                            withInt:image.size.width
                                                            withInt:image.size.height
                                                            withInt:resizedSize.width
                                                            withInt:resizedSize.height];
}


@end
