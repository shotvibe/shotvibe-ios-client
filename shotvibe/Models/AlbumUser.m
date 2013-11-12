//
//  AlbumUser.m
//  shotvibe
//
//  Created by benny on 8/20/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AlbumUser.h"

@implementation AlbumUser

- (id)initWithMemberId:(int64_t)memberId
              nickname:(NSString *)nickname
			 avatarUrl:(NSString *)avatarUrl
		  inviteStatus:(NSString *)inviteStatus
{
    self = [super init];

    if (self) {
        _memberId = memberId;
        _nickname = nickname;
        _avatarUrl = avatarUrl;
		_inviteStatus = inviteStatus;
    }

    return self;
}

@end
