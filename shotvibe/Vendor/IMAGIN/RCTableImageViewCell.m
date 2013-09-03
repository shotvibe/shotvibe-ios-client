//
//  RCTableImageViewCell.m
//  shotvibe
//
//  Created by Baluta Cristian on 03/09/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "RCTableImageViewCell.h"

@implementation RCTableImageViewCell
@synthesize detailLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
		largeImageContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, IMAGE_CELL_HEIGHT)];
		largeImageContainer.clipsToBounds = YES;
		largeImageContainer.backgroundColor = [UIColor darkGrayColor];
		largeImageContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self.contentView addSubview:largeImageContainer];
		
		detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, IMAGE_CELL_HEIGHT-30, self.frame.size.width, 30)];
		detailLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
		detailLabel.textColor = [UIColor lightGrayColor];
		detailLabel.numberOfLines = 1;
		detailLabel.textAlignment = NSTextAlignmentLeft;
		detailLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12];
		detailLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self.contentView addSubview:detailLabel];
		
		butDelete = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width-60, IMAGE_CELL_HEIGHT-25, 20, 20)];
		[butDelete setImage:[UIImage imageNamed:@"trashIcon.png"] forState:UIControlStateNormal];
		[butDelete addTarget:self action:@selector(butDeletePressed:) forControlEvents:UIControlEventTouchUpInside];
		butDelete.alpha = 0.5;
		butDelete.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		[self.contentView addSubview:butDelete];
		
		butShare = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width-30, IMAGE_CELL_HEIGHT-25, 20, 20)];
		[butShare setImage:[UIImage imageNamed:@"exportIcon.png"] forState:UIControlStateNormal];
		[butShare addTarget:self action:@selector(butSharePressed:) forControlEvents:UIControlEventTouchUpInside];
		butShare.alpha = 0.5;
		butShare.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		[self.contentView addSubview:butShare];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setLargeImageView:(RCScrollImageView *)largeImageView {
	
	if (_largeImageView != nil) {
		for (id subview in largeImageContainer.subviews) {
			if ([subview isKindOfClass:[RCScrollImageView class]]) {
				[subview removeFromSuperview];
				break;
			}
		}
	}
	
	_largeImageView = largeImageView;
	CGRect rect = _largeImageView.frame;
	rect.origin.y = IMAGE_CELL_HEIGHT/2 - rect.size.height/2;
	_largeImageView.frame = rect;
	[largeImageContainer addSubview:_largeImageView];
}


-(void)butDeletePressed:(id)sender {
	if ([self.delegate respondsToSelector:@selector(deleteButtonPressedForIndex:)]) {
		[self.delegate performSelector:@selector(deleteButtonPressedForIndex:) withObject:self];
	}
}
-(void)butSharePressed:(id)sender {
	if ([self.delegate respondsToSelector:@selector(shareButtonPressedForIndex:)]) {
		[self.delegate performSelector:@selector(shareButtonPressedForIndex:) withObject:self];
	}
}

@end
