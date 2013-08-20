//
//  AlbumListListener.h
//  shotvibe
//
//  Created by benny on 8/20/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AlbumListListener <NSObject>

- (void)onAlbumListBeginRefresh;

/**
 Is called on the main thread when a refresh is complete

 @param albums An array of `AlbumSummary` objects containing the current AlbumList
 */
- (void)onAlbumListRefreshComplete:(NSArray *)albums;

- (void)onAlbumListRefreshError:(NSError *)error;

@end
