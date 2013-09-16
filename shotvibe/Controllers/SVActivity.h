//
//  SVActivity.h
//  shotvibe
//
//  Created by Baluta Cristian on 04/09/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SVActivity : UIActivity

@property (nonatomic, retain) UIViewController *controller;
@property (nonatomic, retain) NSString *sharingText;
@property (nonatomic, retain) NSURL *sharingUrl;
@property (nonatomic, retain) UIImage *sharingImage;

@end