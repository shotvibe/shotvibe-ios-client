//
//  SVAlbumListViewCell.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/13/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCImageView.h"

@interface SVAlbumListViewCell : UITableViewCell

#pragma mark - Properties

@property (weak, nonatomic) IBOutlet RCImageView *networkImageView;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UIButton *timestamp;
@property (weak, nonatomic) IBOutlet UILabel *author;
@property (weak, nonatomic) IBOutlet UIButton *numberNotViewedIndicator;
@end
