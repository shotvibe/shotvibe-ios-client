//
//  PhotoImageView.m
//  shotvibe
//
//  Created by Baluta Cristian on 25/11/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "PhotoImageView.h"

#import "PhotoFilesManager.h"

@implementation PhotoImageView
{
    PhotoFilesManager *prevManager_;
    NSString *photoId_;
    PhotoSize *photoSize_;
	
    BOOL fullControls_;
	
    UIActivityIndicatorView *activityIndicatorView_;
    UIProgressView *progressView_;
}

- (id)initWithFrame:(CGRect)frame withFullControls:(BOOL)fullControls
{
    self = [super initWithFrame:frame];
    if (self) {
        fullControls_ = fullControls;
		
        prevManager_ = nil;
        photoId_ = nil;
        photoSize_ = nil;
		
        //self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		//self.backgroundColor = [UIColor yellowColor];
        
        if (fullControls_) {
            activityIndicatorView_ = [[UIActivityIndicatorView alloc] init];
            progressView_ = [[UIProgressView alloc] init];
			
            const float indicatorSize = 80.0f;
            const float indicatorCornerRadius = 20.0f;
            const float indicatorAlpha = 0.75f;
			
            activityIndicatorView_.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
            [activityIndicatorView_ setFrame:CGRectMake(0, 0, indicatorSize, indicatorSize)];
            activityIndicatorView_.backgroundColor = [UIColor colorWithWhite:0.0f alpha:indicatorAlpha];
            activityIndicatorView_.layer.cornerRadius = indicatorCornerRadius;
			
            [self addSubview:activityIndicatorView_];
            [self addSubview:progressView_];
        }
        else {
            activityIndicatorView_ = nil;
            progressView_ = nil;
        }
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame withFullControls:NO];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    return [self initWithFrame:[self frame]];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
	
	//self.contentMode = self.contentMode;
	//self.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
	
	if (fullControls_) {
		activityIndicatorView_.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
		
		const CGFloat progressWidth = 80.0f;
		const CGFloat progressHeight = 9.0f;
		
		[progressView_ setFrame:CGRectMake((self.frame.size.width / 2.0f) - (progressWidth / 2.0f), (self.frame.size.height / 2.0f) - (progressHeight / 2.0f), progressWidth, progressHeight)];
	}
}
//- (void)scaleToFitImageSize {
//	
//	RCLog(@"scaleToFitImageSize");
//	RCLogRect(self.frame);
//	RCLogSize(self.image.size);
//	
//	self.frame = (CGRect){.size=self.image.size, .origin=self.frame.origin};
//	
//	RCLogRect(self.frame);
//	RCLogSize(self.image.size);
//}

- (void)setPhoto:(NSString *)photoId photoUrl:(NSString *)photoUrl photoSize:(PhotoSize *)photoSize manager:(PhotoFilesManager *)photoFilesManager
{
    [self cancelPrevious];
	
    photoId_ = photoId;
    photoSize_ = photoSize;
    prevManager_ = photoFilesManager;
	
    [photoFilesManager loadBitmap:photoId photoUrl:photoUrl photoSize:photoSize photoObserver:(PhotoView*)self];
}

- (void)cancelPrevious
{
    if (prevManager_) {
        [prevManager_ removePhotoObserver:photoId_ photoSize:photoSize_ photoObserver:(PhotoView*)self];
		
        prevManager_ = nil;
        photoId_ = nil;
        photoSize_ = nil;
    }
}

- (void)setImage:(UIImage *)image
{
    [self cancelPrevious];
	
    //self.alpha = 1.0f;
    [super setImage:image];
	
    if (fullControls_) {
        [activityIndicatorView_ stopAnimating];
        progressView_.hidden = YES;
    }
}


- (void)onPhotoLoadUpdate:(PhotoBitmap *)bmp
{
    if (fullControls_) {
        [self updateWithFullControls:bmp];
    }
    else {
        if (bmp.state == PhotoBitmapLoaded) {
            self.alpha = 1.0f;
            [self setImage:bmp.bmp];
			if ([self.delegate respondsToSelector:@selector(onPhotoLoadComplete)]) {
				[self.delegate performSelector:@selector(onPhotoLoadComplete) withObject:nil];
			}
        }
        else {
            [self showLowQuality:bmp.lowQualityBmp];
        }
    }
}

- (void) updateWithFullControls:(PhotoBitmap *)bmp
{
    switch (bmp.state) {
        case PhotoBitmapQueuedForDownload:
            //NSLog(@"photoLoadUpdate %@ queued", photoId_);
            [self showLowQuality:bmp.lowQualityBmp];
            [activityIndicatorView_ startAnimating];
            progressView_.hidden = YES;
            break;
			
        case PhotoBitmapDownloading:
            //NSLog(@"photoLoadUpdate %@ downloading", photoId_);
            [self showLowQuality:bmp.lowQualityBmp];
            [activityIndicatorView_ stopAnimating];
            progressView_.hidden = NO;
            progressView_.progress = bmp.downloadProgress;
            break;
			
        case PhotoBitmapLoading:
            //NSLog(@"photoLoadUpdate %@ loading", photoId_);
            [self showLowQuality:bmp.lowQualityBmp];
            [activityIndicatorView_ startAnimating];
            progressView_.hidden = YES;
            break;
			
        case PhotoBitmapLoaded:
            //NSLog(@"photoLoadUpdate %@ loaded", photoId_);
            self.alpha = 1.0f;
            [self setImage:bmp.bmp];
            [activityIndicatorView_ stopAnimating];
            progressView_.hidden = YES;
			if ([self.delegate respondsToSelector:@selector(onPhotoLoadComplete)]) {
				[self.delegate performSelector:@selector(onPhotoLoadComplete) withObject:nil];
			}
            break;
			
        case PhotoBitmapDownloadError:
            //NSLog(@"photoLoadUpdate %@ downloadError", photoId_);
            // TODO ...
            break;
    }
}

- (void)showLowQuality:(UIImage *)lowQualityImg
{
    self.alpha = 0.5f;
    [self setImage:lowQualityImg];
}

@end
