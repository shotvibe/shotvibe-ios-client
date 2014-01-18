//
//  ShotVibeDB.h
//  shotvibe
//
//  Created by benny on 8/19/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FMDatabase.h"
#import "SL/AlbumContents.h"

@class SLHashMap;

@interface ShotVibeDB : NSObject
{
    FMDatabase *db;
}

- (id)init;

// Returns an array of `AlbumSummary` objects
- (SLArrayList *)getAlbumList;

// Returns a dictionary mapping `NSNumber` values (wrapping `int64_t` values) to `NSString` values
- (SLHashMap *)getAlbumListEtagValues;

// `albums` must be an array of `AlbumSummary` objects
- (void)setAlbumListWithAlbums:(NSMutableArray *)albums;

- (SLAlbumContents *)getAlbumContents:(int64_t)albumId;

- (void)setAlbumContents:(int64_t)albumId withContents:(SLAlbumContents *)albumContents;

- (void)markAlbumAsViewed:(int64_t)albumId lastAccess:(SLDateTime *)lastAccess;

@end
