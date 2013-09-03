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
#import "AlbumContentsListener.h"
#import "PhotoUploadManager.h"

@interface AlbumManager : NSObject <PhotosUploadListener>
{
    NSMutableArray *albumListListeners;
    NSMutableDictionary *albumContentsObjs;

    ShotVibeAPI *shotvibeAPI;
    ShotVibeDB *shotvibeDB;

    int refreshStatus;
}

@property (nonatomic, readonly, strong) PhotoUploadManager *photoUploadManager;

- (id)initWithShotvibeAPI:(ShotVibeAPI *)api shotvibeDB:(ShotVibeDB *)db;

- (ShotVibeAPI *)getShotVibeAPI;

// Returns an array of `AlbumSummary` objects, which is the current cached AlbumList
- (NSArray *)addAlbumListListener:(id<AlbumListListener>)listener;

- (void)removeAlbumListListener:(id<AlbumListListener>)listener;

- (void)refreshAlbumList;

- (AlbumContents *)addAlbumContentsListener:(int64_t)albumId listener:(id<AlbumContentsListener>)listener;

- (void)removeAlbumContentsListener:(int64_t)albumId listener:(id<AlbumContentsListener>)listener;

- (void)refreshAlbumContents:(int64_t)albumId;

- (void)reportAlbumUpdate:(int64_t)albumId;

@end