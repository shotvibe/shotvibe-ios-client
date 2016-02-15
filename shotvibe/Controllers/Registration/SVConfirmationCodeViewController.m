//
//  ConfirmationCodeViewController.m
//  shotvibe
//
//  Created by Baluta Cristian on 31/07/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//
#import "GLProfilePictureController.h"
#import "SVConfirmationCodeViewController.h"
#import "SVPushNotificationsManager.h"
#import "SVProfileViewController.h"
#import "ShotVibeAppDelegate.h"
#import "ShotVibeAPITask.h"
#import "SL/HTTPLib.h"
#import "IosHTTPLib.h"

@implementation SVConfirmationCodeViewController


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self.codeField1 becomeFirstResponder];

    self.butSubmit.layer.cornerRadius = self.butSubmit.frame.size.width/2;
    
//    UIView * f1b = [[UIView alloc] initWithFrame:CGRectMake(self.codeField1.frame.origin.x, self.codeField1.frame.size.height+self.codeField1.frame.origin.y, self.codeField1.frame.size.width, 10)];
//    f1b.backgroundColor = [UIColor purpleColor];
//    
//    [self.codeField1 addSubview:f1b];
    
//    self.codeField1
//    self.codeField2
//    self.codeField3
//    self
    
//    [self.codeField1 resignFirstResponder];
    
    [[Mixpanel sharedInstance] track:@"Activation Screen Viewed"];
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

- (IBAction)backPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)validateRegistrationCode:(NSString *)registrationCode
{
	RCLog(@"validateRegistrationCode - code:  %@", registrationCode);

//    [self handleSuccessfulLogin:YES];
    
//    [[Mixpanel sharedInstance] track:@"Activation Code Submitted"];
//
    id<SLHTTPLib> httpLib = [[IosHTTPLib alloc] init];

    [ShotVibeAPITask runTask:self

                  withAction:
     ^SLAuthData * {
        SLAuthData *authData = [SLShotVibeAPI confirmSMSCodeWithSLHTTPLib:httpLib
                                   withSLShotVibeAPI_SMSConfirmationToken:self.smsConfirmationToken
                                                             withNSString:registrationCode];
        return authData;
    }


              onTaskComplete:
     ^(SLAuthData *authData) {
        if (authData) {
            [[ShotVibeAppDelegate sharedDelegate] setAuthData:authData];
            
            
            [self handleSuccessfulLogin:YES];
            [KVNProgress dismiss];
        } else {
            [[Mixpanel sharedInstance] track:@"Activation Code Submitted Incorrect"];
            
            
            [KVNProgress showErrorWithStatus:@"Please enter the code that was sent to you, or go back to check your phone number" completion:^{
                [self.codeField1 becomeFirstResponder];
            }];
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Incorrect Code"
//                                                            message:@"Please enter the code that was sent to you, or go back to check your phone number"
//                                                           delegate:nil
//                                                  cancelButtonTitle:@"OK"
//                                                  otherButtonTitles:nil];
//            [alert show];
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


- (void)handleSuccessfulLogin:(BOOL)animated
{
	RCLog(@"handleSuccessfulLogin");

    [[Mixpanel sharedInstance] track:@"User Registered"];
    [[Mixpanel sharedInstance] track:@"User Registered (Manual)"];

    
    
    
    
    //[[SVDownloadSyncEngine sharedEngine] startSync];

    // Grab the storyboard
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
//
    [[ShotVibeAppDelegate sharedDelegate] setAfterActivation:YES];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"kUserLoggedIn"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"kUserSettedPicture"];
    [[NSUserDefaults standardUserDefaults] synchronize];
//
//    // Grab the deal and make it our root view controller from the storyboard for this navigation controller
//    SVAlbumListViewController *rootView = [storyboard instantiateViewControllerWithIdentifier:@"SVAlbumListViewController"];
//
//    GLProfilePictureController *profilePictureController = [storyboard instantiateViewControllerWithIdentifier:@"GLProfilePictureController"];
//    
//    SVProfileViewController *profileController = [storyboard instantiateViewControllerWithIdentifier:@"SVProfileViewController"];
//    profileController.shouldPrompt = YES;
//
//    UIView *v = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
//    v.backgroundColor = [UIColor whiteColor];
//    [self.navigationController.view addSubview:v];
//    
//    
////    [[[GLSharedCamera sharedInstance] videoCamera] stopCameraCapture];
    [[GLSharedCamera sharedInstance] hideGlCameraView];
    
    
    GLProfilePictureController * profilePicViewController = [[GLProfilePictureController alloc] init];
    [[[ShotVibeAppDelegate sharedDelegate]navigationController]pushViewController:profilePicViewController animated:YES];
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self.navigationController setViewControllers:@[rootView, profilePictureController] animated:NO];
//        [v removeFromSuperview];
////        [[[GLSharedCamera sharedInstance] cameraViewBackground] setAlpha:0];
//
//    });
}


-(void)resizeViewToIphone5:(UIView *)view width:(BOOL)width height:(BOOL)height cornerRadius:(BOOL)cornerRadius {
    
    CGRect f = view.frame;
    f.origin.x = f.origin.x/1.15;
    f.origin.y = f.origin.y/1.15;
    if(width){
        f.size.width = f.size.width/1.15;
    }
    if(height){
        f.size.height = f.size.height/1.15;
    }
    view.frame = f;
    if(cornerRadius){
        view.layer.cornerRadius = view.layer.cornerRadius/1.15;
    }
}

#pragma mark Rotation

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if([[ShotVibeAppDelegate sharedDelegate] platformTypeIsIphone5]){
        
        [self resizeViewToIphone5:self.butSubmit width:YES height:YES cornerRadius:YES];
        [self resizeViewToIphone5:self.line1 width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone5:self.line2 width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone5:self.tf1 width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone5:self.tf2 width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone5:self.tf3 width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone5:self.tf4 width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone5:self.codeField1 width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone5:self.codeField2 width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone5:self.codeField3 width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone5:self.codeField4 width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone5:self.backButton width:YES height:YES cornerRadius:NO];
    
    } else if([[ShotVibeAppDelegate sharedDelegate] platformTypeIsIphone6plus]){
//        for(UIView * view in self.view.subviews){
//            [self resizeViewToIphone6plus:view width:YES height:YES cornerRadius:view.layer.cornerRadius > 0 ? YES : NO];
//        }
        
        [self resizeViewToIphone6plus:self.butSubmit width:YES height:YES cornerRadius:YES];
//        [self resizeViewToIphone6plus:self.line1 width:YES height:YES cornerRadius:NO];
//        [self resizeViewToIphone6plus:self.line2 width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone6plus:self.tf1 width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone6plus:self.tf2 width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone6plus:self.tf3 width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone6plus:self.tf4 width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone6plus:self.codeField1 width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone6plus:self.codeField2 width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone6plus:self.codeField3 width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone6plus:self.codeField4 width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone6plus:self.backButton width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone6plus:self.line1 width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone6plus:self.line2 width:YES height:YES cornerRadius:NO];
    }
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
