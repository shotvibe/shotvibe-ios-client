//
//  AuthData.m
//  shotvibe
//
//  Created by benny on 8/10/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AuthData.h"

@implementation AuthData

- (id)initWithUserID:(int64_t)userId authToken:(NSString *)authToken defaultCountryCode:(NSString *)defaultCountryCode
{
    self = [super init];

    _userId = userId;
    _authToken = authToken;
    _defaultCountryCode = defaultCountryCode;

    return self;
}

@end
