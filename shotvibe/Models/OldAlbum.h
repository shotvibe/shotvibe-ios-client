//
//  Album.h
//  shotvibe
//
//  Created by John Gabelmann on 7/2/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class OldAlbumPhoto, OldMember;

@interface OldAlbum : NSManagedObject

@property (nonatomic, retain) NSString * albumId;
@property (nonatomic, retain) NSDate * date_created;
@property (nonatomic, retain) NSString * etag;
@property (nonatomic, retain) NSDate * last_updated;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * notificationsOption;
@property (nonatomic, retain) NSNumber * objectSyncStatus;
@property (nonatomic, retain) NSNumber * pushNotificationsOption;
@property (nonatomic, retain) NSString * tempAlbumId;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSSet *albumPhotos;
@property (nonatomic, retain) NSSet *members;
@end

@interface OldAlbum (CoreDataGeneratedAccessors)

- (void)addAlbumPhotosObject:(OldAlbumPhoto *)value;
- (void)removeAlbumPhotosObject:(OldAlbumPhoto *)value;
- (void)addAlbumPhotos:(NSSet *)values;
- (void)removeAlbumPhotos:(NSSet *)values;

- (void)addMembersObject:(OldMember *)value;
- (void)removeMembersObject:(OldMember *)value;
- (void)addMembers:(NSSet *)values;
- (void)removeMembers:(NSSet *)values;

@end
