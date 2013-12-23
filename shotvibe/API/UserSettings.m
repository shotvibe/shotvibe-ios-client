//
//  UserSettings.m
//  shotvibe
//
//  Created by benny on 8/22/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "UserSettings.h"

@implementation UserSettings

static NSString * const AUTH_TOKEN = @"auth_token";
static NSString * const USER_ID = @"user_id";
static NSString * const DEFAULT_COUNTRY_CODE = @"default_country_code";

+ (AuthData *)getAuthData
{
    NSNumber *userId = [[NSUserDefaults standardUserDefaults] objectForKey:USER_ID];
    NSString *authToken = [[NSUserDefaults standardUserDefaults] objectForKey:AUTH_TOKEN];
    NSString *defaultCountryCode = [[NSUserDefaults standardUserDefaults] objectForKey:DEFAULT_COUNTRY_CODE];

    if (userId && authToken && defaultCountryCode) {
        return [[AuthData alloc] initWithUserID:[userId longLongValue] authToken:authToken defaultCountryCode:defaultCountryCode];
    }
    else {
        return nil;
    }
}

+ (void)setAuthData:(AuthData *)authData
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLongLong:authData.userId] forKey:USER_ID];
    [[NSUserDefaults standardUserDefaults] setObject:authData.authToken forKey:AUTH_TOKEN];
    [[NSUserDefaults standardUserDefaults] setObject:authData.defaultCountryCode forKey:DEFAULT_COUNTRY_CODE];

    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
