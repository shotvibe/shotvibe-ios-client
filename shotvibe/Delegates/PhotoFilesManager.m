//
//  PhotoFilesManager.m
//  shotvibe
//
//  Created by benny on 10/30/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "PhotoFilesManager.h"
#import "PhotoView.h"
#import "PhotoSize.h"
#import "FileUtils.h"

@interface PhotoLoadObserver : NSObject

@property (nonatomic, readonly, strong) PhotoSize *photoSize;
@property (nonatomic, readonly, weak) PhotoView *photoView;

@end

@implementation PhotoLoadObserver

@end

@implementation PhotoFilesManager
{
    // The directory in the file system where photos are stored for offline viewing
    NSString *photosDirectory_;

    // Dictionary from `NSString` objects to `PhotoLoadObserver` objects
    NSMutableDictionary *photoLoadObservers_;
}

static NSString * const PHOTOS_DIRECTORY = @"photos";

- (id)init
{
    self = [super init];

    if (self) {
        NSString *applicationSupportDirectory = [FileUtils getApplicationSupportDirectory];

        photosDirectory_ = [applicationSupportDirectory stringByAppendingPathComponent:PHOTOS_DIRECTORY];

        NSFileManager *manager = [NSFileManager defaultManager];
        if (![manager fileExistsAtPath:photosDirectory_]) {
            NSError *error;
            if (![manager createDirectoryAtPath:photosDirectory_ withIntermediateDirectories:NO attributes:nil error:&error]) {
                NSAssert(NO, @"Error creating Photos Directory: %@", [error localizedDescription]);
            }
        }

        photoLoadObservers_ = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (void)loadBitmap:(NSString *)photoId photoUrl:(NSString *)photoUrl photoSize:(PhotoSize *)photoSize photoObserver:(PhotoView *)photoObserver
{
    // TODO ...
}

- (void)removePhotoObserver:(NSString *)photoId photoSize:(PhotoSize *)photoSize photoObserver:(PhotoView *)photoObserver
{
    // TODO ...
}

- (void)queuePhotoDownload:(NSString *)photoId photoUrl:(NSString *)photoUrl photoSize:(PhotoSize *)photoSize highPriority:(BOOL)highPriority
{
    // TODO
}

@end
