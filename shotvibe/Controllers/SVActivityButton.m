//
//  SVActivityButton.m
//  shotvibe
//
//  Created by Baluta Cristian on 04/09/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVActivityButton.h"

@implementation SVActivityButton
@synthesize label;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
		
		label = [[UILabel alloc] initWithFrame:CGRectMake(0, self.frame.size.height, self.frame.size.width, 20)];
		label.textColor = [UIColor darkGrayColor];
		label.numberOfLines = 1;
		label.textAlignment = NSTextAlignmentCenter;
		label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12];
		[self addSubview:label];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
