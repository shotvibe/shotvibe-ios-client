//
//  SVUploaderDelegate.m
//  shotvibe
//
//  Created by Peter Kasson on 6/22/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVUploaderDelegate.h"

#import "SVUploaderWS.h"

@implementation SVUploaderDelegate


+ (void) startSync
{
    SVUploaderWS *workerSession = [[SVUploaderWS alloc] init];
    
    return [workerSession startSync];
}


+ (void)addPhoto:(NSString *)photoId withAlbumId:(NSNumber *)albumId
{
    SVUploaderWS *workerSession = [[SVUploaderWS alloc] init];
    
    return [workerSession addPhoto:photoId withAlbumId:albumId];
}


+ (void)changeStatusForPhoto:(NSString *)photoId withAlbumId:(NSNumber *)albumId toStatus:(NSNumber *) syncStatus
{
    SVUploaderWS *workerSession = [[SVUploaderWS alloc] init];
    
    return [workerSession changeStatusForPhoto:photoId withAlbumId:albumId toStatus:syncStatus];
}


+ (void)deletePhoto:(NSString *)photoId withAlbumId:(NSNumber *)albumId
{
    SVUploaderWS *workerSession = [[SVUploaderWS alloc] init];
    
    return [workerSession deletePhoto:photoId withAlbumId:albumId];
}



@end
