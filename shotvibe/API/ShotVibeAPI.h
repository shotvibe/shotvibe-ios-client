//
//  ShotVibeAPI.h
//  shotvibe
//
//  Created by benny on 8/10/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AuthData.h"
#import "SL/AlbumContents.h"
#import "SL/AlbumUser.h"

typedef NS_ENUM(NSInteger, AuthorizePhoneNumberResult) {
    AuthorizePhoneNumberError,
    AuthorizePhoneNumberOk,
    AuthorizePhoneNumberInvalidNumber
};

typedef NS_ENUM(NSInteger, ConfirmSMSCodeResult) {
    ConfirmSMSCodeError,
    ConfirmSMSCodeOk,
    ConfirmSMSCodeIncorrectCode
};

@interface ShotVibeAPI : NSObject

@property (nonatomic, copy, readonly) AuthData *authData;

- (id)init;

- (id)initWithAuthData:(AuthData *)authData;

- (BOOL)registerDevicePushWithDeviceToken:(NSString *)deviceToken error:(NSError**)error;

- (NSDictionary*)submitAddressBook:(NSDictionary *)dictionary error:(NSError**)error;
- (AuthorizePhoneNumberResult)authorizePhoneNumber:(NSString *)phoneNumber defaultCountry:(NSString *)defaultCountry error:(NSError **)error;

- (ConfirmSMSCodeResult)confirmSMSCode:(NSString *)confirmationCode
               deviceDeviceDescription:(NSString *)deviceDescription
                    defaultCountryCode:(NSString *)defaultCountryCode
                                 error:(NSError **)error;

- (SLAlbumUser *)getUserProfile:(int64_t)userId withError:(NSError **)error;

- (BOOL)setUserNickname:(int64_t)userId nickname:(NSString *)nickname withError:(NSError **)error;

- (BOOL)uploadUserAvatar:(int64_t)userId filePath:(NSString *)filePath uploadProgress:(void (^)(int, int))uploadProgress withError:(NSError **)error;

// Returns an array of `AlbumSummary` objects
- (NSArray *)getAlbumsWithError:(NSError **)error;

- (BOOL)markAlbumAsViewed:(int64_t)albumId lastAccess:(SLDateTime *)lastAccess withError:(NSError **)error;

- (SLAlbumContents *)getAlbumContents:(int64_t)albumId withError:(NSError **)error;

- (SLAlbumContents *)createNewBlankAlbum:(NSString *)albumName withError:(NSError **)error;

// Returns an array of `NSString` objects
- (NSArray *)photosUploadRequest:(int)numPhotos withError:(NSError **)error;

- (BOOL)photoUpload:(NSString *)photoId filePath:(NSString *)filePath uploadProgress:(void (^)(int, int))uploadProgress withError:(NSError **)error;

/**
 @param photoIds Array of `NSString` objects
 */
- (SLAlbumContents *)albumAddPhotos:(int64_t)albumId photoIds:(NSArray *)photoIds withError:(NSError **)error;
- (SLAlbumContents *)albumAddMembers:(int64_t)albumId phoneNumbers:(NSArray *)phoneNumbers withError:(NSError **)error;
- (BOOL)deletePhotos:(NSArray *)photos withError:(NSError **)error;

- (BOOL)leaveAlbumWithId:(int64_t)albumId;

@end
