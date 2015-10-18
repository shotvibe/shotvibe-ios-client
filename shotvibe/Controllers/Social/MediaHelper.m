//
//  MediaHelper.m
//  shotvibe
//
//  Created by benny on 11/19/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

#import "MediaHelper.h"

@implementation MediaHelper

+ (void)saveImageToAlbum:(UIImage *)image toAlbum:(NSString *)albumName withCompletionBlock:(SaveImageCompletion)completionBlock
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];

    // write the image data to the assets library (camera roll)
    [library writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation

                          completionBlock:^(NSURL *assetURL, NSError *error) {
        // error handling
        if (error) {
            completionBlock(error);
            return;
        }

        // add the asset to the custom photo album
        [self addAssetURL:assetURL
                     toAlbum:albumName
         withCompletionBlock:completionBlock];
    }];
}


+ (void)addAssetURL:(NSURL *)assetURL toAlbum:(NSString *)albumName withCompletionBlock:(SaveImageCompletion)completionBlock
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];

    __block BOOL albumWasFound = NO;

    //search all photo albums in the library
    [library enumerateGroupsWithTypes:ALAssetsGroupAlbum

                           usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        // compare the names of the albums
        if ([albumName compare:[group valueForProperty:ALAssetsGroupPropertyName]] == NSOrderedSame) {
            // target album is found
            albumWasFound = YES;

            // get a hold of the photo's asset instance
            [library assetForURL:assetURL

                     resultBlock:^(ALAsset *asset) {
                // add photo to the target album
                [group addAsset:asset];

                // run the completion block
                completionBlock(nil);
            }


                    failureBlock:completionBlock];

            // album was found, bail out of the method
            return;
        }
        if (group == nil && albumWasFound == NO) {
            // photo albums are over, target album does not exist, thus create it

            __weak ALAssetsLibrary *weakSelf = library;

            // create new assets album
            [library addAssetsGroupAlbumWithName:albumName

                                     resultBlock:^(ALAssetsGroup *group) {
                // get the photo's instance
                [weakSelf assetForURL:assetURL

                          resultBlock:^(ALAsset *asset) {
                    // add photo to the newly created album
                    [group addAsset:asset];

                    // call the completion block
                    completionBlock(nil);
                }


                         failureBlock:completionBlock];
            }


                                    failureBlock:completionBlock];

            // should be the last iteration anyway, but just in case
            return;
        }
    }


                         failureBlock:completionBlock];
}


@end
