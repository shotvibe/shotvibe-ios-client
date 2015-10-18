//
//  GalleryPhotoUploadRequest.h
//  shotvibe
//
//  Created by raptor on 9/23/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AssetsLibrary/AssetsLibrary.h>

#import "SL/PhotoUploadRequest.h"

@interface GalleryPhotoUploadRequest : NSObject <SLPhotoUploadRequest>

- (id)initWithAsset:(ALAsset *)asset;

@end
