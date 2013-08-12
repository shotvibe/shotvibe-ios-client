//
//  AlbumPhoto.h
//  shotvibe
//
//  Created by John Gabelmann on 6/26/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Album, Member;

@interface AlbumPhoto : NSManagedObject

@property (nonatomic, retain) NSDate * date_created;
@property (nonatomic, retain) NSNumber * hasViewed;
@property (nonatomic, retain) NSNumber * isNew;// this is reset when you leave the app or visit an album
@property (nonatomic, retain) NSNumber * objectSyncStatus;
@property (nonatomic, retain) NSNumber * photoUploadStatus;
@property (nonatomic, retain) NSString * photo_id;
@property (nonatomic, retain) NSString * photo_url;
@property (nonatomic, retain) NSString * tempPhotoId;
@property (nonatomic, retain) Album *album;
@property (nonatomic, retain) Member *author;

@end
