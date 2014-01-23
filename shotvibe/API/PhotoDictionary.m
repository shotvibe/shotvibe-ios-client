//
//  PhotoDictionary.m
//  shotvibe
//
//  Created by martijn on 23-01-14.
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
    NSMutableArray *photosAlreadyInQueue = [photosIndexedByAlbum_ objectForKey:[NSNumber numberWithLongLong:albumId]];

    if (!photosAlreadyInQueue) {
        photosAlreadyInQueue = [[NSMutableArray alloc] init];
        [photosIndexedByAlbum_ setObject:photosAlreadyInQueue forKey:[NSNumber numberWithLongLong:albumId]];
    }

    [photosAlreadyInQueue addObject:photo];
}


- (BOOL)removePhoto:(AlbumUploadingPhoto *)photo album:(int64_t)albumId
{
    NSMutableArray *photosInQueue = [photosIndexedByAlbum_ objectForKey:[NSNumber numberWithLongLong:albumId]];

    if (photosInQueue && [photosInQueue containsObject:photo]) {
        [photosInQueue removeObject:photo];

        if ([photosInQueue count] == 0) {
            [photosIndexedByAlbum_ removeObjectForKey:[NSNumber numberWithLongLong:albumId]];
        }
        return YES;
    } else {
        return NO;
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
