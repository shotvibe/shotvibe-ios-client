//
//  SVNoCodeViewController.m
//  shotvibe
//
//  Created by Baluta Cristian on 31/07/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVNoCodeViewController.h"

@interface SVNoCodeViewController ()

@end

@implementation SVNoCodeViewController

#pragma mark - Actions

- (IBAction)registerButtonPressed:(id)sender
{
	[self.phoneNumberField resignFirstResponder];
	
	// Construct our phone number
	NSString *countryCode = [self.countryCodeLabel.text stringByReplacingOccurrencesOfString:@"+" withString:@""];
	NSString *phoneNumber = [countryCode stringByAppendingString:self.phoneNumberField.text];
	NSLog(@"countryCode  %@", countryCode);
	NBPhoneNumber *nbPhoneNumber = [[NBPhoneNumber alloc] init];
	nbPhoneNumber.countryCode = [countryCode integerValue];
	nbPhoneNumber.nationalNumber = [self.phoneNumberField.text integerValue];
	
	if ([[NBPhoneNumberUtil sharedInstance] isValidNumber:nbPhoneNumber]) {
		[self submitPhoneNumberRegistration:phoneNumber];
	}
	else
	{
		self.phoneNumberField.text = @"";
		
		UIAlertView *invalidNumberAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Number", @"") message:NSLocalizedString(@"Please enter a valid phone number.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles: nil];
		[invalidNumberAlert show];
	}
}


- (IBAction)countrySelectButtonPressed:(id)sender
{
	// showCountryPicker
	[self.phoneNumberField resignFirstResponder];
    [self performSegueWithIdentifier:@"ChoseCountrySegue" sender:nil];
}


- (IBAction)callmeButtonPressed:(id)sender {
	
	
}



#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
    if([SVBusinessDelegate hasUserBeenAuthenticated])
    {
		[self handleSuccessfulLogin];
    }
}
- (void)viewWillAppear:(BOOL)animated {
	
	self.countryCodeLabel.text = self.countryCode;
	self.phoneNumberField.text = self.phoneNumber;
	
}



- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - CountryPickerDelegate Methods

- (void)didSelectCountryWithName:(NSString *)name code:(NSString *)code
{
	NSLog(@"didselectcountry %@", name);
    // TODO: Handle setting the appropriate country phone code
    
    self.countryFlagView.image = [UIImage imageNamed:code];
    
    NSInteger countryCode = [[NBPhoneNumberUtil sharedInstance] getCountryCodeForRegion:code];
    
    self.countryCodeLabel.text = [NSString stringWithFormat:@"+%i", countryCode];
}


#pragma mark - UITextFieldDelegate Methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	if (!IS_IPHONE_5) {
		CGRect r = self.phoneNumberPhaseContainer.frame;
		r.origin.y -= 30;
		self.phoneNumberPhaseContainer.frame = r;
	}
}
- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if (!IS_IPHONE_5) {
		CGRect r = self.phoneNumberPhaseContainer.frame;
		r.origin.y = 0;
		self.phoneNumberPhaseContainer.frame = r;
	}
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	if (textField == self.phoneNumberField) {
		self.butContinue.enabled = (self.phoneNumberField.text.length > 0);
	}
	
    return YES;
}


#pragma mark - Private Methods

- (void)submitPhoneNumberRegistration:(NSString *)phoneNumber
{
	NSString *cc = [countries selectedCountryCode];
	if (cc == nil)
		cc = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
	
	NSLog(@"submit %@ %@", cc, phoneNumber);
	[SVBusinessDelegate registerPhoneNumber:phoneNumber withCountryCode:cc WithCompletion:^(BOOL success, NSString *confirmationCode, NSError *error) {
		
		NSLog(@"received confirmationCode %@", confirmationCode);
		
		if(success)
		{
			// if successful, this will take user to next part of registration, if not show warning or something to resend a valid phone number
			// Move this to completion handler once implemented
			
			self.confirmationCode = confirmationCode;
			
			[self.navigationController popViewControllerAnimated:YES];
		}
		else
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to register", @"")
															message:NSLocalizedString(@"Failed to register phone number.", @"")
														   delegate:nil
												  cancelButtonTitle:NSLocalizedString(@"OK", @"")
												  otherButtonTitles: nil];
			[alert show];
			
		}
		
	}];
}



- (void)handleSuccessfulLogin
{
	NSLog(@"handleSuccessfulLogin");
    [[SVDownloadSyncEngine sharedEngine] startSync];
    
    // Grab the storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    
    // Grab the deal and make it our root view controller from the storyboard for this navigation controller
    SVAlbumListViewController *rootView = [storyboard instantiateViewControllerWithIdentifier:@"SVAlbumListViewController"];
    
    [self.navigationController setViewControllers:@[rootView] animated:YES];
	
}

@end
