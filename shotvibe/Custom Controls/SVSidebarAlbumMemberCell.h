//
//  SVSidebarAlbumMemberCell.h
//  shotvibe
//
//  Created by John Gabelmann on 4/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NINetworkImageView.h"

@interface SVSidebarAlbumMemberCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *memberLabel;
@property (nonatomic, strong) IBOutlet NINetworkImageView *profileImageView;

@end
