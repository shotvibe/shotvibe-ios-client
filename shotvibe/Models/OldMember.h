//
//  Member.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 6/26/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Album, OldAlbumPhoto;

@interface OldMember : NSManagedObject

@property (nonatomic, retain) NSString * avatar_url;
@property (nonatomic, retain) NSString * nickname;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSNumber * userId;
@property (nonatomic, retain) NSNumber * objectSyncStatus;
@property (nonatomic, retain) NSSet *albumPhotos;
@property (nonatomic, retain) NSSet *albums;
@end

@interface OldMember (CoreDataGeneratedAccessors)

- (void)addAlbumPhotosObject:(OldAlbumPhoto *)value;
- (void)removeAlbumPhotosObject:(OldAlbumPhoto *)value;
- (void)addAlbumPhotos:(NSSet *)values;
- (void)removeAlbumPhotos:(NSSet *)values;

- (void)addAlbumsObject:(Album *)value;
- (void)removeAlbumsObject:(Album *)value;
- (void)addAlbums:(NSSet *)values;
- (void)removeAlbums:(NSSet *)values;

@end
