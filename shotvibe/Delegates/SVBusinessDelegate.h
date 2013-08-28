//
//  SVBusinessDelegate.h
//  shotvibe
//
//  Created by John Gabelmann on 4/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <Foundation/Foundation.h>

@class OldAlbum;
@class OldAlbumPhoto;

@interface SVBusinessDelegate : NSObject

// Offline Storage Methods
+ (BOOL)doesPhotoWithId:(NSString *)photoId existForAlbumId:(id)albumId;

+ (void)saveImageData:(NSData *)imageData forPhoto:(OldAlbumPhoto *)photo inAlbumWithId:(id)albumId;
+ (void)saveUploadedPhotoImageData:(NSData *)imageData forPhotoId:(NSString *)photoId withAlbumId:(NSString *)albumId;

+ (void)cleanupOfflineStorageForAlbum:(OldAlbum *)album;
+ (NSInteger)numberOfViewedImagesInAlbum:(OldAlbum *)album;
+ (UIImage *)loadImageFromAlbum:(OldAlbum *)album withPath:(NSString *)path;
+ (void)loadImageFromAlbum:(OldAlbum *)album withPath:(NSString *)path WithCompletion:(void (^)(UIImage *image, NSError *error))block;

+ (UIImage *)getRandomThumbnailPlaceholder;

// ALAssset Storage Methods
+ (void)loadAllLocalAlbumsOnDeviceWithCompletion:(void (^)(NSArray *albums, NSError *error))block;
+ (void)loadAllAssetsForAlbumGroup:(ALAssetsGroup *)group WithCompletion:(void (^)(NSArray *assets, NSError *error))block;


// URL Fetching methods
+ (NSURL *)getURLForPhoto:(OldAlbumPhoto *)aPhoto;

// user registration
+ (void) registerPhoneNumber:(NSString *) phoneNumber withCountryCode:(NSString *) countryCode WithCompletion:(void (^)(BOOL success, NSString *confirmationCode, NSError *error))block;
+ (void) validateRegistrationCode:(NSString *) confirmationCode withConfirmationCode:(NSString *) confirmationCode WithCompletion:(void (^)(BOOL success, NSString *authToken, NSString *userId,  NSError *error))block;

+ (BOOL) hasUserBeenAuthenticated;

// Album management options
+ (void) leaveAlbum:(OldAlbum*)album completion:(void (^)(BOOL success))block;


@end
