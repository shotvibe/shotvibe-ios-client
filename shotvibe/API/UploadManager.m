//
//  UploadManager.m
//  shotvibe
//
//  Created by omer klein on 12/1/15.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import "UploadManager.h"

#import "SL/ArrayList.h"
#import "SL/AwsToken.h"
#import "SL/AlbumUploadingMedia.h"
#import "SL/AlbumUploadingVideo.h"
#import "SL/MediaType.h"
#import "ShotVibeCredentialsProvider.h"

#import "ShotVibeAppDelegate.h"
#import <AWSS3/AWSS3.h>

typedef NS_ENUM(NSInteger, UploadJobType) {
    UploadJobTypePhoto,
    UploadJobTypeVideo
};

@interface UploadJob : NSObject

- (id)initVideoUploadWithFile:(NSString *)filePath withAlbumId:(long long)albumId;

- (NSString *)getFilePath;
- (NSString *)getUniqueName;
- (long long)getAlbumId;
- (SLAlbumUploadingMedia *)getAlbumUploadingMedia;

- (void)setProgress:(float)progress;

+ (NSString *)generateUniqueName;

@end

@implementation UploadJob
{
    NSString *filePath_;
    long long albumId_;
    NSString *uniqueName_;

    SLAlbumUploadingMedia *uploadingMediaObj_;
}

- (id)initVideoUploadWithFile:(NSString *)filePath withAlbumId:(long long)albumId
{
    self = [super init];
    if (self) {
        filePath_ = filePath;
        albumId_ = albumId;
        uniqueName_ = [UploadJob generateUniqueName];

        SLAlbumUploadingVideo *uploadingVideo = [[SLAlbumUploadingVideo alloc] init];
        uploadingMediaObj_ = [[SLAlbumUploadingMedia alloc] initWithSLMediaTypeEnum:[SLMediaTypeEnum  VIDEO] withSLAlbumUploadingVideo:uploadingVideo withFloat:0.0f];
    }
    return self;
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

@interface UploadManager ()

- (void)processNextJob;

+ (NSString *)bucketKeyForVideoUploadWithUserId:(long long)userId withAlbumId:(long long)albumId withFilename:(NSString *)filename;

@end


@implementation UploadManager
{
    long long userId_;
    AWSS3TransferManager *transferManager_;

    id <SLMediaUploader_Listener> listener_;

    NSMutableArray *uploadQueue_;
}

-(id)initWithAWSCredentialsProvider:(id<AWSCredentialsProvider>)awsCredentialsProvider withUserId:(long long)userId
{
    self = [super init];
    if (self) {
        userId_ = userId;
        AWSServiceConfiguration *config = [[AWSServiceConfiguration alloc] initWithRegion:AWS_REGION
                                                                      credentialsProvider:awsCredentialsProvider];
        
        [AWSS3TransferManager registerS3TransferManagerWithConfiguration:config forKey:S3_TRANSFER_MANAGER_KEY];

        transferManager_ = [AWSS3TransferManager S3TransferManagerForKey:S3_TRANSFER_MANAGER_KEY];

        listener_ = nil;

        uploadQueue_ = [[NSMutableArray alloc] init];
    }
    return self;
}

NSString * GLANCE_UPLOAD_BUCKET = @"glance-uploads";

NSString * S3_TRANSFER_MANAGER_KEY = @"TRANSFER_MANAGER";
AWSRegionType AWS_REGION = AWSRegionUSEast1;

+ (NSString *)bucketKeyForVideoUploadWithUserId:(long long)userId withAlbumId:(long long)albumId withFilename:(NSString *)filename
{
    return [NSString stringWithFormat:@"videos/%lld/%lld/%@.mp4", userId, albumId, filename];
}

- (void)jobCompleted
{
    NSLog(@"Upload Job Completed");

    UploadJob *completedJob = [uploadQueue_ objectAtIndex:0];
    [uploadQueue_ removeObjectAtIndex:0];
    
    [listener_ onMediaUploadObjectsChangedWithLong:[completedJob getAlbumId]];
    [[ShotVibeAppDelegate sharedDelegate].albumManager refreshAlbumContentsWithLong:[completedJob getAlbumId] withBoolean:NO];

    [self processNextJob];
}

- (void)jobFailed
{
    NSLog(@"Upload Job Failed");
    
    [self processNextJob];
}

- (void)jobProgressWithProgress:(float)progress
{
    UploadJob *currentJob = [uploadQueue_ objectAtIndex:0];
    [currentJob setProgress:progress];

    long long albumId = [currentJob getAlbumId];

    [listener_ onMediaUploadProgressWithLong:albumId];
}

- (void)processNextJob
{
    if ([uploadQueue_ count] == 0) {
        return;
    }
    
    UploadJob *job = [uploadQueue_ objectAtIndex:0];

    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = GLANCE_UPLOAD_BUCKET;
    uploadRequest.key = [UploadManager bucketKeyForVideoUploadWithUserId:userId_ withAlbumId:[job getAlbumId] withFilename:[job getUniqueName]];
    uploadRequest.body = [NSURL fileURLWithPath:[job getFilePath]];

    NSLog(@"Starting upload");
    AWSTask *uploadTask = [transferManager_ upload:uploadRequest];
    [uploadTask continueWithExecutor:[AWSExecutor mainThreadExecutor]
                           withBlock:^id(AWSTask *task) {
                               if (task.error) {
                                   NSLog(@"Upload Error: %@", task.error);
                                   // TODO ...
                                   int sleepMillis = 2000;
                                   return [[AWSTask taskWithDelay:sleepMillis] continueWithBlock:^id(AWSTask *task) {
                                       [self jobFailed];
                                       return nil;
                                   }];
                               } else if (task.result) {
                                   // The file uploaded successfully.
                                   [self jobCompleted];
                                   return nil;
                               } else {
                                   // TODO Impossible
                                   return nil;
                               }
                           }];

    uploadRequest.uploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        dispatch_async(dispatch_get_main_queue(), ^{
            int percent = (int)(100LL * totalBytesSent / totalBytesExpectedToSend);
            NSLog(@"progress:  %d%% %lld (%lld/%lld)",
                  percent, bytesSent, totalBytesSent, totalBytesExpectedToSend);

            float progress = (double)totalBytesSent / (double)totalBytesExpectedToSend;
            [self jobProgressWithProgress:progress];
        });
    };
}

-(void)addUploadVideoJob:(NSString *)videoFilePath withAlbumId:(long long)albumId
{
    UploadJob *newJob = [[UploadJob alloc] initVideoUploadWithFile:videoFilePath withAlbumId:albumId];

    [uploadQueue_ addObject:newJob];
    
    // If the queue was empty then we need to initiate the job. Otherwise, it will automatically run when the currently executing jobs complete
    if (uploadQueue_.count == 1) {
        [self processNextJob];
    }

    [listener_ onMediaUploadObjectsChangedWithLong:albumId];
}


- (id<JavaUtilList>)getUploadingMediaWithLong:(long long int)albumId
{
    NSMutableArray *results = [[NSMutableArray alloc] init];

    // isCurrentJob is the first object (the first iteration of the loop)
    for (UploadJob *job in uploadQueue_) {
        if ([job getAlbumId] == albumId) {
            [results addObject:[job getAlbumUploadingMedia]];
        }
    }

    return [[SLArrayList alloc] initWithInitialArray:results];
}


- (void)setListenerWithSLMediaUploader_Listener:(id<SLMediaUploader_Listener>)listener
{
    listener_ = listener;
}


@end
