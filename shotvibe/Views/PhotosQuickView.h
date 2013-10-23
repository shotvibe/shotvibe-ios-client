//
//  PhotosQuickView.h
//  shotvibe
//
//  Created by Baluta Cristian on 23/10/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCScrollImageView.h"

@class PhotosQuickView;

@protocol PhotosQuickViewDelegate <NSObject>
@required
- (void)photoDidCheck:(NSIndexPath*)indexPath;
- (void)photoDidClose:(PhotosQuickView*)photo;

@end

@interface PhotosQuickView : RCScrollImageView

@property (nonatomic, strong) id<PhotosQuickViewDelegate> quickDelegate;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) UIButton *selectionButton;

@end
