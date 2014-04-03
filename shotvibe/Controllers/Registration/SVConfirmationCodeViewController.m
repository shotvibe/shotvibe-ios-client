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

@implementation SVConfirmationCodeViewController


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self.codeField1 becomeFirstResponder];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"NoCodeSegue"]) {
		SVNoCodeViewController *destination = (SVNoCodeViewController *)segue.destinationViewController;
		destination.albumManager = self.albumManager;
		destination.pushNotificationsManager = self.pushNotificationsManager;
		destination.phoneNumber = self.phoneNumber;
		[destination selectCountry:self.selectedCountryCode];
    }
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

static NSString * deviceDescription()
{
    UIDevice *currentDevice = [UIDevice currentDevice];
	return [NSString stringWithFormat:@"%@ (%@ %@)", [currentDevice model], [currentDevice systemName], [currentDevice systemVersion]];
}

- (void)validateRegistrationCode:(NSString *)registrationCode
{
	RCLog(@"validateRegistrationCode - code:  %@", registrationCode);

    UIAlertView *activityDialog = [[UIAlertView alloc] initWithTitle:@"Registering..." message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [activityDialog show];

    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    indicator.center = CGPointMake(activityDialog.bounds.size.width / 2, activityDialog.bounds.size.height - 50);
    [indicator startAnimating];
    [activityDialog addSubview:indicator];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error;
        ConfirmSMSCodeResult r = [[self.albumManager getShotVibeAPI] confirmSMSCode:registrationCode
                                                            deviceDeviceDescription:deviceDescription()
                                                                 defaultCountryCode:self.selectedCountryCode
                                                                              error:&error];

        dispatch_async(dispatch_get_main_queue(), ^{
            [activityDialog dismissWithClickedButtonIndex:0 animated:YES];
            if (r == ConfirmSMSCodeOk) {
                [self handleSuccessfulLogin:YES];
            }
            else if (r == ConfirmSMSCodeIncorrectCode) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Incorrect Code"
                                                                message:@"Please enter the code that was sent to you, or go back to check your phone number"
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            else if (r == ConfirmSMSCodeError) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:[error description]
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        });
    });
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
    //[[SVDownloadSyncEngine sharedEngine] startSync];

    // Now that AuthData is available this should be done:
    [self.albumManager authDataUpdated];
    
    // Grab the storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    
    // Grab the deal and make it our root view controller from the storyboard for this navigation controller
    SVAlbumListViewController *rootView = [storyboard instantiateViewControllerWithIdentifier:@"SVAlbumListViewController"];
    rootView.albumManager = self.albumManager;

    SVProfileViewController *profileController = [storyboard instantiateViewControllerWithIdentifier:@"SVProfileViewController"];
    profileController.shouldPrompt = YES;
    profileController.albumManager = self.albumManager;

    UIView *v = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    v.backgroundColor = [UIColor whiteColor];
    [self.navigationController.view addSubview:v];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.navigationController setViewControllers:@[rootView, profileController] animated:NO];
        [v removeFromSuperview];

    });
    
    [self.pushNotificationsManager setup];
    
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
