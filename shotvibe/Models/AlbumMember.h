//
//  AlbumMember.h
//  shotvibe
//
//  Created by benny on 8/20/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AlbumMember : NSObject

- (id)initWithMemberId:(int64_t)memberId
              nickname:(NSString *)nickname
             avatarUrl:(NSString *)avatarUrl
		  inviteStatus:(NSString *)inviteStatus;

@property (nonatomic, readonly, assign) int64_t memberId;
@property (nonatomic, readonly, copy) NSString *nickname;
@property (nonatomic, readonly, copy) NSString *avatarUrl;
@property (nonatomic, readonly, copy) NSString *inviteStatus;

@end
