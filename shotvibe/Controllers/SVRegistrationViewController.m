//
//  SVRegistrationViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 4/30/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVRegistrationViewController.h"
#import "SVAlbumListViewController.h"
#import "SVBusinessDelegate.h"
#import "SVDefines.h"
#import "AlbumManager.h"

@interface SVRegistrationViewController ()

@property (nonatomic, strong) IBOutlet UIButton *butContinue;
@property (nonatomic, strong) IBOutlet UIView *phoneNumberPhaseContainer;
@property (nonatomic, strong) IBOutlet UIImageView *countryFlagView;
@property (nonatomic, strong) IBOutlet UITextField *phoneNumberField;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;


- (IBAction)registerButtonPressed:(id)sender;
- (IBAction)countrySelectButtonPressed:(id)sender;
- (void)submitPhoneNumberRegistration:(NSString *)phoneNumber;

@end

@implementation SVRegistrationViewController
{
	SVCountriesViewController *countries;
    NSString *selectedCountryCode;
}


- (void)selectCountry:(NSString *)regionCode
{
    NSLog(@"Selecting country: %@", regionCode);

    selectedCountryCode = regionCode;
    [self didSelectCountryWithName:regionCode regionCode:regionCode];
}


- (void)skipRegistration
{
    [self handleSuccessfulLogin];
}

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
    NSString *defaultCountry = countries.selectedCountryCode;
    if (!defaultCountry) {
        defaultCountry = selectedCountryCode;
    }

    NSLog(@"phoneNumber:'%@' defaultCountry:'%@'", phoneNumber, defaultCountry);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error;
        AuthorizePhoneNumberResult r = [[self.albumManager getShotVibeAPI] authorizePhoneNumber:phoneNumber defaultCountry:defaultCountry error:&error];

        dispatch_async(dispatch_get_main_queue(), ^{
            [activityDialog dismissWithClickedButtonIndex:0 animated:YES];
            if (r == AuthorizePhoneNumberOk) {
                [self performSegueWithIdentifier:@"ConfirmationCodeSegue" sender:nil];
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




#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    NSLog(@"SVRegistrationViewController.viewDidLoad");

    if ([self.albumManager getShotVibeAPI].authData)
    {
        NSLog(@"SVRegistrationViewController AuthData available");
		[self handleSuccessfulLogin];
    }
	else {
		self.countryFlagView.image = [UIImage imageNamed:@"US"];

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
        destination.albumManager = self.albumManager;
        destination.pushNotificationsManager = self.pushNotificationsManager;

        NSString *defaultCountry = countries.selectedCountryCode;
        if (!defaultCountry) {
            defaultCountry = selectedCountryCode;
        }

        destination.defaultCountryCode = defaultCountry;
	}
}



- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - CountryPickerDelegate Methods

- (void)didSelectCountryWithName:(NSString *)name regionCode:(NSString *)regionCode
{
    self.countryFlagView.image = [UIImage imageNamed:regionCode];
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

- (void)handleSuccessfulLogin
{
	NSLog(@"handleSuccessfulLogin");
    //[[SVDownloadSyncEngine sharedEngine] startSync];
    
    // Grab the storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    
    // Grab the deal and make it our root view controller from the storyboard for this navigation controller
    SVAlbumListViewController *rootView = [storyboard instantiateViewControllerWithIdentifier:@"SVAlbumListViewController"];

    rootView.albumManager = self.albumManager;

    [self.navigationController setViewControllers:@[rootView] animated:YES];
	
}

@end
