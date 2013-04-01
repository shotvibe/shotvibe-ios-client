//
//  SVAlbumListViewCell.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/13/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NINetworkImageView.h"

@interface SVAlbumListViewCell : UITableViewCell

#pragma mark - Properties

@property (weak, nonatomic) IBOutlet NINetworkImageView *networkImageView;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UIButton *timestamp;
@end
