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

@property (nonatomic, strong) IBOutlet UITextField *codeField1;
@property (nonatomic, strong) IBOutlet UITextField *codeField2;
@property (nonatomic, strong) IBOutlet UITextField *codeField3;
@property (nonatomic, strong) IBOutlet UITextField *codeField4;
@property (nonatomic, strong) IBOutlet UIButton *butSubmit;

- (void)validateRegistrationCode:(NSString *)registrationCode;
- (void)handleSuccessfulLogin:(BOOL)animated;

@end
