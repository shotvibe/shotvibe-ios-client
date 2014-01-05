//
//  SVSettingsAboutViewController.h
//  shotvibe
//
//  Created by Baluta Cristian on 19/08/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVWebViewController.h"

@interface SVSettingsAboutViewController : UITableViewController

@property (nonatomic, weak) IBOutlet UILabel *versionLabel;
@property (nonatomic, weak) IBOutlet UILabel *gitInfoLabel;

@end
