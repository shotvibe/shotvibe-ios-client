//
//  AlbumPhotoBrowserDelegate.h
//  shotvibe
//
//  Created by benny on 8/26/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MWPhotoBrowser.h"

#import "AlbumContents.h"

@interface AlbumPhotoBrowserDelegate : NSObject <MWPhotoBrowserDelegate>

- (id)initWithAlbumContents:(AlbumContents *)albumContents;

@end
