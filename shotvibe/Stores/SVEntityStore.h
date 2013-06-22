//
//  SVEntityStore.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/7/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "Album.h"
#import <Foundation/Foundation.h>

@interface SVEntityStore : AFHTTPClient

#pragma mark - Class Methods

+ (SVEntityStore *)sharedStore;


#pragma mark - Instance Methods

/**
 Album Methods
 */
- (void)userAlbums;

- (void)photosForAlbumWithID:(NSNumber *)albumID;

// - (void)photosForAlbumWithID:(NSNumber *)albumID atIndexPath:(NSIndexPath *)indexPath;
- (void)photosForAlbumWithID:(Album *) anAlbum atIndexPath:(NSIndexPath *)indexPath;

- (void)newAlbumWithName:(NSString *)albumName;

- (void)addPhotos:(NSArray *)photos ToAlbumWithID:(NSNumber *)albumID WithCompletion:(void (^)(BOOL success, NSError *error))block;

-(void)newUploadedPhotoForAlbum:(Album *) album withPhotoId:(NSString *) photoId;

@end
