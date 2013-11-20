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

    BOOL fullControls_;

    UIImageView *imageView_;
    UIActivityIndicatorView *activityIndicatorView_;
    UIProgressView *progressView_;
}

- (id)initWithFrame:(CGRect)frame withFullControls:(BOOL)fullControls
{
    self = [super initWithFrame:frame];
    if (self) {
		
		// Add scrollview stuffs
		self.delegate = self;
		self.scrollEnabled = YES;
		self.showsHorizontalScrollIndicator = NO;
		self.showsVerticalScrollIndicator = NO;
		self.autoresizesSubviews = YES;
		self.pagingEnabled = NO;
		self.decelerationRate = UIScrollViewDecelerationRateFast;
		self.minimumZoomScale = 1.0;
		self.maximumZoomScale = 1.0;
		//self.backgroundColor = [UIColor orangeColor];
		//self.layer.borderWidth = 10;
		//self.layer.borderColor = [UIColor lightGrayColor].CGColor;
		self.contentSize = frame.size;
		
		
        fullControls_ = fullControls;

        prevManager_ = nil;
        photoId_ = nil;
        photoSize_ = nil;

        imageView_ = [[UIImageView alloc] init];
		[imageView_ setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
		imageView_.contentMode = self.contentMode;
        [self addSubview:imageView_];

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
	
    [imageView_ setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    imageView_.contentMode = self.contentMode;

    if (fullControls_) {
        activityIndicatorView_.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);

        const CGFloat progressWidth = 80.0f;
        const CGFloat progressHeight = 9.0f;

        [progressView_ setFrame:CGRectMake((self.frame.size.width / 2.0f) - (progressWidth / 2.0f), (self.frame.size.height / 2.0f) - (progressHeight / 2.0f), progressWidth, progressHeight)];
    }
}
- (void)layoutSubviews2 {
	[super layoutSubviews];
	
	// Center the image as it becomes smaller than the size of the screen.
	
	CGSize boundsSize = self.frame.size;
	CGRect frameToCenter = imageView_.frame;
	
	// Center horizontally.
	if (frameToCenter.size.width < boundsSize.width) {
		frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2);
	} else {
		frameToCenter.origin.x = 0;
	}
	
	// Center vertically.
	if (frameToCenter.size.height < boundsSize.height) {
		frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2);
	} else {
		frameToCenter.origin.y = 0;
	}
	
	imageView_.frame = frameToCenter;
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

    imageView_.alpha = 1.0f;
    [imageView_ setImage:image];
	[self setMaxMinZoomScalesForCurrentBounds];

    if (fullControls_) {
        [activityIndicatorView_ stopAnimating];
        progressView_.hidden = YES;
    }
}
- (UIImage*)image {
	return imageView_.image;
}

- (void)onPhotoLoadUpdate:(PhotoBitmap *)bmp
{
    if (fullControls_) {
        [self updateWithFullControls:bmp];
    }
    else {
        if (bmp.state == PhotoBitmapLoaded) {
            imageView_.alpha = 1.0f;
            [imageView_ setImage:bmp.bmp];
			[self setMaxMinZoomScalesForCurrentBounds];
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
            imageView_.alpha = 1.0f;
            [imageView_ setImage:bmp.bmp];
            [activityIndicatorView_ stopAnimating];
			[self setMaxMinZoomScalesForCurrentBounds];
            progressView_.hidden = YES;
            break;

        case PhotoBitmapDownloadError:
            //NSLog(@"photoLoadUpdate %@ downloadError", photoId_);
            // TODO ...
            break;
    }
}

- (void)showLowQuality:(UIImage *)lowQualityImg
{
    imageView_.alpha = 0.5f;
    [imageView_ setImage:lowQualityImg];
}



- (void)toggleZoom {
	[self setZoomScale:(self.zoomScale < self.maximumZoomScale ? self.maximumZoomScale : self.minimumZoomScale) animated:YES];
}


#pragma mark UIScrollView delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return imageView_;
}
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
	[self setNeedsLayout];
}


- (void)setMaxMinZoomScalesForCurrentBounds {
	
	CGSize imageSize = imageView_.image.size;
	
	// Avoid crashing if the image has no dimensions.
	if (imageSize.width <= 0 || imageSize.height <= 0) {
		self.maximumZoomScale = 1;
		self.minimumZoomScale = 1;
	}
	else {
		float scaleWMin = self.frame.size.width / imageSize.width;
		float scaleHMin = self.frame.size.height / imageSize.height;
		self.minimumZoomScale = ((scaleWMin < scaleHMin) ? scaleWMin : scaleHMin);
	}
	//	self.maximumZoomScale = 1;
	[self setZoomScale:self.minimumZoomScale animated:NO];
	[self setNeedsLayout];
	RCLog(@"self.minimumZoomScale %f %f", self.minimumZoomScale, self.maximumZoomScale);
}



@end
