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
#import "SVCameraPickerController.h"

@implementation SVNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	if (IS_IOS7) {
		
		self.navigationBar.tintColor = [UIColor whiteColor];
		self.navigationBar.barTintColor = BLUE;
		
		[self setNeedsStatusBarAppearanceUpdate];
		
		// Disable going back by panning the vc to the right
		// It causes problems when the right side menu is open
		self.interactivePopGestureRecognizer.delegate = nil;
	}
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
	return UIStatusBarAnimationFade;
}

- (BOOL)prefersStatusBarHidden {
	
	if ([[self.viewControllers lastObject] isKindOfClass:[SVCameraPickerController class]]) {
		return YES;
	}
	else if ([[self.viewControllers lastObject] isKindOfClass:[SVPhotoViewerController class]]) {
		return [[self.viewControllers lastObject] prefersStatusBarHidden];
	}
	return NO;// setNeedsStatusBarAppearanceUpdate
}

- (UIViewController *)childViewControllerForStatusBarHidden {
//	if ([[self.viewControllers lastObject] isKindOfClass:[SVCameraPickerController class]]) {
//		return [self.viewControllers lastObject];
//	}
    return nil;
}


@end
