//
//  AppDelegate.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/5/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Crashlytics/Crashlytics.h>
#import "ShotVibeAppDelegate.h"
#import "SVInitializationBD.h"
#import "SVBusinessDelegate.h"
#import "SVPushNotificationsManager.h"
#import "MagicalRecordShorthand.h"
#import "MagicalRecord+Actions.h"
#import "SVEntityStore.h"
#import "SVDefines.h"
#import "SVAlbumListViewController.h"
#import "SVRegistrationViewController.h"

@interface ShotVibeAppDelegate ()

@end


@interface RegistrationInfo : NSObject

+ (RegistrationInfo *)RegistrationInfoFromURL:(NSURL *)url;

@property (nonatomic) BOOL startWithAuth;
@property (nonatomic, copy) NSString *countryCode;
@property (nonatomic, copy) NSString *authToken;
@property (nonatomic, copy) NSString *userId;

@end

@implementation RegistrationInfo

+ (RegistrationInfo *)RegistrationInfoFromURL:(NSURL *)url
{
    RegistrationInfo *result = [[RegistrationInfo alloc] init];

    NSDictionary* queryParameters = parseQueryParameters([url query]);

    result.countryCode = [queryParameters objectForKey:@"country_code"];
    if(result.countryCode == nil) {
        NSLog(@"Error: No country_code query parameter found in %@", [url description]);
        return nil;
    }

    for (NSString *seg in [url pathComponents]) {
        if([seg isEqualToString:@"start_with_auth"]) {
            result.startWithAuth = YES;

            result.authToken = [queryParameters objectForKey:@"auth_token"];
            if(result.authToken == nil) {
                NSLog(@"Error: No auth_token query parameter found in %@", [url description]);
                return nil;
            }

            result.userId = [queryParameters objectForKey:@"user_id"];
            if(result.userId == nil) {
                NSLog(@"Error: No user_id query parameter found  in %@", [url description]);
                return nil;
            }

            return result;
        }
        else if([seg isEqualToString:@"start_unregistered"]) {
            result.startWithAuth = NO;

            return result;
        }
    }

    return nil;
}


NSDictionary * parseQueryParameters(NSString * query)
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];

    NSArray *components = [query componentsSeparatedByString:@"&"];
    for (NSString *component in components) {
        NSArray *subcomponents = [component componentsSeparatedByString:@"="];
        if ([subcomponents count] >= 1) {
            NSString *key = [subcomponents objectAtIndex:0];
            NSString *value;
            if([subcomponents count] >= 2) {
                value = [subcomponents objectAtIndex:1];
            }
            else {
                value = @"";
            }

            NSString *decodedKey = [key stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString *decodedValue = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

            [parameters setObject:decodedValue forKey:decodedKey];
        }
    }

    return parameters;
}

@end


@implementation ShotVibeAppDelegate

#pragma mark - UIApplicationDelegate Methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if !CONFIGURATION_Debug
    // Initialize Crashlytics
    [Crashlytics startWithAPIKey:@"7f25f8f82f6578b40464674ed500ef0c60435027"];
#endif

	[SVInitializationBD initialize];
	
    if ([SVBusinessDelegate hasUserBeenAuthenticated]) {
		[SVPushNotificationsManager setup];
    }
    else {
        // TODO Verify that there is an internet connection

        NSString* shotvibeAppInitUrl = @"https://www.shotvibe.com/app_init/?";

        shotvibeAppInitUrl = appendQueryParameter(shotvibeAppInitUrl, @"app", @"iphone");
        shotvibeAppInitUrl = appendQueryParameter(shotvibeAppInitUrl, @"device_description", deviceDescription());

        double currentTime = [[NSDate date] timeIntervalSince1970];
        shotvibeAppInitUrl = appendQueryParameter(shotvibeAppInitUrl, @"cache_buster", [[NSNumber numberWithDouble:currentTime] stringValue]);

        NSURL* url = [NSURL URLWithString:shotvibeAppInitUrl];
        NSAssert(url != nil, @"Error construction NSURL from string %@", shotvibeAppInitUrl);

        BOOL success = [application openURL:url];
        NSAssert(success, @"Error opening url: %@", [url description]);
    }

    return YES;
}


NSString * appendQueryParameter(NSString *url, NSString *key, NSString *value)
{
    NSString *escapedKey = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *escapedValue = [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    NSString *result = [url stringByAppendingString:@"&"];
    result = [result stringByAppendingString:escapedKey];
    result = [result stringByAppendingString:@"="];
    result = [result stringByAppendingString:escapedValue];

    return result;
}


NSString * deviceDescription()
{
    UIDevice *currentDevice = [UIDevice currentDevice];
	return [NSString stringWithFormat:@"%@ (%@ %@)", [currentDevice model], [currentDevice systemName], [currentDevice systemVersion]];
}


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSLog(@"openURL: %@", [url description]);

    RegistrationInfo *registrationInfo = [RegistrationInfo RegistrationInfoFromURL:url];

    if(registrationInfo == nil) {
        NSLog(@"Error reading RegistrationInfo from url");
    }
    else {
        // The following casts will work because of the way the MainStoryboard is set up.

        NSAssert([self.window.rootViewController isKindOfClass:[UINavigationController class]], @"Error");
        UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;

        NSAssert([navigationController.visibleViewController isKindOfClass:[SVRegistrationViewController class]], @"Error");
        SVRegistrationViewController *registrationViewController = (SVRegistrationViewController *)navigationController.visibleViewController;

        if (registrationInfo.startWithAuth) {

            // Store the registration data using the legacy system:

            [[NSUserDefaults standardUserDefaults] setObject:registrationInfo.userId forKey:kApplicationUserId];
            [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"Token %@", registrationInfo.authToken] forKey:kApplicationUserAuthToken];
            [[NSUserDefaults standardUserDefaults] synchronize];

            [SVPushNotificationsManager setup];

            [registrationViewController skipRegistration];
        }
        else {
            [registrationViewController selectCountry:registrationInfo.countryCode];
        }
    }

    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	
	if ([SVBusinessDelegate hasUserBeenAuthenticated]) {
		[[SVEntityStore sharedStore] setAllPhotosToNotNew];
    }
	
	NSLog(@"applicationWillResignActive fin");
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	NSLog(@"applicationDidEnterBackground fin");
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

	if ([SVBusinessDelegate hasUserBeenAuthenticated]) {
        //TODO: This should be set on a timer
        //[[SVDownloadSyncEngine sharedEngine] startSync];
    }
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [MagicalRecord cleanUp];
}


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [SVPushNotificationsManager setAPNSDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    UIAlertView* failureAlert = [[UIAlertView alloc] initWithTitle:@"Error Registering for Push Notifications"
                                                           message:[error localizedDescription]
                                                          delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
#if !CONFIGURATION_Debug
    [failureAlert show];
#endif
}

#pragma mark - Class Methods

+ (ShotVibeAppDelegate *)sharedDelegate
{
    return (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];
}
@end
