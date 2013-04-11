//
//  SVBusinessDelegate.m
//  shotvibe
//
//  Created by John Gabelmann on 4/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVBusinessDelegate.h"
#import "SVOfflineStorageWS.h"
#import "Photo.h"

@implementation SVBusinessDelegate

+ (void)saveImage:(UIImage *)image forPhoto:(Photo *)photo
{
    SVOfflineStorageWS *workerSession = [[SVOfflineStorageWS alloc] init];
    
    [workerSession saveLoadedImage:image forPhotoObject:photo];
}


+ (void)cleanupOfflineStorageForAlbum:(Album *)album
{
    SVOfflineStorageWS *workerSession = [[SVOfflineStorageWS alloc] init];
    
    [workerSession cleanupOfflineStorageForAlbum:album];
}


+ (NSInteger)numberOfViewedImagesInAlbum:(Album *)album
{
    SVOfflineStorageWS *workerSession = [[SVOfflineStorageWS alloc] init];
    
    return [workerSession numberOfImagesSavedInAlbum:album];
}


+ (UIImage *)loadImageFromAlbum:(Album *)album withPath:(NSString *)path
{
    SVOfflineStorageWS *workerSession = [[SVOfflineStorageWS alloc] init];
    
    return [workerSession loadImageFromOfflineWithPath:path inAlbum:album];
}

@end
