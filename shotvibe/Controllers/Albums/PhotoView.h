//
//  PhotoView.h
//  shotvibe
//
//  Created by benny on 10/30/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PhotoBitmap.h"
#import "PhotoSize.h"

@class PhotoFilesManager;

@interface PhotoView : UIView

@property (nonatomic, retain) id delegate;

- (id)initWithFrame:(CGRect)frame withFullControls:(BOOL)fullControls;

- (void)setPhoto:(NSString *)photoId photoUrl:(NSString *)photoUrl photoSize:(PhotoSize *)photoSize manager:(PhotoFilesManager *)photoFilesManager;

- (UIImage*)image;
- (void)setImage:(UIImage *)image;

- (void)onPhotoLoadUpdate:(PhotoBitmap *)bmp;

@end
