//
//  UploadJob.h
//  shotvibe
//
//  Created by omer klein on 12/16/15.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SL/MediaType.h"
#import "SL/AlbumUploadingMedia.h"

@interface UploadJob : NSObject

- (id)initVideoUploadWithFile:(NSString *)filePath withPreviewImageFile:(NSString *)imageFile withAlbumId:(long long)albumId;

- (id)initPhotoUploadWithFile:(NSString *)filePath withAlbumId:(long long)albumId;

- (SLMediaTypeEnum *)getMediaType;

- (NSString *)getFilePath;
- (NSString *)getUniqueName;
- (long long)getAlbumId;
- (SLAlbumUploadingMedia *)getAlbumUploadingMedia;

- (void)setProgress:(float)progress;

+ (NSString *)generateUniqueName;

@end
