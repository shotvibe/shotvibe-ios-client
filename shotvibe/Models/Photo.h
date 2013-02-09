//
//  Photo.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>

@class Album;

@interface Photo : NSManagedObject

#pragma mark - Properties

/**
 The member which created this photo.
 */
@property (nonatomic, retain) NSNumber * author;

/**
 The date this photo was created
 */
@property (nonatomic, retain) NSDate * dateCreated;

/**
 This photo's unique ID
 */
@property (nonatomic, retain) NSNumber * photoId;

/**
 This photo's resource URI
 */
@property (nonatomic, retain) NSString * photoUrl;

/**
 The album this photo belongs to.
 */
@property (nonatomic, retain) Album *album;

@end
