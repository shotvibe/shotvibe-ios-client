//
//  ImageDiskCache.m
//  shotvibe
//
//  Created by benny on 9/29/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "ImageDiskCache.h"

@implementation ImageDiskCache
{
    void (^ refreshHandler_)(void);

    NSCache *imageCache_;

    dispatch_queue_t dqueue_;

    NSObject *lock_;

    // Elements are of type NSString
    NSHashTable *loadingFilePaths_;

    // Elements are of type NSString
    NSMutableArray *loadingQueue_;
}


- (id)initWithRefreshHandler:(void (^)(void))refreshHandler
{
    self = [super init];
    if (self) {
        refreshHandler_ = refreshHandler;

        imageCache_ = [[NSCache alloc] init];

        dqueue_ = dispatch_queue_create(0, DISPATCH_QUEUE_SERIAL);

        lock_ = [[NSObject alloc] init];

        loadingFilePaths_ = [[NSHashTable alloc] initWithOptions:NSHashTableStrongMemory capacity:8];

        loadingQueue_ = [[NSMutableArray alloc] init];
    }
    return self;
}


// This is called from a background thread
- (void)loadNextImage
{
    NSString *nextFilePath = nil;
    @synchronized(lock_) {
        if (loadingQueue_.count == 0) {
            return;
        }
        nextFilePath = [loadingQueue_ objectAtIndex:0];
        [loadingQueue_ removeObjectAtIndex:0];
    }

    UIImage *image = [UIImage imageWithContentsOfFile:nextFilePath];

    @synchronized(lock_) {
        [loadingFilePaths_ removeObject:nextFilePath];
    }

    // Assume this value:
    NSUInteger bytesPerPixel = 4;
    NSUInteger cost = (NSUInteger)image.size.width * (NSUInteger)image.size.height * bytesPerPixel;

    [imageCache_ setObject:image forKey:nextFilePath cost:cost];

    dispatch_async(dispatch_get_main_queue(), ^{
        refreshHandler_();
    });
}


- (UIImage *)getImage:(NSString *)filePath
{
    UIImage *image = [imageCache_ objectForKey:filePath];

    if (image) {
        return image;
    }

    // Image not in cache, need to load it

    @synchronized(lock_) {
        if ([loadingFilePaths_ containsObject:filePath]) {
            return nil;
        }

        // Add to the head of the queue
        [loadingQueue_ insertObject:filePath atIndex:0];
    }

    dispatch_async(dqueue_, ^{
        [self loadNextImage];
    });

    return nil;
}


@end
