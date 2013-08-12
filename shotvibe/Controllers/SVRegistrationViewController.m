//
//  SVRegistrationViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 4/30/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVRegistrationViewController.h"
#import "SVAlbumListViewController.h"
#import "NBPhoneNumberUtil.h"
#import "NBPhoneNumber.h"
#import "SVBusinessDelegate.h"
#import "SVDefines.h"

@interface SVRegistrationViewController ()

@property (nonatomic, strong) IBOutlet UIButton *butContinue;
@property (nonatomic, strong) IBOutlet UIView *phoneNumberPhaseContainer;
@property (nonatomic, strong) IBOutlet UIImageView *countryFlagView;
@property (nonatomic, strong) IBOutlet UITextField *phoneNumberField;
@property (nonatomic, strong) IBOutlet UILabel *countryCodeLabel;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) NSString *confirmationCode;


- (IBAction)registerButtonPressed:(id)sender;
- (IBAction)countrySelectButtonPressed:(id)sender;
- (void)submitPhoneNumberRegistration:(NSString *)phoneNumber;

@end

@implementation SVRegistrationViewController
{
	SVCountriesViewController *countries;
}


- (void)selectCountry:(NSString *)countryCode
{
    NSLog(@"Selecting country: %@", countryCode);

    [self didSelectCountryWithName:countryCode code:countryCode];
}


- (void)skipRegistration
{
    [self handleSuccessfulLogin];
}

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




#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
    if([SVBusinessDelegate hasUserBeenAuthenticated])
    {
		[self handleSuccessfulLogin];
    }
	else {
		
		NSString *cc = [[NSUserDefaults standardUserDefaults] stringForKey:kUserCountryCode];
		if (cc == nil) {
			cc = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
		}
		
		self.countryFlagView.image = [UIImage imageNamed:cc];
		NSInteger countryCode = [[NBPhoneNumberUtil sharedInstance] getCountryCodeForRegion:cc];
		
		self.countryCodeLabel.text = [NSString stringWithFormat:@"+%i", countryCode];
		
		[self.phoneNumberField becomeFirstResponder];
	}
	
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ChoseCountrySegue"]) {
		SVCountriesViewController *destination = (SVCountriesViewController *)segue.destinationViewController;
        destination.delegate = self;
		countries = destination;
    }
	else if ([segue.identifier isEqualToString:@"ConfirmationCodeSegue"]) {
		SVConfirmationCodeViewController *destination = (SVConfirmationCodeViewController *)segue.destinationViewController;
        destination.confirmationCode = self.confirmationCode;
		destination.countryCode = self.countryCodeLabel.text;
		destination.phoneNumber = self.phoneNumberField.text;
	}
}



- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - CountryPickerDelegate Methods

- (void)didSelectCountryWithName:(NSString *)name code:(NSString *)code
{
	NSLog(@"didselectcountry %@", name);
	[[NSUserDefaults standardUserDefaults] setObject:code forKey:kUserCountryCode];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
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
	[self.activityIndicator startAnimating];
	
	NSString *cc = [countries selectedCountryCode];
	if (cc == nil)
		cc = [[NSUserDefaults standardUserDefaults] stringForKey:kUserCountryCode];
	if (cc == nil)
		cc = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
	
	NSLog(@"submit %@ %@", cc, phoneNumber);
	[SVBusinessDelegate registerPhoneNumber:phoneNumber withCountryCode:cc WithCompletion:^(BOOL success, NSString *confirmationCode, NSError *error) {
		
		[self.activityIndicator stopAnimating];
		
		NSLog(@"received confirmationCode %@", confirmationCode);
		
		if(success)
		{
			// if successful, this will take user to next part of registration, if not show warning or something to resend a valid phone number
			// Move this to completion handler once implemented
			
			self.confirmationCode = confirmationCode;
			
			[self performSegueWithIdentifier:@"ConfirmationCodeSegue" sender:nil];
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
    //[[SVDownloadSyncEngine sharedEngine] startSync];
    
    // Grab the storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    
    // Grab the deal and make it our root view controller from the storyboard for this navigation controller
    SVAlbumListViewController *rootView = [storyboard instantiateViewControllerWithIdentifier:@"SVAlbumListViewController"];
    
    [self.navigationController setViewControllers:@[rootView] animated:YES];
	
}

@end
