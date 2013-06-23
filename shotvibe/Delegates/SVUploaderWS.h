//
//  SVUploaderWS.h
//  shotvibe
//
//  Created by Peter Kasson on 6/22/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SVUploaderWS : NSObject


- (void) startSync;

- (void)addPhoto:(NSString *)photoId withAlbumId:(NSNumber *)albumId;
- (void)changeStatusForPhoto:(NSString *)photoId withAlbumId:(NSNumber *)albumId toStatus:(NSNumber *) syncStatus;
- (void)deletePhoto:(NSString *)photoId withAlbumId:(NSNumber *)albumId;


@end
