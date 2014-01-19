//
//  SVAlbumListViewCell.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/13/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVAlbumListViewCell.h"
#import "SVDefines.h"

NSString *const SVSwipeForOptionsCellEnclosingTableViewDidBeginScrollingNotification = @"SVSwipeForOptionsCellEnclosingTableViewDidScrollNotification";

@implementation SVAlbumListViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}


- (void)setup
{
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.contentView.bounds) + CGRectGetWidth(self.backView.bounds), CGRectGetHeight(self.contentView.bounds) - 2);
    self.scrollView.showsHorizontalScrollIndicator = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enclosingTableViewDidScroll:) name:SVSwipeForOptionsCellEnclosingTableViewDidBeginScrollingNotification object:nil];
    
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(Select:)];
    [self.scrollView addGestureRecognizer:recognizer];
}


- (IBAction)Select:(id)sender
{
    [self.delegate selectCell:self];
}


- (IBAction)CameraButton:(id)sender
{
    [self.delegate releaseOnCamera:self];
}


- (IBAction)PickerButton:(id)sender
{
    [self.delegate releaseOnLibrary:self];
}


- (void)enclosingTableViewDidScroll:(NSNotification *)notification
{
    if ([notification object] != self) {
        [self.scrollView setContentOffset:CGPointZero animated:YES];
    }
}


- (void)prepareForReuse
{
    [super prepareForReuse];

    [self.scrollView setContentOffset:CGPointZero animated:NO];
}


#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SVSwipeForOptionsCellEnclosingTableViewDidBeginScrollingNotification object:self];
}


- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    //If scrolling more than 0.5, or closing, it will show completely the back view
    if ((scrollView.contentOffset.x > self.backView.frame.size.width * 0.5) && ([scrollView.panGestureRecognizer velocityInView:scrollView].x < 0)) {
        targetContentOffset->x = self.backView.frame.size.width, 0;
    } else {
        
        *targetContentOffset = CGPointZero;

        // Need to call this subsequently to remove flickering. Strange.
        dispatch_async(dispatch_get_main_queue(), ^{
            [scrollView setContentOffset:CGPointZero animated:YES];
        });
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    //Making the back view stand still when the scrollview is moved.
    if (scrollView.contentOffset.x < 0) {
        scrollView.contentOffset = CGPointZero;
    }
    
    self.backView.frame = CGRectMake(scrollView.contentOffset.x + (CGRectGetWidth(self.bounds) - self.backView.frame.size.width), 0.0f, self.backView.frame.size.width, CGRectGetHeight(self.bounds));
}

//-----------------------------------
/*
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
		
		_swipeStage = 0;
		self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	
	UITouch *touch = [touches anyObject];
	_originalCenter = [touch locationInView:self];
	
	self.backView.backgroundColor = [UIColor colorWithRed:0.63 green:0.85 blue:0.07 alpha:1];
	self.backImageView.image = [UIImage imageNamed:@"SwipePicker.png"];
	
	[super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
	self.parentTableView.scrollEnabled = NO;

	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self];
	int dx = location.x - _originalCenter.x;
	if (dx < 0) {
		self.frontView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
	}
	else {
		self.frontView.frame = CGRectMake(dx, 0, self.frame.size.width, self.frame.size.height);
		
		int dw = MIN_SWIPE_X;
		if (dx > MIN_SWIPE_X) {
			dw = dx;
			self.backView.alpha = 1;
		}
		else {
			self.backView.alpha = 0.5;
		}
		
		self.backView.frame = CGRectMake(0, 0, dw, self.frame.size.height);
		
		if (dx > 160 && _swipeStage == 0) {
			_swipeStage = 1;
			self.backImageView.image = [UIImage imageNamed:@"SwipeCamera.png"];
			[UIView animateWithDuration:0.28 animations:^{
				self.backView.backgroundColor = [UIColor colorWithRed:1 green:0.44 blue:0.27 alpha:1];
			}];
		}
		else if (dx <= 160 && _swipeStage == 1) {
			_swipeStage = 0;
			self.backImageView.image = [UIImage imageNamed:@"SwipePicker.png"];
			[UIView animateWithDuration:0.28 animations:^{
				self.backView.backgroundColor = [UIColor colorWithRed:0.63 green:0.85 blue:0.07 alpha:1];
			}];
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
	self.parentTableView.scrollEnabled = YES;
	
	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self];
	int dx = location.x - _originalCenter.x;
	
	if (self.frontView.frame.origin.x < 4) {
		[super touchesEnded:touches withEvent:event];
	}
	else if (self.frontView.frame.origin.x < MIN_SWIPE_X) {
		if (IS_IOS7) {
			// On ios7
			[super touchesCancelled:touches withEvent:event];
		}
		else {
			[super touchesEnded:touches withEvent:event];
		}
	}
	else {
		[super touchesCancelled:touches withEvent:event];
		
		if (dx > 160 && _swipeStage == 1) {
			[self.delegate releaseOnCamera:self];
		}
		else if (dx <= 160 && _swipeStage == 0) {
			[self.delegate releaseOnLibrary:self];
		}
	}
	
	_swipeStage = 0;
	
	[UIView animateWithDuration:0.18 animations:^{
		self.frontView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
	}];
}
*/

@end
