//
//  UploadDelegate.h
//  shotvibe
//
//  Created by martijn on 23-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ProgressHandlerType) (int64_t, int64_t);

typedef void (^CompletionHandlerType)();


@interface UploadSessionDelegate : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate>

- (void)setDelegateForTask:(NSURLSessionTask *)task progressHandler:(ProgressHandlerType)progressHandler completionHandler:(CompletionHandlerType)completionHandler;

@end
