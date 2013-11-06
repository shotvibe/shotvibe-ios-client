//
//  SVAlbumListViewCell.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/13/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PhotoView.h"

@protocol SVAlbumListViewCellDelegate <NSObject>
@required
- (void)releaseOnCamera:(UITableViewCell*)cell;
- (void)releaseOnLibrary:(UITableViewCell*)cell;
@end


@interface SVAlbumListViewCell : UITableViewCell <UIGestureRecognizerDelegate> {
	
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
@end
