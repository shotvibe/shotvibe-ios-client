//
//  SVAlbumListViewCell.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/13/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVAlbumListViewCell.h"
#import "SVDefines.h"
#import "ShotVibeAppDelegate.h"

NSString *const SVSwipeForOptionsCellEnclosingTableViewDidBeginScrollingNotification = @"SVSwipeForOptionsCellEnclosingTableViewDidScrollNotification";

@implementation SVAlbumListViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}


- (void)dealloc
{
    @try {
        [self removeObserver:self forKeyPath:@"scrollView.frame"];
    } @catch (NSException *exception) {
    }
}


- (void)adjustScrollViewContentSize
{
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.contentView.bounds) + CGRectGetWidth(self.backView.bounds), CGRectGetHeight(self.contentView.bounds) - 2);
}


- (void)setup
{
    // We need the tap gesture as the scrollView is intercepting all the touches, and it would be impossible
    // to select a cell;
    // We set the backview (camera/picture buttons) within the scrollView, and not behind, for the same reason,
    // it would have been untouchable
    self.scrollView.scrollEnabled = NO;

    self.networkImageView.layer.cornerRadius = self.networkImageView.frame.size.width/2;
    [self adjustScrollViewContentSize];
    self.scrollView.showsHorizontalScrollIndicator = NO;

    [self addObserver:self forKeyPath:@"scrollView.frame" options:NSKeyValueObservingOptionNew context:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enclosingTableViewDidScroll:) name:SVSwipeForOptionsCellEnclosingTableViewDidBeginScrollingNotification object:nil];

    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(Select:)];
    [self.scrollView addGestureRecognizer:recognizer];

    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.accessoryType = UITableViewCellAccessoryNone;
    
    
    
}


- (void)slideBackToOriginalPosition
{
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    // *INDENT-OFF* Uncrustify block problem: https://github.com/bengardner/uncrustify/pull/233
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        [self.scrollView setContentOffset:CGPointZero animated:NO];
    });
    // *INDENT-ON*
}


- (IBAction)Select:(id)sender
{
    [self slideBackToOriginalPosition];
    [self.delegate selectCell:self];
}


- (IBAction)CameraButton:(id)sender
{
    [self slideBackToOriginalPosition];
    if ([self.delegate respondsToSelector:@selector(cameraButtonTapped:)]) {
        [self.delegate cameraButtonTapped:self];
    }
}


- (IBAction)PickerButton:(id)sender
{
    [self slideBackToOriginalPosition];
    if ([self.delegate respondsToSelector:@selector(libraryButtonTapped:)]) {
        [self.delegate libraryButtonTapped:self];
    }
}


- (void)enclosingTableViewDidScroll:(NSNotification *)notification
{
    //This notification is sent by the table view, when scrolled we want to close the cells
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
    //Let's close all the other cells when opening a new one
    [[NSNotificationCenter defaultCenter] postNotificationName:SVSwipeForOptionsCellEnclosingTableViewDidBeginScrollingNotification object:self];
}


- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    //If scrolling more than 0.5, or closing, it will show completely the back view
    if ((scrollView.contentOffset.x > self.backView.frame.size.width * 0.5) && ([scrollView.panGestureRecognizer velocityInView:scrollView].x < 0)) {
        targetContentOffset->x = self.backView.frame.size.width;
    } else {
        *targetContentOffset = CGPointZero;

        // Need to call this subsequently to remove flickering. Strange.
        dispatch_async(dispatch_get_main_queue(), ^{
            [scrollView setContentOffset:CGPointZero animated:YES];
        }


                       );
    }
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //Making the back view stand still when the scrollview is moved.
    if (scrollView.contentOffset.x < 0) {
        scrollView.contentOffset = CGPointZero;
    }

    self.backView.frame = CGRectMake(scrollView.contentOffset.x + (CGRectGetWidth(self.bounds) - self.backView.frame.size.width), 0.0f, self.backView.frame.size.width, CGRectGetHeight(self.bounds));
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"scrollView.frame"] && (object == self)) {
        [self adjustScrollViewContentSize];
    }
}


@end
