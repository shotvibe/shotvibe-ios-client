//
//  SVOfflineStorageWS.h
//  shotvibe
//
//  Created by John Gabelmann on 4/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OldAlbum;
@class OldAlbumPhoto;

@interface SVOfflineStorageWS : NSObject

- (BOOL)doesPhotoWithId:(NSString *)photoId existForAlbumId:(id)albumId;

- (void)saveImageData:(NSData *)imageData forPhoto:(OldAlbumPhoto *)photo inAlbumWithId:(id)albumId;
- (void)saveUploadedPhotoImageData:(NSData *)imageData forPhotoId:(NSString *)photoId inAlbumWithId:(NSString *)albumId;

- (void)cleanupOfflineStorageForAlbum:(OldAlbum *)album;
- (NSUInteger)numberOfImagesSavedInAlbum:(OldAlbum *)album;
- (void)loadImageFromOfflineWithPath:(NSString *)path inAlbum:(OldAlbum *)album WithCompletion:(void (^)(UIImage *image, NSError *error))block;
- (UIImage *)loadImageFromOfflineWithPath:(NSString *)path inAlbum:(OldAlbum *)album;

- (UIImage *)defaultThumbnailImage;
@end
