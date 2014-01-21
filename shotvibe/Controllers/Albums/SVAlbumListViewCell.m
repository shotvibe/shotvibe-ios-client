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
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        [self.scrollView setContentOffset:CGPointZero animated:NO];
    }


                   );
    [self.delegate selectCell:self];
}


- (IBAction)CameraButton:(id)sender
{
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        [self.scrollView setContentOffset:CGPointZero animated:NO];
    }


                   );
    [self.delegate releaseOnCamera:self];
}


- (IBAction)PickerButton:(id)sender
{
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        [self.scrollView setContentOffset:CGPointZero animated:NO];
    }


                   );
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


@end
