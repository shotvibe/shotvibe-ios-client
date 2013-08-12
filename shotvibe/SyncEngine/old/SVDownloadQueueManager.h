//
//  SVDownloadAPIClient.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 7/1/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AFHTTPClient.h"

@interface SVDownloadQueueManager : AFHTTPClient

#pragma mark - Class Methods

+ (SVDownloadQueueManager *)sharedManager;


#pragma mark - Instance Methods

- (void)start;
- (void)stop;
- (void)pause;
@end
