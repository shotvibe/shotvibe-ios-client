//
//  AlbumPhoto.h
//  shotvibe
//
//  Created by John Gabelmann on 4/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Album, Member;

@interface AlbumPhoto : NSManagedObject

@property (nonatomic, retain) id albumId;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSNumber * hasViewed;
@property (nonatomic, retain) NSString * photoId;
@property (nonatomic, retain) NSString * photoUrl;
@property (nonatomic, retain) NSNumber * objectSyncStatus;
@property (nonatomic, retain) NSString * tempPhotoId;
@property (nonatomic, retain) NSNumber * imageWasDownloaded;
@property (nonatomic, retain) Album *album;
@property (nonatomic, retain) Member *author;

@end
