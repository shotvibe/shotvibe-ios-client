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


typedef enum {
 IFObjectSynced = 0,
 IFObjectCreated,
 IFObjectDeleted,
} IFObjectSyncStatus;

typedef enum {
 IFObjectRelationshipNeeded = 0,
 IFObjectRelationshipSynced,
} IFObjectRelationshipSyncStatus;

@interface SyncEngine : NSObject

#pragma mark - Class Methods

+ (SyncEngine *)sharedEngine;


#pragma mark - Instance Methods

- (void)registerNSManagedObjectClassToSync:(Class)aClass;
- (void)startSync;
- (void)setInitialSyncCompleted;
- (BOOL)initialSyncComplete;
@end
