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
        // Initialization code
		self.backgroundColor = [UIColor clearColor];
		NSLog(@"instantiate section");
		self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(7, 0, frame.size.width-7, frame.size.height)];
		self.dateLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
		self.dateLabel.textColor = [UIColor darkGrayColor];
		self.dateLabel.backgroundColor = [UIColor redColor];
		self.dateLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self addSubview:self.dateLabel];
		
    }
    return self;
}

@end
