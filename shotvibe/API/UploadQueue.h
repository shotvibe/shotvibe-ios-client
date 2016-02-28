//
//  UploadQueue.h
//  shotvibe
//
//  Created by omer klein on 12/16/15.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UploadJob.h"

@interface UploadQueue : NSObject

- (id)init;

- (UploadJob *)currentJob;
- (UploadJob *)popCurrentJob;

- (NSInteger)numActiveJobs;

- (void)addJob:(UploadJob *)job;

- (NSArray *)allJobs;

- (void)cleanCompletedUploads:(NSArray *)photos;

@end
