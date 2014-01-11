//
//  AlbumServerPhoto.h
//  shotvibe
//
//  Created by benny on 8/20/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SL/AlbumUser.h"

@interface AlbumServerPhoto : NSObject

@property (nonatomic, readonly, copy) NSString *photoId;
@property (nonatomic, readonly, copy) NSString *url;
@property (nonatomic, readonly, strong) SLAlbumUser* author;
@property (nonatomic, readonly, copy) NSDate *dateAdded;
@property (nonatomic, readonly, copy) NSDate *lastAccess;

- (id)initWithPhotoId:(NSString *)photoId
                  url:(NSString *)url
               author:(SLAlbumUser *)author
            dateAdded:(NSDate *)dateAdded
           lastAccess:(NSDate *)lastAccess;

- (BOOL)isNewForMember:(int64_t)memberId;

@end
