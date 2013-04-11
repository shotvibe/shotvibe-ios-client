//
//  Member.h
//  shotvibe
//
//  Created by John Gabelmann on 4/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Album, AlbumPhoto, Photo;

@interface Member : NSManagedObject

@property (nonatomic, retain) id albumIds;
@property (nonatomic, retain) NSString * avatarUrl;
@property (nonatomic, retain) NSString * nickname;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSNumber * userId;
@property (nonatomic, retain) NSSet *albums;
@property (nonatomic, retain) NSSet *photos;
@property (nonatomic, retain) NSSet *albumPhotos;
@end

@interface Member (CoreDataGeneratedAccessors)

- (void)addAlbumsObject:(Album *)value;
- (void)removeAlbumsObject:(Album *)value;
- (void)addAlbums:(NSSet *)values;
- (void)removeAlbums:(NSSet *)values;

- (void)addPhotosObject:(Photo *)value;
- (void)removePhotosObject:(Photo *)value;
- (void)addPhotos:(NSSet *)values;
- (void)removePhotos:(NSSet *)values;

- (void)addAlbumPhotosObject:(AlbumPhoto *)value;
- (void)removeAlbumPhotosObject:(AlbumPhoto *)value;
- (void)addAlbumPhotos:(NSSet *)values;
- (void)removeAlbumPhotos:(NSSet *)values;

@end
