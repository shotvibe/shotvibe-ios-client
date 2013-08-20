//
//  AlbumMember.m
//  shotvibe
//
//  Created by benny on 8/20/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AlbumMember.h"

@implementation AlbumMember

- (id)initWithMemberId:(int64_t)memberId
              nickname:(NSString *)nickname
             avatarUrl:(NSString *)avatarUrl
{
    self = [super init];

    if (self) {
        _memberId = memberId;
        _nickname = nickname;
        _avatarUrl = avatarUrl;
    }

    return self;
}

@end
