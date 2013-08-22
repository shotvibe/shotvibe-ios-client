//
//  RCScrollImageView.m
//  shotvibe
//
//  Created by Baluta Cristian on 21/08/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "RCScrollImageView.h"

@implementation RCScrollImageView


- (void)layoutSubviews {
	[super layoutSubviews];
	
	// Center the image as it becomes smaller than the size of the screen.
	
	UIView* zoomingSubview = [self.delegate viewForZoomingInScrollView:self];
	CGSize boundsSize = self.bounds.size;
	CGRect frameToCenter = zoomingSubview.frame;
	
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
	
	zoomingSubview.frame = frameToCenter;
}


- (id)initWithFrame:(CGRect)frame delegate:(id)d
{
    self = [super initWithFrame:frame];
    if (self) {
		
		//self.contentSize = CGSizeMake((w+60)*[self.sortedPhotos count], h);
		self.scrollEnabled = YES;
		self.showsHorizontalScrollIndicator = NO;
		self.showsVerticalScrollIndicator = NO;
		self.pagingEnabled = NO;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.decelerationRate = UIScrollViewDecelerationRateFast;
		self.minimumZoomScale = 1.0;
		self.maximumZoomScale = 1.0;
		self.delegate = self;
		
        // Initialization code
		imageView = [[RCImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height) delegate:d];
		imageView.autosize = YES;
		imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self addSubview:imageView];
    }
    return self;
}

- (void)setI:(int)i {
	_i = i;
	imageView.i = i;
}
- (void) setImage:(UIImage *)image {
	imageView.image = image;
}
- (void)loadNetworkImage:(NSString *)path {
	
	if (loadingIndicator == nil) {
		loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		[loadingIndicator sizeToFit];
		//loadingIndicator.frame = NIFrameOfCenteredViewWithinView(_loadingView, self);
		loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
		[self addSubview:loadingIndicator];
	}
	[imageView loadNetworkImage:path];
}


#pragma mark UIScrollView delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return imageView;
}
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
	NSLog(@"did end zooming %f", scale);
	[self setNeedsLayout];
}


- (void)setMaxMinZoomScalesForCurrentBounds {
	
	CGSize imageSize = imageView.bounds.size;
	
	// Avoid crashing if the image has no dimensions.
	if (imageSize.width <= 0 || imageSize.height <= 0) {
		self.maximumZoomScale = 1;
		self.minimumZoomScale = 1;
	}
	else {
		float scaleWMin = self.bounds.size.width / imageSize.width;
		float scaleHMin = self.bounds.size.height / imageSize.height;
		self.minimumZoomScale = (scaleWMin < scaleHMin) ? scaleWMin : scaleHMin;
	}
	[self setZoomScale:self.minimumZoomScale animated:NO];
	[self setNeedsLayout];
}


@end
