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
static NSString *const NICKNAME_SET = @"nickname_set";


// Utility function to retrieve a BOOL value from the standard user defaults.
+ (bool)getPersistentBoolForKey:(NSString *)key withDefault:(bool)defaultVal
{
    NSString *str = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (str == nil) {
        return defaultVal;
    } else {
        return [str boolValue];
    }
}


+ (SLAuthData *)getAuthData
{
    NSNumber *userId = [[NSUserDefaults standardUserDefaults] objectForKey:USER_ID];
    NSString *authToken = [[NSUserDefaults standardUserDefaults] objectForKey:AUTH_TOKEN];
    NSString *defaultCountryCode = [[NSUserDefaults standardUserDefaults] objectForKey:DEFAULT_COUNTRY_CODE];

    if (userId && authToken && defaultCountryCode) {
        return [[SLAuthData alloc] initWithLong:[userId longLongValue] withNSString:authToken withNSString:defaultCountryCode];
    }
    else {
        return nil;
    }
}

+ (void)setAuthData:(SLAuthData *)authData
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLongLong:[authData getUserId]] forKey:USER_ID];
    [[NSUserDefaults standardUserDefaults] setObject:[authData getAuthToken] forKey:AUTH_TOKEN];
    [[NSUserDefaults standardUserDefaults] setObject:[authData getDefaultCountryCode] forKey:DEFAULT_COUNTRY_CODE];

    [[NSUserDefaults standardUserDefaults] synchronize];
}


+ (BOOL)isNicknameSet
{
    return [UserSettings getPersistentBoolForKey:NICKNAME_SET withDefault:NO];
}


+ (void)setNicknameSet:(BOOL)nickNameSet
{
    [[NSUserDefaults standardUserDefaults] setBool:nickNameSet forKey:NICKNAME_SET];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


@end
