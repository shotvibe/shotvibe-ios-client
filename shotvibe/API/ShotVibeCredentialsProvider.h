//
//  ShotVibeCredentialsProvider.h
//  shotvibe
//
//  Created by omer klein on 12/1/15.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AWSS3/AWSS3.h>
#import "SL/ShotVibeAPI.h"

@interface ShotVibeCredentialsProvider : NSObject <AWSCredentialsProvider>

- (id)initWithShotVibeAPI:(SLShotVibeAPI *)shotVibeAPI;

@property (nonatomic, strong, readonly) NSString *accessKey;
@property (nonatomic, strong, readonly) NSString *secretKey;
@property (nonatomic, strong, readonly) NSString *sessionKey;
@property (nonatomic, strong, readonly) NSDate *expiration;

@end
