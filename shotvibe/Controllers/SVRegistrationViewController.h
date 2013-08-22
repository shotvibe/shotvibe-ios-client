//
//  SVRegistrationViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 4/30/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVCountriesViewController.h"
#import "SVConfirmationCodeViewController.h"

#import "AlbumManager.h"
#import "SVPushNotificationsManager.h"

@interface SVRegistrationViewController : UIViewController <UITextFieldDelegate, SVCountriesDelegate>

@property (nonatomic, strong) AlbumManager *albumManager;
@property (nonatomic, strong) SVPushNotificationsManager *pushNotificationsManager;

- (void)selectCountry:(NSString *)countryCode;
- (void)skipRegistration;

@end
