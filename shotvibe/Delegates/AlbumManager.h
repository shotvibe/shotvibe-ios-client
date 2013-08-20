//
//  AlbumManager.h
//  shotvibe
//
//  Created by benny on 8/20/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ShotVibeAPI.h"
#import "ShotVibeDB.h"
#import "AlbumListListener.h"

@interface AlbumManager : NSObject
{
    NSMutableArray *albumListListeners;
    ShotVibeAPI *shotvibeAPI;
    ShotVibeDB *shotvibeDB;

    int refreshStatus;
}

- (id)initWithShotvibeAPI:(ShotVibeAPI *)api shotvibeDB:(ShotVibeDB *)db;

// Returns an array of `AlbumSummary` objects, which is the current cached AlbumList
- (NSArray *)addAlbumListListener:(id<AlbumListListener>)listener;

- (void)removeAlbumListListener:(id<AlbumListListener>)listener;

- (void)refreshAlbumList;

@end
