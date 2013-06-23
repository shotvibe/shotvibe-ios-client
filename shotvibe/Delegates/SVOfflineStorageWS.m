//
//  SVOfflineStorageWS.m
//  shotvibe
//
//  Created by John Gabelmann on 4/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVDefines.h"
#import "SVOfflineStorageWS.h"
#import "Photo.h"
#import "Album.h"
#import "AlbumPhoto.h"

@interface SVOfflineStorageWS ()

@property (nonatomic, strong) NSOperationQueue *offlineStorageQueue;

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


- (void)saveLoadedImage:(UIImage *)image forPhotoObject:(Photo *)photo
{
    if (!self.offlineStorageQueue) {
        self.offlineStorageQueue = [[NSOperationQueue alloc] init];
    }
    
    __block Photo *blockPhoto = photo;
    
    [self.offlineStorageQueue addOperationWithBlock:^{
        NSData *imgData = UIImageJPEGRepresentation(image, 1);
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *documentsDirectoryPath = [documentsDirectory stringByAppendingPathComponent:blockPhoto.album.name];
        NSError *filePathError;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectoryPath
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&filePathError])
        {
            NSLog(@"Create directory error: %@", [filePathError localizedDescription]);
        }
        NSString *filePath = [NSString stringWithFormat:@"%@/%@.jpg", documentsDirectoryPath, blockPhoto.photoId];
        
        [imgData writeToFile:filePath atomically:YES];
    }];
    
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
    [self saveImageToFileSystem:imageData forPhotoId:photoId inAlbumWithId:[albumId stringValue]];
}



/*
 * consolidated method to handle centric photo saves to file sytem
 */
- (void) saveImageToFileSystem:(NSData *)imageData forPhotoId:(NSString *)photoId inAlbumWithId:(NSString *)albumId
{
    if (!self.offlineStorageQueue) {
        self.offlineStorageQueue = [[NSOperationQueue alloc] init];
    }
    
    
    [self.offlineStorageQueue addOperationWithBlock:^{
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
        if ([imageData writeToFile:filePath atomically:NO]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSString *photoIdToPost = [NSString stringWithString:photoId];
                [[NSNotificationCenter defaultCenter] postNotificationName:kSDSyncEnginePhotoSavedToDiskNotification object:photoIdToPost];
                
            });
        }
    }];
}




- (void)cleanupOfflineStorageForAlbum:(Album *)album
{
    if (!self.offlineStorageQueue) {
        self.offlineStorageQueue = [[NSOperationQueue alloc] init];
    }
    
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
    if (!self.offlineStorageQueue) {
        self.offlineStorageQueue = [[NSOperationQueue alloc] init];
    }
    
    [self.offlineStorageQueue addOperationWithBlock:^{
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
    }];
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
