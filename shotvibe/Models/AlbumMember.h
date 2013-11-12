//
//  AlbumMember.h
//  shotvibe
//
//  Created by benny on 11/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AlbumUser.h"

typedef NS_ENUM(NSInteger, AlbumMemberInviteStatus) {
    AlbumMemberInviteStatusUnknown,
    AlbumMemberJoined,
    AlbumMemberSmsSent,
    AlbumMemberInvitationViewed,
};

@interface AlbumMember : NSObject

- (id)initWithAlbumUser:(AlbumUser *)user inviteStatus:(AlbumMemberInviteStatus)inviteStatus;

@property (nonatomic, readonly, strong) AlbumUser *user;
@property (nonatomic, readonly, assign) AlbumMemberInviteStatus inviteStatus;

@end
