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
#import "SL/HTTPException.h"
#import "SL/JSONException.h"
#import "SL/HashMap.h"
#import "SL/JSONObject.h"
#import "SL/HTTPResponse.h"
#import "IosHTTPLib.h"
#import "ShotVibeAPITask.h"
#import "SVCountriesViewController.h"
#import "GLUserScore.h"

//#import "GLSharedCamera.h"
@interface SVRegistrationViewController () < UIAlertViewDelegate ,UIWebViewDelegate>

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


//- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
//    return YES;
//}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    id<SLHTTPLib> httpLib = [[IosHTTPLib alloc] init];
    id<JavaUtilMap> utilmap = [[SLHashMap alloc] init];
    
    @try {
        SLHTTPResponse * res = [httpLib sendRequestWithNSString:@"GET" withNSString:@"http://ip-api.com/json" withJavaUtilMap:utilmap withNSString:@""];
        SLJSONObject * json = [res bodyAsJSONObject];
        selectedCountryCode = [json getStringWithNSString:@"countryCode"];
    } @catch (SLHTTPException *exception) {
        selectedCountryCode = @"US";
    } @catch (SLJSONException * jsonexception) {
        selectedCountryCode = @"US";
    }
    
    [self hideInviteOverlay];
    
    
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
    
    self.butContinue.layer.cornerRadius = self.butContinue.frame.size.width/2;
    
    ShotVibeAppDelegate * appDelegate = [ShotVibeAppDelegate sharedDelegate];
    GLSharedCamera * camera = [GLSharedCamera sharedInstance];
    camera.picYourGroup.alpha = 0;
    [[[[GLSharedCamera sharedInstance] userScore] view] setHidden:YES];
    camera.cameraViewBackground.userInteractionEnabled = NO;
    [appDelegate.window addSubview:camera.cameraViewBackground];
    [self.phoneNumberField becomeFirstResponder];
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
//    [self.phoneNumberField becomeFirstResponder];
}

-(void)resizeViewToIphone6plus:(UIView *)view width:(BOOL)width height:(BOOL)height cornerRadius:(BOOL)cornerRadius {
    
    CGRect f = view.frame;
    f.origin.x = f.origin.x*1.103;
    f.origin.y = f.origin.y*1.103;
    if(width){
        f.size.width = f.size.width*1.103;
    }
    if(height){
        f.size.height = f.size.height*1.103;
    }
    view.frame = f;
    if(cornerRadius){
        view.layer.cornerRadius = view.layer.cornerRadius*1.103;
    }
}

-(void)resizeViewToIphone5:(UIView *)view width:(BOOL)width height:(BOOL)height cornerRadius:(BOOL)cornerRadius {
    
    CGRect f = view.frame;
    f.origin.x = f.origin.x/1.17;
    f.origin.y = f.origin.y/1.17;
    if(width){
        f.size.width = f.size.width/1.17;
    }
    if(height){
        f.size.height = f.size.height/1.17;
    }
    view.frame = f;
    if(cornerRadius){
        view.layer.cornerRadius = view.layer.cornerRadius/1.17;
    }
}

- (void) viewWillAppear:(BOOL)animated {
	
	[super viewWillAppear:animated];

    if([[ShotVibeAppDelegate sharedDelegate] platformTypeIsIphone5]){
        [self resizeViewToIphone5:self.feelTheVibes width:NO height:YES cornerRadius:NO];
        [self resizeViewToIphone5:self.phoneNumberField width:NO height:NO cornerRadius:NO];
        [self resizeViewToIphone5:self.aValidationCode width:NO height:NO cornerRadius:NO];
        [self resizeViewToIphone5:self.countryFlagView width:NO height:NO cornerRadius:NO];
        [self resizeViewToIphone5:self.countrySelectButton width:NO height:YES cornerRadius:NO];
        [self resizeViewToIphone5:self.butContinue width:YES height:YES cornerRadius:YES];
    } else if([[ShotVibeAppDelegate sharedDelegate] platformTypeIsIphone6plus]){
        
//        CGRect frame = self.phoneNumberPhaseContainer.bounds;
//        frame.origin.x = frame.origin.x*2.103;
//        frame.origin.y = frame.origin.y*2.103;
//        self.phoneNumberPhaseContainer.frame = frame;
        [self resizeViewToIphone6plus:self.feelTheVibes width:NO height:YES cornerRadius:NO];
        [self resizeViewToIphone6plus:self.phoneNumberField width:NO height:NO cornerRadius:NO];
        [self resizeViewToIphone6plus:self.aValidationCode width:NO height:NO cornerRadius:NO];
        [self resizeViewToIphone6plus:self.countryFlagView width:NO height:NO cornerRadius:NO];
        [self resizeViewToIphone6plus:self.countrySelectButton width:NO height:YES cornerRadius:NO];
        [self resizeViewToIphone6plus:self.butContinue width:YES height:YES cornerRadius:YES];
    } else {
        
    }
    
    
//	if (IS_IOS7) {
//		self.navigationController.navigationBar.translucent = NO;
//	}
}
//
//- (void) viewWillDisappear:(BOOL)animated {
//	
//	[super viewWillDisappear:animated];
//	
//	if (IS_IOS7) {
//		self.navigationController.navigationBar.translucent = YES;
//	}
//}
//
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//    if ([segue.identifier isEqualToString:@"ChoseCountrySegue"]) {
//		
//		SVCountriesViewController *destination = (SVCountriesViewController *)segue.destinationViewController;
//        destination.delegate = self;
//		destination.regionCode = selectedCountryCode;
//		countries = destination;
//    }
//	else if ([segue.identifier isEqualToString:@"ConfirmationCodeSegue"]) {
//		
//		SVConfirmationCodeViewController *destination = (SVConfirmationCodeViewController *)segue.destinationViewController;
//        destination.selectedCountryCode = selectedCountryCode;
//        destination.smsConfirmationToken = smsConfirmationToken_;
//		destination.phoneNumber = self.phoneNumberField.text;
//	}
//}

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
            
//            [[GLSharedCamera sharedInstance] showGlCameraView];
            smsConfirmationToken_ = smsConfirmationToken;
//            [self performSegueWithIdentifier:@"ConfirmationCodeSegue" sender:nil];
            
//
            [KVNProgress dismiss];
                SVConfirmationCodeViewController *confirmationViewController = [[SVConfirmationCodeViewController alloc] init];
    confirmationViewController.selectedCountryCode = selectedCountryCode;
    confirmationViewController.smsConfirmationToken = smsConfirmationToken_;
    confirmationViewController.phoneNumber = self.phoneNumberField.text;
    [[[ShotVibeAppDelegate sharedDelegate] navigationController] pushViewController:confirmationViewController animated:YES];
//            
//            
        } else {
            [[Mixpanel sharedInstance] track:@"Phone Number Submitted Invalid"];
//
//            [KVNProgress dismiss];
              [KVNProgress showErrorWithStatus:@"Check that you have entered your correct phone number"];
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Number"
//                                                            message:@"Check that you have entered your correct phone number"
//                                                           delegate:nil
//                                                  cancelButtonTitle:@"OK"
//                                                  otherButtonTitles:nil];
//            [alert show];
        }
    }];
}

- (IBAction)countrySelectButtonPressed:(id)sender
{
	// showCountryPicker
	[self.phoneNumberField resignFirstResponder];
    
    countries = [[SVCountriesViewController alloc] init];
    countries.delegate = self;
    [self presentViewController:countries animated:YES completion:^{
//        [SVCountriesViewController ];
    }];
    
}




#pragma mark - CountryPickerDelegate Methods

- (void)didSelectCountryWithName:(NSString *)name regionCode:(NSString *)regionCode
{
	selectedCountryCode = regionCode;
    self.countryFlagView.image = [UIImage imageNamed:regionCode];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
    
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
