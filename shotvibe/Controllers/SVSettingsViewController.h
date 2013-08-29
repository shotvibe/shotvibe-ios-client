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

@class AlbumSummary;

@interface SVSettingsViewController : UITableViewController <MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) AlbumSummary *currentAlbum;

- (IBAction)doLogout:(id)sender;

@end
