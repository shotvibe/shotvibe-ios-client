//
//  SVEntityStore.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/7/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AFHTTPClient.h"
#import "OldAlbum.h"
#import <Foundation/Foundation.h>

@interface SVEntityStore : AFHTTPClient

#pragma mark - Class Methods

+ (SVEntityStore *)sharedStore;


#pragma mark - Registration Methods

- (void)registerPhoneNumber:(NSString *) phoneNumber withCountryCode:(NSString *) countryCode WithCompletion:(void (^)(BOOL success, NSString *confirmationCode, NSError *error))block;
- (void)validateRegistrationCode:(NSString *) registrationCode withConfirmationCode:(NSString *) confirmationCode  WithCompletion:(void (^)(BOOL success, NSString *authToken, NSString *userId,  NSError *error))block;

- (void)invitePhoneNumbers:(NSDictionary*)phoneNumbers toAlbumId:(NSString *)albumId WithCompletion:(void (^)(BOOL success, NSError *error))block;

#pragma mark - FRC Methods

- (NSFetchedResultsController *)allAlbumsForCurrentUserWithDelegate:(id)delegate;
- (NSFetchedResultsController *)allAlbumsMatchingSearchTerm:(NSString *)searchTerm WithDelegate:(id)delegate;
- (NSFetchedResultsController *)allPhotosForAlbum:(OldAlbum *)anAlbum WithDelegate:(id)delegate;


#pragma mark - Album Methods

- (void)newAlbumWithName:(NSString *)albumName andUserID:(NSNumber *)userID;
- (void)addPhotoWithID:(NSString *)photoId ToAlbumWithID:(NSString *)albumID WithCompletion:(void (^)(BOOL success, NSError *error))block;
- (void)leaveAlbum:(OldAlbum*)album completion:(void (^)(BOOL success, NSError *error))block;
- (void)deleteAlbum:(OldAlbum*)album;

#pragma mark - Image Methods

@property (nonatomic, strong) NSURL *imageDataDirectory;
- (void)wipe;

- (void)setAllPhotosToNotNew;
- (void)setPhotosInAlbumToNotNew:(OldAlbum*)album;
- (void)setPhotoAsViewed:(NSString *)photoId;
- (void)getImageForPhoto:(OldAlbumPhoto *)aPhoto WithCompletion:(void (^)(UIImage *image))block;
- (void)getImageForPhotoData:(OldAlbumPhoto *)aPhoto WithCompletion:(void (^)(NSData *imageData, BOOL success))block;
// Need to be able to just do a hard pull on the image without blocks for the detail view. This is OK because the photo detail view manages its own loading and cache
- (UIImage *)getImageForPhoto:(OldAlbumPhoto *)aPhoto;
- (void)getImageDataForImageID:(NSString *)imageID WithCompletion:(void (^)(NSData *imageData))block;
- (void)getFullsizeImageDataForImageID:(NSString *)imageID WithCompletion:(void (^)(NSData *imageData))block;
- (void)writeImageData:(NSData *)imageData toDiskForImageID:(NSString *)imageID WithCompletion:(void (^)(BOOL success, NSURL *fileURL, NSError *error))block;
- (void)deletePhoto:(OldAlbumPhoto *)aPhoto;

@end
