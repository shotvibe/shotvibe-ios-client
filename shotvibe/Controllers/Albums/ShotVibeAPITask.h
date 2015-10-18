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

@end
