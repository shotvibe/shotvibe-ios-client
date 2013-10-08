//
//  SVAlbumListViewCell.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/13/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCImageView.h"

@protocol SVAlbumListViewCellDelegate <NSObject>

-(void)releaseOnCamera;
-(void)releaseOnLibrary;

@end


@interface SVAlbumListViewCell : UITableViewCell <UIGestureRecognizerDelegate> {
	
	CGPoint _originalCenter;
	int _swipeStage;
}

#pragma mark - Properties


@property (strong, nonatomic) id<SVAlbumListViewCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIView *backView;
@property (weak, nonatomic) IBOutlet UIView *frontView;

@property (weak, nonatomic) IBOutlet UIImageView *backImageView;
@property (weak, nonatomic) IBOutlet RCImageView *networkImageView;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UIButton *timestamp;
@property (weak, nonatomic) IBOutlet UILabel *author;
@property (weak, nonatomic) IBOutlet UIButton *numberNotViewedIndicator;
@end
