//
//  GalleryPhotoUploadRequest.m
//  shotvibe
//
//  Created by raptor on 9/23/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "GalleryPhotoUploadRequest.h"

#import "FileUtils.h"

@implementation GalleryPhotoUploadRequest
{
    ALAsset *asset_;
}

- (id)initWithAsset:(ALAsset *)asset
{
    self = [super init];
    if (self) {
        asset_ = asset;
    }
    return self;
}


- (void)saveToFileWithNSString:(NSString *)fileName
{
    NSLog(@"Saving asset to file: %@", fileName);

    ALAssetRepresentation *rep = [asset_ defaultRepresentation];

    if (![[NSFileManager defaultManager] createFileAtPath:fileName contents:nil attributes:nil]) {
        @throw [[NSException alloc] initWithName:@"createFileAtPath Error"
                                          reason:[NSString stringWithFormat:@"Error creating file: %@", fileName]
                                        userInfo:nil];
    }

    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:fileName];

    if (!handle) {
        @throw [[NSException alloc] initWithName:@"fileHandleForWritingAtPath Error"
                                          reason:[NSString stringWithFormat:@"Error opening file: %@", fileName]
                                        userInfo:nil];
    }

    const int BUFFER_SIZE = 4096;

    uint8_t *buffer = malloc(BUFFER_SIZE);

    if (!buffer) {
        @throw [[NSException alloc] initWithName:@"malloc Error"
                                          reason:[NSString stringWithFormat:@"Error allocating buffer of size: %d", BUFFER_SIZE]
                                        userInfo:nil];
    }

    long long offset = 0;
    while (offset < [rep size]) {
        NSError *error;
        NSUInteger numBytesRead = [rep getBytes:buffer fromOffset:offset length:BUFFER_SIZE error:&error];

        if (numBytesRead == 0) {
            @throw [[NSException alloc] initWithName:@"getBytes error"
                                              reason:[error description]
                                            userInfo:nil];
        }

        // Be aware that the following may internally throw an exception:
        [handle writeData:[NSData dataWithBytesNoCopy:buffer length:numBytesRead freeWhenDone:NO]];

        offset += numBytesRead;
    }

    free(buffer);

    NSLog(@"Closing file: %@", fileName);
    [handle closeFile];

    [FileUtils addSkipBackupAttributeToItemAtURL:fileName];
}


@end
