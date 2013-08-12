//
//  SVUploadQueueManager.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 7/6/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AFHTTPClient.h"

@interface SVUploadQueueManager : AFHTTPClient

#pragma mark - Properties

@property (atomic, readonly) BOOL syncInProgress;


#pragma mark - Class Methods

+ (SVUploadQueueManager *)sharedManager;


#pragma mark - Instance Methods

- (void)start;
- (void)stop;
- (void)pause;
@end
