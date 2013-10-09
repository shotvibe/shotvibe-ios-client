//
//  SVProfileViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 4/16/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVProfileViewController.h"
#import "SVDefines.h"
#import "MBProgressHUD.h"
#import "RCImageView.h"

@interface SVProfileViewController ()

@property (nonatomic, strong) IBOutlet UITextField *nicknameField;
@property (nonatomic, strong) IBOutlet RCImageView *userPhoto;

- (IBAction)changeProfilePicture:(id)sender;

@end


@implementation SVProfileViewController



- (IBAction)changeProfilePicture:(id)sender {
	[self.nicknameField resignFirstResponder];
	[self performSegueWithIdentifier:@"ProfilePicSegue" sender:self];
}



- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"ProfilePicSegue"]) {
		
		SVProfilePicViewController *destination = segue.destinationViewController;
        destination.image = self.userPhoto.image;
		destination.delegate = self;
		destination.albumManager = self.albumManager;
    }
}


#pragma mark 

- (void) didCropImage:(UIImage*)image {
	
	RCLog(@"image did crop and save");
	self.userPhoto.image = image;
	[self.navigationController popToViewController:self animated:YES];
}



- (void)viewDidLoad
{
    [super viewDidLoad];
	
    NSAssert(self.albumManager, @"SVProfileViewController started without setting albumManager property");

    ShotVibeAPI *shotvibeAPI = [self.albumManager getShotVibeAPI];

    int64_t userId = shotvibeAPI.authData.userId;

    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error;
        AlbumMember *userProfile = [shotvibeAPI getUserProfile:userId withError:&error];

        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if (!userProfile) {
                // TODO Better error dialog with Retry option
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
//                                                                message:[error description]
//                                                               delegate:nil
//                                                      cancelButtonTitle:@"OK"
//                                                      otherButtonTitles:nil];
//                [alert show];
            }
            else {
                self.nicknameField.text = userProfile.nickname;
				[self.userPhoto loadNetworkImage:userProfile.avatarUrl];
            }
        });
    });
	
	self.title = @"Profile";
	
	NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	path = [path stringByAppendingString:@"/avatar.jpg"];
	self.userPhoto.image = [UIImage imageWithContentsOfFile:path];
}

#pragma mark - UITextFieldDelegate Method

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
	
    NSString *newNickname = [self.nicknameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
	
    ShotVibeAPI *shotvibeAPI = [self.albumManager getShotVibeAPI];
	
    int64_t userId = shotvibeAPI.authData.userId;
	
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		// Save nickname
        NSError *error;
        BOOL success = [shotvibeAPI setUserNickname:userId nickname:newNickname withError:&error];
		
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if (!success) {
                // TODO Better error dialog with Retry option
				//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
				//                                                                message:[error description]
				//                                                               delegate:nil
				//                                                      cancelButtonTitle:@"OK"
				//                                                      otherButtonTitles:nil];
				//                [alert show];
            }
            else {
				//self.navigationItem.rightBarButtonItem = nil;
				//nameChanged = NO;
            }
        });
    });
	
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	return YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[self.nicknameField resignFirstResponder];
	self.navigationItem.rightBarButtonItem = nil;
}

@end
