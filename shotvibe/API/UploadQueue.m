//
//  UploadQueue.m
//  shotvibe
//
//  Created by omer klein on 12/16/15.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import "UploadQueue.h"

#import "SL/AlbumPhoto.h"
#import "SL/AlbumServerPhoto.h"

@implementation UploadQueue
{
    NSMutableArray *queue_;
    NSInteger currentIndex_;
}

- (id)init
{
    self = [super init];
    if (self) {
        queue_ = [[NSMutableArray alloc] init];
        currentIndex_ = 0;
    }
    return self;
}

- (UploadJob *)currentJob
{
    return [queue_ objectAtIndex:currentIndex_];
}

- (UploadJob *)popCurrentJob
{
    UploadJob *job = [queue_ objectAtIndex:currentIndex_];
    currentIndex_++;
    return job;
}

- (NSInteger)numActiveJobs
{
    return queue_.count - currentIndex_;
}

- (void)addJob:(UploadJob *)job
{
    [queue_ addObject:job];
}

- (NSArray *)allJobs
{
    return queue_;
}

- (void)removeCompletedWjthClientUploadId:(NSString *)clientUploadId withServerPhotoUrl:(NSString *)serverPhotoUrl
{
    for (NSInteger i = 0; i < currentIndex_; ++i) {
        UploadJob *job = [queue_ objectAtIndex:i];
        if ([[job getUniqueName] isEqualToString:clientUploadId]) {
            [queue_ removeObjectAtIndex:i];
            currentIndex_--;

            [job injectIntoCacheAndDeleteWithServerPhotoUrl:serverPhotoUrl];

            [[NSNotificationCenter defaultCenter] postNotificationName:@"GLUploadComplete" object:nil];
            return;
        }
    }
}

- (void)cleanCompletedUploads:(NSArray *)photos
{
    if (currentIndex_ == 0) {
        return;
    }

    for (SLAlbumPhoto *photo in photos) {
        SLAlbumServerPhoto *serverPhoto = [photo getServerPhoto];
        if (serverPhoto) {
            NSString *clientUploadId = [serverPhoto getClientUploadId];
            if (clientUploadId && clientUploadId.length > 0) {
                [self removeCompletedWjthClientUploadId:clientUploadId withServerPhotoUrl:[serverPhoto getUrl]];
            }
        }
    }
}

@end
