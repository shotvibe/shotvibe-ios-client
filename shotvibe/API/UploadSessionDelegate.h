//
//  UploadSessionDelegate.h
//  shotvibe
//
//  Created by martijn on 23-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ProgressHandlerType) (int64_t, int64_t);

typedef void (^CompletionHandlerType)();


/**
 Delegate that implements NSURLSessionDelegate and NSURLSessionTaskDelegate and supports setting both a progress handler and a completion handler per task. Standard upload tasks only allow the completion handler to be set with a block.

 @note Currently, the blocks are not restored when the app has terminated and was relaunched. For this, we need to persistently store information that allows us to re-create the blocks on startup. For now, any tasks existing on startup are simply deleted.
 */
@interface UploadSessionDelegate : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate>

- (void)setDelegateForTask:(NSURLSessionTask *)task progressHandler:(ProgressHandlerType)progressHandler completionHandler:(CompletionHandlerType)completionHandler;

@end
