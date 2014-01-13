//
//  AlbumManager.m
//  shotvibe
//
//  Created by benny on 8/20/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AlbumManager.h"
#import "SL/AlbumSummary.h"
#import "SL/AlbumContents.h"
#import "PhotoUploadManager.h"
#import "SL/AlbumPhoto.h"
#import "SL/ArrayList.h"
#import "SL/AlbumServerPhoto.h"
#import "SL/AlbumUploadingPhoto.h"
#import "AlbumUploadingPhoto.h"
#import "SL/DateTime.h"

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

        _photoUploadManager = [[PhotoUploadManager alloc] initWithShotVibeAPI:shotvibeAPI listener:self];
        _photoFilesManager = [[PhotoFilesManager alloc] init];
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
        RCLog(@"DATABASE ERROR: %@", [shotvibeDB lastErrorMessage]);
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
    RCLog(@"##### REFRESHING ALBUM LIST");

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

                NSLog(@"### AlbumManager.refreshAlbumList: ERROR in shotvibeAPI getAlbumsWithError:\n%@", [error localizedDescription]);

                // TODO Schedule to retry soon
                return;
            }

            latestAlbumsList = [latestAlbumsList sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
                SLAlbumSummary *lhs = a;
                SLAlbumSummary *rhs = b;
                if ([[lhs getDateUpdated] getTimeStamp] < [[rhs getDateUpdated] getTimeStamp]) {
                    return NSOrderedAscending;
                }
                if ([[lhs getDateUpdated] getTimeStamp] > [[rhs getDateUpdated] getTimeStamp]) {
                    return NSOrderedDescending;
                }
                return NSOrderedSame;
            }];

            RCLog(@"##### LATEST ALBUM LIST: %d", [latestAlbumsList count]);

            dispatch_sync(dispatch_get_main_queue(), ^{
                if (refreshStatus == REFRESHING) {
                    if (![shotvibeDB setAlbumListWithAlbums:latestAlbumsList]) {
                        RCLog(@"DATABASE ERROR: %@", [shotvibeDB lastErrorMessage]);
                    }

                    // Loop over the new albumsList, and refresh any albums that have
                    // an updated etag value:
                    // TODO Right now all of these refresh requests happen in parallel, they should run in sequence

                    NSDictionary *albumEtags = [shotvibeDB getAlbumListEtagValues];

                    for (SLAlbumSummary *a in latestAlbumsList) {
                        NSString *newEtag = [a getEtag];
                        NSString *oldEtag = [albumEtags objectForKey:[[NSNumber alloc] initWithLongLong:[a getId]]];
                        if (![newEtag isEqualToString:oldEtag]) {
                            [self refreshAlbumContents:[a getId]];
                        }
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

- (SLAlbumContents *)addAlbumContentsListener:(int64_t)albumId listener:(id<AlbumContentsListener>)listener
{
    SLAlbumContents *cachedAlbum = [shotvibeDB getAlbumContents:albumId];
	
    AlbumContentsData *data = [albumContentsObjs objectForKey:[NSNumber numberWithLongLong:albumId]];
    if (!data) {
        data = [[AlbumContentsData alloc] init];
        [albumContentsObjs setObject:data forKey:[NSNumber numberWithLongLong:albumId]];
    }

    [data.listeners addObject:listener];
	
    if (data.refreshStatus == REFRESHING || data.refreshStatus == REFRESHING_UPDATE) {
        [listener onAlbumContentsBeginRefresh:albumId];
    }

    // Add the Uploading photos to the end of album:
    cachedAlbum = [AlbumManager addUploadingPhotosToAlbumContents:cachedAlbum uploadingPhotos:[self.photoUploadManager getUploadingPhotos:albumId]];

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
    RCLog(@"##### REFRESHING ALBUM CONTENTS %lld", albumId);

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
            SLAlbumContents *albumContents = [shotvibeAPI getAlbumContents:albumId withError:&error];
            if (!albumContents) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    AlbumContentsData *data = [albumContentsObjs objectForKey:[NSNumber numberWithLongLong:albumId]];
                    for(id<AlbumContentsListener> listener in data.listeners) {
                        [listener onAlbumContentsRefreshError:albumId error:error];
                    }

                    data.refreshStatus = IDLE;
                    [self cleanAlbumContentsListeners:albumId];
                });

                NSLog(@"### AlbumManager.refreshAlbumContents: ERROR in shotvibeAPI getAlbumContents for %lld:\n%@", albumId, [error localizedDescription]);
                // TODO Schedule to retry soon
                return;
            }

            // TODO Sort members by nickname

            RCLog(@"##### ALBUM CONTENTS %lld Number of photos: %d", albumId, [albumContents getPhotos].array.count);

            dispatch_sync(dispatch_get_main_queue(), ^{
                AlbumContentsData *data = [albumContentsObjs objectForKey:[NSNumber numberWithLongLong:albumId]];

                if (data.refreshStatus == REFRESHING) {
                    if (![shotvibeDB setAlbumContents:albumId withContents:albumContents]) {
                        RCLog(@"DATABASE ERROR: %@", [shotvibeDB lastErrorMessage]);
                    }

                    // Start downloading the photos in the background
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                        for (SLAlbumPhoto *p in [albumContents getPhotos].array) {
                            NSString *photoId = [[p getServerPhoto] getId];
                            NSString *photoUrl = [[p getServerPhoto] getUrl];
                            [self.photoFilesManager queuePhotoDownload:photoId
                                                              photoUrl:photoUrl
                                                             photoSize:[PhotoSize Thumb75]
                                                          highPriority:YES];
                            [self.photoFilesManager queuePhotoDownload:photoId
                                                              photoUrl:photoUrl
                                                             photoSize:self.photoFilesManager.DeviceDisplayPhotoSize
                                                          highPriority:NO];
                        }
                    });

                    // Add the Uploading photos to the end of album:
                    SLAlbumContents *updatedContents = [AlbumManager addUploadingPhotosToAlbumContents:albumContents uploadingPhotos:[self.photoUploadManager getUploadingPhotos:albumId]];

                    for(id<AlbumContentsListener> listener in data.listeners) {
                        [listener onAlbumContentsRefreshComplete:albumId albumContents:updatedContents];
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

+ (SLAlbumContents *)addUploadingPhotosToAlbumContents:(SLAlbumContents *)albumContents uploadingPhotos:(NSArray *)uploadingPhotos
{
    // Bail out early if there are no uploadingPhotos
    if (uploadingPhotos.count == 0) {
        return albumContents;
    }

    // In rare cases it is possible for uploaded photos to be added to the
    // server and contained in albumContents, before the client has
    // received the acknowledgment and so they will have not yet been
    // removed from uploadingPhotos. We must make sure to not show such duplicates

    // But first an optimization: if none of the uploadingPhotos are
    // being isAddingToAlbum, then there can be no duplicates, so just
    // add them all
    BOOL foundAddingToAlbum = NO;
    for (SLAlbumPhoto *u in uploadingPhotos) {
        AlbumUploadingPhoto *uploadingPhoto = (AlbumUploadingPhoto *)[u getUploadingPhoto];
        if ([uploadingPhoto isAddingToAlbum]) {
            foundAddingToAlbum = YES;
        }
    }
    if (!foundAddingToAlbum) {
        NSMutableArray *currentPhotos = [albumContents getPhotos].array;
        NSMutableArray *combinedPhotos = [NSMutableArray arrayWithArray:currentPhotos];
        [combinedPhotos addObjectsFromArray:uploadingPhotos];

        return [[SLAlbumContents alloc] initWithLong:[albumContents getId]
                                        withNSString:[albumContents getEtag]
                                        withNSString:[albumContents getName]
                                      withSLDateTime:[albumContents getDateCreated]
                                      withSLDateTime:[albumContents getDateUpdated]
                                            withLong:[albumContents getNumNewPhotos]
                                      withSLDateTime:[albumContents getLastAccess]
                                     withSLArrayList:[[SLArrayList alloc] initWithInitialArray:combinedPhotos]
                                     withSLArrayList:[albumContents getMembers]];
    }

    // Keep track of all the server photo ids in an appropriate efficient data
    // structure, so that duplicates can be found:
    NSMutableSet *serverPhotoIds = [[NSMutableSet alloc] init];
    for (SLAlbumPhoto *p in [albumContents getPhotos].array) {
        if ([p getServerPhoto]) {
            [serverPhotoIds addObject:[[p getServerPhoto] getId]];
        }
    }

    // Add only the uploading photos that don't appear in the server photos
    NSMutableArray *combinedPhotos = [NSMutableArray arrayWithArray:[albumContents getPhotos].array];
    for (SLAlbumPhoto *u in uploadingPhotos) {
        AlbumUploadingPhoto *uploadingPhoto = (AlbumUploadingPhoto *)[u getUploadingPhoto];

        if (![uploadingPhoto isAddingToAlbum] || ![serverPhotoIds containsObject:uploadingPhoto.photoId]) {
            [combinedPhotos addObject:u];
        }
    }

    return [[SLAlbumContents alloc] initWithLong:[albumContents getId]
                                    withNSString:[albumContents getEtag]
                                    withNSString:[albumContents getName]
                                  withSLDateTime:[albumContents getDateCreated]
                                  withSLDateTime:[albumContents getDateUpdated]
                                        withLong:[albumContents getNumNewPhotos]
                                  withSLDateTime:[albumContents getLastAccess]
                                 withSLArrayList:[[SLArrayList alloc] initWithInitialArray:combinedPhotos]
                                 withSLArrayList:[albumContents getMembers]];
}

- (void)cleanAlbumContentsListeners:(int64_t)albumId
{
    AlbumContentsData *data = [albumContentsObjs objectForKey:[NSNumber numberWithLongLong:albumId]];
    if (data.listeners.count == 0 && data.refreshStatus == IDLE) {
        [albumContentsObjs removeObjectForKey:[NSNumber numberWithLongLong:albumId]];
    }
}

- (void)reportAlbumUpdate:(int64_t)albumId
{
    [self refreshAlbumList];

    [self refreshAlbumContents:albumId];
}


// Set lastAccess to the timestamp of the most recent server photo in both the cache and the server,
// and trigger refresh for album list and albumContents.
- (void)markAlbumAsViewed:(SLAlbumContents *)album
{
    if ([album getPhotos].array.count > 0) {
        SLDateTime *mostRecentPhotoDate = nil;
        for (SLAlbumPhoto *photo in [album getPhotos]) {
            if ([photo getServerPhoto]) { // don't do this if album.photos[i] is not a serverPhoto
                if (!mostRecentPhotoDate) {
                    mostRecentPhotoDate = [[photo getServerPhoto] getDateAdded];
                } else {
                    long long photoTimestamp = [[[photo getServerPhoto] getDateAdded] getTimeStamp];
                    if ([mostRecentPhotoDate getTimeStamp] < photoTimestamp) {
                        mostRecentPhotoDate = [[photo getServerPhoto] getDateAdded];
                    }
                }
            }
        }

        SLDateTime *lastAccess = mostRecentPhotoDate;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSError *error;

            BOOL success = [shotvibeAPI markAlbumAsViewed:[album getId] lastAccess:lastAccess withError:&error];

            if (!success) {
                NSLog(@"### AlbumManager.markAlbumAsViewed: ERROR in shotvibeAPI markAlbumViewed:\n%@", [error localizedDescription]);
            } // TODO: handle error
        });

        if (![shotvibeDB markAlbumAsViewed:[album getId] lastAccess:lastAccess]) {
            RCLog(@"DATABASE ERROR: %@", [shotvibeDB lastErrorMessage]);
        }

        [self refreshAlbumListFromDb];
        [self refreshAlbumContentsFromDb:[album getId]];
    }
}


// Update album list with database version for all listeners
- (void)refreshAlbumListFromDb
{
    NSArray *albumListFromDb = [shotvibeDB getAlbumList];

    if (albumListFromDb) { // TODO: handle error
        for(id<AlbumListListener> listener in albumListListeners) {
            [listener onAlbumListBeginRefresh];
            [listener onAlbumListRefreshComplete:albumListFromDb];
        }
    }
}

// Update album contents with contents from database for all its listeners
- (void)refreshAlbumContentsFromDb:(int64_t)albumId
{
    AlbumContentsData *data = [albumContentsObjs objectForKey:[NSNumber numberWithLongLong:albumId]];

    if (data) {
        SLAlbumContents *albumContentsFromDb = [shotvibeDB getAlbumContents:albumId];

        if (albumContentsFromDb) { // TODO: handle error
            for (id<AlbumContentsListener> listener in data.listeners) {
                [listener onAlbumContentsBeginRefresh:albumId];
                [listener onAlbumContentsRefreshComplete:albumId albumContents:albumContentsFromDb];
            }
        }
    }
}


- (void)photoUploadAdditions:(int64_t)albumId
{
    AlbumContentsData *data = [albumContentsObjs objectForKey:[NSNumber numberWithLongLong:albumId]];
    if (!data) {
        return;
    }

    SLAlbumContents *cachedAlbum = [shotvibeDB getAlbumContents:albumId];

    // Add the Uploading photos to the end of album:
    SLAlbumContents *updatedContents = [AlbumManager addUploadingPhotosToAlbumContents:cachedAlbum uploadingPhotos:[self.photoUploadManager getUploadingPhotos:albumId]];

    for(id<AlbumContentsListener> listener in data.listeners) {
        [listener onAlbumContentsRefreshComplete:albumId albumContents:updatedContents];
    }
}

- (void)photoUploadProgress:(int64_t)albumId
{
    AlbumContentsData *data = [albumContentsObjs objectForKey:[NSNumber numberWithLongLong:albumId]];
    if (!data) {
        return;
    }

    for(id<AlbumContentsListener> listener in data.listeners) {
        [listener onAlbumContentsPhotoUploadProgress:albumId];
    }
}

- (void)photoUploadComplete:(int64_t)albumId
{
    AlbumContentsData *data = [albumContentsObjs objectForKey:[NSNumber numberWithLongLong:albumId]];
    if (!data) {
        return;
    }

    for(id<AlbumContentsListener> listener in data.listeners) {
        [listener onAlbumContentsPhotoUploadProgress:albumId];
    }
}

- (void)photoAlbumAllPhotosUploaded:(int64_t)albumId
{
    [self refreshAlbumContents:albumId];
}

- (void)photoUploadError:(NSError *)error
{
    // TODO ...
}

@end
