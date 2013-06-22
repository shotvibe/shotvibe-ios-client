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
#import "Album.h"

typedef enum {
 SVObjectSynced = 0,
 SVObjectCreated,
 SVObjectDeleted,
} SVObjectSyncStatus;

@interface SyncEngine : NSObject

#pragma mark - Class Methods

+ (SyncEngine *)sharedEngine;


#pragma mark - Instance Methods

- (void)startSync;

- (void)syncAlbums;
- (NSArray *)getAlbums;

- (void)addPhotos:(NSArray *)photos ToAlbum:(Album *) album;

@end
