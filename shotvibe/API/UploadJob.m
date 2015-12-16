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

@implementation UploadJob
{
    SLMediaTypeEnum *mediaType_;
    
    NSString *filePath_;
    long long albumId_;
    NSString *uniqueName_;
    
    SLAlbumUploadingMedia *uploadingMediaObj_;
}

- (id)initVideoUploadWithFile:(NSString *)filePath withPreviewImageFile:(NSString *)imageFile withAlbumId:(long long)albumId
{
    self = [super init];
    if (self) {
        mediaType_ = [SLMediaTypeEnum VIDEO];
        
        filePath_ = filePath;
        albumId_ = albumId;
        uniqueName_ = [UploadJob generateUniqueName];
        uniqueName_ = [uniqueName_ stringByAppendingString:@".mp4"];
        
        SLAlbumUploadingVideo *uploadingVideo = [[SLAlbumUploadingVideo alloc] initWithNSString:imageFile];
        uploadingMediaObj_ = [[SLAlbumUploadingMedia alloc] initWithSLMediaTypeEnum:[SLMediaTypeEnum VIDEO] withSLAlbumUploadingVideo:uploadingVideo withSLAlbumUploadingMediaPhoto:nil withFloat:0.0f];
    }
    return self;
}

- (id)initPhotoUploadWithFile:(NSString *)filePath withAlbumId:(long long)albumId
{
    self = [super init];
    if (self) {
        mediaType_ = [SLMediaTypeEnum PHOTO];
        
        filePath_ = filePath;
        albumId_ = albumId;
        uniqueName_ = [UploadJob generateUniqueName];
        uniqueName_ = [uniqueName_ stringByAppendingString:@".jpg"];
        
        SLAlbumUploadingMediaPhoto *uploadingPhoto = [[SLAlbumUploadingMediaPhoto alloc] initWithNSString:filePath];
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


@end
