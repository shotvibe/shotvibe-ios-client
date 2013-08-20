//
//  ShotVibeAPI.h
//  shotvibe
//
//  Created by benny on 8/10/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AuthData.h"
#import "AlbumContents.h"

@interface ShotVibeAPI : NSObject

@property (nonatomic, copy, readonly) AuthData *authData;

- (id)init;

- (id)initWithAuthData:(AuthData *)authData;

- (BOOL)registerDevicePushWithDeviceToken:(NSString *)deviceToken error:(NSError**)error;

// Returns an array of `AlbumSummary` objects
- (NSArray *)getAlbumsWithError:(NSError **)error;

- (AlbumContents *)getAlbumContents:(int64_t)albumId withError:(NSError **)error;

- (AlbumContents *)createNewBlankAlbum:(NSString *)albumName withError:(NSError **)error;

@end
