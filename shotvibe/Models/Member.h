//
//  Member.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Album;

@interface Member : NSManagedObject

#pragma mark - Properties

/**
 The unique ID for this member
 */
@property (nonatomic, strong) NSNumber *userId;


/**
 The  url for this member
 */
@property (nonatomic, strong) NSString *url;


/**
 The nickname for this member
 */
@property (nonatomic, strong) NSString *nickname;


/**
 The avatar image url for this member
 */
@property (nonatomic, strong) NSString *avatarUrl;


/**
 This member's albumIds
 */
@property (nonatomic, strong) NSArray *albumIds;


/**
 The albums shared by or with this member
 */
@property (nonatomic, strong) NSSet *albums;
@end


#pragma mark - Core Data Generated Accessors

@interface Member (CoreDataGeneratedAccessors)

- (void)addAlbumsObject:(Album *)value;
- (void)removeAlbumsObject:(Album *)value;
- (void)addAlbums:(NSSet *)values;
- (void)removeAlbums:(NSSet *)values;

@end
