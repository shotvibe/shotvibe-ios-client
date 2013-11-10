//
//  AppDelegate.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/5/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Crashlytics/Crashlytics.h>
#import "ShotVibeAppDelegate.h"
#import "SVInitialization.h"
#import "SVPushNotificationsManager.h"
#import "SVDefines.h"
#import "SVAlbumListViewController.h"
#import "SVRegistrationViewController.h"
#import "MFSideMenu.h"
#import "SVSidebarManagementController.h"
#import "SVSidebarMemberController.h"
#import "MPNotificationView.h"
#import "UIImageView+AFNetworking.h"
#import "MBProgressHUD.h"

#import "UserSettings.h"
#import "ShotVibeAPI.h"
#import "ShotVibeDB.h"
#import "JSON.h"

@interface ShotVibeAppDelegate ()
@property (nonatomic, strong) SVSidebarMemberController *sidebarRight;
@property (nonatomic, strong) SVSidebarManagementController *sidebarLeft;
@property (nonatomic, strong) MFSideMenuContainerViewController *sideMenu;
@end


@interface RegistrationInfo : NSObject

+ (RegistrationInfo *)RegistrationInfoFromURL:(NSURL *)url;

@property (nonatomic) BOOL startWithAuth;
@property (nonatomic, copy) NSString *countryCode;
@property (nonatomic, copy) NSString *authToken;
@property (nonatomic, assign) int64_t userId;

@end

@implementation RegistrationInfo

+ (RegistrationInfo *)RegistrationInfoFromURL:(NSURL *)url
{
    RegistrationInfo *result = [[RegistrationInfo alloc] init];

    NSDictionary* queryParameters = parseQueryParameters([url query]);

    result.countryCode = [queryParameters objectForKey:@"country_code"];
    if(result.countryCode == nil) {
        RCLog(@"Error: No country_code query parameter found in %@", [url description]);
        return nil;
    }

    for (NSString *seg in [url pathComponents]) {
        if([seg isEqualToString:@"start_with_auth"]) {
            result.startWithAuth = YES;

            result.authToken = [queryParameters objectForKey:@"auth_token"];
            if(result.authToken == nil) {
                RCLog(@"Error: No auth_token query parameter found in %@", [url description]);
                return nil;
            }

            NSString *userIdStr = [queryParameters objectForKey:@"user_id"];
            if(userIdStr == nil) {
                RCLog(@"Error: No user_id query parameter found  in %@", [url description]);
                return nil;
            }

            result.userId = [userIdStr longLongValue];

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
{
    SVPushNotificationsManager *pushNotificationsManager;
}

#pragma mark - UIApplicationDelegate Methods

// This should be updated whenever submitting the app
static NSString *const appCountryLookupVersion = @"1";

NSString * serverCountryLookup(NSString *version, void (^errorReporter)(NSString *, NSString *))
{
    NSString* shotvibeCountryLookupURL = @"https://api.shotvibe.com/auth/country_lookup/?";

    shotvibeCountryLookupURL = appendQueryParameter(shotvibeCountryLookupURL, @"version", version);

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:shotvibeCountryLookupURL]];
    [request setHTTPMethod:@"POST"];

    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSError *httpError;
    NSHTTPURLResponse *httpResponse;
    NSData *httpResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&httpResponse error:&httpError];

    if (httpResponseData == nil) {
        errorReporter(@"Network Error", httpError.localizedDescription);
        return nil;
    }

    if (httpResponse.statusCode >= 400) {
        errorReporter(@"Server Error", [NSString stringWithFormat:@"Invalid Server Status Code: %ld", (long)httpResponse.statusCode]);
        return nil;
    }


    @try {
        JSONObject *obj = [[JSONObject alloc] initWithData:httpResponseData];
        NSString *countryCode = [obj getString:@"country_code"];

        RCLog(@"%@", countryCode);

        return countryCode;
    }
    @catch (JSONException *exception) {
        errorReporter(@"Server Error", [NSString stringWithFormat:@"Invalid JSON: %@", exception.description]);
        return nil;
    }
}

- (void)processCountryCode:(UIApplication *)application registrationViewController:(SVRegistrationViewController *)registrationViewController
{
    // TODO This is very messy code

    // Hide the keyboard, since it shows up above the HUD:
    [self.window.rootViewController.view endEditing:YES];

    [MBProgressHUD hideAllHUDsForView:self.window.rootViewController.view animated:NO];
    [MBProgressHUD showHUDAddedTo:self.window.rootViewController.view animated:NO];

    // Ask the server if we should use the autologin system
    NSString *countryCode;

    countryCode = serverCountryLookup(appCountryLookupVersion, ^(NSString *titleText, NSString *detailText) {
        [MBProgressHUD hideAllHUDsForView:self.window.rootViewController.view animated:NO];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.window.rootViewController.view animated:NO];
        hud.labelText = titleText;
        hud.detailsLabelText = detailText;
        hud.opacity = 1.0f;
        hud.cornerRadius = 0.0f;
        hud.minSize = self.window.bounds.size;

        // Make sure that the keyboard is hidden:
        [self.window.rootViewController.view endEditing:YES];

        RCLog(@"%@: %@", titleText, detailText);
    });


    if (!countryCode) {
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self processCountryCode:application registrationViewController:registrationViewController];
        });

        return;
    }

    [MBProgressHUD hideAllHUDsForView:self.window.rootViewController.view animated:NO];

    NSString *COUNTRY_CODE_AUTOLOGIN = @"auto";

    if ([countryCode isEqualToString:COUNTRY_CODE_AUTOLOGIN]) {
        NSString* shotvibeAppInitUrl = @"https://www.shotvibe.com/app_init/?";

        shotvibeAppInitUrl = appendQueryParameter(shotvibeAppInitUrl, @"app", @"iphone");
        shotvibeAppInitUrl = appendQueryParameter(shotvibeAppInitUrl, @"device_description", deviceDescription());

        NSString *app_url_scheme;
#if CONFIGURATION_Debug
        app_url_scheme = @"shotvibe.debug";
#elif CONFIGURATION_AdHoc
        app_url_scheme = @"shotvibe.adhoc";
#elif CONFIGURATION_Release
        app_url_scheme = @"shotvibe";
#else
#error "UNKNOWN CONFIGURATION"
#endif

        shotvibeAppInitUrl = appendQueryParameter(shotvibeAppInitUrl, @"app_url_scheme", app_url_scheme);

        double currentTime = [[NSDate date] timeIntervalSince1970];
        shotvibeAppInitUrl = appendQueryParameter(shotvibeAppInitUrl, @"cache_buster", [[NSNumber numberWithDouble:currentTime] stringValue]);

        NSURL* url = [NSURL URLWithString:shotvibeAppInitUrl];
        NSAssert(url != nil, @"Error construction NSURL from string %@", shotvibeAppInitUrl);

        BOOL success = [application openURL:url];
        NSAssert(success, @"Error opening url: %@", [url description]);
    }
    else {
        // Skip the autologin, just use the country code

        [registrationViewController selectCountry:countryCode];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if !CONFIGURATION_Debug
    // Initialize Crashlytics
    [Crashlytics startWithAPIKey:@"7f25f8f82f6578b40464674ed500ef0c60435027"];
#endif

	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
	
    ShotVibeAPI *shotvibeAPI = [[ShotVibeAPI alloc] initWithAuthData:[UserSettings getAuthData]];
    ShotVibeDB *shotvibeDB = [[ShotVibeDB alloc] init];

    self.albumManager = [[AlbumManager alloc] initWithShotvibeAPI:shotvibeAPI shotvibeDB:shotvibeDB];

    pushNotificationsManager = [[SVPushNotificationsManager alloc] initWithAlbumManager:self.albumManager];

    // The following casts will work because of the way the MainStoryboard is set up.

    NSAssert([self.window.rootViewController isKindOfClass:[UINavigationController class]], @"Error");
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
	
    NSAssert([navigationController.visibleViewController isKindOfClass:[SVRegistrationViewController class]], @"Error");
    SVRegistrationViewController *registrationViewController = (SVRegistrationViewController *)navigationController.visibleViewController;
    registrationViewController.albumManager = self.albumManager;
    registrationViewController.pushNotificationsManager = pushNotificationsManager;

	// Initialize the sidebar menu
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
	self.sidebarRight = [storyboard instantiateViewControllerWithIdentifier:@"SidebarMenuView"];
	self.sidebarLeft = [storyboard instantiateViewControllerWithIdentifier:@"SidebarManagementView"];
	self.sideMenu = [MFSideMenuContainerViewController containerWithCenterViewController:navigationController
																  leftMenuViewController:nil
																 rightMenuViewController:self.sidebarRight];
	self.sideMenu.panMode = MFSideMenuPanModeNone;
	//self.sideMenu.shadow.enabled = NO;
	self.window.rootViewController = self.sideMenu;
	self.window.rootViewController.wantsFullScreenLayout = YES;
	
	SVInitialization *worker = [[SVInitialization alloc] init];
	
    [worker configureAppearanceProxies];
    [worker initializeLocalSettingsDefaults];

    if (shotvibeAPI.authData) {
		[pushNotificationsManager setup];
    }
    else {
        [self processCountryCode:application registrationViewController:registrationViewController];
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
    RCLog(@"openURL: %@", [url description]);

    RegistrationInfo *registrationInfo = [RegistrationInfo RegistrationInfoFromURL:url];

    if(registrationInfo == nil) {
        RCLog(@"Error reading RegistrationInfo from url");
    }
    else {
        // The following casts will work because of the way the MainStoryboard is set up.

        NSAssert([self.window.rootViewController isKindOfClass:[MFSideMenuContainerViewController class]], @"Error");
        MFSideMenuContainerViewController *sideMenu = (MFSideMenuContainerViewController *)self.window.rootViewController;
		UINavigationController *nav = (UINavigationController*)sideMenu.centerViewController;
        NSAssert([nav.visibleViewController isKindOfClass:[SVRegistrationViewController class]], @"Error");
        SVRegistrationViewController *registrationViewController = (SVRegistrationViewController *)nav.visibleViewController;

        if (registrationInfo.startWithAuth) {
            AuthData *authData = [[AuthData alloc] initWithUserID:registrationInfo.userId
                                                        authToken:registrationInfo.authToken
                                               defaultCountryCode:registrationInfo.countryCode];

            [UserSettings setAuthData:authData];

            [pushNotificationsManager setup];

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
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	RCLog(@"applicationDidEnterBackground fin");
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive.
	// If the application was previously in the background, optionally refresh the user interface.
	
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	
}


#pragma mark Remote notifications

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [pushNotificationsManager setAPNSDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [pushNotificationsManager handleNotification:userInfo];
	
	// Present the notification to the user
	
    // Temporarily disable the push notification banner
    /*
	NSString *title = @"Băluță Cristian";
	NSDictionary *aps = [userInfo objectForKey:@"aps"];
	NSString *alert = [aps objectForKey:@"alert"];
	
	MPNotificationView *notification = [MPNotificationView notifyWithText:title
																   detail:alert
																	image:nil
															  andDuration:5.0];
	
	//From UIImage+AFNetworking.h:
	[notification.imageView setImageWithURL:[NSURL URLWithString:@"https://dl.dropbox.com/u/361895/mopeddog.png"]];
     */
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
#if !CONFIGURATION_Debug
    UIAlertView* failureAlert = [[UIAlertView alloc] initWithTitle:@"Error Registering for Push Notifications"
                                                           message:[error localizedDescription]
                                                          delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];

    [failureAlert show];
#endif
}



#pragma mark - Class Methods

+ (ShotVibeAppDelegate *)sharedDelegate
{
    return (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];
}
@end
