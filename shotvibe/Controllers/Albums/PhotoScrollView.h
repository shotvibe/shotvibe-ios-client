//
//  PhotoScrollView.h
//  shotvibe
//
//  Created by Baluta Cristian on 20/11/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoImageView.h"

@interface PhotoScrollView : UIScrollView <UIScrollViewDelegate> {
	
	PhotoImageView *imageView;
	BOOL loaded;
	CGSize o_size;
}

// PhotoView API
- (id)initWithFrame:(CGRect)frame withFullControls:(BOOL)fullControls;
- (void)setPhoto:(NSString *)photoId photoUrl:(NSString *)photoUrl photoSize:(PhotoSize *)photoSize manager:(PhotoFilesManager *)photoFilesManager;
- (UIImage*)image;
- (void)setImage:(UIImage *)image;

// PhotoScrollView API
- (void)toggleZoom;
- (void)setMaxMinZoomScalesForCurrentBounds;

@property (nonatomic) int index;

@end
