//
//  Album.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>

@class Member, Photo;

@interface Album : NSManagedObject

#pragma mark - Properties

/**
 The date this album was created
 */
@property (nonatomic, retain) NSDate * dateCreated;

/**
 This album's HTTP entity tag
 */
@property (nonatomic, retain) NSNumber * etag;

/**
 The unique ID for this album
 */
@property (nonatomic, retain) NSNumber * albumId;

/**
 The date the album was last updated
 */
@property (nonatomic, retain) NSDate * lastUpdated;

/**
 The album name
 */
@property (nonatomic, retain) NSString * name;

/**
 The album's resource URI
 */
@property (nonatomic, retain) NSString * url;

/**
 The ShotVibe members that this album is shared with
 */
@property (nonatomic, retain) NSSet *members;

/**
 The photos this album contains
 */
@property (nonatomic, retain) NSSet *photos;
@end


#pragma mark - Core Data Generated Accessors

@interface Album (CoreDataGeneratedAccessors)

- (void)addMembersObject:(Member *)value;
- (void)removeMembersObject:(Member *)value;
- (void)addMembers:(NSSet *)values;
- (void)removeMembers:(NSSet *)values;

- (void)addPhotosObject:(Photo *)value;
- (void)removePhotosObject:(Photo *)value;
- (void)addPhotos:(NSSet *)values;
- (void)removePhotos:(NSSet *)values;

@end
