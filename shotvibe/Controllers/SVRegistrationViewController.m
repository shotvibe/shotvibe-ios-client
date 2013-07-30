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
#import "SVDownloadSyncEngine.h"
#import "SVUploadQueueManager.h"

@interface SVRegistrationViewController ()

@property (nonatomic, strong) IBOutlet UIButton *butContinue;
@property (nonatomic, strong) IBOutlet UIButton *butSubmit;
@property (nonatomic, strong) IBOutlet UIView *phoneNumberPhaseContainer;
@property (nonatomic, strong) IBOutlet UIImageView *countryFlagView;
@property (nonatomic, strong) IBOutlet UITextField *phoneNumberField;
@property (nonatomic, strong) IBOutlet UILabel *countryCodeLabel;

@property (nonatomic, strong) IBOutlet UIView *registrationCodePhaseContainer;
@property (nonatomic, strong) IBOutlet UITextField *codeField1;
@property (nonatomic, strong) IBOutlet UITextField *codeField2;
@property (nonatomic, strong) IBOutlet UITextField *codeField3;
@property (nonatomic, strong) IBOutlet UITextField *codeField4;

@property (nonatomic, strong) NSString *confirmationCode;


- (IBAction)continueButtonPressed:(id)sender;
- (IBAction)countrySelectButtonPressed:(id)sender;
- (void)submitPhoneNumberRegistration:(NSString *)phoneNumber;
- (void)validateRegistrationCode:(NSString *)registrationCode;
- (void)switchToRegistrationContainer;
- (void)switchToPhoneNumberContainer;
- (void)handleSuccessfulLogin;

@end

@implementation SVRegistrationViewController
{
    BOOL isRegistrationCodePhase;
	SVCountriesViewController *countries;
}

#pragma mark - Actions

- (IBAction)continueButtonPressed:(id)sender
{
    if (!isRegistrationCodePhase) {
        
        [self.phoneNumberField resignFirstResponder];
        
        // Construct our phone number
        NSString *countryCode = [self.countryCodeLabel.text stringByReplacingOccurrencesOfString:@"+" withString:@""];
        NSString *phoneNumber = [countryCode stringByAppendingString:self.phoneNumberField.text];        
        
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
    else
    {
        [self.codeField1 resignFirstResponder];
        [self.codeField2 resignFirstResponder];
        [self.codeField3 resignFirstResponder];
        [self.codeField4 resignFirstResponder];
        
        // Construct the registration code
        NSString *regCode = [NSString stringWithFormat:@"%@%@%@%@", self.codeField1.text, self.codeField2.text, self.codeField3.text, self.codeField4.text];
        
        [self validateRegistrationCode:regCode];
    }
}


- (IBAction)countrySelectButtonPressed:(id)sender
{
	// showCountryPicker
	[self.phoneNumberField resignFirstResponder];
    [self performSegueWithIdentifier:@"ChoseCountrySegue" sender:nil];
}


#pragma mark - Initializers

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
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
	
	NSString *cc = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    
    self.countryFlagView.image = [UIImage imageNamed:cc];
    NSInteger countryCode = [[NBPhoneNumberUtil sharedInstance] getCountryCodeForRegion:cc];
    
    self.countryCodeLabel.text = [NSString stringWithFormat:@"+%i", countryCode];
	
	[self.phoneNumberField becomeFirstResponder];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ChoseCountrySegue"]) {
		SVCountriesViewController *destination = (SVCountriesViewController *)segue.destinationViewController;
        destination.delegate = self;
		countries = destination;
    }
}



-(NSUInteger)supportedInterfaceOrientations{
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
    if (!isRegistrationCodePhase) {
        //[self hideCountryPicker];
    }
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	if (textField == self.phoneNumberField) {
		self.butContinue.enabled = (self.phoneNumberField.text.length > 0);
	}
    if (isRegistrationCodePhase)
    {
        if (self.codeField1.isFirstResponder) {
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
 
    return YES;
}


#pragma mark - Private Methods



- (void)submitPhoneNumberRegistration:(NSString *)phoneNumber
{
	
	[SVBusinessDelegate registerPhoneNumber:phoneNumber withCountryCode:[countries selectedCountryCode] WithCompletion:^(BOOL success, NSString *confirmationCode, NSError *error) {
		
		NSLog(@"received confirmationCode %@", confirmationCode);
		
		if(success)
		{
			// if successful, this will take user to next part of registration, if not show warning or something to resend a valid phone number
			// Move this to completion handler once implemented
			
			self.confirmationCode = confirmationCode;
			
			[self switchToRegistrationContainer];
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


- (void)switchToPhoneNumberContainer
{
    self.phoneNumberPhaseContainer.hidden = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.phoneNumberPhaseContainer.alpha = 1.0;
        self.registrationCodePhaseContainer.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.registrationCodePhaseContainer.hidden = YES;
        isRegistrationCodePhase = NO;
    }];
}


- (void)switchToRegistrationContainer
{
    self.registrationCodePhaseContainer.hidden = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.phoneNumberPhaseContainer.alpha = 0.0;
        self.registrationCodePhaseContainer.alpha = 1.0;
    } completion:^(BOOL finished) {
        self.phoneNumberPhaseContainer.hidden = YES;
        isRegistrationCodePhase = YES;
		[self.codeField1 becomeFirstResponder];
    }];
}


- (void)handleSuccessfulLogin
{
    [[SVDownloadSyncEngine sharedEngine] startSync];
    
    // Grab the storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    
    // Grab the deal and make it our root view controller from the storyboard for this navigation controller
    SVAlbumListViewController *rootView = [storyboard instantiateViewControllerWithIdentifier:@"SVAlbumListViewController"];
    
    [self.navigationController setViewControllers:@[rootView] animated:YES];
}

@end
