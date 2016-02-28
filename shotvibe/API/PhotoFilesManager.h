//
//  PhotoFilesManager.h
//  shotvibe
//
//  Created by benny on 10/30/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SL/PhotoDownloadManager.h"

#import "PhotoSize.h"

@class PhotoView;

@interface PhotoFilesManager : NSObject <SLPhotoDownloadManager>

- (id)init;

// Must be called only from the main thread
- (void)loadBitmap:(NSString *)photoId photoUrl:(NSString *)photoUrl photoSize:(PhotoSize *)photoSize photoObserver:(PhotoView *)photoObserver;

// Must be called only from the main thread
// If the photoObserver isn't registered then this does nothing
- (void)removePhotoObserver:(NSString *)photoId photoSize:(PhotoSize *)photoSize photoObserver:(PhotoView *)photoObserver;

// This should be called from a background thread in order to not block the UI
- (void)queuePhotoDownload:(NSString *)photoId photoUrl:(NSString *)photoUrl photoSize:(PhotoSize *)photoSize highPriority:(BOOL)highPriority;

- (PhotoSize *)DeviceDisplayPhotoSize;

@end
