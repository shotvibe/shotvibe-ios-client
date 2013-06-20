//
//  SVOfflineStorageWS.m
//  shotvibe
//
//  Created by John Gabelmann on 4/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVOfflineStorageWS.h"
#import "Photo.h"
#import "Album.h"

@interface SVOfflineStorageWS ()

@property (nonatomic, strong) NSOperationQueue *offlineStorageQueue;


@end

@implementation SVOfflineStorageWS

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


- (void)cleanupOfflineStorageForAlbum:(Album *)album
{
    if (!self.offlineStorageQueue) {
        self.offlineStorageQueue = [[NSOperationQueue alloc] init];
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    __block NSString *documentsDirectoryPath = [documentsDirectory stringByAppendingPathComponent:album.name];
    
    NSArray *directory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath error:nil];
        
    // Build our photo paths
    NSMutableArray *photoPaths = [[NSMutableArray alloc] init];
    for (Photo *aPhoto in album.photos) {
        
        [photoPaths addObject:[NSString stringWithFormat:@"%@.jpg", aPhoto.photoId]];
    }
    
    // Delete anything that doesn't match
    for (__block NSString *aPath in directory) {
        if (![photoPaths containsObject:aPath]) {
         
//         omer's crash is somewhere in here ... 
         
            [self.offlineStorageQueue addOperationWithBlock:^{
                NSString *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectoryPath, aPath];

             // 20130618 - this is an attempt to catch any problems, possibly the recent crash, that was in this block
             
             @try {
              [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
              NSLog(@"deleting for file:  %@", filePath);
             }
             @catch (NSException *exception) {
              NSLog(@"error - could not delete for file:  %@", filePath);
             }
             
            }];
        }
    }
}


- (NSUInteger)numberOfImagesSavedInAlbum:(Album *)album
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *documentsDirectoryPath = [documentsDirectory stringByAppendingPathComponent:album.name];
    
    NSArray *directory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath error:nil];
    
    return directory.count;
}


- (void)loadImageFromOfflineWithPath:(NSString *)path inAlbum:(Album *)album WithCompletion:(void (^)(UIImage *image, NSError *error))block
{
    if (!self.offlineStorageQueue) {
        self.offlineStorageQueue = [[NSOperationQueue alloc] init];
    }
    
    [self.offlineStorageQueue addOperationWithBlock:^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *documentsDirectoryPath = [documentsDirectory stringByAppendingPathComponent:album.name];
        
        NSString *filePath = [NSString stringWithFormat:@"%@/%@.jpg", documentsDirectoryPath, path];
        
        UIImage *image = [UIImage imageWithContentsOfFile:filePath];
     
        block(image, nil);
    }];
}


- (UIImage *)loadImageFromOfflineWithPath:(NSString *)path inAlbum:(Album *)album
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *documentsDirectoryPath = [documentsDirectory stringByAppendingPathComponent:album.name];
    
    NSString *filePath = [NSString stringWithFormat:@"%@/%@.jpg", documentsDirectoryPath, path];
    
    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
    
    return image;
}
@end
