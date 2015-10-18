//
//  PhotoImageView.h
//  shotvibe
//
//  Created by Baluta Cristian on 25/11/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoBitmap.h"
#import "PhotoSize.h"

@class PhotoFilesManager;

@interface PhotoImageView : UIImageView

@property (nonatomic, retain) id delegate;

- (id)initWithFrame:(CGRect)frame withFullControls:(BOOL)fullControls;

- (void)setPhoto:(NSString *)photoId photoUrl:(NSString *)photoUrl photoSize:(PhotoSize *)photoSize manager:(PhotoFilesManager *)photoFilesManager;

- (void)onPhotoLoadUpdate:(PhotoBitmap *)bmp;


@end
