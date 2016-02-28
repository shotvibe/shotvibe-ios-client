//
//  ConfirmationCodeViewController.h
//  shotvibe
//
//  Created by Baluta Cristian on 31/07/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVAlbumListViewController.h"
#import "SVDefines.h"
#import "SVPushNotificationsManager.h"
#import "SL/ShotVibeAPI.h"

@interface SVConfirmationCodeViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSString *selectedCountryCode;
@property (nonatomic, strong) SLShotVibeAPI_SMSConfirmationToken *smsConfirmationToken;

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (nonatomic, strong) IBOutlet UITextField *codeField1;
@property (nonatomic, strong) IBOutlet UITextField *codeField2;
@property (nonatomic, strong) IBOutlet UITextField *codeField3;
@property (nonatomic, strong) IBOutlet UITextField *codeField4;
@property (nonatomic, strong) IBOutlet UIButton *butSubmit;
@property (weak, nonatomic) IBOutlet UILabel *line1;
@property (weak, nonatomic) IBOutlet UILabel *line2;
@property (weak, nonatomic) IBOutlet UIView *tf1;
@property (weak, nonatomic) IBOutlet UIView *tf4;
@property (weak, nonatomic) IBOutlet UIView *tf3;
@property (weak, nonatomic) IBOutlet UIView *tf2;
- (IBAction)backPressed:(id)sender;

- (void)validateRegistrationCode:(NSString *)registrationCode;
- (void)handleSuccessfulLogin:(BOOL)animated;

@end
