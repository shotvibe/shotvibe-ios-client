//
//  SVSelectionGridCell.h
//  shotvibe
//
//  Created by John Gabelmann on 7/11/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SVSelectionGridCell;

@protocol SVSelectionGridCellDelegate <NSObject>
@required
- (void)cellDidLongPress:(SVSelectionGridCell*)cell;

@end

@interface SVSelectionGridCell : UICollectionViewCell <UIGestureRecognizerDelegate>

@property (nonatomic, strong) id<SVSelectionGridCellDelegate> delegate;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *selectionImage;

@end
