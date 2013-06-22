//
//  SVOfflineStorageWS.h
//  shotvibe
//
//  Created by John Gabelmann on 4/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Photo;
@class Album;
@class AlbumPhoto;

@interface SVOfflineStorageWS : NSObject

- (BOOL)doesPhoto:(NSString *)photo existForAlbumName:(NSString *)albumName;

- (void)saveLoadedImageData:(NSData *)imageData forPhotoObject:(AlbumPhoto *)photo inAlbum:(NSString *)albumName;
- (void)saveUploadedPhotoImageData:(NSData *)imageData forPhotoId:(NSString *)photoId inAlbum:(NSString *)albumName;
- (void)saveLoadedImage:(UIImage *)image forPhotoObject:(Photo *)photo;

- (void)cleanupOfflineStorageForAlbum:(Album *)album;
- (NSUInteger)numberOfImagesSavedInAlbum:(Album *)album;
- (void)loadImageFromOfflineWithPath:(NSString *)path inAlbum:(Album *)album WithCompletion:(void (^)(UIImage *image, NSError *error))block;
- (UIImage *)loadImageFromOfflineWithPath:(NSString *)path inAlbum:(Album *)album;
@end
