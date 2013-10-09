//
//  SVImageCropViewController.m
//  shotvibe
//
//  Created by Baluta Cristian on 17/09/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVImageCropViewController.h"
#import "UIImage+Scale.h"


@implementation SVImageCropViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	self.title = nil;
	
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Choose", @"")
																   style:UIBarButtonItemStyleBordered
																  target:self
																  action:@selector(doneButtonPressed)];
	self.navigationItem.rightBarButtonItem = doneButton;
	
	
	scrollView.backgroundColor = [UIColor clearColor];
	scrollView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.6].CGColor;
	scrollView.layer.borderWidth = 1;
	scrollView.showsHorizontalScrollIndicator = NO;
	scrollView.showsVerticalScrollIndicator = NO;
	scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
	scrollView.minimumZoomScale = 1.0;
	scrollView.maximumZoomScale = 1.0;
	
	imageView = [[UIImageView alloc] initWithImage:self.image];
	[scrollView addSubview:imageView];
	scrollView.contentSize = self.image.size;
	
	[self setMaxMinZoomScalesForCurrentBounds];
}
- (void)viewDidAppear:(BOOL)animated {
	
	[super viewDidAppear:animated];
	topView.frame = CGRectMake(0, 0, 320, scrollView.frame.origin.y);
	bottomView.frame = CGRectMake(0, scrollView.frame.origin.y + scrollView.frame.size.height, 320, topView.frame.size.height);
}

- (BOOL)shouldAutorotate
{
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskPortrait;
}



- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return imageView;
}


- (void)doneButtonPressed {
	RCLog(@"doneButtonPressed %@", self.delegate);
	float scale = 1.0f/scrollView.zoomScale;
	
	CGRect visibleRect;
	visibleRect.origin.x = scrollView.contentOffset.x * scale;
	visibleRect.origin.y = scrollView.contentOffset.y * scale;
	visibleRect.size.width = scrollView.bounds.size.width * scale;
	visibleRect.size.height = scrollView.bounds.size.height * scale;
	
	CGImageRef cr = CGImageCreateWithImageInRect (self.image.CGImage, visibleRect);
	UIImage *cropped = [[UIImage alloc] initWithCGImage:cr];
	CGImageRelease(cr);
	
	if ([self.delegate respondsToSelector:@selector(didCropImage:)]) {
		[self.delegate didCropImage:cropped];
	}
}


- (void)setMaxMinZoomScalesForCurrentBounds {
	
	CGSize imageSize = self.image.size;
	
	// Avoid crashing if the image has no dimensions.
	if (imageSize.width <= 0 || imageSize.height <= 0) {
		scrollView.maximumZoomScale = 1;
		scrollView.minimumZoomScale = 1;
	}
	else {
		float scaleWMin = scrollView.frame.size.width / imageSize.width;
		float scaleHMin = scrollView.frame.size.height / imageSize.height;
		scrollView.minimumZoomScale = (scaleWMin >= scaleHMin) ? scaleWMin : scaleHMin;
	}
	[scrollView setZoomScale:scrollView.minimumZoomScale animated:NO];
}


@end
