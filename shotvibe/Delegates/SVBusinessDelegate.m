//
//  SVBusinessDelegate.m
//  shotvibe
//
//  Created by John Gabelmann on 4/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVBusinessDelegate.h"
#import "SVOfflineStorageWS.h"
#import "SVAssetRetrievalWS.h"
#import "SVEntityStore.h"
#import "SVURLBuilderWS.h"
#import "SVDefines.h"
#import "AlbumSummary.h"
#import "AlbumPhoto.h"

@implementation SVBusinessDelegate


+ (BOOL)doesPhotoWithId:(NSString *)photoId existForAlbumId:(id)albumId
{
    SVOfflineStorageWS *workerSession = [[SVOfflineStorageWS alloc] init];
    
    return [workerSession doesPhotoWithId:photoId existForAlbumId:albumId];
}


+ (void)saveImageData:(NSData *)imageData forPhoto:(AlbumPhoto *)photo inAlbumWithId:(id)albumId
{
    SVOfflineStorageWS *workerSession = [[SVOfflineStorageWS alloc] init];
    
    [workerSession saveImageData:imageData forPhoto:photo inAlbumWithId:albumId];
}


+ (void)saveUploadedPhotoImageData:(NSData *)imageData forPhotoId:(NSString *)photoId withAlbumId:(int64_t)albumId
{
    SVOfflineStorageWS *workerSession = [[SVOfflineStorageWS alloc] init];
 
    [workerSession saveUploadedPhotoImageData:imageData forPhotoId:photoId inAlbumWithId:albumId];
}


+ (void)cleanupOfflineStorageForAlbum:(AlbumSummary *)album
{
    SVOfflineStorageWS *workerSession = [[SVOfflineStorageWS alloc] init];
    
    [workerSession cleanupOfflineStorageForAlbum:album];
}


+ (NSInteger)numberOfViewedImagesInAlbum:(AlbumSummary *)album
{
    SVOfflineStorageWS *workerSession = [[SVOfflineStorageWS alloc] init];
    
    return [workerSession numberOfImagesSavedInAlbum:album];
}


+ (void)loadImageFromAlbum:(AlbumSummary *)album withPath:(NSString *)path WithCompletion:(void (^)(UIImage *image, NSError *error))block
{
    SVOfflineStorageWS *workerSession = [[SVOfflineStorageWS alloc] init];
    
    [workerSession loadImageFromOfflineWithPath:path inAlbum:album WithCompletion:^(UIImage *image, NSError *error) {
        block(image, nil);
    }];
}


+ (UIImage *)loadImageFromAlbum:(AlbumSummary *)album withPath:(NSString *)path
{
    SVOfflineStorageWS *workerSession = [[SVOfflineStorageWS alloc] init];
    
    
    return [workerSession loadImageFromOfflineWithPath:path inAlbum:album];
}


+ (UIImage *)getRandomThumbnailPlaceholder
{
    SVOfflineStorageWS *workerSession = [[SVOfflineStorageWS alloc] init];
    
    return [workerSession defaultThumbnailImage];
}


+ (void)loadAllLocalAlbumsOnDeviceWithCompletion:(void (^)(NSArray *albums, NSError *error))block
{
    SVAssetRetrievalWS *workerSession = [[SVAssetRetrievalWS alloc] init];
    
    [workerSession loadAllLocalAlbumsOnDeviceWithCompletion:^(NSArray *albums, NSError *error) {
        // Just using this to forward our results
        block(albums, error);
    }];
}


+ (void)loadAllAssetsForAlbumGroup:(ALAssetsGroup *)group WithCompletion:(void (^)(NSArray *assets, NSError *error))block
{
    SVAssetRetrievalWS *workerSession = [[SVAssetRetrievalWS alloc] init];
    
    [workerSession loadAllAssetsForAlbumGroup:group WithCompletion:^(NSArray *assets, NSError *error) {
        // Just using this to forward our results
        block(assets, error);
    }];
}


+ (void) registerPhoneNumber:(NSString *) phoneNumber withCountryCode:(NSString *) countryCode WithCompletion:(void (^)(BOOL success, NSString *confirmationCode, NSError *error))block
{
 [[SVEntityStore sharedStore] registerPhoneNumber:phoneNumber withCountryCode:countryCode WithCompletion:^(BOOL success, NSString *confirmationCode, NSError *error) {
  
  NSLog(@"registerPhoneNumber - success/error:  %i, %@", success, confirmationCode);
  
  block(success, confirmationCode, error);
  
 }];
}


+ (NSURL *)getURLForPhoto:(AlbumPhoto *)aPhoto
{
    SVURLBuilderWS *workerSession = [[SVURLBuilderWS alloc] init];
    
    if (aPhoto.serverPhoto.url) {
        return [workerSession photoUrlWithString:aPhoto.serverPhoto.url];
    }
    else
    {
        return nil;
    }
}


+ (void) validateRegistrationCode:(NSString *) registrationCode withConfirmationCode:(NSString *) confirmationCode WithCompletion:(void (^)(BOOL success, NSString *authToken, NSString *userId,  NSError *error))block
{
 [[SVEntityStore sharedStore] validateRegistrationCode:registrationCode withConfirmationCode:(NSString *) confirmationCode  WithCompletion:^(BOOL success, NSString *authToken, NSString *userId, NSError *error) {
  
  NSLog(@"sendSMSConfirmationCode - success/error:  %i", success);
  
  block(success, authToken, userId, error);
  
 }];
}


+ (BOOL) hasUserBeenAuthenticated
{
    BOOL userIsAuthenticated = NO;
    
    NSString *userId        = [[NSUserDefaults standardUserDefaults] objectForKey:kApplicationUserId];
    NSString *userAuthToken = [[NSUserDefaults standardUserDefaults] objectForKey:kApplicationUserAuthToken];
    
    NSLog(@"userId:  %@, token:  %@", userId, userAuthToken);
    
    if(userId != nil && userAuthToken != nil)
    {
        userIsAuthenticated = YES;
        
        NSLog(@"hasUserBeenAuthenticated:  YES");
    }
    else
    {
        NSLog(@"hasUserBeenAuthenticated:  NO");
    }
    
    return userIsAuthenticated;
}



+ (void) leaveAlbum:(AlbumSummary*)album completion:(void (^)(BOOL success))block {
	
	[[SVEntityStore sharedStore] leaveAlbum:album completion:^(BOOL success, NSError *error) {
		
		NSLog(@"leaveAlbum - success/error:  %i", success);
		
		block(success);
		
	}];
}

@end

