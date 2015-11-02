//
//  GLFeedViewController.h
//  shotvibe
//
//  Created by Tsah Kashkash on 26/10/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVNotificationHandler.h"


//#import ""
//#import ""
@interface GLFeedViewController : UITableViewController <NotificationManagerDelegate>

@property(nonatomic) long long int albumId;
@property (retain, nonatomic) NSMutableArray *posts;

@end
