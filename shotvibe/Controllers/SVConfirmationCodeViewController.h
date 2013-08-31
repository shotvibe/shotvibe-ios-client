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
#import "SVNoCodeViewController.h"
#import "SVPushNotificationsManager.h"

@interface SVConfirmationCodeViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, strong) AlbumManager *albumManager;
@property (nonatomic, strong) SVPushNotificationsManager *pushNotificationsManager;
@property (nonatomic, strong) NSString *defaultCountryCode;

//@property (nonatomic, strong) IBOutlet UIView *registrationCodePhaseContainer;
@property (nonatomic, strong) IBOutlet UITextField *codeField1;
@property (nonatomic, strong) IBOutlet UITextField *codeField2;
@property (nonatomic, strong) IBOutlet UITextField *codeField3;
@property (nonatomic, strong) IBOutlet UITextField *codeField4;
@property (nonatomic, strong) IBOutlet UIButton *butSubmit;

- (void)validateRegistrationCode:(NSString *)registrationCode;
- (void)handleSuccessfulLogin;

@end
