//
//  SyncEngine.h
//  shotvibe
//
//  Created by Peter Kasson on 6/18/13.
//
//  Parts taken from IFSyncEngine (Fred G.)
//
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DownloadSyncEngine : NSObject

#pragma mark - Class Methods

+ (DownloadSyncEngine *)sharedEngine;


#pragma mark - Instance Methods

- (void)startSync;
@end
