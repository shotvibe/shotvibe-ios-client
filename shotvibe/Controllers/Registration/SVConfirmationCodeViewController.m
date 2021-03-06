//
//  ConfirmationCodeViewController.m
//  shotvibe
//
//  Created by Baluta Cristian on 31/07/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVConfirmationCodeViewController.h"
#import "SVPushNotificationsManager.h"
#import "SVProfileViewController.h"
#import "ShotVibeAppDelegate.h"
#import "ShotVibeAPITask.h"
#import "SL/HTTPLib.h"
#import "IosHTTPLib.h"

@implementation SVConfirmationCodeViewController


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self.codeField1 becomeFirstResponder];

    [[Mixpanel sharedInstance] track:@"Activation Screen Viewed"];
}


- (IBAction)confirmButtonPressed:(id)sender
{
    [self.codeField1 resignFirstResponder];
	[self.codeField2 resignFirstResponder];
	[self.codeField3 resignFirstResponder];
	[self.codeField4 resignFirstResponder];
	
	// Construct the registration code
	NSString *regCode = [NSString stringWithFormat:@"%@%@%@%@", self.codeField1.text, self.codeField2.text, self.codeField3.text, self.codeField4.text];
	
	[self validateRegistrationCode:regCode];
}

- (void)validateRegistrationCode:(NSString *)registrationCode
{
	RCLog(@"validateRegistrationCode - code:  %@", registrationCode);

    [[Mixpanel sharedInstance] track:@"Activation Code Submitted"];

    id<SLHTTPLib> httpLib = [[IosHTTPLib alloc] init];

    [ShotVibeAPITask runTask:self

                  withAction:
     ^SLAuthData * {
        SLAuthData *authData = [SLShotVibeAPI confirmSMSCodeWithSLHTTPLib:httpLib
                                   withSLShotVibeAPI_SMSConfirmationToken:self.smsConfirmationToken
                                                             withNSString:registrationCode];
        return authData;
    }


              onTaskComplete:
     ^(SLAuthData *authData) {
        if (authData) {
            [[ShotVibeAppDelegate sharedDelegate] setAuthData:authData];
            [self handleSuccessfulLogin:YES];
        } else {
            [[Mixpanel sharedInstance] track:@"Activation Code Submitted Incorrect"];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Incorrect Code"
                                                            message:@"Please enter the code that was sent to you, or go back to check your phone number"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }];
}




#pragma mark TextField delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	if (self.codeField1.isFirstResponder)
	{
		self.codeField1.text = string;
		[self.codeField2 becomeFirstResponder];
	}
	else if (self.codeField2.isFirstResponder)
	{
		self.codeField2.text = string;
		[self.codeField3 becomeFirstResponder];
	}
	else if (self.codeField3.isFirstResponder)
	{
		self.codeField3.text = string;
		[self.codeField4 becomeFirstResponder];
	}
	else
	{
		self.codeField4.text = string;
		[self.codeField4 resignFirstResponder];
		self.butSubmit.enabled = YES;
	}
	
	return NO;
}


- (void)handleSuccessfulLogin:(BOOL)animated
{
	RCLog(@"handleSuccessfulLogin");

    [[Mixpanel sharedInstance] track:@"User Registered"];
    [[Mixpanel sharedInstance] track:@"User Registered (Manual)"];

    //[[SVDownloadSyncEngine sharedEngine] startSync];

    // Grab the storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    
    // Grab the deal and make it our root view controller from the storyboard for this navigation controller
    SVAlbumListViewController *rootView = [storyboard instantiateViewControllerWithIdentifier:@"SVAlbumListViewController"];

    SVProfileViewController *profileController = [storyboard instantiateViewControllerWithIdentifier:@"SVProfileViewController"];
    profileController.shouldPrompt = YES;

    UIView *v = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    v.backgroundColor = [UIColor whiteColor];
    [self.navigationController.view addSubview:v];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.navigationController setViewControllers:@[rootView, profileController] animated:NO];
        [v removeFromSuperview];

    });
}


#pragma mark Rotation

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
