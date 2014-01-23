//
//  NewShotVibeAPI.h
//  shotvibe
//
//  Created by Oblosys on 21-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "ShotVibeAPI.h"
#import "UploadSessionDelegate.h"

@interface NewShotVibeAPI : NSObject

- (id)initWithBaseURL:(NSString *)baseURL oldShotVibeAPI:(ShotVibeAPI *)oldShotVibeAPI;

- (void)photoUploadAsync:(NSString *)photoId filePath:(NSString *)filePath progressHandler:(ProgressHandlerType)progressHandler completionHandler:(CompletionHandlerType)completionHandler;

@end
