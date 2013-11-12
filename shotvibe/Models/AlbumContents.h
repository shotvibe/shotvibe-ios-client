//
//  AlbumContents.h
//  shotvibe
//
//  Created by benny on 8/20/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AlbumBase.h"

@interface AlbumContents : AlbumBase

- (id)initWithAlbumId:(int64_t)albumId
                 etag:(NSString *)etag
                 name:(NSString *)name
          dateCreated:(NSDate *)dateCreated
          dateUpdated:(NSDate *)dateUpdated
               photos:(NSArray *)photos
              members:(NSArray *)members;

// Array of `AlbumPhoto` objects
@property (nonatomic, strong, readonly) NSArray *photos;

// Array of `AlbumUser` objects
@property (nonatomic, strong, readonly) NSArray *members;

@end
