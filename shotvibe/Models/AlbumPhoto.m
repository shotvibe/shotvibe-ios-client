//
//  AlbumPhoto.m
//  shotvibe
//
//  Created by benny on 8/20/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AlbumPhoto.h"

@implementation AlbumPhoto

- (id)initWithAlbumServerPhoto:(AlbumServerPhoto *)photo
{
    self = [super init];

    if (self) {
        _serverPhoto = photo;
        _uploadingPhoto = nil;
    }

    return self;
}

- (id)initWithAlbumUploadingPhoto:(AlbumUploadingPhoto *)photo
{
    self = [super init];

    if (self) {
        _serverPhoto = nil;
        _uploadingPhoto = photo;
    }

    return self;
}

@end
