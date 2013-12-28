//
//  AlbumSummary.m
//  shotvibe
//
//  Created by benny on 8/20/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AlbumSummary.h"

@implementation AlbumSummary

- (id)initWithAlbumId:(int64_t)albumId
                 etag:(NSString *)etag
                 name:(NSString *)name
          dateCreated:(NSDate *)dateCreated
          dateUpdated:(NSDate *)dateUpdated
         numNewPhotos:(int64_t)numNewPhotos
           lastAccess:(NSDate *)lastAccess
         latestPhotos:(NSArray *)latestPhotos
{
    self = [super initWithAlbumId:albumId etag:etag name:name dateCreated:dateCreated dateUpdated:dateUpdated numNewPhotos:numNewPhotos lastAccess:lastAccess];

    if (self) {
        _latestPhotos = latestPhotos;
    }

    return self;
}


@end
