//
//  ConfirmationCodeViewController.m
//  shotvibe
//
//  Created by Baluta Cristian on 31/07/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVConfirmationCodeViewController.h"
#import "SVPushNotificationsManager.h"

@interface SVConfirmationCodeViewController ()

@end

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
        destination.confirmationCode = self.confirmationCode;
		destination.countryCode = self.countryCode;
		destination.phoneNumber = self.phoneNumber;
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


- (void)validateRegistrationCode:(NSString *)registrationCode
{
	NSLog(@"validateRegistrationCode - code:  %@", registrationCode);
	
    [SVBusinessDelegate validateRegistrationCode:registrationCode withConfirmationCode:self.confirmationCode WithCompletion:^(BOOL success, NSString *authToken, NSString *userId, NSError *error) {
        
        if(success)
        {
            // Move this to successful completion handler once implemented
            
            NSLog(@"authToken:  %@, userId:  %@", authToken, userId);
            
            [[NSUserDefaults standardUserDefaults] setObject:userId forKey:kApplicationUserId];
            [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"Token %@", authToken] forKey:kApplicationUserAuthToken];
            
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [[SVDownloadSyncEngine sharedEngine] start];
            
            [self handleSuccessfulLogin];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to validate", @"") message:NSLocalizedString(@"Failed to validate sms code", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles: nil];
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


- (void)handleSuccessfulLogin
{
	NSLog(@"handleSuccessfulLogin");
    //[[SVDownloadSyncEngine sharedEngine] startSync];
    
    // Grab the storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    
    // Grab the deal and make it our root view controller from the storyboard for this navigation controller
    SVAlbumListViewController *rootView = [storyboard instantiateViewControllerWithIdentifier:@"SVAlbumListViewController"];
    
    [self.navigationController setViewControllers:@[rootView] animated:YES];

    [SVPushNotificationsManager setup];
}

@end
