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
		
		self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(7, 0, frame.size.width-7, frame.size.height)];
		self.dateLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
		self.dateLabel.textColor = [UIColor darkGrayColor];
		self.dateLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self addSubview:self.dateLabel];
    }
    return self;
}

- (void)setType:(int)type {
	
	switch (type) {
		case 0:
			self.dateLabel.frame = CGRectMake(7, 0, self.frame.size.width-7, self.frame.size.height);
			self.imageView.hidden = YES;
			break;
			
		case 1:
			self.dateLabel.frame = CGRectMake(7 + self.frame.size.height - 10, 0, self.frame.size.width-7, self.frame.size.height);
			self.imageView.hidden = NO;
			break;
	}
}

@end
