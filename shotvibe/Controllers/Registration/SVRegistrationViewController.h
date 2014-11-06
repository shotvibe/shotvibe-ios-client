//
//  SVRegistrationViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 4/30/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SL/AlbumManager.h"
#import "SVPushNotificationsManager.h"
#import "SVCountriesViewController.h"


@interface SVRegistrationViewController : UIViewController <UITextFieldDelegate, SVCountriesDelegate>

@property (weak, nonatomic) IBOutlet UIView *inviteOverlay;
@property (weak, nonatomic) IBOutlet UILabel *haveInviteLabel;

- (void)selectCountry:(NSString *)countryCode;
- (void)setCustomPayload:(NSString *)customPayload;
- (void)skipRegistration;

@end
