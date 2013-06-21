//
//  AppDelegate.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/5/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <HockeySDK/HockeySDK.h>
#import "ShotVibeAppDelegate.h"
#import "SVInitializationBD.h"
#import "SyncEngine.h"

@interface ShotVibeAppDelegate () <BITHockeyManagerDelegate, BITUpdateManagerDelegate, BITCrashManagerDelegate>

@end

@implementation ShotVibeAppDelegate

#pragma mark - UIApplicationDelegate Methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Initialize JIRA Mobile Connect
    {
        JMCOptions *options = [JMCOptions optionsWithUrl:@"http://devops.reticentmedia.com/jira/"
                                              projectKey:@"SHOT"
                                                  apiKey:@"d0158455-347b-447c-9dca-c92109555871"
                                                  photos:YES
                                                   voice:YES
                                                location:YES
                                          crashReporting:NO
                                           notifications:YES
                                            customFields:nil];
        [[JMC sharedInstance] configureWithOptions:options];
        [JMC sharedInstance].customDataSource = self;
    }
    
    // Initialize HockeyKit
    {
        NSString *betaHockeyIdentifier = @"eb37555764438faae7f78ae5543429cd";
        NSString *liveHockeyIdentifier = @"5245f5f653966a9634ced97598a82a5a";
        [[BITHockeyManager sharedHockeyManager] configureWithBetaIdentifier:betaHockeyIdentifier liveIdentifier:liveHockeyIdentifier delegate:self];
        [[[BITHockeyManager sharedHockeyManager] crashManager] setDelegate:self];
        [[[BITHockeyManager sharedHockeyManager] updateManager] setDelegate:self];
#if CONFIGURATION_Release
        //[[[BITHockeyManager sharedHockeyManager] disableUpdateManager:YES]];
#endif
        [[BITHockeyManager sharedHockeyManager] startManager];
    }
    
    [SVInitializationBD initialize];
 
 // start bg sync for albums
    [[SyncEngine sharedEngine] startSync];

    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


#pragma mark - BITCrashManagerDelegate
- (void)crashManagerWillSendCrashReport:(BITCrashManager *)crashManager
{
    
}


- (void)crashManager:(BITCrashManager *)crashManager didFailWithError:(NSError *)error
{
    NSLog(@"%@\n%@\n%@\n\%@", [error localizedDescription], [error localizedFailureReason], [error localizedRecoveryOptions], [error localizedRecoverySuggestion]);
}


- (void)crashManagerDidFinishSendingCrashReport:(BITCrashManager *)crashManager
{
    
}


- (NSString *)userNameForCrashManager:(BITCrashManager *)crashManager
{
#ifndef CONFIGURATION_Release
    if ([[UIDevice currentDevice] respondsToSelector:@selector(uniqueIdentifier)])
    {
        return [[UIDevice currentDevice] performSelector:@selector(uniqueIdentifier)];
    }
#endif
    return nil;
}


#pragma mark - BITUpdateManagerDelegate
- (NSString *)customDeviceIdentifierForUpdateManager:(BITUpdateManager *)updateManager
{
#ifndef CONFIGURATION_Release
    if ([[UIDevice currentDevice] respondsToSelector:@selector(uniqueIdentifier)])
    {
        return [[UIDevice currentDevice] performSelector:@selector(uniqueIdentifier)];
    }
#endif
    return nil;
}


#pragma mark - Class Methods

+ (ShotVibeAppDelegate *)sharedDelegate
{
    return (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];
}
@end
