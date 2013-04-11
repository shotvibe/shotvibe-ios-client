//
//  SVOfflineStorageWS.h
//  shotvibe
//
//  Created by John Gabelmann on 4/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Photo;
@class Album;

@interface SVOfflineStorageWS : NSObject

- (void)saveLoadedImage:(UIImage *)image forPhotoObject:(Photo *)photo;
- (void)cleanupOfflineStorageForAlbum:(Album *)album;
- (NSUInteger)numberOfImagesSavedInAlbum:(Album *)album;
- (UIImage *)loadImageFromOfflineWithPath:(NSString *)path inAlbum:(Album *)album;

@end
