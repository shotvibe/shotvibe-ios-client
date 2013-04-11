//
//  Album.h
//  shotvibe
//
//  Created by John Gabelmann on 4/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AlbumPhoto, Member, Photo;

@interface Album : NSManagedObject

@property (nonatomic, retain) NSNumber * albumId;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSNumber * etag;
@property (nonatomic, retain) NSDate * lastUpdated;
@property (nonatomic, retain) id memberIds;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) id photoIds;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSSet *members;
@property (nonatomic, retain) NSSet *photos;
@property (nonatomic, retain) NSSet *albumPhotos;
@end

@interface Album (CoreDataGeneratedAccessors)

- (void)addMembersObject:(Member *)value;
- (void)removeMembersObject:(Member *)value;
- (void)addMembers:(NSSet *)values;
- (void)removeMembers:(NSSet *)values;

- (void)addPhotosObject:(Photo *)value;
- (void)removePhotosObject:(Photo *)value;
- (void)addPhotos:(NSSet *)values;
- (void)removePhotos:(NSSet *)values;

- (void)addAlbumPhotosObject:(AlbumPhoto *)value;
- (void)removeAlbumPhotosObject:(AlbumPhoto *)value;
- (void)addAlbumPhotos:(NSSet *)values;
- (void)removeAlbumPhotos:(NSSet *)values;

@end
