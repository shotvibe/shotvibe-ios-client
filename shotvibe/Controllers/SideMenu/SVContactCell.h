//
//  SVContactCell.h
//  shotvibe
//
//  Created by Baluta Cristian on 20/08/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SVContactCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingSpinner;
@property (nonatomic, retain) IBOutlet UIImageView *isMemberImage;
@property (nonatomic, retain) IBOutlet UIImageView *contactIcon;
@property (nonatomic, retain) IBOutlet UIImageView *checkmarkImage;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UILabel *subtitleLabel;
@property (nonatomic) long long int albumId;

@end
