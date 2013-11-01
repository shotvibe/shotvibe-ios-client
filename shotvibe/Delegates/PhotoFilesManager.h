//
//  PhotoFilesManager.h
//  shotvibe
//
//  Created by benny on 10/30/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PhotoSize.h"

@class PhotoView;

@interface PhotoFilesManager : NSObject

- (id)init;

// Must be called only from the main thread
- (void)loadBitmap:(NSString *)photoId photoUrl:(NSString *)photoUrl photoSize:(PhotoSize *)photoSize photoObserver:(PhotoView *)photoObserver;

// Must be called only from the main thread
// If the photoObserver isn't registered then this does nothing
- (void)removePhotoObserver:(NSString *)photoId photoSize:(PhotoSize *)photoSize photoObserver:(PhotoView *)photoObserver;

// Must be called only from the main thread
- (void)queuePhotoDownload:(NSString *)photoId photoUrl:(NSString *)photoUrl photoSize:(PhotoSize *)photoSize highPriority:(BOOL)highPriority;

@end
