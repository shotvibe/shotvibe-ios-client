//
//  CameraRollSection.m
//  shotvibe
//
//  Created by Baluta Cristian on 21/08/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "CameraRollSection.h"

@implementation CameraRollSection

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
		
		self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(-1, 9, frame.size.width+2, 26+6)];
		self.dateLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
		self.dateLabel.textColor = [UIColor darkGrayColor];
		self.dateLabel.backgroundColor = [UIColor whiteColor];
		self.dateLabel.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1].CGColor;
		self.dateLabel.layer.borderWidth = 0.6;
		self.dateLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self addSubview:self.dateLabel];
		
		UIImageView *calendarIcon = [[UIImageView alloc] initWithFrame:CGRectMake(7, 19, 12, 12)];
		calendarIcon.image = [UIImage imageNamed:@"IconCalendar"];
		[self addSubview:calendarIcon];
		
		self.selectButton = [[UIButton alloc] initWithFrame:CGRectMake(frame.size.width-26-7, 12, 26, 26)];
		self.selectButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		[self.selectButton addTarget:self action:@selector(checkmarkTouched) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:self.selectButton];
//		[self selectCheckmark:NO];
    }
    return self;
}

- (void)checkmarkTouched {
	
	if ([self.delegate respondsToSelector:@selector(sectionCheckmarkTouched:)]) {
		[self.delegate performSelector:@selector(sectionCheckmarkTouched:) withObject:self];
	}
}

- (void)selectCheckmark:(BOOL)s {
	[self.selectButton setImage:[UIImage imageNamed:s?@"imageSelected.png":@"imageUnselected.png"] forState:UIControlStateNormal];
}

@end
