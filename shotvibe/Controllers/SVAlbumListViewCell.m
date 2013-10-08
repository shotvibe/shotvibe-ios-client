//
//  SVAlbumListViewCell.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/13/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVAlbumListViewCell.h"

@implementation SVAlbumListViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
		
		_swipeStage = 0;
		NSLog(@"init with style");
		self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}



- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	_originalCenter = [touch locationInView:self];
	[super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
	UITableView *parent = (UITableView *)self.superview;
    parent.scrollEnabled = NO;

	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self];
	int dx = location.x - _originalCenter.x;
	if (dx < 0) {
		self.frontView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
	}
	else {
		self.frontView.frame = CGRectMake(dx, 0, self.frame.size.width, self.frame.size.height);
		
		int dw = 40;
		if (dx > 40) {
			dw = dx;
			self.backView.alpha = 1;
		}
		else {
			self.backView.alpha = 0.5;
		}
		
		self.backView.frame = CGRectMake(0, 0, dw, self.frame.size.height);
		
		if (dx > 160 && _swipeStage == 0) {
			_swipeStage = 1;
			self.backImageView.image = [UIImage imageNamed:@"cameraRollIcon.png"];
			[UIView animateWithDuration:0.18 animations:^{
				self.backView.backgroundColor = [UIColor colorWithRed:1 green:0.44 blue:0.27 alpha:1];
			}];
		}
		else if (dx <= 160 && _swipeStage == 1) {
			_swipeStage = 0;
			self.backImageView.image = [UIImage imageNamed:@"cameraIcon.png"];
			[UIView animateWithDuration:0.18 animations:^{
				self.backView.backgroundColor = [UIColor colorWithRed:0.63 green:0.85 blue:0.07 alpha:1];
			}];
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
	UITableView *parent = (UITableView *)self.superview;
    parent.scrollEnabled = YES;
	
	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self];
	int dx = location.x - _originalCenter.x;
	
	if (self.frontView.frame.origin.x < 40) {
		[super touchesEnded:touches withEvent:event];
	}
	else {
		[super touchesCancelled:touches withEvent:event];
		
		if (dx > 160 && _swipeStage == 1) {
			[self.delegate releaseOnLibrary:self];
		}
		else if (dx <= 160 && _swipeStage == 0) {
			[self.delegate releaseOnCamera:self];
		}
	}
	
	_swipeStage = 0;
	
	[UIView animateWithDuration:0.18 animations:^{
		self.frontView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
	}];
}

@end
