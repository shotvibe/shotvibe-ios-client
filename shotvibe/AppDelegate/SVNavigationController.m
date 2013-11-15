//
//  SVNavigationController.m
//  shotvibe
//
//  Created by Baluta Cristian on 11/11/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVNavigationController.h"
#import "SVDefines.h"
#import "SVPhotoViewerController.h"

@implementation SVNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	if (IS_IOS7) {
		
		self.navigationBar.tintColor = [UIColor whiteColor];
		self.navigationBar.barTintColor = BLUE;
		
		[self setNeedsStatusBarAppearanceUpdate];
	}
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
	return UIStatusBarAnimationFade;
}

- (BOOL)prefersStatusBarHidden {
	RCLog(@"prefersStatusBarHidden in last vc: %@", [self.viewControllers lastObject]);
	if ([[self.viewControllers lastObject] isKindOfClass:[SVPhotoViewerController class]]) {
		return [[self.viewControllers lastObject] prefersStatusBarHidden];
	}
	return NO;// setNeedsStatusBarAppearanceUpdate
}

@end
