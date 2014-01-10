//
//  RegistrationInfo.h
//  shotvibe
//
//  Created by Baluta Cristian on 11/11/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RegistrationInfo : NSObject

+ (RegistrationInfo *)RegistrationInfoFromURL:(NSURL *)url;
+ (NSString *)countryCodeFromURL:(NSURL *)url;

@property (nonatomic) BOOL startWithAuth;
@property (nonatomic, copy) NSString *countryCode;
@property (nonatomic, copy) NSString *authToken;
@property (nonatomic, assign) int64_t userId;

@end