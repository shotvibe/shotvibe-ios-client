//
//  SVOfflineStorageWS.h
//  shotvibe
//
//  Created by John Gabelmann on 4/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AlbumSummary;
@class AlbumPhoto;

@interface SVOfflineStorageWS : NSObject

- (BOOL)doesPhotoWithId:(NSString *)photoId existForAlbumId:(id)albumId;

- (void)saveImageData:(NSData *)imageData forPhoto:(AlbumPhoto *)photo inAlbumWithId:(id)albumId;
- (void)saveUploadedPhotoImageData:(NSData *)imageData forPhotoId:(NSString *)photoId inAlbumWithId:(int64_t)albumId;

- (void)cleanupOfflineStorageForAlbum:(AlbumSummary *)album;
- (NSUInteger)numberOfImagesSavedInAlbum:(AlbumSummary *)album;
- (void)loadImageFromOfflineWithPath:(NSString *)path inAlbum:(AlbumSummary *)album WithCompletion:(void (^)(UIImage *image, NSError *error))block;
- (UIImage *)loadImageFromOfflineWithPath:(NSString *)path inAlbum:(AlbumSummary *)album;

- (UIImage *)defaultThumbnailImage;
@end
