//
//  CaptureNavigationController.m
//  shotvibe
//
//  Created by John Gabelmann on 4/22/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVCameraNavController.h"
#import "SVAlbumGridViewController.h"
#import "SVDefines.h"

@implementation SVCameraNavController


- (void) setNav:(SVNavigationController *)nav {
	
	NSAssert(self.cameraDelegate != nil, @"SVCameraNavController setNav should be called last, after you set cameraDelegate");
	RCLog(@"%lli", self.albumId);
	_nav = nav;
	
	cameraController = [[SVCameraPickerController alloc] initWithNibName:@"SVCameraOverlay" bundle:[NSBundle mainBundle]];
	cameraController.delegate = self;
	cameraController.albums = self.albums;
	cameraController.albumId = self.albumId;
	cameraController.albumManager = self.albumManager;
	
	[_nav pushViewController:cameraController animated:NO];
	
	self.selectedAlbum = [self.albums objectAtIndex:0];
}

#pragma mark SVCameraPicker delegates

- (void)cameraExit {
	
	self.selectedAlbum = nil;
	
	[self.nav popViewControllerAnimated:NO];
	
	if ([self.cameraDelegate respondsToSelector:@selector(cameraExit)]) {
		[self.cameraDelegate cameraExit];
	}
	cameraController = nil;
}

- (void)cameraWasDismissedWithAlbum:(AlbumSummary*)album {
	
	self.selectedAlbum = album;
	self.imageWasTaken = YES;
	int64_t albumId = self.albumId > 0 ? self.albumId : album.albumId;
	
	// Insert the AlbumGrid controller before the CameraPicker controller
	RCLog(@"-------------------------- 2. cameraWasDismissedWithAlbum %@ %lli %lli", album, album.albumId, self.albumId);
	
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
	SVAlbumGridViewController *controller = (SVAlbumGridViewController*)[mainStoryboard instantiateViewControllerWithIdentifier:@"SVAlbumGridViewController"];
	controller.albumManager = self.albumManager;
	controller.albumId = albumId;
	controller.scrollToTop = YES;
	
	// Should be 2 controllers, SVAlbumListViewController and SVCameraPickerController.
	NSMutableArray *controllers = [NSMutableArray arrayWithArray:self.nav.viewControllers];
	RCLogO(controllers);
	NSAssert(controllers.count==2, @"SVCameraNavController should be 2 controllers here");
	
	[controllers insertObject:controller atIndex:1];
	
	[self.nav setViewControllers:controllers];
	
	// Dismiss this controller from the main navigation
	[cameraController.navigationController popViewControllerAnimated:YES];
	
	NSDictionary *userInfo = @{@"albumId":[NSNumber numberWithLongLong:albumId]};
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATIONCENTER_ALBUM_CHANGED object:nil userInfo:userInfo];
	
//	if ([self.cameraDelegate respondsToSelector:@selector(cameraWasDismissedWithAlbum:)]) {
//		[self.cameraDelegate cameraWasDismissedWithAlbum:album];
//	}
}

@end
