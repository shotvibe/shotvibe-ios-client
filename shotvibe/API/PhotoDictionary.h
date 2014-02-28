//
//  PhotoDictionary.h
//  shotvibe
//
//  Created by Oblosys on 23-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AlbumUploadingPhoto.h"

@interface PhotoDictionary : NSObject

/*
 * Dictionary data structure for keeping track of lists of AlbumUploadingPhotos indexed by an album id.
 *
 * NOTE: this code is not thread safe
 *
 * TODO: AlbumUploadingPhotos now have an albumId property, so we can remove it as a parameter in the methods below
 */

- (void)addPhoto:(AlbumUploadingPhoto *)photo album:(int64_t)albumId;

- (void)addPhotos:(NSArray *)photos album:(int64_t)albumId;

- (void)removePhoto:(AlbumUploadingPhoto *)photo album:(int64_t)albumId;

- (void)removePhotos:(NSArray *)photos album:(int64_t)albumId;

- (NSArray *)getAllPhotosForAlbum:(int64_t)albumId;

- (void)removeAllPhotosForAlbum:(int64_t)albumId;

- (NSArray *)getAllAlbumIds;

- (NSArray *)getAllPhotos;

@end
