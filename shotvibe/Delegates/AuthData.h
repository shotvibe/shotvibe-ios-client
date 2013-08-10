//
//  AuthData.h
//  shotvibe
//
//  Created by benny on 8/10/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AuthData : NSObject

- (id)initWithUserID:(NSString *)userId authToken:(NSString *)authToken defaultCountryCode:(NSString *)defaultCountryCode;

@property (nonatomic, copy, readonly) NSString *userId;
@property (nonatomic, copy, readonly) NSString *authToken;
@property (nonatomic, copy, readonly) NSString *defaultCountryCode;

@end
