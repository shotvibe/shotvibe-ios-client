//
//  UploadJob.m
//  shotvibe
//
//  Created by omer klein on 12/16/15.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import "UploadJob.h"
#import "SL/AlbumUploadingMedia.h"
#import "SL/AlbumUploadingMediaPhoto.h"
#import "SL/AlbumUploadingVideo.h"
#import "FileUtils.h"

#import "YYImageCache.h"
#import "YYImageCoder.h"

@implementation UploadJob
{
    SLMediaTypeEnum *mediaType_;
    
    NSString *filePath_;
    long long albumId_;
    NSString *uniqueName_;
    
    SLAlbumUploadingMedia *uploadingMediaObj_;
}

NSString * moveFile(NSString* source, NSString *target) {
    NSError *error;
    if (![[NSFileManager defaultManager] moveItemAtPath:source toPath:target error:&error]) {
        NSCAssert(NO, @"Error moving file %@ to %@: %@", source, target, [error localizedDescription]);
    }

    return target;
}

- (id)initVideoUploadWithUploadDir:(NSString *)uploadDir withFile:(NSString *)filePath withPreviewImageFile:(NSString *)imageFile withAlbumId:(long long)albumId
{
    self = [super init];
    if (self) {
        mediaType_ = [SLMediaTypeEnum VIDEO];
        
        uniqueName_ = [UploadJob generateUniqueName];
        uniqueName_ = [uniqueName_ stringByAppendingString:@".mp4"];

        filePath_ = moveFile(filePath, [[uploadDir stringByAppendingString:@"/"] stringByAppendingString:uniqueName_]);
        [FileUtils addSkipBackupAttributeToItemAtURL:filePath_];
        
        NSString *movedImageFile = @"";

        if (imageFile && imageFile.length > 0) {
            movedImageFile = moveFile(imageFile, [[[uploadDir stringByAppendingString:@"/"] stringByAppendingString:uniqueName_] stringByAppendingString:@".jpg"]);
            [FileUtils addSkipBackupAttributeToItemAtURL:movedImageFile];
        }

        albumId_ = albumId;

        SLAlbumUploadingVideo *uploadingVideo = [[SLAlbumUploadingVideo alloc] initWithNSString:movedImageFile];
        uploadingMediaObj_ = [[SLAlbumUploadingMedia alloc] initWithSLMediaTypeEnum:[SLMediaTypeEnum VIDEO] withSLAlbumUploadingVideo:uploadingVideo withSLAlbumUploadingMediaPhoto:nil withFloat:0.0f];
    }
    return self;
}

- (id)initPhotoUploadWithUploadDir:(NSString *)uploadDir withFile:(NSString *)filePath withAlbumId:(long long)albumId
{
    self = [super init];
    if (self) {
        mediaType_ = [SLMediaTypeEnum PHOTO];
        
        uniqueName_ = [UploadJob generateUniqueName];
        uniqueName_ = [uniqueName_ stringByAppendingString:@".jpg"];

        filePath_ = moveFile(filePath, [[uploadDir stringByAppendingString:@"/"] stringByAppendingString:uniqueName_]);
        [FileUtils addSkipBackupAttributeToItemAtURL:filePath_];
        albumId_ = albumId;
        
        SLAlbumUploadingMediaPhoto *uploadingPhoto = [[SLAlbumUploadingMediaPhoto alloc] initWithNSString:filePath_];
        uploadingMediaObj_ = [[SLAlbumUploadingMedia alloc] initWithSLMediaTypeEnum:[SLMediaTypeEnum PHOTO] withSLAlbumUploadingVideo:nil withSLAlbumUploadingMediaPhoto:uploadingPhoto withFloat:0.0f];
    }
    return self;
}

- (SLMediaTypeEnum *)getMediaType
{
    return mediaType_;
}

+ (NSString *)generateUniqueName
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [formatter setLocale:locale];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    
    [formatter setDateFormat:@"yyyyMMddHHmmssSSS"];
    
    NSDate *now = [NSDate date];
    NSString *dateStr = [formatter stringFromDate:now];
    
    NSString *alphabet  = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789";
    NSUInteger randomStrLen = 16;
    NSMutableString *randomStr = [NSMutableString stringWithCapacity:randomStrLen];
    for (NSUInteger i = 0U; i < randomStrLen; i++) {
        u_int32_t r = arc4random() % [alphabet length];
        unichar c = [alphabet characterAtIndex:r];
        [randomStr appendFormat:@"%C", c];
    }
    
    return [NSString stringWithFormat:@"%@$%@", dateStr, randomStr];
}


- (NSString *)getFilePath
{
    return filePath_;
}

- (NSString *)getUniqueName
{
    return uniqueName_;
}

- (long long)getAlbumId
{
    return albumId_;
}

- (SLAlbumUploadingMedia *)getAlbumUploadingMedia
{
    return uploadingMediaObj_;
}

- (void)setProgress:(float)progress
{
    [uploadingMediaObj_ setProgressWithFloat:progress];
}

- (void)injectIntoCacheAndDeleteWithServerPhotoUrl:(NSString *)serverPhotoUrl
{
    // Only work with photos
    // (TODO Still should delete uploaded file for videos!)
    if ([self getMediaType] != [SLMediaTypeEnum PHOTO]) {
        return;
    }

    NSData *fileContents = [[NSFileManager defaultManager] contentsAtPath:[self getFilePath]];
    YYImageDecoder *decoder = [YYImageDecoder decoderWithData:fileContents scale:2.0];
    UIImage *image = [decoder frameAtIndex:0 decodeForDisplay:YES].image;

    NSString *cacheKey = [serverPhotoUrl stringByReplacingOccurrencesOfString:@".jpg" withString:@"_r_fhd.jpg"];

    [[YYImageCache sharedCache] setImage:image imageData:fileContents forKey:cacheKey withType:YYImageCacheTypeAll];

    // TODO Delete uploaded file
}


@end
