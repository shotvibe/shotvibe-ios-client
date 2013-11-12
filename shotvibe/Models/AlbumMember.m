//
//  AlbumMember.m
//  shotvibe
//
//  Created by benny on 11/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AlbumMember.h"

@implementation AlbumMember

- (id)initWithAlbumUser:(AlbumUser *)user inviteStatus:(AlbumMemberInviteStatus)inviteStatus
{
    self = [super init];

    if (self) {
        _user = user;
        _inviteStatus = inviteStatus;
    }

    return self;
}

@end
