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
#import "UIImageView+WebCache.h"
#import "UserSettings.h"
#import "SL/ShotVibeAPI.h"
#import "SL/AlbumUser.h"
#import "ShotVibeAppDelegate.h"

@interface SVProfileViewController ()

@property (nonatomic, strong) IBOutlet UITextField *nicknameField;
@property (nonatomic, strong) IBOutlet UIImageView *userPhoto;
@property (nonatomic, strong) IBOutlet UILabel *promptLabel;
@property (nonatomic, strong) IBOutlet UIButton *continueButton;

@property (nonatomic) BOOL shouldSave;

- (IBAction)changeProfilePicture:(id)sender;

- (IBAction)handleContinueButtonPressed:(id)sender;

@end


@implementation SVProfileViewController



#pragma mark View lifecycle

- (void)viewDidLoad {
	
    [super viewDidLoad];
	
    self.title = NSLocalizedString(@"Profile", nil);
	
	NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	path = [path stringByAppendingString:@"/avatar.jpg"];
	self.userPhoto.image = [UIImage imageWithContentsOfFile:path];
	
	
    SLShotVibeAPI *shotvibeAPI = [[ShotVibeAppDelegate sharedDelegate].albumManager getShotVibeAPI];
    int64_t userId = [[shotvibeAPI getAuthData] getUserId];
	
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
	
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        SLAlbumUser *userProfile = nil;
        @try {
            userProfile = [shotvibeAPI getUserProfileWithLong:userId];
        } @catch (SLAPIException *exception) {
            // TODO: Shouldn't ignore this
        }

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
                self.nicknameField.text = [userProfile getMemberNickname];
                [self.userPhoto setImageWithURL:[NSURL URLWithString:[userProfile getMemberAvatarUrl]]];
                if (self.shouldPrompt) { // If we're prompting, focus on the name after it has been set
                    [self.nicknameField becomeFirstResponder];
                }
            }
        });
    });
}


- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

    if (IS_IOS7) {
		self.navigationController.navigationBar.translucent = NO;
	}

    if ([self shouldPrompt]) { // Prompt the user for a nick change and don't allow him to go back until he does
        self.navigationItem.title = NSLocalizedString(@"Set your profile", nil);
        self.navigationItem.hidesBackButton = YES;
        self.promptLabel.hidden = NO;
        self.nicknameField.enablesReturnKeyAutomatically = YES;
        self.continueButton.hidden = NO;
    }
    
    self.shouldSave = YES;
}

- (void) viewWillDisappear:(BOOL)animated {
	
	[super viewWillDisappear:animated];
	
	if (IS_IOS7) {
		self.navigationController.navigationBar.translucent = YES;
	}
}

#pragma mark Actions

- (IBAction)changeProfilePicture:(id)sender {
	
    self.shouldSave = NO;
	[self.nicknameField resignFirstResponder];
	[self performSegueWithIdentifier:@"ProfilePicSegue" sender:self];
}


- (IBAction)handleContinueButtonPressed:(id)sender
{
    // TODO: Having to press this after pressing Done on the keyboard is awkward, but
    // when improving this behavior, we have to make sure the nickname is always first
    // responder, except before the server update is received. (which may happen while in
    // the profile pic selection screen)
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	
	if ([segue.identifier isEqualToString:@"ProfilePicSegue"]) {
		
		SVProfilePicViewController *destination = segue.destinationViewController;
        destination.image = self.userPhoto.image;
        destination.delegate = self;

		// Set the text of the back button of the next screen
		UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle: @"Back" style: UIBarButtonItemStyleBordered target: nil action: nil];
		[self.navigationItem setBackBarButtonItem:newBackButton];
    }
}


#pragma mark ImageCrop Delegate

- (void) didCropImage:(UIImage*)image {
	
	self.userPhoto.image = image;
	[self.navigationController popToViewController:self animated:YES];
}


#pragma mark - UITextFieldDelegate Method

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


- (void)textFieldDidBeginEditing:(UITextField *)textField
{
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (self.shouldSave) {

        [textField resignFirstResponder];
        
        NSString *newNickname = [self.nicknameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        SLShotVibeAPI *shotvibeAPI = [[ShotVibeAppDelegate sharedDelegate].albumManager getShotVibeAPI];
        
        int64_t userId = [[shotvibeAPI getAuthData] getUserId];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            // Save nickname
            BOOL success = NO;
            @try {
                [shotvibeAPI setUserNicknameWithLong:userId withNSString:newNickname];
                success = YES;
            } @catch (SLAPIException *exception) {
                // TODO Better error handling
            }

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
                    if (self.shouldPrompt) {
                        [UserSettings setNicknameSet:NO]; // since the update failed, we revert this setting, so the user will be prompted again later
                    }
                }
                else {
                    //self.navigationItem.rightBarButtonItem = nil;
                    //nameChanged = NO;
                    [self handleContinueButtonPressed:nil];
                }
            });
        });
        [UserSettings setNicknameSet:YES];
    }
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	return YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.nicknameField resignFirstResponder];
    self.navigationItem.rightBarButtonItem = nil;
}

- (BOOL)shouldAutorotate
{
    return NO;
}


- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}


@end
