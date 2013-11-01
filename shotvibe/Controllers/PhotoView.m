//
//  PhotoView.m
//  shotvibe
//
//  Created by benny on 10/30/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "PhotoView.h"
#import "PhotoFilesManager.h"

@implementation PhotoView
{
    PhotoFilesManager *prevManager_;
    NSString *photoId_;
    PhotoSize *photoSize_;

    UIImageView *imageView_;
    UIActivityIndicatorView *activityIndicatorView_;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        prevManager_ = nil;
        photoId_ = nil;
        photoSize_ = nil;

        imageView_ = [[UIImageView alloc] initWithFrame:frame];
        activityIndicatorView_ = [[UIActivityIndicatorView alloc] initWithFrame:frame];

        activityIndicatorView_.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;

        [self addSubview:imageView_];
        [self addSubview:activityIndicatorView_];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    return [self initWithFrame:[self frame]];
}

- (void)setPhoto:(NSString *)photoId photoUrl:(NSString *)photoUrl photoSize:(PhotoSize *)photoSize manager:(PhotoFilesManager *)photoFilesManager
{
    [self cancelPrevious];

    photoId_ = photoId;
    photoSize_ = photoSize;
    prevManager_ = photoFilesManager;

    [photoFilesManager loadBitmap:photoId photoUrl:photoUrl photoSize:photoSize photoObserver:self];
}

- (void)cancelPrevious
{
    if (prevManager_) {
        [prevManager_ removePhotoObserver:photoId_ photoSize:photoSize_ photoObserver:self];

        prevManager_ = nil;
        photoId_ = nil;
        photoSize_ = nil;
    }
}

- (void)setImage:(UIImage *)image
{
    [self cancelPrevious];

    [activityIndicatorView_ stopAnimating];
    [imageView_ setImage:image];
}

- (void)onPhotoLoadUpdate:(PhotoBitmap *)bmp
{
    switch (bmp.state) {
        case PhotoBitmapQueuedForDownload:
            NSLog(@"photoLoadUpdate %@ queued", photoId_);
            [self showLowQuality:bmp.lowQualityBmp];
            [activityIndicatorView_ startAnimating];
            // TODO ...
            break;

        case PhotoBitmapDownloading:
            NSLog(@"photoLoadUpdate %@ downloading", photoId_);
            [self showLowQuality:bmp.lowQualityBmp];
            [activityIndicatorView_ startAnimating];
            // TODO ...
            break;

        case PhotoBitmapLoading:
            NSLog(@"photoLoadUpdate %@ loading", photoId_);
            [self showLowQuality:bmp.lowQualityBmp];
            [activityIndicatorView_ startAnimating];
            // TODO ...
            break;

        case PhotoBitmapLoaded:
            NSLog(@"photoLoadUpdate %@ loaded", photoId_);
            [imageView_ setImage:bmp.bmp];
            [activityIndicatorView_ stopAnimating];
            // TODO ...
            break;

        case PhotoBitmapDownloadError:
            NSLog(@"photoLoadUpdate %@ downloadError", photoId_);
            // TODO ...
            break;
    }
}

- (void)showLowQuality:(UIImage *)lowQualityImg
{
    [imageView_ setImage:lowQualityImg];
}

@end
