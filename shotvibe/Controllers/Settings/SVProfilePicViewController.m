//
//  SVProfilePicViewController.m
//  shotvibe
//
//  Created by Baluta Cristian on 17/09/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVProfilePicViewController.h"
#import "SVDefines.h"
#import "MBProgressHUD.h"
#import "UIImage+Scale.h"
#import "ShotVibeAppDelegate.h"
#import "SL/ShotVibeAPI.h"
#import "SL/AuthData.h"
#import "SL/AlbumSummary.h"
#import "ShotVibeAPITask.h"

@implementation SVProfilePicViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = NSLocalizedString(@"Profile picture", @"");

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit", @"")
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(editButtonPressed)];
    self.navigationItem.rightBarButtonItem = doneButton;
    imageView.image = self.image;
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (BOOL)shouldAutorotate
{
    return YES;
}


- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}


- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}


#pragma mark Actions

- (void)editButtonPressed
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose a new profile picture from"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Camera", @"Phone Gallery", nil];
    [actionSheet showFromRect:self.view.frame inView:self.view animated:YES];
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *choice = [actionSheet buttonTitleAtIndex:buttonIndex];
    if (buttonIndex == [actionSheet destructiveButtonIndex]) {
        // destroy something
        RCLog(@"Destroy");
    } else if ([choice isEqualToString:@"Camera"]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;

        [self presentViewController:picker animated:YES completion:NULL];
    } else if ([choice isEqualToString:@"Phone Gallery"]) {
        // do something else
        [self performSegueWithIdentifier:@"PhoneGallerySegue" sender:self];
    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"PhoneGallerySegue"]) {
        UINavigationController *destinationNavigationController = (UINavigationController *)segue.destinationViewController;

        SVImagePickerListViewController *destination = [destinationNavigationController.viewControllers objectAtIndex:0];
        destination.oneImagePicker = YES;
        destination.delegate = self;
    }
}


#pragma mark - UIImagePickerControllerDelegate

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *originalImage = [info valueForKey:UIImagePickerControllerEditedImage];
    [self didSelectPhoto:originalImage];
    [self.navigationController.visibleViewController dismissViewControllerAnimated:YES completion:^{}
    ];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:NULL];
}


- (void)didSelectPhoto:(UIImage *)thePhoto
{
    RCLog(@"didSelectPhoto %@", thePhoto);

    UIImage *scaledImage = [thePhoto imageByScalingAndCroppingForSize:CGSizeMake(320, 320)];

    imageView.image = scaledImage;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.title = NSLocalizedString(@"Uploading picture", @"");

    // Save image to disk
    NSError *err;
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    path = [path stringByAppendingString:@"/avatar.jpg"];
    [UIImageJPEGRepresentation(scaledImage, 0.9) writeToFile:path options:YES error:&err];

    if (err) {
        RCLog(@"some error ocured while saving the avatar to disk");
        return;
    }

    SLShotVibeAPI *shotvibeAPI = [[ShotVibeAppDelegate sharedDelegate].albumManager getShotVibeAPI];

    int64_t userId = [[shotvibeAPI getAuthData] getUserId];

    // Save avatar
    [ShotVibeAPITask runTask:self

                  withAction:
     ^id {
        [shotvibeAPI uploadUserAvatarWithLong:userId withNSString:path];

        return nil;
    }


              onTaskComplete:
     ^(id dummy) {
        if ([self.delegate respondsToSelector:@selector(didCropImage:)]) {
            [self.delegate didCropImage:scaledImage];
        }
    }];
}


- (void)didCropImage:(UIImage *)image
{
    [self didSelectPhoto:image];
    [self.navigationController.visibleViewController dismissViewControllerAnimated:YES completion:^{
    }


    ];
}


#pragma mark camera delegate

- (void)cameraExit
{
    RCLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> cameraExit");
}


- (void)cameraWasDismissedWithAlbum:(SLAlbumSummary *)selectedAlbum
{
    RCLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> cameraWasDismissedWithAlbum %@", [selectedAlbum getName]);
}


@end
