//
//  SVBusinessDelegate.h
//  shotvibe
//
//  Created by John Gabelmann on 4/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <Foundation/Foundation.h>

@class Photo;
@class Album;
@class AlbumPhoto;

@interface SVBusinessDelegate : NSObject

// Offline Storage Methods
+ (BOOL)doesPhoto:(NSString *)photo existForAlbumName:(NSString *)albumName;

+ (void)saveImageData:(NSData *)imageData forPhoto:(AlbumPhoto *)photo inAlbum:(NSString *)albumName;
+ (void)saveUploadedPhotoImageData:(NSData *)imageData forPhotoId:(NSString *)photoId inAlbum:(Album *)album;
+ (void)saveImage:(UIImage *)image forPhoto:(Photo *)photo;

+ (void)cleanupOfflineStorageForAlbum:(Album *)album;
+ (NSInteger)numberOfViewedImagesInAlbum:(Album *)album;
+ (UIImage *)loadImageFromAlbum:(Album *)album withPath:(NSString *)path;
+ (void)loadImageFromAlbum:(Album *)album withPath:(NSString *)path WithCompletion:(void (^)(UIImage *image, NSError *error))block;

// ALAssset Storage Methods
+ (void)loadAllLocalAlbumsOnDeviceWithCompletion:(void (^)(NSArray *albums, NSError *error))block;
+ (void)loadAllAssetsForAlbumGroup:(ALAssetsGroup *)group WithCompletion:(void (^)(NSArray *assets, NSError *error))block;
@end
