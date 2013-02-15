//
//  Member.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>

@class Album;

@interface Member : NSManagedObject

#pragma mark - Properties

/**
 This member's default country
 */
@property (nonatomic, retain) NSString * defaultCountry;

/**
 This member's phone number
 */
@property (nonatomic, retain) NSString * phoneNumber;

/**
 The unique ID for this member
 */
@property (nonatomic, retain) NSNumber * userId;

/**
 The albums shared by or with this member
 */
@property (nonatomic, retain) NSSet *albums;


/**
 This albums photoIds
 */
@property (nonatomic, strong) NSArray *photoIds;
@end


#pragma mark - Core Data Generated Accessors

@interface Member (CoreDataGeneratedAccessors)

- (void)addAlbumsObject:(Album *)value;
- (void)removeAlbumsObject:(Album *)value;
- (void)addAlbums:(NSSet *)values;
- (void)removeAlbums:(NSSet *)values;

@end
