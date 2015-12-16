//
//  UploadQueue.m
//  shotvibe
//
//  Created by omer klein on 12/16/15.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import "UploadQueue.h"

@implementation UploadQueue
{
    NSMutableArray *queue_;
}

- (id)init
{
    self = [super init];
    if (self) {
        queue_ = [[NSMutableArray alloc] init];
    }
    return self;
}

- (UploadJob *)currentJob
{
    return [queue_ objectAtIndex:0];
}

- (UploadJob *)popCurrentJob
{
    UploadJob *job = [queue_ objectAtIndex:0];
    [queue_ removeObjectAtIndex:0];
    return job;
}

- (NSInteger)numActiveJobs
{
    return queue_.count;
}

- (void)addJob:(UploadJob *)job
{
    [queue_ addObject:job];
}

- (NSArray *)allJobs
{
    return queue_;
}

@end
