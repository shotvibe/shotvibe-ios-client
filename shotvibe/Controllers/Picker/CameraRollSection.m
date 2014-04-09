//
//  CameraRollSection.m
//  shotvibe
//
//  Created by Baluta Cristian on 21/08/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "CameraRollSection.h"

#define kButtonWidth 26

@implementation CameraRollSection

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code

        UIView *bg = [[UIView alloc] initWithFrame:CGRectMake(-1, 9, frame.size.width + 2, kButtonWidth + 16)];
        bg.backgroundColor = [UIColor whiteColor];
        bg.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1].CGColor;
        bg.layer.borderWidth = 0.6;
        bg.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:bg];

        self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(26, 9, frame.size.width - 30, kButtonWidth + 16)];
        self.dateLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        self.dateLabel.textColor = [UIColor lightGrayColor];
        self.dateLabel.backgroundColor = [UIColor clearColor];
        self.dateLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:self.dateLabel];

        UIImageView *calendarIcon = [[UIImageView alloc] initWithFrame:CGRectMake(7, 25, 12, 12)];
        calendarIcon.image = [UIImage imageNamed:@"IconCalendar"];
        [self addSubview:calendarIcon];

        self.selectButton = [[UIButton alloc] initWithFrame:CGRectMake(frame.size.width - kButtonWidth - 7 - 8, 9, kButtonWidth + 16, kButtonWidth + 16)];
        self.selectButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self.selectButton addTarget:self action:@selector(checkmarkTouched) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.selectButton];
//		[self selectCheckmark:NO];

        UIView *locationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, kButtonWidth + 16)];
        locationView.hidden = YES;
        [self addSubview:locationView];

        UIImageView *locationIcon = [[UIImageView alloc] initWithFrame:CGRectMake(7, 25, 9, 12)];
        locationIcon.image = [UIImage imageNamed:@"iconLocation"];
        [locationView addSubview:locationIcon];

        self.locationLabel = [[UILabel alloc] initWithFrame:CGRectMake(26, 9, frame.size.width - 30, kButtonWidth + 16)];
        self.locationLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        self.locationLabel.textColor = [UIColor lightGrayColor];
        self.locationLabel.backgroundColor = [UIColor clearColor];
        self.locationLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [locationView addSubview:self.locationLabel];
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

- (void)setDateText:(NSString *)s
{
    self.dateLabel.text = s;
    CGSize size = [s sizeWithFont:self.dateLabel.font];

    UIView *locationView = self.locationLabel.superview;
    CGRect frame = locationView.frame;
    frame.origin.x = self.dateLabel.frame.origin.x + size.width + 7;
    frame.size.width = self.selectButton.frame.origin.x - frame.origin.x;
    locationView.frame = frame;
}


- (void)prepareForReuse
{
    self.locationLabel.superview.hidden = YES;
}


@end
