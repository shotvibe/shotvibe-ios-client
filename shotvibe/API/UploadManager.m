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
#import "SL/AlbumUploadingMediaPhoto.h"
#import "SL/AlbumUploadingVideo.h"
#import "SL/MediaType.h"
#import "ShotVibeCredentialsProvider.h"
#import "UploadQueue.h"
#import "UploadJob.h"

#import "ShotVibeAppDelegate.h"
#import <AWSS3/AWSS3.h>

@interface UploadManager ()

- (void)processNextJob;
- (void)addUploadJob:(UploadJob *)job withAlbumId:(long long)albumId;

+ (NSString *)bucketKeyForVideoUploadWithUserId:(long long)userId withAlbumId:(long long)albumId withFilename:(NSString *)filename;
+ (NSString *)bucketKeyForPhotoUploadWithUserId:(long long)userId withAlbumId:(long long)albumId withFilename:(NSString *)filename;

@end


@implementation UploadManager
{
    long long userId_;
    AWSS3TransferManager *transferManager_;

    id <SLMediaUploader_Listener> listener_;

    UploadQueue *uploadQueue_;
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

        uploadQueue_ = [[UploadQueue alloc] init];
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

+ (NSString *)bucketKeyForPhotoUploadWithUserId:(long long)userId withAlbumId:(long long)albumId withFilename:(NSString *)filename
{
    return [NSString stringWithFormat:@"photos/%lld/%lld/%@.mp4", userId, albumId, filename];
}

- (void)jobCompleted
{
    NSLog(@"Upload Job Completed");

    UploadJob *completedJob = [uploadQueue_ popCurrentJob];
    
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
    UploadJob *currentJob = [uploadQueue_ currentJob];
    [currentJob setProgress:progress];

    long long albumId = [currentJob getAlbumId];

    [listener_ onMediaUploadProgressWithLong:albumId];
}

- (void)processNextJob
{
    if ([uploadQueue_ numActiveJobs] == 0) {
        return;
    }
    
    UploadJob *job = [uploadQueue_ currentJob];

    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = GLANCE_UPLOAD_BUCKET;

    NSString *uploadKey;
    if ([job getMediaType] == [SLMediaTypeEnum VIDEO]) {
        uploadKey = [UploadManager bucketKeyForVideoUploadWithUserId:userId_ withAlbumId:[job getAlbumId] withFilename:[job getUniqueName]];
    } else if ([job getMediaType] == [SLMediaTypeEnum PHOTO]) {
        uploadKey = [UploadManager bucketKeyForPhotoUploadWithUserId:userId_ withAlbumId:[job getAlbumId] withFilename:[job getUniqueName]];
    } else {
        NSAssert(false, @"Unknown mediaType");
    }

    uploadRequest.key = uploadKey;

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

- (void)addUploadJob:(UploadJob *)job withAlbumId:(long long)albumId
{
    [uploadQueue_ addJob:job];
    
    // If the queue was empty then we need to initiate the job. Otherwise, it will automatically run when the currently executing jobs complete
    if ([uploadQueue_ numActiveJobs] == 1) {
        [self processNextJob];
    }

    [listener_ onMediaUploadObjectsChangedWithLong:albumId];
}

-(void)addUploadVideoJob:(NSString *)videoFilePath withImageFilePath:(NSString *)imageFile withAlbumId:(long long)albumId
{
    UploadJob *newJob = [[UploadJob alloc] initVideoUploadWithFile:videoFilePath withPreviewImageFile:imageFile withAlbumId:albumId];
    [self addUploadJob:newJob withAlbumId:albumId];
}


-(void)addUploadPhotoJob:(NSString *)photoFilePath withAlbumId:(long long)albumId
{
    UploadJob *newJob = [[UploadJob alloc] initPhotoUploadWithFile:photoFilePath withAlbumId:albumId];
    [self addUploadJob:newJob withAlbumId:albumId];
}


- (id<JavaUtilList>)getUploadingMediaWithLong:(long long int)albumId
{
    NSMutableArray *results = [[NSMutableArray alloc] init];

    // isCurrentJob is the first object (the first iteration of the loop)
    for (UploadJob *job in [uploadQueue_ allJobs]) {
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
