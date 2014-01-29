//
//  PhotoDictionary.m
//  shotvibe
//
//  Created by Oblosys on 23-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "PhotoDictionary.h"

@implementation PhotoDictionary {
    NSMutableDictionary *photosIndexedByAlbum_; // (int64_t)albumId -> NSMutableArray of (PhotoUploadRequest *)
}

- (id)init
{
    self = [super init];

    if (self) {
        photosIndexedByAlbum_ = [[NSMutableDictionary alloc] init];
    }
    return self;
}


- (void)addPhoto:(AlbumUploadingPhoto *)photo album:(int64_t)albumId
{
    [self addPhotos:@[photo] album:albumId];
}


- (void)addPhotos:(NSArray *)photos album:(int64_t)albumId
{
    NSMutableArray *photosAlreadyInQueue = [photosIndexedByAlbum_ objectForKey:[NSNumber numberWithLongLong:albumId]];

    if (!photosAlreadyInQueue) { // create a new album entry, if necessary
        photosAlreadyInQueue = [[NSMutableArray alloc] init];
        [photosIndexedByAlbum_ setObject:photosAlreadyInQueue forKey:[NSNumber numberWithLongLong:albumId]];
    }
    [photosAlreadyInQueue addObjectsFromArray:photos];
}


// Does nothing if photo is not stored under key albumId
- (void)removePhoto:(AlbumUploadingPhoto *)photo album:(int64_t)albumId
{
    [self removePhotos:@[photo] album:albumId];
}


// Does nothing for photos that are not stored under key albumId
- (void)removePhotos:(NSArray *)photos album:(int64_t)albumId
{
    NSMutableArray *photosInQueue = [photosIndexedByAlbum_ objectForKey:[NSNumber numberWithLongLong:albumId]];

    if (photosInQueue) {
        [photosInQueue removeObjectsInArray:photos]; // removeObjectsInArray ignores photos not in photosQueue

        if ([photosInQueue count] == 0) { // get rid of the album entry if this removal made it empty
            [photosIndexedByAlbum_ removeObjectForKey:[NSNumber numberWithLongLong:albumId]];
        }
    }
}


- (NSArray *)getPhotosForAlbum:(int64_t)albumId
{ // return a non-mutable array for safety
    return [NSArray arrayWithArray:[photosIndexedByAlbum_ objectForKey:[NSNumber numberWithLongLong:albumId]]];
}


- (void)removeAllPhotosForAlbum:(int64_t)albumId
{
    [photosIndexedByAlbum_ removeObjectForKey:[NSNumber numberWithLongLong:albumId]];
}


- (NSArray *)getAllAlbumIds
{
    return photosIndexedByAlbum_.allKeys;
}


// Return AlbumUploadingPhotos for all albums
- (NSArray *)getAllPhotos
{
    NSMutableArray *allPhotos = [[NSMutableArray alloc] init];

    for (NSNumber *albumId in photosIndexedByAlbum_.allKeys) {
        [allPhotos addObjectsFromArray:[photosIndexedByAlbum_ objectForKey:albumId]];
    }

    return [NSArray arrayWithArray:allPhotos];
}


- (NSString *)description
{
    NSString *str = @"PhotoQueue:";
    for (NSNumber *albumId in photosIndexedByAlbum_.allKeys) {
        str = [NSString stringWithFormat:@"%@ (album:%@, #photos:%lu)", str, albumId, (unsigned long)[[photosIndexedByAlbum_ objectForKey:albumId] count]];
    }

    return str;
}


@end
