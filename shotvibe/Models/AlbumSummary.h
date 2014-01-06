//
//  AlbumSummary.h
//  shotvibe
//
//  Created by benny on 8/20/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AlbumBase.h"

@interface AlbumSummary : AlbumBase

- (id)initWithAlbumId:(int64_t)albumId
                 etag:(NSString *)etag
                 name:(NSString *)name
          dateCreated:(NSDate *)dateCreated
          dateUpdated:(NSDate *)dateUpdated
         numNewPhotos:(int64_t)numNewPhotos
           lastAccess:(NSDate *)lastAccess
         latestPhotos:(NSArray *)latestPhotos;

// Array of `AlbumPhoto` objects
@property (nonatomic, strong, readonly) NSArray *latestPhotos;

@end
