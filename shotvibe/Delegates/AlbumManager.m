//
//  AlbumManager.m
//  shotvibe
//
//  Created by benny on 8/20/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AlbumManager.h"

enum RefreshStatus
{
    IDLE,
    REFRESHING,
    REFRESHING_UPDATE
};

@implementation AlbumManager

- (id)initWithShotvibeAPI:(ShotVibeAPI *)api shotvibeDB:(ShotVibeDB *)db
{
    self = [super init];

    if (self) {
        shotvibeAPI = api;
        shotvibeDB = db;

        refreshStatus = IDLE;

        albumListListeners = [[NSMutableArray alloc] init];
    }

    return self;
}

- (NSArray *)addAlbumListListener:(id<AlbumListListener>)listener
{
    NSArray *cachedAlbums = [shotvibeDB getAlbumList];

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
                });

                // TODO Schedule to retry soon
                return;
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                if (refreshStatus == REFRESHING) {
                    [shotvibeDB setAlbumListWithAlbums:latestAlbumsList];

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

@end
