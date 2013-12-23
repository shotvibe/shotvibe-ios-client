//
//  SVNoCodeViewController.h
//  shotvibe
//
//  Created by Baluta Cristian on 31/07/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVCountriesViewController.h"
#import "AlbumManager.h"
#import "SVPushNotificationsManager.h"

@interface SVNoCodeViewController : UIViewController <UITextFieldDelegate, SVCountriesDelegate> {
	
	SVCountriesViewController *countries;
    NSString *selectedCountryCode;
}

@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSString *confirmationCode;
@property (nonatomic, strong) AlbumManager *albumManager;
@property (nonatomic, strong) SVPushNotificationsManager *pushNotificationsManager;

- (void)selectCountry:(NSString *)countryCode;

@end
