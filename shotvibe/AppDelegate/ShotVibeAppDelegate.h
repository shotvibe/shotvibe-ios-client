//
//  AppDelegate.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/5/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Crashlytics/Crashlytics.h>

#import <UIKit/UIKit.h>
#import "AlbumManager.h"
#import "SL/NetworkStatusManager.h"

@interface ShotVibeAppDelegate : UIResponder <UIApplicationDelegate>

#pragma mark - Properties

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) AlbumManager *albumManager;
@property (strong, nonatomic) SLNetworkStatusManager *networkStatusManager;

@property (copy) void (^ uploadSessionCompletionHandler)(); //stored by handleEventsForBackgroundURLSession for later use

#pragma mark - Class Methods

+ (ShotVibeAppDelegate *)sharedDelegate;

@end

@interface CrashlyticsDelegate : NSObject <CrashlyticsDelegate>

+ (CrashlyticsDelegate *)sharedInstance;

@property (atomic, assign) BOOL crashlyticsDidDetectCrashDuringPreviousExecution;

@end
