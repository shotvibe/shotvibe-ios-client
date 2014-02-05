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
    NSString *lowResFilePath_;
    NSString *fullResFilePath_;
}

static const CGFloat kLowResJPEGQuality = 0.01;

- (id)initWithAsset:(ALAsset *)asset
{
    self = [super init];

    if (self) {
        asset_ = asset;
        lowResFilePath_ = nil;
        fullResFilePath_ = nil;
    }

    return self;
}

- (id)initWithPath:(NSString *)path
{
    self = [super init];
	
    if (self) {
        asset_ = nil;
        lowResFilePath_ = nil;
        fullResFilePath_ = path;
    }
	
    return self;
}

- (UIImage *)getThumbnail
{
	if (asset_) {
		return [UIImage imageWithCGImage:asset_.thumbnail];
	}
	
    NSMutableString *thumbPath = [NSMutableString stringWithString:fullResFilePath_];
	[thumbPath replaceOccurrencesOfString:@".jpg"
							   withString:@"_thumb.jpg"
								  options:NSLiteralSearch
									range:NSMakeRange(0, [thumbPath length])];
	
	return [UIImage imageWithContentsOfFile:thumbPath];
}

static NSString * const UPLOADS_DIRECTORY = @"uploads";

+ (NSString *)createUniqueUploadFilePath
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

- (void)saveToFiles
{
    [self saveToFileLowRes];
    [self saveToFileFullRes];
}


- (void)saveToFileFullRes
{
	// If the path already exists skip this step
    if (fullResFilePath_) {
		return;
	}
	
    fullResFilePath_ = [PhotoUploadRequest createUniqueUploadFilePath];
	
    ALAssetRepresentation *rep = [asset_ defaultRepresentation];
    CGImageRef croppedImage = [rep fullResolutionImage];
    NSDictionary *metadata = [rep metadata][@"AdjustmentXMP"];

    // Write to disk the cropped image
	if (metadata) {
        CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:fullResFilePath_];
		CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
		CGImageDestinationAddImage(destination, croppedImage, nil);
		
		if (!CGImageDestinationFinalize(destination)) {
            RCLog(@"Failed to write image to %@", fullResFilePath_);
		}
		else{
            RCLog(@"write success %@", fullResFilePath_);
		}
		
		CFRelease(destination);
		
        [FileUtils addSkipBackupAttributeToItemAtURL:fullResFilePath_];
		return;
	}

	
	// Write to disk the original image
    if (![[NSFileManager defaultManager] createFileAtPath:fullResFilePath_ contents:nil attributes:nil]) {
        RCLog(@"ERROR CREATING FILE: %@", fullResFilePath_);
        // TODO Handle error...
        return;
    }

    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:fullResFilePath_];

    if (!handle) {
        RCLog(@"ERROR OPENING FILE: %@", fullResFilePath_);
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
            RCLog(@"ERROR WRITING FILE: %@", [error description]);
            // TODO Handle error...
        }

        [handle writeData:[NSData dataWithBytesNoCopy:buffer length:numBytesRead freeWhenDone:NO]];

        offset += numBytesRead;
    }

    free(buffer);

    RCLog(@"Closing file");
    [handle closeFile];
    handle = nil;

    [FileUtils addSkipBackupAttributeToItemAtURL:fullResFilePath_];
}


- (void)saveToFileLowRes
{
    UIImage *highResImage;

    if (fullResFilePath_) { // if there's no file, then this request was initialized with an asset (coming from image picker)
        highResImage = [UIImage imageWithContentsOfFile:fullResFilePath_];
    } else {
        ALAssetRepresentation *rep = [asset_ defaultRepresentation];
        CGImageRef croppedImage = [rep fullScreenImage];
        highResImage = [UIImage imageWithCGImage:croppedImage];
    }

    // TODO: even with the low JPEG compression the filesize is still quite high, so we will probably also need to lower the resolution.

    lowResFilePath_ = [PhotoUploadRequest createUniqueUploadFilePath];
    [UIImageJPEGRepresentation(highResImage, kLowResJPEGQuality) writeToFile:lowResFilePath_ atomically:YES];
}


- (NSString *)getLowResFilename
{
    return lowResFilePath_;
}


- (NSString *)getFullResFilename
{
    return fullResFilePath_;
}

@end
