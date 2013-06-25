//
//  SVOfflineStorageWS.m
//  shotvibe
//
//  Created by John Gabelmann on 4/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVDefines.h"
#import "SVOfflineStorageWS.h"
#import "Album.h"
#import "AlbumPhoto.h"
#import "SVEntityStore.h"

@interface SVOfflineStorageWS ()

- (void) saveImageToFileSystem:(NSData *)imageData forPhotoId:(NSString *)photoId inAlbumWithId:(NSString *)albumId;

@end

@implementation SVOfflineStorageWS


/*
 * check to see if the photo exists
 */
- (BOOL)doesPhotoWithId:(NSString *)photoId existForAlbumId:(id)albumId
{
    BOOL exists = NO;
    
    NSString *albumIdAsString = nil;
    if ([albumId isKindOfClass:[NSNumber class]]) {
        albumIdAsString = [albumId stringValue];
    } else if ([albumId isKindOfClass:[NSString class]]) {
        albumIdAsString = albumId;
    } else {
        NSException *exception = [NSException exceptionWithName:@"SuppliedArgumentIsWrongTypeException"
                                                         reason:@"albumId should be either an NSNumber or NSString."
                                                       userInfo:nil];
        [exception raise];
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *documentsDirectoryPath = [documentsDirectory stringByAppendingPathComponent:albumIdAsString];
    
    NSString *filePath = [NSString stringWithFormat:@"%@/%@.jpg", documentsDirectoryPath, photoId];
    
    exists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    
    return exists;
}


/*
 * this is used when downloading photos for an album
 */
- (void)saveImageData:(NSData *)imageData forPhoto:(AlbumPhoto *)photo inAlbumWithId:(id)albumId
{
    NSString *albumIdAsString = nil;
    if ([albumId isKindOfClass:[NSNumber class]]) {
        albumIdAsString = [albumId stringValue];
    } else if ([albumId isKindOfClass:[NSString class]]) {
        albumIdAsString = albumId;
    } else {
        NSException *exception = [NSException exceptionWithName:@"SuppliedArgumentIsWrongTypeException"
                                                         reason:@"albumId should be either an NSNumber or NSString."
                                                       userInfo:nil];
        [exception raise];
    }    
    
    [self saveImageToFileSystem:imageData forPhotoId:photo.photoId inAlbumWithId:albumIdAsString];
}


/*
 * this is the 'immediate store' for the photo that is being requested to upload
 */
- (void)saveUploadedPhotoImageData:(NSData *)imageData forPhotoId:(NSString *)photoId inAlbumWithId:(NSNumber *)albumId
{
    [[SVEntityStore sharedStore] addPhotoWithID:photoId ToAlbumWithID:albumId WithCompletion:^(BOOL success, NSError *error) {
        
        if (success) {
            [self saveImageToFileSystem:imageData forPhotoId:photoId inAlbumWithId:[albumId stringValue]];
        }
        else
        {
            NSLog(@"There was an error saving the photo locally: %@", [error userInfo]);
        }
        
    }];

}

/*
 * consolidated method to handle centric photo saves to file sytem
 */
- (void)saveImageToFileSystem:(NSData *)imageData forPhotoId:(NSString *)photoId inAlbumWithId:(NSString *)albumId
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *documentsDirectoryPath = [documentsDirectory stringByAppendingPathComponent:albumId];
    NSError *filePathError;
    
    if (![[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectoryPath
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&filePathError])
    {
        NSLog(@"Create directory error: %@", [filePathError localizedDescription]);
    }
    
    NSString *filePath = [NSString stringWithFormat:@"%@/%@.jpg", documentsDirectoryPath, photoId];
    
    // TODO: After performance tuning is complete, we can pass YES for atomically:
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        if ([imageData writeToFile:filePath atomically:YES]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSManagedObjectContext *localContext = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
                
                NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Album"];
                
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"albumId = %@", albumId];
                fetchRequest.predicate = predicate;
                
                NSError *fetchError = nil;
                
                Album *localAlbum = (Album *)[[localContext executeFetchRequest:fetchRequest error:&fetchError] lastObject];
                
                NSString *photoIdToPost = [NSString stringWithString:photoId];
                [[NSNotificationCenter defaultCenter] postNotificationName:kSDSyncEnginePhotoSavedToDiskNotification object:photoIdToPost];
                [[NSNotificationCenter defaultCenter] postNotificationName:kSDSyncEngineSyncAlbumCompletedNotification object:localAlbum];
                
            });
        }
        
    });
}


- (void)cleanupOfflineStorageForAlbum:(Album *)album
{
    //    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //    NSString *documentsDirectory = [paths objectAtIndex:0];
    //    __block NSString *documentsDirectoryPath = [documentsDirectory stringByAppendingPathComponent:album.name];
    //
    //    NSArray *directory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath error:nil];
    
    // Build our photo paths
    //    NSMutableArray *photoPaths = [[NSMutableArray alloc] init];
    //    for (Photo *aPhoto in album.photos) {
    //
    //        [photoPaths addObject:[NSString stringWithFormat:@"%@.jpg", aPhoto.photoId]];
    //    }
    
    // Delete anything that doesn't match
    //    for (__block NSString *aPath in directory) {
    //        if (![photoPaths containsObject:aPath]) {
    //
    //            [self.offlineStorageQueue addOperationWithBlock:^{
    //                NSString *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectoryPath, aPath];
    //
    //             NSLog(@"deleting:  %@", filePath);
    //
    //             // 20130618 - this is an attempt to catch any problems, possibly the recent crash, that was in this block
    //
    //             @try
    //             {
    //              if([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    //              {
    //               [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    //               NSLog(@"deleting for file:  %@", filePath);
    //              }
    //             }
    //             @catch (NSException *exception)
    //             {
    //              NSLog(@"error - could not delete for file:  %@", filePath);
    //             }
    //
    //            }];
    //        }
    //    }
}


- (NSUInteger)numberOfImagesSavedInAlbum:(Album *)album
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *documentsDirectoryPath = [documentsDirectory stringByAppendingPathComponent:album.name];
    
    NSArray *directory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath error:nil];
    
    return directory.count;
}

// This is primarily used for loading in the images for the grid cells and album cells
- (void)loadImageFromOfflineWithPath:(NSString *)path inAlbum:(Album *)album WithCompletion:(void (^)(UIImage *image, NSError *error))block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *documentsDirectoryPath = [documentsDirectory stringByAppendingPathComponent:[album.albumId stringValue]];
        
        NSString *filePath = [NSString stringWithFormat:@"%@/%@.jpg", documentsDirectoryPath, path];
        
        UIImage *originalImage = [UIImage imageWithContentsOfFile:filePath];
        
        CGSize newSize = CGSizeMake(100, 100);
        
        float oldWidth = originalImage.size.width;
        float scaleFactor = newSize.width / oldWidth;
        
        float newHeight = originalImage.size.height * scaleFactor;
        float newWidth = oldWidth * scaleFactor;
        
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
        [originalImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        block(image, nil);
    });
}


- (UIImage *)loadImageFromOfflineWithPath:(NSString *)path inAlbum:(Album *)album
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *documentsDirectoryPath = [documentsDirectory stringByAppendingPathComponent:[album.albumId stringValue]];
    
    NSString *filePath = [NSString stringWithFormat:@"%@/%@.jpg", documentsDirectoryPath, path];
    
    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
    
    return image;
}
@end
