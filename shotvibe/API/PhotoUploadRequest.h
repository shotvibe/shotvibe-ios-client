//
//  PhotoUploadRequest.h
//  shotvibe
//
//  Created by benny on 8/25/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>

@interface PhotoUploadRequest : NSObject

- (id)initWithAsset:(ALAsset *)asset;
- (id)initWithPath:(NSString *)path;

- (UIImage *)getThumbnail;

- (void)saveToFile;

- (NSString *)getFilename;

@end