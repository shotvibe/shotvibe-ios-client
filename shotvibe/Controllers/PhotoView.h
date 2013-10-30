//
//  PhotoView.h
//  shotvibe
//
//  Created by benny on 10/30/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PhotoBitmap.h"

@interface PhotoView : UIView

- (void)onPhotoLoadUpdate:(PhotoBitmap *)bmp;

@end
