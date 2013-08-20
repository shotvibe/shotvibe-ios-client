//
//  AlbumServerPhoto.h
//  shotvibe
//
//  Created by benny on 8/20/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AlbumServerPhoto : NSObject

- (id)initWithPhotoId:(NSString *)photoId
                  url:(NSString *)url
         authorUserId:(int64_t)authorUserId
       authorNickname:(NSString *)authorNickname
            dateAdded:(NSDate *)dateAdded;

@property (nonatomic, readonly, copy) NSString *photoId;
@property (nonatomic, readonly, copy) NSString *url;
@property (nonatomic, readonly, assign) int64_t authorUserId;
@property (nonatomic, readonly, copy) NSString *authorNickname;
@property (nonatomic, readonly, copy) NSDate *dateAdded;

@end
