//
//  SVDownloadSyncEngine.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 6/25/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SVDownloadSyncEngine : NSObject

#pragma mark - Properties

@property (nonatomic, strong) NSOperationQueue *downloadQueue;
@property (nonatomic, strong) NSOperationQueue *photoSaveQueue;


#pragma mark - Class Methods

+ (SVDownloadSyncEngine *)sharedEngine;


#pragma mark - Instance Methods

- (void)registerNSManagedObjectClassToSync:(Class)aClass;
- (void)startSync;
@end
