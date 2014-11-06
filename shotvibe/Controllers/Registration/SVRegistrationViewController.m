//
//  SVRegistrationViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 4/30/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "ShotVibeAppDelegate.h"
#import "SVRegistrationViewController.h"
#import "SVAlbumListViewController.h"
#import "SVConfirmationCodeViewController.h"
#import "SL/AlbumManager.h"
#import "SL/ShotVibeAPI.h"
#import "SL/HTTPLib.h"
#import "IosHTTPLib.h"
#import "ShotVibeAPITask.h"

@interface SVRegistrationViewController () < UIAlertViewDelegate >

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
    NSString *customPayload_;

    SLShotVibeAPI_SMSConfirmationToken *smsConfirmationToken_;
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    self.haveInviteLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(haveInviteTapped)];
    [self.haveInviteLabel addGestureRecognizer:tapGesture];

    if ([[ShotVibeAppDelegate sharedDelegate] isLoggedIn]) {
        RCLog(@"SVRegistrationViewController AuthData available");
		[self handleSuccessfulLogin:NO];
    }
	else {
        // The following line is commented out since we now an the Invite overlay and we don't want the keyboard to pop up
        //[self.phoneNumberField becomeFirstResponder];
	}
	if (selectedCountryCode == nil) {
		[self didSelectCountryWithName:nil regionCode:[[NSLocale currentLocale] objectForKey:NSLocaleCountryCode]];
	}
    else {
        [self didSelectCountryWithName:selectedCountryCode regionCode:selectedCountryCode];
    }
}


- (void)haveInviteTapped
{
    NSLog(@"haveInviteTapped");

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enter Invite Code"
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Ok", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert textFieldAtIndex:0].keyboardType = UIKeyboardTypeNumberPad;
    [alert show];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        NSString *SECRET_CODE = @"1337";

        NSString *inviteCode = [alertView textFieldAtIndex:0].text;

        if ([inviteCode isEqualToString:SECRET_CODE]) {
            [self hideInviteOverlay];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Code"
                                                            message:nil
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }
}


- (void)hideInviteOverlay
{
    [self.inviteOverlay setHidden:YES];
    [self.phoneNumberField becomeFirstResponder];
}


//- (void) viewWillAppear:(BOOL)animated {
//	
//	[super viewWillAppear:animated];
//	
//	if (IS_IOS7) {
//		self.navigationController.navigationBar.translucent = NO;
//	}
//}
//
//- (void) viewWillDisappear:(BOOL)animated {
//	
//	[super viewWillDisappear:animated];
//	
//	if (IS_IOS7) {
//		self.navigationController.navigationBar.translucent = YES;
//	}
//}

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
        destination.selectedCountryCode = selectedCountryCode;
        destination.smsConfirmationToken = smsConfirmationToken_;
		destination.phoneNumber = self.phoneNumberField.text;
	}
}

#pragma mark - Actions

- (IBAction)registerButtonPressed:(id)sender
{
	[self.phoneNumberField resignFirstResponder];
	
    NSString *phoneNumber = self.phoneNumberField.text;
    NSString *defaultCountry = selectedCountryCode;
    
    RCLog(@"phoneNumber:'%@' defaultCountry:'%@'", phoneNumber, defaultCountry);

    [[Mixpanel sharedInstance] track:@"Phone Number Submitted"];
	
    id<SLHTTPLib> httpLib = [[IosHTTPLib alloc] init];
    [ShotVibeAPITask runTask:self

                  withAction:
     ^SLShotVibeAPI_SMSConfirmationToken * {
        SLShotVibeAPI_SMSConfirmationToken *smsConfirmationToken =
            [SLShotVibeAPI authorizePhoneNumberWithSLHTTPLib:httpLib
                                                withNSString:phoneNumber
                                                withNSString:defaultCountry
                                                withNSString:[ShotVibeAppDelegate getDeviceName]
                                                withNSString:customPayload_];
        return smsConfirmationToken;
    }


              onTaskComplete:
     ^(SLShotVibeAPI_SMSConfirmationToken *smsConfirmationToken) {
        if (smsConfirmationToken) {
            smsConfirmationToken_ = smsConfirmationToken;
            [self performSegueWithIdentifier:@"ConfirmationCodeSegue" sender:nil];
        } else {
            [[Mixpanel sharedInstance] track:@"Phone Number Submitted Invalid"];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Number"
                                                            message:@"Check that you have entered your correct phone number"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }];
}

- (IBAction)countrySelectButtonPressed:(id)sender
{
	// showCountryPicker
	[self.phoneNumberField resignFirstResponder];
    [self performSegueWithIdentifier:@"ChoseCountrySegue" sender:nil];
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
	if ([UIScreen mainScreen].bounds.size.height < 568) {
		CGRect r = self.phoneNumberPhaseContainer.frame;
		r.origin.y -= 30;
		self.phoneNumberPhaseContainer.frame = r;
	}
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

- (void)setCustomPayload:(NSString *)customPayload
{
    NSLog(@"SVRegistrationViewController customPayload: %@", customPayload);
    customPayload_ = customPayload;
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

    UIView *v = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    v.backgroundColor = [UIColor whiteColor];
    [self.navigationController.view addSubview:v];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.navigationController setViewControllers:@[rootView] animated:animated];
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
