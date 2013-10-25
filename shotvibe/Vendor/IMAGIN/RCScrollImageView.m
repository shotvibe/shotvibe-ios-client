//
//  RCScrollImageView.m
//  shotvibe
//
//  Created by Baluta Cristian on 21/08/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "RCScrollImageView.h"

@implementation RCScrollImageView
@synthesize loadingIndicator;


- (id)initWithFrame:(CGRect)frame delegate:(id)d
{
    self = [super initWithFrame:frame];
    if (self) {
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
		
        // Initialization code
		imageView = [[RCImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height) delegate:d];
		//imageView.autosize = YES;// this line is trouble, don't use it
		//imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		
		[self addSubview:imageView];
    }
    return self;
}

- (void)toggleZoom {
	[self setZoomScale:(self.zoomScale < self.maximumZoomScale ? self.maximumZoomScale : self.minimumZoomScale) animated:YES];
}


- (void)layoutSubviews {
	[super layoutSubviews];
	
	// Center the image as it becomes smaller than the size of the screen.
	
	CGSize boundsSize = self.frame.size;
	CGRect frameToCenter = imageView.frame;
	
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
	
	imageView.frame = frameToCenter;
}


- (void)setI:(int)i {
	_i = i;
	imageView.i = i;
}

- (UIImage*) image {
	return imageView.image;
}

- (void) setImage:(UIImage *)image {
	imageView.image = image;
	[self loadComplete];
}

- (void)loadNetworkImage:(NSString *)path {
	
	if (loadingIndicator == nil) {
		loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		[loadingIndicator sizeToFit];
		CGRect rect = loadingIndicator.frame;
		rect.origin.x = self.frame.size.width/2 - rect.size.width/2;
		rect.origin.y = self.frame.size.height/2 - rect.size.height/2;
		loadingIndicator.frame = rect;
		loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
		[self addSubview:loadingIndicator];
	}
	
	[loadingIndicator startAnimating];
	[imageView loadNetworkImage:path];
	
	// If the image already exists stop the loadingIndicator
//	if (imageView.image) {
//		[self loadComplete];
//	}
}

- (void)loadComplete {
	[loadingIndicator stopAnimating];
	imageView.frame = (CGRect){.size=imageView.image.size, .origin=CGPointMake(0, 0)};
}


#pragma mark UIScrollView delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return imageView;
}
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
	[self setNeedsLayout];
}


- (void)setMaxMinZoomScalesForCurrentBounds {
	
	CGSize imageSize = imageView.image.size;
	
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
//	RCLog(@"self.minimumZoomScale %f %f", self.minimumZoomScale, self.maximumZoomScale);
}


@end
