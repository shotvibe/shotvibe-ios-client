//
//  Album.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 6/26/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AlbumPhoto, Member;

@interface Album : NSManagedObject

@property (nonatomic, retain) NSNumber * albumId;
@property (nonatomic, retain) NSDate * date_created;
@property (nonatomic, retain) NSString * etag;
@property (nonatomic, retain) NSDate * last_updated;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * newPhotoTone;
@property (nonatomic, retain) NSNumber * notificationsOption;
@property (nonatomic, retain) NSNumber * objectSyncStatus;
@property (nonatomic, retain) NSNumber * pushNotificationsOption;
@property (nonatomic, retain) NSString * tempAlbumId;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSSet *albumPhotos;
@property (nonatomic, retain) NSSet *members;
@end

@interface Album (CoreDataGeneratedAccessors)

- (void)addAlbumPhotosObject:(AlbumPhoto *)value;
- (void)removeAlbumPhotosObject:(AlbumPhoto *)value;
- (void)addAlbumPhotos:(NSSet *)values;
- (void)removeAlbumPhotos:(NSSet *)values;

- (void)addMembersObject:(Member *)value;
- (void)removeMembersObject:(Member *)value;
- (void)addMembers:(NSSet *)values;
- (void)removeMembers:(NSSet *)values;

@end
