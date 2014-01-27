//
//  SVAlbumListViewCell.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/13/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoView.h"

#define MIN_SWIPE_X 60

@protocol SVAlbumListViewCellDelegate <NSObject>
@required
- (void)cameraButtonTapped:(UITableViewCell *)cell;
- (void)libraryButtonTapped:(UITableViewCell *)cell;
- (void)selectCell:(UITableViewCell*)cell;

@end

extern NSString *const SVSwipeForOptionsCellEnclosingTableViewDidBeginScrollingNotification;

@interface SVAlbumListViewCell : UITableViewCell {
	
	CGPoint _originalCenter;
	int _swipeStage;
}

#pragma mark - Properties


@property (strong, nonatomic) id<SVAlbumListViewCellDelegate> delegate;
@property (strong, nonatomic) UITableView *parentTableView;

@property (weak, nonatomic) IBOutlet UIView *backView;
@property (weak, nonatomic) IBOutlet UIView *frontView;

@property (weak, nonatomic) IBOutlet UIImageView *backImageView;
@property (weak, nonatomic) IBOutlet PhotoView *networkImageView;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UIButton *timestamp;
@property (weak, nonatomic) IBOutlet UILabel *author;
@property (weak, nonatomic) IBOutlet UIButton *numberNotViewedIndicator;

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;

- (IBAction)CameraButton:(id)sender;
- (IBAction)PickerButton:(id)sender;

@end
