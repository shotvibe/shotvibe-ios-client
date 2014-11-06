//
//  AppDelegate.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/5/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Crashlytics/Crashlytics.h>
#import <Appsee/Appsee.h>
#import "ShotVibeAppDelegate.h"
#import "SVInitialization.h"
#import "SVPushNotificationsManager.h"
#import "SVDefines.h"
#import "SVAlbumListViewController.h"
#import "SVRegistrationViewController.h"
#import "SVSidebarManagementController.h"
#import "SVSidebarMemberController.h"
#import "SVNavigationController.h"

#import "TutorialViewController.h"

#import "MPNotificationView.h"
#import "MFSideMenu.h"
#import "MBProgressHUD.h"
#import "UIImageView+AFNetworking.h"

#import "IosBackgroundUploadSession.h"
#import "IosBackgroundTaskManager.h"
#import "IosFileSystemManager.h"
#import "IosBitmapProcessor.h"
#import "SL/UploadStateDB.h"
#import "SL/UploadSystemDirector.h"

#import "RegistrationInfo.h"
#import "UserSettings.h"
#import "ShotVibeAPI.h"
#import "SL/ShotVibeAPI.h"
#import "ShotVibeDB.h"
#import "JSON.h"
#import "DatabaseOpener.h"
#import "FileUtils.h"
#import "SL/HTTPLib.h"
#import "IosHTTPLib.h"
#import "IosDevicePhoneContactsLib.h"

@interface ShotVibeAppDelegate ()
@property (nonatomic, strong) SVSidebarMemberController *sidebarRight;
@property (nonatomic, strong) SVSidebarManagementController *sidebarLeft;
@property (nonatomic, strong) MFSideMenuContainerViewController *sideMenu;
@end


@implementation ShotVibeAppDelegate {
	
    SVPushNotificationsManager *pushNotificationsManager;
}


- (BOOL)isLoggedIn
{
    return self.albumManager != nil;
}


#pragma mark - Class Methods

+ (ShotVibeAppDelegate *)sharedDelegate {
    return (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];
}


#pragma mark - SDK Methods

- (void)initSDKs
{
    //[NewRelicAgent startWithApplicationToken:@"AAea0623ed205b8e4119889914a4605318944a6535"];
    [Appsee start:@"215369473db946c39b7ae4276adf3e5b"];

#if !CONFIGURATION_Debug
    [Crashlytics startWithAPIKey:@"7f25f8f82f6578b40464674ed500ef0c60435027"];
#endif

#if CONFIGURATION_Release
    [Mixpanel sharedInstanceWithToken:@"0ff5e52a6784417a3c1621ebcc27222c"];
#else
    // This is needed so that event tracking doesn't cause warning logs,
    // and is useful for verifying that events are being properly sent
    // with MIXPANEL_LOG=1. See the online mixpanel docs:
    //   https://mixpanel.com/help/reference/ios#debugging-and-logging
    [Mixpanel sharedInstanceWithToken:@"0"];
#endif
}


- (void)configureSDKs:(SLAuthData *)authData
{
    NSString *user_id_str = [NSString stringWithFormat:@"%lld", [authData getUserId]];

#if !CONFIGURATION_Debug
    [Crashlytics setUserIdentifier:user_id_str];
#endif

    if (![[Mixpanel sharedInstance].distinctId isEqualToString:user_id_str]) {
        [[Mixpanel sharedInstance] createAlias:user_id_str
                                 forDistinctID:[Mixpanel sharedInstance].distinctId];

        [[Mixpanel sharedInstance] identify:user_id_str];
        [[Mixpanel sharedInstance].people set:@{ @"user_id" : user_id_str }];
    }
}


#pragma mark - UIApplicationDelegate Methods

- (void)testBackgroundThread:(id)arg
{
    int counter = 0;

//    [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
//        // Nothing
//    }];

    while (YES) {
        NSTimeInterval timeRemaining = [[UIApplication sharedApplication] backgroundTimeRemaining];
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertAction = @"action";
        notification.alertBody = [NSString stringWithFormat:@"%d: Time Remaining: %.3f", counter, timeRemaining];
        notification.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];

        counter++;

        [NSThread sleepForTimeInterval:1.0];
    }
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    BOOL background = application.applicationState == UIApplicationStateBackground;
    NSLog(@"App Start");

//    NSThread *testBackgroundThread = [[NSThread alloc] initWithTarget:self selector:@selector(testBackgroundThread:) object:nil];
//    [testBackgroundThread start];

    [self initSDKs];

    _albumManager = nil;

    self.networkStatusManager = [[SLNetworkStatusManager alloc] init];

    _photoFilesManager = [[PhotoFilesManager alloc] init];

    pushNotificationsManager = [[SVPushNotificationsManager alloc] init];

    SLAuthData *authData = [UserSettings getAuthData];
    if (authData) {
        [self loadAlbumManager:authData];
    }

    // The following casts will work because of the way the MainStoryboard is set up.

    NSAssert([self.window.rootViewController isKindOfClass:[SVNavigationController class]], @"Error: rootViewController is not UINavigationController");
    SVNavigationController *navigationController = (SVNavigationController *)self.window.rootViewController;


    NSAssert([navigationController.visibleViewController isKindOfClass:[SVRegistrationViewController class]], @"Error: visibleViewController is not SVRegistrationViewController");
    SVRegistrationViewController *registrationViewController = (SVRegistrationViewController *)navigationController.visibleViewController;


    // Initialize the sidebar menu
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    self.sidebarRight = [storyboard instantiateViewControllerWithIdentifier:@"SidebarMembersView"];
    self.sidebarLeft = [storyboard instantiateViewControllerWithIdentifier:@"SidebarManagementView"];
    self.sideMenu = [MFSideMenuContainerViewController containerWithCenterViewController:navigationController
                                                                  leftMenuViewController:nil
                                                                 rightMenuViewController:self.sidebarRight];
    self.sideMenu.panMode = MFSideMenuPanModeNone;
    self.window.rootViewController = self.sideMenu;

    if (IS_IOS7) {
    } else {
        self.window.rootViewController.wantsFullScreenLayout = YES;
    }

    SVInitialization *worker = [[SVInitialization alloc] init];
    [worker configureAppearanceProxies];
    [worker initializeLocalSettingsDefaults];

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"kTutorialShown"]) {
        TutorialViewController *t = [[TutorialViewController alloc] init];
        t.onClose = ^(id responseObject) {
            self.window.rootViewController = self.sideMenu;

            if (![self isLoggedIn]) {
                [self processCountryCode:[UIApplication sharedApplication] registrationViewController:registrationViewController];
            }
        };

        self.window.rootViewController = t;

        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"kTutorialShown"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        if (![self isLoggedIn]) {
            [self processCountryCode:application registrationViewController:registrationViewController];
        }
    }

    return YES;
}


static NSString *const UPLOADS_DIRECTORY = @"uploads";


+ (NSString *)getUploadsDir
{
    NSString *baseDirectory = [FileUtils getApplicationSupportDirectory];
    NSString *dir = [baseDirectory stringByAppendingPathComponent:UPLOADS_DIRECTORY];

    // Create the directory if it doesn't exist:
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:dir]) {
        NSError *error;
        if (![manager createDirectoryAtPath:dir withIntermediateDirectories:NO attributes:nil error:&error]) {
            NSAssert(NO, @"Error creating Uploads Directory: %@", [error localizedDescription]);
        }
    }

    if ([dir characterAtIndex:[dir length] - 1] != '/') {
        dir = [dir stringByAppendingString:@"/"];
    }

    return dir;
}


- (void)loadAlbumManager:(SLAuthData *)authData
{
    [self configureSDKs:authData];

    id<SLHTTPLib> httpLib = [[IosHTTPLib alloc] init];
    SLShotVibeAPI *shotVibeAPI = [[SLShotVibeAPI alloc] initWithSLHTTPLib:httpLib
                                               withSLNetworkStatusManager:self.networkStatusManager
                                                           withSLAuthData:authData];
    SLShotVibeDB *shotVibeDB = [DatabaseOpener open:[[SLShotVibeDB_Recipe alloc] init]];

    NSString *uploadsDir = [ShotVibeAppDelegate getUploadsDir];

    NSString *MAIN_SESSION_IDENTIFIER = @"BackgroundUploader.MainSession";
    NSString *ORIGINALS_SESSION_IDENTIFIER = @"BackgroundUploader.OriginalsSession";

    NSOperationQueue *commonUploadOperationQueue = [[NSOperationQueue alloc] init];
    [commonUploadOperationQueue setMaxConcurrentOperationCount:1];

    IosBackgroundUploadSession_Factory *factory = [[IosBackgroundUploadSession_Factory alloc]
                                                   initWithSessionIdentifier:MAIN_SESSION_IDENTIFIER
                                                                 shotVibeAPI:shotVibeAPI
                                                              operationQueue:commonUploadOperationQueue
                                                               discretionary:NO];

    IosBackgroundUploadSession_Factory *originalsFactory = [[IosBackgroundUploadSession_Factory alloc]
                                                            initWithSessionIdentifier:ORIGINALS_SESSION_IDENTIFIER
                                                                          shotVibeAPI:shotVibeAPI
                                                                       operationQueue:commonUploadOperationQueue
                                                                        discretionary:YES];

    SLUploadStateDB *uploadStateDB = [DatabaseOpener open:[[SLUploadStateDB_Recipe alloc] init]];

    id<SLFileSystemManager> fileSystemManager = [[IosFileSystemManager alloc] init];

    id<SLBitmapProcessor> bitmapProcessor = [[IosBitmapProcessor alloc] init];

    id<SLBackgroundTaskManager> backgroundTaskManager = [[IosBackgroundTaskManager alloc] init];

    SLUploadSystemDirector *uploadSystemDirector = [[SLUploadSystemDirector alloc]
                                                    initWithSLBackgroundUploadSession_Factory:factory
                                                        withSLBackgroundUploadSession_Factory:originalsFactory
                                                                          withSLUploadStateDB:uploadStateDB
                                                                            withSLShotVibeAPI:shotVibeAPI
                                                                      withSLFileSystemManager:fileSystemManager
                                                                   withSLPhotoDownloadManager:_photoFilesManager
                                                                                 withNSString:uploadsDir
                                                                        withSLBitmapProcessor:bitmapProcessor
                                                                  withSLBackgroundTaskManager:backgroundTaskManager];

    _albumManager = [[SLAlbumManager alloc] initWithSLShotVibeAPI:shotVibeAPI
                                                 withSLShotVibeDB:shotVibeDB
                                       withSLPhotoDownloadManager:_photoFilesManager
                                              withSLUploadManager:[uploadSystemDirector getUploadManager]];

    id <SLDevicePhoneContactsLib> devicePhoneContactsLib = [[IosDevicePhoneContactsLib alloc] init];

    _phoneContactsManager = [[SLPhoneContactsManager alloc] initWithSLDevicePhoneContactsLib:devicePhoneContactsLib
                                                                           withSLShotVibeAPI:shotVibeAPI
                                                                            withSLShotVibeDB:shotVibeDB];

    [pushNotificationsManager setup];
}


- (void)setAuthData:(SLAuthData *)authData
{
    NSAssert(![self isLoggedIn], @"Already logged in");

    [UserSettings setAuthData:authData];

    [self loadAlbumManager:authData];
}


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    RCLog(@"openURL: %@", [url description]);
    // TODO: probably want to skip this if we have authInfo (although you'd need an explicit url to get here in that case)

    // The following casts will work because of the way the MainStoryboard is set up.

    NSAssert([self.window.rootViewController isKindOfClass:[MFSideMenuContainerViewController class]], @"Error");
    MFSideMenuContainerViewController *sideMenu = (MFSideMenuContainerViewController *)self.window.rootViewController;
    UINavigationController *nav = (UINavigationController *)sideMenu.centerViewController;
    NSAssert([nav.visibleViewController isKindOfClass:[SVRegistrationViewController class]], @"Error");
    // TODO: DANGEROUS: this assert may fail when opening a shotvibe url while the app is running.

    SVRegistrationViewController *registrationViewController = (SVRegistrationViewController *)nav.visibleViewController;

    RegistrationInfo *registrationInfo = [RegistrationInfo RegistrationInfoFromURL:url];

    if (registrationInfo) {
        if (registrationInfo.startWithAuth) {
            SLAuthData *authData = [[SLAuthData alloc] initWithLong:registrationInfo.userId
                                                       withNSString:registrationInfo.authToken
                                                       withNSString:registrationInfo.countryCode];
            [self setAuthData:authData];

            [[Mixpanel sharedInstance] track:@"User Registered"];
            [[Mixpanel sharedInstance] track:@"User Registered (Invite Link)"];


            [registrationViewController skipRegistration];
        } else {
            [[Mixpanel sharedInstance] track:@"Phone Number Screen Viewed"];

            [registrationViewController selectCountry:registrationInfo.countryCode];
            [registrationViewController setCustomPayload:registrationInfo.customPayload];
        }
    }

    return YES;
}


- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    RCLog(@"handleEventsForBackgroundURLSession");
    // This is called when a background task finishes or requires authentication. There are two possible situations:
    //  - The app was suspended but still running
    //  - The app has been launched to handle the background events
    // After handling the events, the completionHandler needs to be called

    // Store the completion handler for the appropriate NSURLSession (currently we only have one: the upload session)
// TODO:
/*
    if ([identifier isEqualToString:kUploadSessionId]) {
        self.uploadSessionCompletionHandler = completionHandler;
    } else {
        RCLog(@"ERROR: request to handle background events for unknown NSURLSession: %@", identifier);
    }
*/
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





// This should be updated whenever submitting the app
static NSString *const appCountryLookupVersion = @"8";

NSString * serverCountryLookup(NSString *version, void (^errorReporter)(NSString *, NSString *))
{
    NSString *shotvibeCountryLookupURL = [[SLShotVibeAPI BASE_URL] stringByAppendingString:@"/auth/country_lookup/?"];
    RCLog(@"shotvibeCountryLookupURL %@", shotvibeCountryLookupURL);
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
        NSString *shotvibeAppInitUrl = @"https://www.useglance.com/app_init/?";

        shotvibeAppInitUrl = appendQueryParameter(shotvibeAppInitUrl, @"app", @"iphone");
        shotvibeAppInitUrl = appendQueryParameter(shotvibeAppInitUrl, @"device_description", [ShotVibeAppDelegate getDeviceName]);
		
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

        // Use this url for easy testing of invitation-cookie auto login process (make sure auth_token and user_id are valid)
        //NSURL* url = [NSURL URLWithString:@"shotvibe.debug://shotvibe/start_with_auth/?country_code=31&auth_token=d161c5523fed23a75100b0ffb986ccaecfc86610&user_id=675085580"];
        NSAssert(url != nil, @"Error construction NSURL from string %@", shotvibeAppInitUrl);
		
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            // The openURL causes iOS to execute code on the main thread and blocks while waiting for the result.
            // To prevent this deadlock, we execute it on a background thread.
            BOOL success = [application openURL:url];
            NSAssert(success, @"Error opening url: %@", [url description]);
        });
    }
    else {
        // Skip the autologin, just use the country code
		
        [registrationViewController selectCountry:countryCode];
    }
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

+ (NSString *)getDeviceName
{
    UIDevice *currentDevice = [UIDevice currentDevice];
	return [NSString stringWithFormat:@"%@ (%@ %@)", [currentDevice model], [currentDevice systemName], [currentDevice systemVersion]];
}


@end
