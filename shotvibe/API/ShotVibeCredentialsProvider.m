//
//  ShotVibeCredentialsProvider.m
//  shotvibe
//
//  Created by omer klein on 12/1/15.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import "ShotVibeCredentialsProvider.h"

#include <libkern/OSAtomic.h>

#import "SL/AwsToken.h"
#import "SL/DateTime.h"
#import "SL/ShotVibeAPI.h"

@implementation ShotVibeCredentialsProvider
{
    SLShotVibeAPI *shotVibeAPI_;
    
    // Only allowed to be accessed within a @synchronized(self) block
    SLAwsToken *awsToken_;
}

- (id)initWithShotVibeAPI:(SLShotVibeAPI *)shotVibeAPI
{
    self = [super init];
    if (self) {
        shotVibeAPI_ = shotVibeAPI;
        awsToken_ = nil;
        
        // Make sure the previous write to shotVibeAPI_ is visible to all threads.
        // From this point on, shotVibeAPI_ should be treated as read-only
        OSMemoryBarrier();
    }
    return self;
}

- (NSString *)accessKey {
    @synchronized(self) {
        if (!awsToken_) {
            return nil;
        }
        return [awsToken_ getAwsAccessKey];
    }
}

- (NSString *)secretKey {
    @synchronized(self) {
        if (!awsToken_) {
            return nil;
        }
        return [awsToken_ getAwsSecretKey];
    }
}

- (NSString *)sessionKey {
    @synchronized(self) {
        if (!awsToken_) {
            return nil;
        }
        return [awsToken_ getAwsSessionToken];
    }
}

- (NSDate *)expiration {
    @synchronized(self) {
        if (!awsToken_) {
            return nil;
        }
        
        return [[NSDate alloc] initWithTimeIntervalSince1970:[[awsToken_ getExpires] getTimeStamp] / 1000000.0];
    }
}

- (AWSTask *)refresh
{
    AWSExecutor *executor = [AWSExecutor executorWithDispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
    
    return [AWSTask taskFromExecutor:executor withBlock:^id{
        @try {
            SLAwsToken *result = [shotVibeAPI_ getAwsToken];
            @synchronized(self) {
                awsToken_ = result;
            }
        }
        @catch (SLAPIException *exception) {
            // Most likely a network error. The operation will be retried again automatically, but we sleep here to prevent potentially hammering the network
            [NSThread sleepForTimeInterval:2.0];
        }
        return nil;
    }];
}

@end
