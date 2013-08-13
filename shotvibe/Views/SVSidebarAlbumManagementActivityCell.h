//
//  SVSidebarAlbumManagementActivityCell.h
//  shotvibe
//
//  Created by Baluta Cristian on 02/08/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCImageView.h"

@interface SVSidebarAlbumManagementActivityCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *memberLabel;
@property (nonatomic, strong) IBOutlet RCImageView *profileImageView;
@property (nonatomic, strong) IBOutlet UIImageView *icon;

@end
