//
//  AlbumUser.h
//  shotvibe
//
//  Created by benny on 8/20/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AlbumUser : NSObject

- (id)initWithMemberId:(int64_t)memberId
              nickname:(NSString *)nickname
             avatarUrl:(NSString *)avatarUrl;

@property (nonatomic, readonly, assign) int64_t memberId;
@property (nonatomic, readonly, copy) NSString *nickname;
@property (nonatomic, readonly, copy) NSString *avatarUrl;

@end
