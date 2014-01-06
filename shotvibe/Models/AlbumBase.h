//
//  AlbumBase.h
//  shotvibe
//
//  Created by benny on 8/20/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AlbumBase : NSObject

- (id)initWithAlbumId:(int64_t)albumId
                 etag:(NSString *)etag
                 name:(NSString *)name
          dateCreated:(NSDate *)dateCreated
          dateUpdated:(NSDate *)dateUpdated
         numNewPhotos:(int64_t)numNewPhotos
           lastAccess:(NSDate *)lastAccess;

@property (nonatomic, readonly, assign) int64_t albumId;
@property (nonatomic, readonly, copy) NSString *etag;
@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, copy) NSDate *dateCreated;
@property (nonatomic, readonly, copy) NSDate *dateUpdated;
@property (nonatomic, readonly, assign) int64_t numNewPhotos;
@property (nonatomic, readonly, copy) NSDate *lastAccess;

@end
