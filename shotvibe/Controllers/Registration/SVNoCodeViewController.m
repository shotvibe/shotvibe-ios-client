//
//  SVNoCodeViewController.m
//  shotvibe
//
//  Created by Baluta Cristian on 31/07/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVNoCodeViewController.h"
#import "SVDefines.h"
#import "SVAlbumListViewController.h"
#import "SVConfirmationCodeViewController.h"

@interface SVNoCodeViewController ()

@property (nonatomic, strong) IBOutlet UIButton *butContinue;
@property (nonatomic, strong) IBOutlet UIView *phoneNumberPhaseContainer;
@property (nonatomic, strong) IBOutlet UIImageView *countryFlagView;
@property (nonatomic, strong) IBOutlet UITextField *phoneNumberField;


- (IBAction)registerButtonPressed:(id)sender;
- (IBAction)countrySelectButtonPressed:(id)sender;
- (IBAction)callmeButtonPressed:(id)sender;

@end

@implementation SVNoCodeViewController

#pragma mark - Actions


- (IBAction)registerButtonPressed:(id)sender
{
	[self.phoneNumberField resignFirstResponder];
	
    UIAlertView *activityDialog = [[UIAlertView alloc] initWithTitle:@"Registering..." message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [activityDialog show];
	
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    indicator.center = CGPointMake(activityDialog.bounds.size.width / 2, activityDialog.bounds.size.height - 50);
    [indicator startAnimating];
    [activityDialog addSubview:indicator];
	
    NSString *phoneNumber = self.phoneNumberField.text;
    NSString *defaultCountry = selectedCountryCode;
	
    RCLog(@"phoneNumber:'%@' defaultCountry:'%@'", phoneNumber, defaultCountry);
	
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error;
        AuthorizePhoneNumberResult r = [[self.albumManager getShotVibeAPI] authorizePhoneNumber:phoneNumber defaultCountry:defaultCountry error:&error];
		
        dispatch_async(dispatch_get_main_queue(), ^{
            [activityDialog dismissWithClickedButtonIndex:0 animated:YES];
            if (r == AuthorizePhoneNumberOk) {
				[self.navigationController popViewControllerAnimated:YES];
            }
            else if (r == AuthorizePhoneNumberInvalidNumber) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Number"
                                                                message:@"Check that you have entered your correct phone number"
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            else if (r == AuthorizePhoneNumberError) {
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
	self.phoneNumberField.text = self.phoneNumber;
	self.countryFlagView.image = [UIImage imageNamed:selectedCountryCode];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ChoseCountrySegue"]) {
		
		SVCountriesViewController *destination = (SVCountriesViewController *)segue.destinationViewController;
        destination.delegate = self;
		destination.regionCode = selectedCountryCode;
		countries = destination;
    }
}




- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - CountryPickerDelegate Methods

- (void)didSelectCountryWithName:(NSString *)name regionCode:(NSString *)regionCode
{
    selectedCountryCode = regionCode;
    self.countryFlagView.image = [UIImage imageNamed:regionCode];
    
	RCLog(@"didselectcountry %@ %@", name, regionCode);
}


#pragma mark - UITextFieldDelegate Methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	CGRect r = self.phoneNumberPhaseContainer.frame;
	r.origin.y -= 30;
	self.phoneNumberPhaseContainer.frame = r;
}
- (void)textFieldDidEndEditing:(UITextField *)textField
{
	CGRect r = self.phoneNumberPhaseContainer.frame;
	r.origin.y = 0;
	self.phoneNumberPhaseContainer.frame = r;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	if (textField == self.phoneNumberField) {
		self.butContinue.enabled = (self.phoneNumberField.text.length > 0);
	}
	
    return YES;
}


#pragma mark public methods

- (void)selectCountry:(NSString *)regionCode
{
    RCLog(@"Selecting country: %@", regionCode);
    [self didSelectCountryWithName:regionCode regionCode:regionCode];
}


@end
