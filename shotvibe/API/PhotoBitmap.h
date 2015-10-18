//
//  PhotoBitmap.h
//  shotvibe
//
//  Created by benny on 9/3/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PhotoBitmapState) {
    PhotoBitmapDownloadError,
    PhotoBitmapQueuedForDownload,
    PhotoBitmapDownloading,
    PhotoBitmapLoading,
    PhotoBitmapLoaded,
};

@interface PhotoBitmap : NSObject

/**
 @param lowQualityBmp may be nil
 */
- (id)initAsDownloadError:(UIImage *)lowQualityBmp;

/**
 @param lowQualityBmp may be nil
 */
- (id)initAsQueuedForDownload:(UIImage *)lowQualityBmp;

/**
 @param downloadProgress from 0.0 to 1.0
 @param lowQualityBmp may be nil
 */
- (id)initAsDownloading:(float)downloadProgress lowQualityBmp:(UIImage *)lowQualityBmp;

/**
 @param lowQualityBmp may be nil
 */
- (id)initAsLoading:(UIImage *)lowQualityBmp;

- (id)initAsLoaded:(UIImage *)bmp;


@property (nonatomic, readonly, assign) PhotoBitmapState state;

- (float)downloadProgress;

/**
 @return nil if there is none
 */
- (UIImage *)bmp;

/**
 @return nil if there is none
 */
- (UIImage *)lowQualityBmp;

@end
