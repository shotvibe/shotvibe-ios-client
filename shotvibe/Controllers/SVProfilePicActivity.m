//
//  SVProfilePicActivity.m
//  shotvibe
//
//  Created by Baluta Cristian on 27/10/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVProfilePicActivity.h"

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

-(BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
	return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
	
}

- (void)performActivity
{
	if (self.sharingImage) {
		NSData *imageData = UIImageJPEGRepresentation(self.sharingImage, 0.75f);
		[[UIPasteboard generalPasteboard] setData:imageData
								forPasteboardType:[UIPasteboardTypeListImage objectAtIndex:0]];
	}
}

@end
