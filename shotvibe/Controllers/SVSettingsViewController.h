//
//  SVSettingsViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 4/16/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import <UIKit/UIKit.h>
#import "SVWebViewController.h"

@class Album;

@interface SVSettingsViewController : UITableViewController <MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) Album *currentAlbum;

- (IBAction)doLogout:(id)sender;

@end
