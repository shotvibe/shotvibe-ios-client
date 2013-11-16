//
//  SVImagePickerController.m
//  shotvibe
//
//  Created by Baluta Cristian on 16/11/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVImagePickerController.h"
#import "SVDefines.h"

@implementation SVImagePickerController


- (void)viewDidLoad {
	[super viewDidLoad];
	
	if (IS_IOS7) {
		[self prefersStatusBarHidden];
		[self setNeedsStatusBarAppearanceUpdate];
	}
}

- (BOOL)prefersStatusBarHidden {
	RCLog(@"prefersStatusBarHidden");
	return YES;// setNeedsStatusBarAppearanceUpdate
}

- (UIViewController *)childViewControllerForStatusBarHidden {
	RCLog(@"childViewControllerForStatusBarHidden");
    return nil;
}


@end
