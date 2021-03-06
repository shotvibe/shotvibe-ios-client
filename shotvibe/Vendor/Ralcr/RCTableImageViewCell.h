//
//  RCTableImageViewCell.h
//  shotvibe
//
//  Created by Baluta Cristian on 03/09/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCImageView.h"
#import "RCScrollImageView.h"

#define IMAGE_CELL_HEIGHT 260

@class RCTableImageViewCell;
@protocol RCTableImageViewCellDelegate <NSObject>

- (void)deleteButtonPressedForIndex:(RCTableImageViewCell*)cell;
- (void)shareButtonPressedForIndex:(RCTableImageViewCell*)cell;

@end

@interface RCTableImageViewCell : UITableViewCell {
	
	UIView *largeImageContainer;
	UIButton *butDelete;
	UIButton *butShare;
}

@property (nonatomic, retain) RCScrollImageView *largeImageView;
@property (nonatomic, retain) UILabel *detailLabel;
@property (nonatomic, retain) id delegate;

@end
