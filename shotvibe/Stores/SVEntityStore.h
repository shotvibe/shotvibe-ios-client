//
//  SVEntityStore.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/7/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "AFJSONRequestOperation.h"
#import "AlbumSummary.h"
#import "AlbumPhoto.h"
#import "AlbumMember.h"
#import "SVDefines.h"
#import "SVBusinessDelegate.h"

@interface SVEntityStore : AFHTTPClient

#pragma mark - Class Methods

+ (SVEntityStore *)sharedStore;

#pragma mark - Registration Methods

- (void)registerPhoneNumber:(NSString *) phoneNumber withCountryCode:(NSString *) countryCode WithCompletion:(void (^)(BOOL success, NSString *confirmationCode, NSError *error))block;
- (void)validateRegistrationCode:(NSString *) registrationCode withConfirmationCode:(NSString *) confirmationCode  WithCompletion:(void (^)(BOOL success, NSString *authToken, NSString *userId,  NSError *error))block;

- (void)invitePhoneNumbers:(NSDictionary*)phoneNumbers toAlbumId:(int64_t)albumId WithCompletion:(void (^)(BOOL success, NSError *error))block;


#pragma mark - Album Methods

- (void)newAlbumWithName:(NSString *)albumName andUserID:(NSNumber *)userID;
- (void)addPhotoWithID:(NSString *)photoId ToAlbumWithID:(int64_t)albumID WithCompletion:(void (^)(BOOL success, NSError *error))block;
- (void)leaveAlbum:(AlbumSummary*)album completion:(void (^)(BOOL success, NSError *error))block;
- (void)deleteAlbum:(AlbumSummary*)album;

#pragma mark - Image Methods

@property (nonatomic, strong) NSURL *imageDataDirectory;
- (NSURL *)imageDataDirectory;
- (void)wipe;

- (void)setAllPhotosToNotNew;
- (void)setPhotosInAlbumToNotNew:(AlbumSummary*)album;
- (void)setPhotoAsViewed:(NSString *)photoId;
- (void)getImageForPhoto:(AlbumPhoto *)aPhoto WithCompletion:(void (^)(UIImage *image))block;
- (void)getImageForPhotoData:(AlbumPhoto *)aPhoto WithCompletion:(void (^)(NSData *imageData, BOOL success))block;
// Need to be able to just do a hard pull on the image without blocks for the detail view. This is OK because the photo detail view manages its own loading and cache
- (UIImage *)getImageForPhoto:(AlbumPhoto *)aPhoto;
- (void)getImageDataForImageID:(NSString *)imageID WithCompletion:(void (^)(NSData *imageData))block;
- (void)getFullsizeImageDataForImageID:(NSString *)imageID WithCompletion:(void (^)(NSData *imageData))block;
- (void)writeImageData:(NSData *)imageData toDiskForImageID:(NSString *)imageID WithCompletion:(void (^)(BOOL success, NSURL *fileURL, NSError *error))block;
- (void)deletePhoto:(AlbumPhoto *)aPhoto;

@end
