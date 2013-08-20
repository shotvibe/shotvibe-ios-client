//
//  AlbumPhoto.h
//  shotvibe
//
//  Created by benny on 8/20/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AlbumServerPhoto.h"

@interface AlbumPhoto : NSObject

- (id)initWithAlbumServerPhoto:(AlbumServerPhoto *)photo;

@property (nonatomic, readonly, strong) AlbumServerPhoto *serverPhoto;

@end
