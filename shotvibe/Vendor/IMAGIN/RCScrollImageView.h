//
//  RCScrollImageView.h
//  shotvibe
//
//  Created by Baluta Cristian on 21/08/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCImageView.h"

@interface RCScrollImageView : UIScrollView <UIScrollViewDelegate> {
	
	RCImageView *imageView;
}

- (id)initWithFrame:(CGRect)frame delegate:(id)d;
- (void)loadNetworkImage:(NSString *)path;
- (void)setMaxMinZoomScalesForCurrentBounds;
- (void)loadComplete;
- (void)toggleZoom;

@property(nonatomic, retain) UIImage *image;
@property(nonatomic) int i;
@property(nonatomic, retain) UIActivityIndicatorView *loadingIndicator;

@end
