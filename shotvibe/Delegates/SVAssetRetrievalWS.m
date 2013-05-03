//
//  SVAssetRetrievalWS.m
//  shotvibe
//
//  Created by John Gabelmann on 5/2/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "ALAssetsLibrary+helper.h"
#import "SVAssetRetrievalWS.h"

@implementation SVAssetRetrievalWS

- (void)loadAllLocalAlbumsOnDeviceWithCompletion:(void (^)(NSArray *albums, NSError *error))block
{
    __block NSMutableArray *assetGroups = [[NSMutableArray alloc] init];
    
    [[ALAssetsLibrary sharedLibrary] enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            NSLog(@"Fetched Album: %@ - %i photos", [group valueForProperty:ALAssetsGroupPropertyName], group.numberOfAssets);
            
            [assetGroups addObject:group];
        }
        else
        {
            block(assetGroups, nil);
        }
    } failureBlock:^(NSError *error) {
        NSLog(@"Error fetching asset groups: %@", [error localizedDescription]);
        block(nil, error);
    }];
}


- (void)loadAllAssetsForAlbumGroup:(ALAssetsGroup *)group WithCompletion:(void (^)(NSArray *assets, NSError *error))block
{
    __block NSMutableArray *assets = [[NSMutableArray alloc] init];
    
    [group setAssetsFilter:[ALAssetsFilter allPhotos]];
    
    [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if (result) {
            [assets addObject:result];
        }
        else
        {
            block(assets, nil);
        }
    }];
}

@end
