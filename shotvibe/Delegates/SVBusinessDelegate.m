//
//  SVBusinessDelegate.m
//  shotvibe
//
//  Created by John Gabelmann on 4/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVBusinessDelegate.h"
#import "SVOfflineStorageWS.h"
#import "SVAssetRetrievalWS.h"
#import "AlbumPhoto.h"
#import "Photo.h"

@implementation SVBusinessDelegate


+ (BOOL)doesPhoto:(NSString *)photo existForAlbumName:(NSString *)albumName
{
    SVOfflineStorageWS *workerSession = [[SVOfflineStorageWS alloc] init];
    
    return [workerSession doesPhoto:photo existForAlbumName:albumName];
}





+ (void)saveImageAlbumPhoto:(UIImage *)image forPhoto:(AlbumPhoto *)photo  :(NSString *) albumName
{
    SVOfflineStorageWS *workerSession = [[SVOfflineStorageWS alloc] init];
    
    [workerSession saveLoadedImageAlbumPhoto:image forPhotoObject:photo :albumName];
}


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


+ (void)loadImageFromAlbum:(Album *)album withPath:(NSString *)path WithCompletion:(void (^)(UIImage *image, NSError *error))block
{
    SVOfflineStorageWS *workerSession = [[SVOfflineStorageWS alloc] init];
    
    [workerSession loadImageFromOfflineWithPath:path inAlbum:album WithCompletion:^(UIImage *image, NSError *error) {
        block(image, nil);
    }];
}


+ (UIImage *)loadImageFromAlbum:(Album *)album withPath:(NSString *)path
{
    SVOfflineStorageWS *workerSession = [[SVOfflineStorageWS alloc] init];
    
    
    return [workerSession loadImageFromOfflineWithPath:path inAlbum:album];
}


+ (void)loadAllLocalAlbumsOnDeviceWithCompletion:(void (^)(NSArray *albums, NSError *error))block
{
    SVAssetRetrievalWS *workerSession = [[SVAssetRetrievalWS alloc] init];
    
    [workerSession loadAllLocalAlbumsOnDeviceWithCompletion:^(NSArray *albums, NSError *error) {
        // Just using this to forward our results
        block(albums, error);
    }];
}


+ (void)loadAllAssetsForAlbumGroup:(ALAssetsGroup *)group WithCompletion:(void (^)(NSArray *assets, NSError *error))block
{
    SVAssetRetrievalWS *workerSession = [[SVAssetRetrievalWS alloc] init];
    
    [workerSession loadAllAssetsForAlbumGroup:group WithCompletion:^(NSArray *assets, NSError *error) {
        // Just using this to forward our results
        block(assets, error);
    }];
}


@end
