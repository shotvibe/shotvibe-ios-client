//
//  SVEntityStore.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/7/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SVEntityStore : NSObject

#pragma mark - Class Methods

+ (SVEntityStore *)sharedStore;


#pragma mark - Instance Methods

- (void)userAlbums;
- (void)photosForAlbumWithID:(NSNumber *)albumID;
@end
