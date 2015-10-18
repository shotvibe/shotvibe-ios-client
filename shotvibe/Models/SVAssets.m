//
//  SVAssetRetrievalWS.m
//  shotvibe
//
//  Created by John Gabelmann on 5/2/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "ALAssetsLibrary+helper.h"
#import "SVAssets.h"

@implementation SVAssets

+ (void)loadAllLocalAlbumsOnDeviceWithCompletion:(void (^)(NSArray *albums, NSError *error))block
{
    __block NSMutableArray *assetGroups = [[NSMutableArray alloc] init];
    
    [[ALAssetsLibrary sharedLibrary] enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            //RCLog(@"Fetched Album: %@ - %i photos type %@", [group valueForProperty:ALAssetsGroupPropertyName], group.numberOfAssets, [group valueForProperty:ALAssetsGroupPropertyType]);
            
			// Camera roll type
			if ([[group valueForProperty:ALAssetsGroupPropertyType] intValue] == ALAssetsGroupSavedPhotos) {
				[assetGroups insertObject:group atIndex:0];
			}
			else if ([[group valueForProperty:ALAssetsGroupPropertyType] intValue] == ALAssetsGroupPhotoStream) {
				[assetGroups insertObject:group atIndex:1];
			}
			else {
				[assetGroups addObject:group];
			}
        }
        else
        {
            block(assetGroups, nil);
        }
    } failureBlock:^(NSError *error) {
        RCLog(@"Error fetching asset groups: %@", [error localizedDescription]);
        block(nil, error);
    }];
}


+ (void)loadAllAssetsForAlbumGroup:(ALAssetsGroup *)group WithCompletion:(void (^)(NSArray *assets, NSError *error))block
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
