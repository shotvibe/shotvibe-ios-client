//
//  AppDelegate.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/5/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SL/AlbumManager.h"
#import "SL/NetworkStatusManager.h"
#import "SL/AuthData.h"
#import "SL/PhoneContactsManager.h"
#import "PhotoFilesManager.h"

@interface ShotVibeAppDelegate : UIResponder <UIApplicationDelegate>

#pragma mark - Properties

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, readonly, strong) SLAlbumManager *albumManager;
@property (strong, nonatomic) SLNetworkStatusManager *networkStatusManager;
@property (nonatomic, readonly, strong) PhotoFilesManager *photoFilesManager;
@property (nonatomic, readonly, strong) SLPhoneContactsManager *phoneContactsManager;

@property (copy) void (^ uploadSessionCompletionHandler)(); //stored by handleEventsForBackgroundURLSession for later use

- (BOOL)isLoggedIn;
- (void)setAuthData:(SLAuthData *)authData;

#pragma mark - Class Methods

+ (ShotVibeAppDelegate *)sharedDelegate;

+ (NSString *)getDeviceName;

@end
