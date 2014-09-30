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
#import "ShotVibeAPITask.h"
#import "SL/AuthData.h"
#import "SL/ShotVibeAPI.h"

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
	
	
	ShotVibeAppDelegate *app = [ShotVibeAppDelegate sharedDelegate];
    SLShotVibeAPI *shotvibeAPI = [app.albumManager getShotVibeAPI];
	
    int64_t userId = [[shotvibeAPI getAuthData] getUserId];

    [ShotVibeAPITask runTask:self.controller
                  withAction:
     ^id {
        [shotvibeAPI uploadUserAvatarWithLong:userId withNSString:path];
        return nil;
    }


              onTaskComplete:
     ^(id dummy) {
        [self.delegate closeAndClean:YES];
        [self.controller.navigationController popViewControllerAnimated:YES];
    }];
}


@end
