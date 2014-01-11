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
               author:(SLAlbumUser *)author
            dateAdded:(NSDate *)dateAdded
           lastAccess:(NSDate *)lastAccess

{
    self = [super init];

    if (self) {
        _photoId = photoId;
        _url = url;
        _author = author;
        _dateAdded = dateAdded;
        _lastAccess = lastAccess;
    }

    return self;
}

// Return YES if the photo was added after its album was last accessed and memberId is not the author.
- (BOOL)isNewForMember:(int64_t)memberId
{
    if ([self.author getMemberId] == memberId)
        return NO;
    else
        return self.lastAccess ? [self.dateAdded compare:self.lastAccess] == NSOrderedDescending : YES;
}

@end
