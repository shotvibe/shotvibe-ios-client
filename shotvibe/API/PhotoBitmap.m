//
//  PhotoBitmap.m
//  shotvibe
//
//  Created by benny on 9/3/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "PhotoBitmap.h"

@implementation PhotoBitmap
{
    UIImage *bmp_;
    float downloadProgress_;
}

- (id)initAsDownloadError:(UIImage *)lowQualityBmp
{
    self = [super init];

    if (self) {
        _state = PhotoBitmapDownloadError;
        bmp_ = lowQualityBmp;
        downloadProgress_ = 0.0f;
    }

    return self;
}

- (id)initAsQueuedForDownload:(UIImage *)lowQualityBmp
{
    self = [super init];

    if (self) {
        _state = PhotoBitmapQueuedForDownload;
        bmp_ = lowQualityBmp;
        downloadProgress_ = 0.0f;
    }

    return self;
}

- (id)initAsDownloading:(float)downloadProgress lowQualityBmp:(UIImage *)lowQualityBmp
{
    self = [super init];

    if (self) {
        _state = PhotoBitmapDownloading;
        bmp_ = lowQualityBmp;
        downloadProgress_ = downloadProgress;
    }

    return self;
}

- (id)initAsLoading:(UIImage *)lowQualityBmp
{
    self = [super init];

    if (self) {
        _state = PhotoBitmapLoading;
        bmp_ = lowQualityBmp;
        downloadProgress_ = 0.0f;
    }

    return self;
}

- (id)initAsLoaded:(UIImage *)bmp
{
    self = [super init];

    if (self) {
        _state = PhotoBitmapLoaded;
        bmp_ = bmp;
        downloadProgress_ = 0.0f;
    }

    return self;
}

- (float)downloadProgress
{
    NSAssert(self.state == PhotoBitmapDownloading, @"downloadProgress available only when state is PhotoBitmapDownloading");

    return downloadProgress_;
}

- (UIImage *)lowQualityBmp
{
    NSAssert(self.state != PhotoBitmapLoaded, @"lowQualityBmp not available when state is PhotoBitmapLoaded");

    return bmp_;
}

- (UIImage *)bmp
{
    NSAssert(self.state == PhotoBitmapLoaded, @"bmp available only when state is PhotoBitmapLoaded");
    
    return bmp_;
}

@end
