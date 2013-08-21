//
//  AlbumContentsListener.h
//  shotvibe
//
//  Created by benny on 8/20/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AlbumContents.h"

@protocol AlbumContentsListener <NSObject>

- (void)onAlbumContentsBeginRefresh:(int64_t)albumId;

/**
 Is called on the main thread when a refresh is complete
 */
- (void)onAlbumContentsRefreshComplete:(int64_t)albumId albumContents:(AlbumContents *)album;

- (void)onAlbumContentsRefreshError:(int64_t)albumId error:(NSError *)error;

@end
