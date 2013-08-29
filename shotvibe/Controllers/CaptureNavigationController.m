//
//  CaptureNavigationController.m
//  shotvibe
//
//  Created by John Gabelmann on 4/22/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "CaptureNavigationController.h"


@implementation CaptureNavigationController


- (id)init {

    self = [super init];
	if (self) {
	}
	return self;
}

- (void) setNav:(UINavigationController *)nav {
	_nav = nav;
	cameraController = [[SVCameraPickerController alloc] initWithNibName:@"SVCameraOverlay" bundle:[NSBundle mainBundle]];
	cameraController.delegate = self;
	cameraController.albums = self.albums;
	[nav pushViewController:cameraController animated:NO];
	self.selectedAlbum = [self.albums objectAtIndex:0];
}

#pragma mark SVCameraPicker delegates

- (void)cameraExit {
	
	[self.nav popViewControllerAnimated:YES];
	
	if ([self.cameraDelegate respondsToSelector:@selector(cameraExit)]) {
		[self.cameraDelegate cameraExit];
	}
	cameraController = nil;
}

- (void)cameraWasDismissedWithAlbum:(AlbumSummary*)album {
	
	self.selectedAlbum = album;
	[self.nav popViewControllerAnimated:YES];
	
//	if ([self.cameraDelegate respondsToSelector:@selector(cameraWasDismissedWithAlbum:)]) {
//		[self.cameraDelegate cameraWasDismissedWithAlbum:album];
//	}
}

@end
