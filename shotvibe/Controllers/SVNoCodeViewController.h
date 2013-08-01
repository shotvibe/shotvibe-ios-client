//
//  SVNoCodeViewController.h
//  shotvibe
//
//  Created by Baluta Cristian on 31/07/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVCountriesViewController.h"
#import "SVConfirmationCodeViewController.h"
#import "SVAlbumListViewController.h"
#import "NBPhoneNumberUtil.h"
#import "NBPhoneNumber.h"
#import "SVBusinessDelegate.h"
#import "SVDefines.h"
#import "SVDownloadSyncEngine.h"
#import "SVUploadQueueManager.h"

@interface SVNoCodeViewController : UIViewController <UITextFieldDelegate, SVCountriesDelegate> {
	
	SVCountriesViewController *countries;
}

@property (nonatomic, strong) IBOutlet UIButton *butContinue;
@property (nonatomic, strong) IBOutlet UIView *phoneNumberPhaseContainer;
@property (nonatomic, strong) IBOutlet UIImageView *countryFlagView;
@property (nonatomic, strong) IBOutlet UITextField *phoneNumberField;
@property (nonatomic, strong) IBOutlet UILabel *countryCodeLabel;

@property (nonatomic, strong) NSString *countryCode;
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSString *confirmationCode;


- (IBAction)registerButtonPressed:(id)sender;
- (IBAction)countrySelectButtonPressed:(id)sender;
- (IBAction)callmeButtonPressed:(id)sender;
- (void)submitPhoneNumberRegistration:(NSString *)phoneNumber;

@end