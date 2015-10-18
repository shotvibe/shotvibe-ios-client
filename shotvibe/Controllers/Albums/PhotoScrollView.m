//
//  PhotoScrollView.m
//  shotvibe
//
//  Created by Baluta Cristian on 20/11/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "PhotoScrollView.h"

@implementation PhotoScrollView

- (id)initWithFrame:(CGRect)frame withFullControls:(BOOL)fullControls {
	
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
		//self.layer.borderWidth = 1;
		//self.layer.borderColor = [UIColor redColor].CGColor;
		self.contentSize = frame.size;
		self.index = -1;
		
        // Initialization code
		imageView = [[PhotoImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height) withFullControls:fullControls];
		imageView.contentMode = UIViewContentModeScaleAspectFit;
//		imageView.backgroundColor = [UIColor greenColor];
		[self addSubview:imageView];
    }
    return self;
}

- (void)setPhoto:(NSString *)photoId photoUrl:(NSString *)photoUrl photoSize:(PhotoSize *)photoSize manager:(PhotoFilesManager *)photoFilesManager {
    imageView.delegate = self;
	[imageView setPhoto:photoId photoUrl:photoUrl photoSize:photoSize manager:photoFilesManager];
}

- (void)setImage:(UIImage *)image {
    [imageView setImage:image];
	[self onPhotoLoadComplete];
}

- (UIImage*)image {
	return [imageView image];
}




- (void)layoutSubviews {
	[super layoutSubviews];
	[self centerScrollViewContents];
//	RCLog(@"layoutSubviews");
}




#pragma mark PhotoView delegate

- (void)onPhotoLoadComplete {
	
	o_size = imageView.image.size;
	imageView.frame = (CGRect){.size=o_size, .origin=self.frame.origin};
	self.contentSize = o_size;
	
	[self setMaxMinZoomScalesForCurrentBounds];
	loaded = YES;
}


#pragma mark UIScrollView delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return imageView;
}
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
	[self setNeedsLayout];
	//RCLogSize(self.contentSize);
}


- (void)setMaxMinZoomScalesForCurrentBounds {
	
    CGFloat scaleWidth = self.frame.size.width / o_size.width;
    CGFloat scaleHeight = self.frame.size.height / o_size.height;
    CGFloat minScale = MIN(scaleWidth, scaleHeight);
    self.minimumZoomScale = minScale;
    self.maximumZoomScale = 1.0f;
    self.zoomScale = minScale;
	
    [self centerScrollViewContents];
	
	RCLog(@"self.minimumZoomScale %i %f %f", self.index, self.minimumZoomScale, self.maximumZoomScale);
	RCLogSize(self.contentSize);
}

- (void)centerScrollViewContents {
	
    CGSize boundsSize = self.bounds.size;
    CGRect contentsFrame = imageView.frame;
	
    if (contentsFrame.size.width < boundsSize.width) {
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0f;
    } else {
        contentsFrame.origin.x = 0.0f;
    }
	
	if (contentsFrame.size.height < boundsSize.height) {
		contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0f;
	} else {
		contentsFrame.origin.y = 0.0f;
	}
	
	imageView.frame = contentsFrame;
}

- (void)toggleZoom {
	[self setZoomScale:(self.zoomScale < self.maximumZoomScale ? self.maximumZoomScale : self.minimumZoomScale) animated:YES];
}


@end
