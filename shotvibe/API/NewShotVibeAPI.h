//
//  NewShotVibeAPI.h
//  ShotVibeUploadTest
//
//  Created by martijn on 21-01-14.
//  Copyright (c) 2014 Oblomov Systems. All rights reserved.
//

#import "ShotVibeAPI.h"

typedef void (^ProgressHandlerType) (int64_t, int64_t);

typedef void (^CompletionHandlerType)();

@interface NewShotVibeAPI : NSObject

- (id)initWithOldShotVibeAPI:(ShotVibeAPI *)oldShotVibeAPI;

- (void)photoUploadAsync:(NSString *)photoId filePath:(NSString *)filePath progressHandler:(ProgressHandlerType)progressHandler completionHandler:(CompletionHandlerType)completionHandler;

@end
