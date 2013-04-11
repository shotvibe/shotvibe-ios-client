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

@implementation SVOfflineStorageWS

- (void)saveLoadedImage:(UIImage *)image forPhotoObject:(Photo *)photo
{
    NSData *imgData = UIImageJPEGRepresentation(image, 1);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *documentsDirectoryPath = [documentsDirectory stringByAppendingPathComponent:photo.album.name];
    NSError *filePathError;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectoryPath
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&filePathError])
    {
        NSLog(@"Create directory error: %@", [filePathError localizedDescription]);
    }
    NSString *filePath = [NSString stringWithFormat:@"%@/%@.jpg", documentsDirectoryPath, photo.photoId];
    
    [imgData writeToFile:filePath atomically:YES];
}


- (void)cleanupOfflineStorageForAlbum:(Album *)album
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *documentsDirectoryPath = [documentsDirectory stringByAppendingPathComponent:album.name];
    
    NSArray *directory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath error:nil];
        
    // Build our photo paths
    NSMutableArray *photoPaths = [[NSMutableArray alloc] init];
    for (Photo *aPhoto in album.photos) {
        
        [photoPaths addObject:[NSString stringWithFormat:@"%@.jpg", aPhoto.photoId]];
    }
    
    // Delete anything that doesn't match
    for (NSString *aPath in directory) {
        if (![photoPaths containsObject:aPath]) {
            NSString *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectoryPath, aPath];

            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
    }
}


- (NSUInteger)numberOfImagesSavedInAlbum:(Album *)album
{
    // Always sync before returning this
    [self cleanupOfflineStorageForAlbum:album];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *documentsDirectoryPath = [documentsDirectory stringByAppendingPathComponent:album.name];
    
    NSArray *directory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath error:nil];
    
    return directory.count;
}


- (UIImage *)loadImageFromOfflineWithPath:(NSString *)path inAlbum:(Album *)album
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *documentsDirectoryPath = [documentsDirectory stringByAppendingPathComponent:album.name];
    
    NSString *filePath = [NSString stringWithFormat:@"%@/%@.jpg", documentsDirectoryPath, path];
    
    return [UIImage imageWithContentsOfFile:filePath];
}
@end
