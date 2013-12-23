//
//  SVProfilePicActivity.m
//  shotvibe
//
//  Created by Baluta Cristian on 27/10/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVProfilePicActivity.h"
#import "MBProgressHUD.h"
#import "UIImage+Scale.h"
#import "ShotVibeAppDelegate.h"

@implementation SVProfilePicActivity


- (NSString *)activityType {
    return NSStringFromClass([self class]);
}

- (NSString *)activityTitle {
    return NSLocalizedString(@"Profile Pic", @"");
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"IconUser.png"];
}

-(BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
	return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
	
}

- (void)performActivity {
	
	if (self.sharingImage) {
		NSData *imageData = UIImageJPEGRepresentation(self.sharingImage, 0.75f);
		
		SVImageCropViewController *cropController = [[SVImageCropViewController alloc] initWithNibName:@"SVImageCropViewController"
																								bundle:[NSBundle mainBundle]];
		cropController.delegate = self;
		cropController.image = [UIImage imageWithData:imageData];
		[self.controller.navigationController pushViewController:cropController animated:YES];
	}
}

- (BOOL)canClose {
	return NO;
}


#pragma mark SVImageCropDelegate

- (void) didCropImage:(UIImage*)image {
	RCLogO(@"Choose pressed");
	
	UIImage *scaledImage = [image imageByScalingAndCroppingForSize:CGSizeMake(320, 320)];
	
	//self.controller.navigationController.rightBarButtonItem.enabled = NO;
	self.controller.navigationController.visibleViewController.title = NSLocalizedString(@"Saving avatar...", @"");
	
	// Save image to disk
	NSError *err;
	NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	path = [path stringByAppendingString:@"/avatar.jpg"];
	[UIImageJPEGRepresentation(scaledImage, 0.9) writeToFile:path options:NSAtomicWrite error:&err];
	
	if (err) {
		RCLog(@"some error ocured while saving the avatar to disk");
		return;
	}
	
	
	[MBProgressHUD showHUDAddedTo:self.controller.navigationController.visibleViewController.view animated:YES];
	
	ShotVibeAppDelegate *app = [ShotVibeAppDelegate sharedDelegate];
    ShotVibeAPI *shotvibeAPI = [app.albumManager getShotVibeAPI];
	
    int64_t userId = shotvibeAPI.authData.userId;
	
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		// Save avatar
		NSError *error2;
		[shotvibeAPI uploadUserAvatar:userId filePath:path uploadProgress:^(int i, int j){
			RCLog(@"upload avatar %i %i", i, j);
		} withError:&error2];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[MBProgressHUD hideHUDForView:self.controller.navigationController.visibleViewController.view animated:YES];
			[self.delegate closeAndClean:YES];
			[self.controller.navigationController popViewControllerAnimated:YES];
		});
	});
}


@end
