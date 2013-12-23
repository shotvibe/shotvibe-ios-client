//
//  UserSettings.h
//  shotvibe
//
//  Created by benny on 8/22/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AuthData.h"

@interface UserSettings : NSObject

// Returns nil if there is no AuthData (the user has not logged in)
+ (AuthData *)getAuthData;

+ (void)setAuthData:(AuthData *)authData;

@end
