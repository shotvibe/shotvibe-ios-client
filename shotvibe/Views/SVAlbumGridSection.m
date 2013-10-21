//
//  SVAlbumGridSection.m
//  shotvibe
//
//  Created by Baluta Cristian on 29/09/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVAlbumGridSection.h"


@implementation SVAlbumGridSection

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
		self.backgroundColor = [UIColor clearColor];
		
		self.imageView = [[RCImageView alloc] initWithFrame:CGRectMake(7, 10, frame.size.height-20, frame.size.height-20)];
		[self addSubview:self.imageView];
		
		self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(7, 0, frame.size.width-7, frame.size.height)];
		self.nameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
		self.nameLabel.textColor = [UIColor darkGrayColor];
		self.nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self addSubview:self.nameLabel];
		
		self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(7, 0, frame.size.width-7-7, frame.size.height)];
		self.dateLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
		self.dateLabel.textColor = [UIColor darkGrayColor];
		self.dateLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.dateLabel.textAlignment = NSTextAlignmentRight;
		[self addSubview:self.dateLabel];
    }
    return self;
}

- (void)setType:(int)type section:(int)section {
	
	int y = section == 0 ? 40 : 0;
	int h = self.frame.size.height+y;
	
	self.imageView.frame = CGRectMake(7, y+10, self.frame.size.height-20, self.frame.size.height-20);
	self.dateLabel.frame = CGRectMake(7, y, self.frame.size.width-7-7, h-y);
	self.dateLabel.text = @"";
	self.nameLabel.text = @"";
	
	switch (type) {
		case 0:
			self.nameLabel.frame = CGRectMake(7 + self.frame.size.height - 10, y, self.frame.size.width-7, h-y);
			self.imageView.hidden = NO;
			break;
		case 1:
			self.nameLabel.frame = CGRectMake(7 + self.frame.size.height - 10, y, self.frame.size.width-7, h-y);
			self.imageView.hidden = NO;
			break;
		case 2:
			self.nameLabel.frame = CGRectMake(7, y, self.frame.size.width-7, h-y);
			self.imageView.hidden = YES;
			break;
	}
}

@end
