//
//  AlbumBase.m
//  shotvibe
//
//  Created by benny on 8/20/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AlbumBase.h"

@implementation AlbumBase

- (id)initWithAlbumId:(int64_t)albumId
                 etag:(NSString *)etag
                 name:(NSString *)name
          dateCreated:(NSDate *)dateCreated
          dateUpdated:(NSDate *)dateUpdated
           lastAccess:(NSDate *)lastAccess
{
    self = [super init];

    if (self) {
        _albumId = albumId;
        _etag = etag;
        _name = name;
        _dateCreated = dateCreated;
        _dateUpdated = dateUpdated;
        _lastAccess = lastAccess;
    }

    return self;
}


@end
