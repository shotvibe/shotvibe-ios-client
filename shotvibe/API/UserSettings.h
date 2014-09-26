//
//  UserSettings.h
//  shotvibe
//
//  Created by benny on 8/22/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SL/AuthData.h"

@interface UserSettings : NSObject

// Returns nil if there is no AuthData (the user has not logged in)
+ (SLAuthData *)getAuthData;

+ (void)setAuthData:(SLAuthData *)authData;

// Returns YES if the user has updated his nickname since installing the app
+ (BOOL)isNicknameSet;

+ (void)setNicknameSet:(BOOL)nickNameSet;

@end
