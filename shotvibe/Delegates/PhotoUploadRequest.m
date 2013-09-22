//
//  PhotoUploadRequest.m
//  shotvibe
//
//  Created by benny on 8/25/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "PhotoUploadRequest.h"
#import "FileUtils.h"

@implementation PhotoUploadRequest
{
    ALAsset *asset_;
    NSString *filePath_;
}

- (id)initWithAsset:(ALAsset *)asset
{
    self = [super init];

    if (self) {
        asset_ = asset;
        filePath_ = nil;
    }

    return self;
}

- (id)initWithPath:(NSString *)path
{
    self = [super init];
	
    if (self) {
        asset_ = nil;
        filePath_ = path;
    }
	
    return self;
}

- (UIImage *)getThumbnail
{
	if (asset_) {
		return [UIImage imageWithCGImage:asset_.thumbnail];
	}
	
	NSMutableString *thumbPath = [NSMutableString stringWithString:filePath_];
	[thumbPath replaceOccurrencesOfString:@".jpg"
							   withString:@"_thumb.jpg"
								  options:NSLiteralSearch
									range:NSMakeRange(0, [thumbPath length])];
	
	return [UIImage imageWithContentsOfFile:thumbPath];
}

static NSString * const UPLOADS_DIRECTORY = @"uploads";

+ (NSString *)getUploadingPhotoFilename
{
    NSString *applicationSupportDirectory = [FileUtils getApplicationSupportDirectory];

    NSString *uploadsDirectory = [applicationSupportDirectory stringByAppendingPathComponent:UPLOADS_DIRECTORY];

    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:uploadsDirectory]) {
        NSError *error;
        if (![manager createDirectoryAtPath:uploadsDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            NSAssert(false, @"Error creating Uploads Directory: %@", [error localizedDescription]);
        }
    }

    NSString *randomBaseName = [[NSUUID UUID] UUIDString];

    NSString *fileName = [randomBaseName stringByAppendingPathExtension:@"jpg"];

    return [uploadsDirectory stringByAppendingPathComponent:fileName];
}

- (void)saveToFile
{
	// If the path already exists skip this step
	if (filePath_) {
		return;
	}
	
    filePath_ = [PhotoUploadRequest getUploadingPhotoFilename];

    ALAssetRepresentation *rep = [asset_ defaultRepresentation];

    if (![[NSFileManager defaultManager] createFileAtPath:filePath_ contents:nil attributes:nil]) {
        NSLog(@"ERROR CREATING FILE: %@", filePath_);
        // TODO Handle error...
        return;
    }

    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filePath_];

    if (!handle) {
        NSLog(@"ERROR OPENING FILE: %@", filePath_);
        // TODO Handle error...
        return;
    }

    const int BUFFER_SIZE = 4096;

    uint8_t *buffer = malloc(BUFFER_SIZE);

    long long offset = 0;
    while (offset < [rep size]) {
        NSError *error;
        NSUInteger numBytesRead = [rep getBytes:buffer fromOffset:offset length:BUFFER_SIZE error:&error];

        if (numBytesRead == 0) {
            NSLog(@"ERROR WRITING FILE: %@", [error description]);
            // TODO Handle error...
        }

        [handle writeData:[NSData dataWithBytesNoCopy:buffer length:numBytesRead freeWhenDone:NO]];

        offset += numBytesRead;
    }

    free(buffer);

    NSLog(@"Closing file");
    [handle closeFile];
    handle = nil;

    [FileUtils addSkipBackupAttributeToItemAtURL:filePath_];
}

- (NSString *)getFilename
{
    return filePath_;
}

@end
