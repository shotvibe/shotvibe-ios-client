//
//  SVRegistrationViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 4/30/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVRegistrationViewController.h"
#import "SVAlbumListViewController.h"
#import "SVConfirmationCodeViewController.h"
#import "AlbumManager.h"

@interface SVRegistrationViewController ()

@property (nonatomic, strong) IBOutlet UIButton *butContinue;
@property (nonatomic, strong) IBOutlet UIView *phoneNumberPhaseContainer;
@property (nonatomic, strong) IBOutlet UIImageView *countryFlagView;
@property (nonatomic, strong) IBOutlet UITextField *phoneNumberField;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;


- (IBAction)registerButtonPressed:(id)sender;
- (IBAction)countrySelectButtonPressed:(id)sender;

@end

@implementation SVRegistrationViewController
{
	SVCountriesViewController *countries;
    NSString *selectedCountryCode;
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
    NSString *defaultCountry = selectedCountryCode;
    
    RCLog(@"phoneNumber:'%@' defaultCountry:'%@'", phoneNumber, defaultCountry);
	
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
            else /*if (r == AuthorizePhoneNumberError)*/ {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unknown Error"
                                                                message:@"Possible causes are invalid phone numbers or the server is down"
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
	
    if ([self.albumManager getShotVibeAPI].authData)
    {
        RCLog(@"SVRegistrationViewController AuthData available");
		[self handleSuccessfulLogin:NO];
    }
	else {
		[self.phoneNumberField becomeFirstResponder];
	}
	if (selectedCountryCode == nil) {
		[self didSelectCountryWithName:nil regionCode:[[NSLocale currentLocale] objectForKey:NSLocaleCountryCode]];
	}
    else {
        [self didSelectCountryWithName:selectedCountryCode regionCode:selectedCountryCode];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ChoseCountrySegue"]) {
		
		SVCountriesViewController *destination = (SVCountriesViewController *)segue.destinationViewController;
        destination.delegate = self;
		destination.regionCode = selectedCountryCode;
		countries = destination;
    }
	else if ([segue.identifier isEqualToString:@"ConfirmationCodeSegue"]) {
		
		SVConfirmationCodeViewController *destination = (SVConfirmationCodeViewController *)segue.destinationViewController;
        destination.albumManager = self.albumManager;
        destination.pushNotificationsManager = self.pushNotificationsManager;
        destination.selectedCountryCode = selectedCountryCode;
		destination.phoneNumber = self.phoneNumberField.text;
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


#pragma mark public methods

- (void)selectCountry:(NSString *)regionCode
{
    RCLog(@"Selecting country: %@", regionCode);
    [self didSelectCountryWithName:regionCode regionCode:regionCode];
}

- (void)skipRegistration
{
    [self handleSuccessfulLogin:YES];
}



#pragma mark - Private Methods

- (void)handleSuccessfulLogin:(BOOL)animated
{
	RCLog(@"handleSuccessfulLogin");
    //[[SVDownloadSyncEngine sharedEngine] startSync];
    
    // Grab the storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    
    // Grab the deal and make it our root view controller from the storyboard for this navigation controller
    SVAlbumListViewController *rootView = [storyboard instantiateViewControllerWithIdentifier:@"SVAlbumListViewController"];

    rootView.albumManager = self.albumManager;

    [self.navigationController setViewControllers:@[rootView] animated:animated];
	
}

@end
