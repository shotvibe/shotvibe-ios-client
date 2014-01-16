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
#import "MFSideMenu.h"

@implementation SVNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	if (IS_IOS7) {
		
		self.navigationBar.tintColor = [UIColor whiteColor];
		self.navigationBar.barTintColor = BLUE;
		
		[self setNeedsStatusBarAppearanceUpdate];
		
		// Disable going back by panning the vc to the right
		// It causes problems when the right side menu is open
		
		NSOperationQueue *queue = [[NSOperationQueue alloc] init];
		[[NSNotificationCenter defaultCenter] addObserverForName:MFSideMenuStateNotificationEvent
														  object:nil
														   queue:queue
													  usingBlock:^(NSNotification *note)
		 {
			 // This is called when you open and close the side menu
			 // 1 = did open
			 // 3 = did close
			 if ([note.userInfo[@"eventType"] integerValue] == 1) {
				 dispatch_async(dispatch_get_main_queue(), ^{
					 self.interactivePopGestureRecognizer.enabled = NO;
				 });
			 }
			 else if ([note.userInfo[@"eventType"] integerValue] == 3) {
				 dispatch_async(dispatch_get_main_queue(), ^{
					 self.interactivePopGestureRecognizer.enabled = YES;
				 });
			 }
		 }];
	}
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
	return UIStatusBarAnimationFade;
}

- (BOOL)prefersStatusBarHidden {
	//RCLog(@"prefersStatusBarHidden %@", [self.viewControllers lastObject]);
	if ([[self.viewControllers lastObject] isKindOfClass:[SVCameraPickerController class]]) {
		SVCameraPickerController *controller = [self.viewControllers lastObject];
		return [controller prefersStatusBarHidden];
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
