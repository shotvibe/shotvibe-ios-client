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

@interface SVRegistrationViewController ()

@property (nonatomic, strong) IBOutlet UIView *phoneNumberPhaseContainer;
@property (nonatomic, strong) IBOutlet UIImageView *countryFlagView;
@property (nonatomic, strong) IBOutlet UITextField *phoneNumberField;
@property (nonatomic, strong) IBOutlet UILabel *countryCodeLabel;
@property (nonatomic, strong) CountryPicker *countryPicker;

@property (nonatomic, strong) IBOutlet UIView *registrationCodePhaseContainer;
@property (nonatomic, strong) IBOutlet UITextField *codeField1;
@property (nonatomic, strong) IBOutlet UITextField *codeField2;
@property (nonatomic, strong) IBOutlet UITextField *codeField3;
@property (nonatomic, strong) IBOutlet UITextField *codeField4;

- (IBAction)continueButtonPressed:(id)sender;
- (IBAction)countrySelectButtonPressed:(id)sender;
- (void)submitPhoneNumberRegistration:(NSString *)phoneNumber;
- (void)validateRegistrationCode:(NSString *)registrationCode;
- (void)showCountryPicker;
- (void)hideCountryPicker;
- (void)switchToRegistrationContainer;
- (void)switchToPhoneNumberContainer;
- (void)handleSuccessfulLogin;

@end

@implementation SVRegistrationViewController
{
    BOOL isRegistrationCodePhase;
}

#pragma mark - Actions

- (IBAction)continueButtonPressed:(id)sender
{
    if (!isRegistrationCodePhase) {
        
        [self hideCountryPicker];
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
    [self showCountryPicker];
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
    
    
    self.countryPicker = [[CountryPicker alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 216)];
    self.countryPicker.delegate = self;
    self.countryPicker.showsSelectionIndicator = YES;
    
    
    [self.countryPicker setWithLocale:[NSLocale currentLocale]];
    
    [self.phoneNumberPhaseContainer addSubview:self.countryPicker];
    
    self.countryFlagView.image = [UIImage imageNamed:self.countryPicker.selectedCountryCode];
    NSInteger countryCode = [[NBPhoneNumberUtil sharedInstance] getCountryCodeForRegion:self.countryPicker.selectedCountryCode];
    
    self.countryCodeLabel.text = [NSString stringWithFormat:@"+%i", countryCode];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - CountryPickerDelegate Methods

- (void)countryPicker:(CountryPicker *)picker didSelectCountryWithName:(NSString *)name code:(NSString *)code
{
    // TODO: Handle setting the appropriate country phone code
    
    self.countryFlagView.image = [UIImage imageNamed:code];
    
    NSInteger countryCode = [[NBPhoneNumberUtil sharedInstance] getCountryCodeForRegion:code];
    
    self.countryCodeLabel.text = [NSString stringWithFormat:@"+%i", countryCode];
}


#pragma mark - UITextFieldDelegate Methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (!isRegistrationCodePhase) {
        [self hideCountryPicker];
    }
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
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
        }
        
        return NO;
    }
    
    return YES;
}


#pragma mark - Private Methods

- (void)submitPhoneNumberRegistration:(NSString *)phoneNumber
{
    // TODO: Handle sending the phone number registration to the server
    
    // if successful, this will take user to next part of registration, if not show warning or something to resend a valid phone number
    // Move this to completion handler once implemented
    [self switchToRegistrationContainer];
    
}


- (void)validateRegistrationCode:(NSString *)registrationCode
{
    // TODO: Handle validating that the reg code is correct? If it is, send to main screen, if not ??? alert+re-enter? option to resend? wat? not even mentioned
    
    // Move this to successful completion handler once implemented
    [self handleSuccessfulLogin];
}


- (void)showCountryPicker
{
    [self.phoneNumberField resignFirstResponder];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.countryPicker.frame = CGRectMake(0, self.view.frame.size.height - self.countryPicker.frame.size.height, self.view.frame.size.width, self.countryPicker.frame.size.height);
    }];
}


- (void)hideCountryPicker
{
    [UIView animateWithDuration:0.3 animations:^{
        self.countryPicker.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.countryPicker.frame.size.height);
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
    }];
}


- (void)handleSuccessfulLogin
{
    // Grab the storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    
    // Grab the deal and make it our root view controller from the storyboard for this navigation controller
    SVAlbumListViewController *rootView = [storyboard instantiateViewControllerWithIdentifier:@"SVAlbumListViewController"];
    
    [self.navigationController setViewControllers:@[rootView] animated:YES];
}

@end
