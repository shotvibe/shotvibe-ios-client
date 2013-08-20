//
//  AlbumContents.m
//  shotvibe
//
//  Created by benny on 8/20/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AlbumContents.h"

@implementation AlbumContents

- (id)initWithAlbumId:(int64_t)albumId
                 etag:(NSString *)etag
                 name:(NSString *)name
          dateCreated:(NSDate *)dateCreated
          dateUpdated:(NSDate *)dateUpdated
               photos:(NSArray *)photos
              members:(NSArray *)members
{
    self = [super initWithAlbumId:albumId etag:etag name:name dateCreated:dateCreated dateUpdated:dateUpdated];

    if (self) {
        _photos = photos;
        _members = members;
    }

    return self;
}

@end
