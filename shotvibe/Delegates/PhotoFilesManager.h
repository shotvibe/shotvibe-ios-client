//
//  PhotoFilesManager.h
//  shotvibe
//
//  Created by benny on 10/30/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PhotoSize.h"
#import "PhotoView.h"

@interface PhotoFilesManager : NSObject

- (id)init;

- (void)loadBitmap:(NSString *)photoId photoUrl:(NSString *)photoUrl photoSize:(PhotoSize *)photoSize photoObserver:(PhotoView *)photoObserver;

- (void)removePhotoObserver:(NSString *)photoId photoSize:(PhotoSize *)photoSize photoObserver:(PhotoView *)photoObserver;

- (void)queuePhotoDownload:(NSString *)photoId photoUrl:(NSString *)photoUrl photoSize:(PhotoSize *)photoSize highPriority:(BOOL)highPriority;

@end
