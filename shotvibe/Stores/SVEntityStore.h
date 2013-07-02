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


- (void)newAlbumWithName:(NSString *)albumName;

- (void)addPhotoWithID:(NSString *)photoId ToAlbumWithID:(NSString *)albumID WithCompletion:(void (^)(BOOL success, NSError *error))block;

- (void) registerPhoneNumber:(NSString *) phoneNumber withCountryCode:(NSString *) countryCode WithCompletion:(void (^)(BOOL success, NSString *confirmationCode, NSError *error))block;

- (void) validateRegistrationCode:(NSString *) registrationCode withConfirmationCode:(NSString *) confirmationCode  WithCompletion:(void (^)(BOOL success, NSString *authToken, NSString *userId,  NSError *error))block;

- (void)uploadPhoto:(NSString *)photoId withImageData:(NSData *)imageData;


#pragma mark - FRC Methods

- (NSFetchedResultsController *)allAlbumsForCurrentUserWithDelegate:(id)delegate;
- (NSFetchedResultsController *)allAlbumsMatchingSearchTerm:(NSString *)searchTerm WithDelegate:(id)delegate;
- (NSFetchedResultsController *)allPhotosForAlbum:(Album *)anAlbum WithDelegate:(id)delegate;


#pragma mark - Album Methods

- (void)setAllPhotosToHasViewedInAlbum:(Album *)anAlbum;


#pragma mark - Image Method
- (void)getImageForPhoto:(AlbumPhoto *)aPhoto WithCompletion:(void (^)(UIImage *image))block;
// Need to be able to just do a hard pull on the image without blocks for the detail view. This is OK because the photo detail view manages its own loading and cache
- (UIImage *)getImageForPhoto:(AlbumPhoto *)aPhoto;

- (void)getImageDataForImageID:(NSString *)imageID WithCompletion:(void (^)(NSData *imageData))block;

- (void)writeImageData:(NSData *)imageData toDiskForImageID:(NSString *)imageID WithCompletion:(void (^)(BOOL success, NSURL *fileURL, NSError *error))block;
@end
