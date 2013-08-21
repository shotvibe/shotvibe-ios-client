//
//  AlbumManager.m
//  shotvibe
//
//  Created by benny on 8/20/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AlbumManager.h"
#import "AlbumSummary.h"

enum RefreshStatus
{
    IDLE,
    REFRESHING,
    REFRESHING_UPDATE
};

@interface AlbumContentsData : NSObject

- (id)init;

@property (nonatomic, strong) NSMutableArray *listeners;
@property (nonatomic, assign) int refreshStatus;

@end

@implementation AlbumContentsData

- (id)init
{
    self = [super init];

    if (self) {
        self.listeners = [[NSMutableArray alloc] init];
        self.refreshStatus = IDLE;
    }

    return self;
}

@end

@implementation AlbumManager

- (id)initWithShotvibeAPI:(ShotVibeAPI *)api shotvibeDB:(ShotVibeDB *)db
{
    self = [super init];

    if (self) {
        shotvibeAPI = api;
        shotvibeDB = db;

        refreshStatus = IDLE;

        albumListListeners = [[NSMutableArray alloc] init];
        albumContentsObjs = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (ShotVibeAPI *)getShotVibeAPI
{
    return shotvibeAPI;
}

- (NSArray *)addAlbumListListener:(id<AlbumListListener>)listener
{
    NSArray *cachedAlbums = [shotvibeDB getAlbumList];
    if (!cachedAlbums) {
        NSLog(@"DATABASE ERROR: %@", [shotvibeDB lastErrorMessage]);
    }

    [albumListListeners addObject:listener];

    if (refreshStatus == REFRESHING || refreshStatus == REFRESHING_UPDATE) {
        [listener onAlbumListBeginRefresh];
    }

    return cachedAlbums;
}

- (void)removeAlbumListListener:(id<AlbumListListener>)listener
{
    [albumListListeners removeObjectIdenticalTo:listener];
}

- (void)refreshAlbumList
{
    NSLog(@"##### REFRESHING ALBUM LIST");

    if (refreshStatus == IDLE) {
        refreshStatus = REFRESHING;
    }
    else if(refreshStatus == REFRESHING) {
        refreshStatus = REFRESHING_UPDATE;
        return;
    }
    else if(refreshStatus == REFRESHING_UPDATE) {
        return;
    }

    for(id<AlbumListListener> listener in albumListListeners) {
        [listener onAlbumListBeginRefresh];
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        __block BOOL done = NO;

        while (!done) {
            NSError *error;
            NSArray *latestAlbumsList = [shotvibeAPI getAlbumsWithError:&error];
            if (!latestAlbumsList) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    for(id<AlbumListListener> listener in albumListListeners) {
                        [listener onAlbumListRefreshError:error];
                    }
                    refreshStatus = IDLE;
                });

                NSLog(@"##### Error!");
                // TODO Schedule to retry soon
                return;
            }

            latestAlbumsList = [latestAlbumsList sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
                AlbumSummary *lhs = a;
                AlbumSummary *rhs = b;
                return [lhs.dateUpdated compare:rhs.dateUpdated];
            }];

            NSLog(@"##### LATEST ALBUM LIST: %d", [latestAlbumsList count]);

            dispatch_sync(dispatch_get_main_queue(), ^{
                if (refreshStatus == REFRESHING) {
                    if (![shotvibeDB setAlbumListWithAlbums:latestAlbumsList]) {
                        NSLog(@"DATABASE ERROR: %@", [shotvibeDB lastErrorMessage]);
                    }

                    for(id<AlbumListListener> listener in albumListListeners) {
                        [listener onAlbumListRefreshComplete:latestAlbumsList];
                    }

                    refreshStatus = IDLE;
                    done = true;
                }
                else if (refreshStatus == REFRESHING_UPDATE) {
                    refreshStatus = REFRESHING;
                    done = false;
                }
            });
        }
    });
}

- (AlbumContents *)addAlbumContentsListener:(int64_t)albumId listener:(id<AlbumContentsListener>)listener
{
    AlbumContents *cachedAlbum = [shotvibeDB getAlbumContents:albumId];

    AlbumContentsData *data = [albumContentsObjs objectForKey:[NSNumber numberWithLongLong:albumId]];
    if (!data) {
        data = [[AlbumContentsData alloc] init];
        [albumContentsObjs setObject:data forKey:[NSNumber numberWithLongLong:albumId]];
    }

    [data.listeners addObject:listener];

    if (data.refreshStatus == REFRESHING || data.refreshStatus == REFRESHING_UPDATE) {
        [listener onAlbumContentsBeginRefresh:albumId];
    }

    // TODO Later add the uploading photos to the end of the album

    return cachedAlbum;
}

- (void)removeAlbumContentsListener:(int64_t)albumId listener:(id<AlbumContentsListener>)listener
{
    AlbumContentsData *data = [albumContentsObjs objectForKey:[NSNumber numberWithLongLong:albumId]];
    [data.listeners removeObjectIdenticalTo:listener];

    [self cleanAlbumContentsListeners:albumId];
}

- (void)refreshAlbumContents:(int64_t)albumId
{
    NSLog(@"##### REFRESHING ALBUM CONTENTS %lld", albumId);

    AlbumContentsData *data = [albumContentsObjs objectForKey:[NSNumber numberWithLongLong:albumId]];
    if (!data) {
        data = [[AlbumContentsData alloc] init];
        [albumContentsObjs setObject:data forKey:[NSNumber numberWithLongLong:albumId]];
    }

    if (data.refreshStatus == IDLE) {
        data.refreshStatus = REFRESHING;
    }
    else if (data.refreshStatus == REFRESHING) {
        data.refreshStatus = REFRESHING_UPDATE;
        return;
    }
    else if (data.refreshStatus == REFRESHING_UPDATE) {
        return;
    }

    for (id<AlbumContentsListener> listener in data.listeners) {
        [listener onAlbumContentsBeginRefresh:albumId];
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        __block BOOL done = NO;

        while (!done) {
            NSError *error;
            AlbumContents *albumContents = [shotvibeAPI getAlbumContents:albumId withError:&error];
            if (!albumContents) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    AlbumContentsData *data = [albumContentsObjs objectForKey:[NSNumber numberWithLongLong:albumId]];
                    for(id<AlbumContentsListener> listener in data.listeners) {
                        [listener onAlbumContentsRefreshError:albumId error:error];
                    }

                    data.refreshStatus = IDLE;
                    [self cleanAlbumContentsListeners:albumId];
                });

                NSLog(@"##### Error!");
                // TODO Schedule to retry soon
                return;
            }

            // TODO Sort members by nickname

            NSLog(@"##### ALBUM CONTENTS %lld Number of photos: %d", albumId, albumContents.photos.count);

            dispatch_sync(dispatch_get_main_queue(), ^{
                AlbumContentsData *data = [albumContentsObjs objectForKey:[NSNumber numberWithLongLong:albumId]];

                if (data.refreshStatus == REFRESHING) {
                    if (![shotvibeDB setAlbumContents:albumId withContents:albumContents]) {
                        NSLog(@"DATABASE ERROR: %@", [shotvibeDB lastErrorMessage]);
                    }

                    // TODO Later add the uploading photos to the end of the album

                    for(id<AlbumContentsListener> listener in data.listeners) {
                        [listener onAlbumContentsRefreshComplete:albumId albumContents:albumContents];
                    }

                    data.refreshStatus = IDLE;
                    [self cleanAlbumContentsListeners:albumId];
                    done = true;
                }
                else if (data.refreshStatus == REFRESHING_UPDATE) {
                    data.refreshStatus = REFRESHING;
                    done = false;
                }
            });
        }
    });
}

- (void)cleanAlbumContentsListeners:(int64_t)albumId
{
    AlbumContentsData *data = [albumContentsObjs objectForKey:[NSNumber numberWithLongLong:albumId]];
    if (data.listeners.count == 0 && data.refreshStatus == IDLE) {
        [albumContentsObjs removeObjectForKey:[NSNumber numberWithLongLong:albumId]];
    }
}

@end
