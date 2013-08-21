//
//  ShotVibeDB.h
//  shotvibe
//
//  Created by benny on 8/19/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FMDatabase.h"
#import "AlbumContents.h"

@interface ShotVibeDB : NSObject
{
    FMDatabase *db;
}

- (id)init;

// Call this after any failed method
- (NSString *)lastErrorMessage;

// Returns an array of `AlbumSummary` objects
- (NSArray *)getAlbumList;

// `albums` must be an array of `AlbumSummary` objects
- (BOOL)setAlbumListWithAlbums:(NSArray *)albums;

- (AlbumContents *)getAlbumContents:(int64_t)albumId;

- (BOOL)setAlbumContents:(int64_t)albumId withContents:(AlbumContents *)albumContents;

@end
