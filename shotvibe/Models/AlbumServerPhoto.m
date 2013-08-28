//
//  AlbumServerPhoto.m
//  shotvibe
//
//  Created by benny on 8/20/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AlbumServerPhoto.h"

@implementation AlbumServerPhoto

- (id)initWithPhotoId:(NSString *)photoId
                  url:(NSString *)url
         authorUserId:(int64_t)authorUserId
       authorNickname:(NSString *)authorNickname
            dateAdded:(NSDate *)dateAdded
{
    self = [super init];

    if (self) {
        _photoId = photoId;
        _url = url;
        _authorUserId = authorUserId;
        _authorNickname = authorNickname;
        _dateAdded = dateAdded;
    }

    return self;
}

@end
