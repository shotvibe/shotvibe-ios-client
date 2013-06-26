//
//  SVEntityStore.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/7/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AFHTTPClient.h"
#import "Album.h"
#import <Foundation/Foundation.h>

@interface SVEntityStore : AFHTTPClient

#pragma mark - Class Methods

+ (SVEntityStore *)sharedStore;


#pragma mark - Instance Methods

/**
 Album Methods
 */
- (NSFetchedResultsController *)allAlbumsForCurrentUserWithDelegate:(id)delegate;
- (NSFetchedResultsController *)allAlbumsMatchingSearchTerm:(NSString *)searchTerm WithDelegate:(id)delegate;
- (NSFetchedResultsController *)allPhotosForAlbum:(Album *)anAlbum WithDelegate:(id)delegate;

- (void)newAlbumWithName:(NSString *)albumName;

- (void)addPhotoWithID:(NSString *)photoId ToAlbumWithID:(NSNumber *)albumID WithCompletion:(void (^)(BOOL success, NSError *error))block;

- (void)uploadPhoto:(NSString *)photoId withImageData:(NSData *)imageData;
@end
