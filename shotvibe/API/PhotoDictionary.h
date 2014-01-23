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
 */

- (void)addPhoto:(AlbumUploadingPhoto *)photo album:(int64_t)albumId;

- (BOOL)removePhoto:(AlbumUploadingPhoto *)photo album:(int64_t)albumId;

- (NSArray *)getPhotosForAlbum:(int64_t)albumId;

- (void)removeAllPhotosForAlbum:(int64_t)albumId;

- (NSArray *)getAllAlbumIds;

- (NSArray *)getAllPhotos;

@end
