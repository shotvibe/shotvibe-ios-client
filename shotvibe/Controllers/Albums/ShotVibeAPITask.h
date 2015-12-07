//
//  ShotVibeAPITask.h
//  shotvibe
//
//  Created by benny on 6/6/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ShotVibeAPITask : NSObject

+ (void)runTask:(UIViewController *)viewController withAction:(id (^)())run onTaskComplete:(void (^)(id))onTaskComplete;

+ (void)runTask:(UIViewController *)viewController withAction:(id (^)())run onTaskComplete:(void (^)(id))onTaskComplete onTaskFailure:(void (^)(id))onTaskFailure withLoaderIndicator:(BOOL)withLoader;
+ (void)runTask:(UIViewController *)viewController withAction:(id (^)())run onTaskComplete:(void (^)(id))onTaskComplete withSuccess:(BOOL)withSuccess withFailure:(BOOL)withFailure successText:(NSString*)successText failureText:(NSString*)failureText showLoadingText:(BOOL)showLoadingText loadingText:(NSString*)loadingText;
@end
