//
//  SVSaveImageActivity.m
//  shotvibe
//
//  Created by benny on 11/19/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

#import "SVSaveImageActivity.h"
#import "MediaHelper.h"

@implementation SVSaveImageActivity

- (NSString *)activityType
{
    return NSStringFromClass([self class]);
}


- (NSString *)activityTitle
{
    return NSLocalizedString(@"Save Image", @"");
}


- (UIImage *)activityImage
{
    return [UIImage imageNamed:@"IconSaveImage.png"];
}


- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    return YES;
}


- (void)prepareWithActivityItems:(NSArray *)activityItems
{
}


- (void)performActivity
{
    NSLog(@"Save Image");

    NSString *albumName = @"Glance Photos";

    if (self.sharingImage) {
        [MediaHelper saveImageToAlbum:self.sharingImage toAlbum:albumName withCompletionBlock:^(NSError *error) {
            NSString *title;
            NSString *message;
            if (error) {
                title = @"Error Saving Photo";
                message = [error localizedDescription];
            } else {
                title = @"Photo Saved";
                message = [NSString stringWithFormat:@"Photo Saved to Album: %@", albumName];
            }
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }];
    }
}


@end
