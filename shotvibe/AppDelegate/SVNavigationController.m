//
//  SVNavigationController.m
//  shotvibe
//
//  Created by Baluta Cristian on 11/11/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVNavigationController.h"
#import "SVDefines.h"


@implementation SVNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	if (IS_IOS7) {
		
		self.navigationBar.tintColor = [UIColor blackColor];
		self.navigationBar.barTintColor = BLUE;
		
		[self setNeedsStatusBarAppearanceUpdate];
	}
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
	return NO;// setNeedsStatusBarAppearanceUpdate
}

@end
