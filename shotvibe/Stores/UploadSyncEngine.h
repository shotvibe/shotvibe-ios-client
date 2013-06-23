//
//  UploadSyncEngine.h
//  shotvibe
//
//  Created by Peter Kasson on 6/22/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UploadSyncEngine : NSObject



#pragma mark - Class Methods

+ (UploadSyncEngine *)sharedEngine;


#pragma mark - Instance Methods

- (void)startSync;


@end
