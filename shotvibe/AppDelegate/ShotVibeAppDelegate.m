//
//  AppDelegate.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/5/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

//#import <Crashlytics/Crashlytics.h>



//#import <Appsee/Appsee.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <PubNub/PubNub.h>

#import "ShotVibeAppDelegate.h"
#import "SVInitialization.h"
#import "SVPushNotificationsManager.h"
#import "SVDefines.h"
#import "SVAlbumListViewController.h"
#import "SVRegistrationViewController.h"
#import "SVSidebarManagementController.h"
#import "SVSidebarMemberController.h"
#import "SVNavigationController.h"
#import <sys/sysctl.h>
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
#import "UploadManager.h"
#import "ShotVibeCredentialsProvider.h"

#import "GLSharedCamera.h"
#import "ContainerViewController.h"
#import "GLWelcomeViewController.h"
#import "GLProfilePictureController.h"

#import "GLPubNubManager.h"

#import "GLContainersViewController.h"

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
    //    [Appsee start:@"215369473db946c39b7ae4276adf3e5b"];
    
    //    [Fabric with:@[[Crashlytics class]]];
    
    [Fabric with:@[[Crashlytics class], [PubNub class]]];
    GLPubNubManager * glPubManager =[[GLPubNubManager sharedInstance] init];
    
    
    //    [self.pubNubCLient setState:@{@"state":@"online"} forUUID:[NSString stringWithFormat:@"%lld",[[UserSettings getAuthData] getUserId]] onChannel:@"Channel-ylnvwg0uh"
    //                 withCompletion:^(PNClientStateUpdateStatus *status) {
    //
    //                     // Check whether request successfully completed or not.
    //                     if (!status.isError) {
    //
    //                         // Client state successfully modified on specified channel.
    //                     }
    //                     // Request processing failed.
    //                     else {
    //
    //                         // Handle client state modification error. Check 'category' property to find out possible
    //                         // issue because of which request did fail.
    //                         //
    //                         // Request can be resent using: [status retry];
    //                     }
    //                 }];
    
    
    //    self.pubNubCLient
    //    [[PubNub superclass] superclass];
    
    
    
    
    //    [self.client publish:@{@"announcement": @"Welcome to PubNub!"}
    //               toChannel:@"announcements" withCompletion:^(PNPublishStatus *status) {
    //
    //                   // Check whether request successfully completed or not.
    //                   if (!status.isError) {
    //
    //                       // Message successfully published to specified channel.
    //                   }
    //                   // Request processing failed.
    //                   else {
    //
    //                       // Handle message publish error. Check 'category' property to find out possible issue
    //                       // because of which request did fail.
    //                       //
    //                       // Request can be resent using: [status retry];
    //                   }
    //               }];
    
    
    
    //#if !CONFIGURATION_Debug
    //    [Crashlytics startWithAPIKey:@"7f25f8f82f6578b40464674ed500ef0c60435027"];
    //#endif
    
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
    
    //#if !CONFIGURATION_Debug
    NSString * userName = [[NSUserDefaults standardUserDefaults] objectForKey:@"kUserNickName"];
    
    [[Crashlytics sharedInstance] setUserIdentifier:user_id_str];
    [[Crashlytics sharedInstance] setUserName:userName];
    
    //#endif
    
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
    
    
    
    
    
    
    [self initSDKs];
    
    _albumManager = nil;
    
    self.networkStatusManager = [[SLNetworkStatusManager alloc] init];
    
    _photoFilesManager = [[PhotoFilesManager alloc] init];
    
    pushNotificationsManager = [[SVPushNotificationsManager alloc] init];
    
    SLAuthData *authData = [UserSettings getAuthData];
    if (authData) {
        [self loadAlbumManager:authData];
    }
    
    GLContainersViewController * glContainer = [[GLContainersViewController alloc] init];
    
    self.window.rootViewController = glContainer;
    
    return YES;
    
    //    BOOL background = application.applicationState == UIApplicationStateBackground;
    //    NSLog(@"App Start");
    //
    //    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    //
    ////    NSThread *testBackgroundThread = [[NSThread alloc] initWithTarget:self selector:@selector(testBackgroundThread:) object:nil];
    ////    [testBackgroundThread start];
    //
    //
    //    [GLSharedCamera sharedInstance];
    //
    //    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
    //        if (granted) {
    //            // Microphone enabled code
    //        }
    //        else {
    //            // Microphone disabled code
    //        }
    //    }];
    //
    //
    //    [self initSDKs];
    //
    //
    //
    //    _albumManager = nil;
    //
    //    self.networkStatusManager = [[SLNetworkStatusManager alloc] init];
    //
    //    _photoFilesManager = [[PhotoFilesManager alloc] init];
    //
    //    pushNotificationsManager = [[SVPushNotificationsManager alloc] init];
    //
    //    SLAuthData *authData = [UserSettings getAuthData];
    //    if (authData) {
    //        [self loadAlbumManager:authData];
    //    }
    //
    //    [[LNNotificationCenter defaultCenter] registerApplicationWithIdentifier:@"glance_app" name:@"Glance" icon:[UIImage imageNamed:@"CaptureButton"] defaultSettings:LNNotificationDefaultAppSettings];
    ////    [[LNNotificationCenter defaultCenter] setNotificationsBannerStyle:LNNotificationBannerStyleLight];
    ////    [LNNotificationCenter defaultCenter].notificationsBannerStyle = LNNotificationBannerStyleLight;
    //
    //
    //    // The following casts will work because of the way the MainStoryboard is set up.
    //
    ////    NSAssert([self.window.rootViewController isKindOfClass:[SVNavigationController class]], @"Error: rootViewController is not UINavigationController");
    //    SVNavigationController *navigationController = (SVNavigationController *)self.window.rootViewController;
    ////
    //    [navigationController setNavigationBarHidden:YES];
    ////
    ////    NSAssert([navigationController.visibleViewController isKindOfClass:[SVRegistrationViewController class]], @"Error: visibleViewController is not SVRegistrationViewController");
    //
    ////    GLWelcomeViewController * welcome = [[GLWelcomeViewController alloc] init];
    ////    ContainerViewController *registrationViewController = (ContainerViewController *)navigationController.visibleViewController;
    //    GLWelcomeViewController * welcome = [[GLWelcomeViewController alloc] init];
    //
    //
    //
    //    self.window.backgroundColor = [UIColor whiteColor];
    //
    //
    ////    welcome = (GLWelcomeViewController *)navigationController.visibleViewController;
    ////
    ////
    //////    UIPageViewController * pagesViewController = [[UIPageViewController alloc] init];
    //////    pagesViewController.ch
    ////
    //////    // Initialize the sidebar menu
    ////    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    //////    GLProfilePictureController *glprof = [storyboard instantiateViewControllerWithIdentifier:@"GLProfilePictureController"];
    ////
    ////    self.sidebarRight = [storyboard instantiateViewControllerWithIdentifier:@"SidebarMembersView"];
    ////    self.sidebarLeft = [storyboard instantiateViewControllerWithIdentifier:@"SidebarManagementView"];
    ////    self.sideMenu = [MFSideMenuContainerViewController containerWithCenterViewController:navigationController
    ////                                                                  leftMenuViewController:nil
    ////                                                                 rightMenuViewController:self.sidebarRight];
    ////    self.sideMenu.panMode = MFSideMenuPanModeNone;
    ////
    ////
    ////
    ////    self.window.rootViewController = self.sideMenu;
    //
    //
    ////    self.window.rootViewController.wantsFullScreenLayout = YES;
    //
    //
    ////    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    //    // Override point for customization after application launch.
    ////    self.window.backgroundColor = [UIColor whiteColor];
    ////    [self.window makeKeyAndVisible];
    //
    ////    self.window.rootViewController = container;
    ////    return YES;
    //
    //
    //    self.appOpenedFromPush = NO;
    //    SVInitialization *worker = [[SVInitialization alloc] init];
    //    [worker configureAppearanceProxies];
    //    [worker initializeLocalSettingsDefaults];
    //
    //
    ////    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"kUserSettedPicture"];
    //
    ////    [[NSUserDefaults standardUserDefaults] synchronize];
    //
    //    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"kUserLoggedIn"]) {
    ////        TutorialViewController *t = [[TutorialViewController alloc] init];
    ////        t.onClose = ^(id responseObject) {
    ////            self.window.rootViewController = navigationController;
    ////
    ////            if (![self isLoggedIn]) {
    //////                [self processCountryCode:[UIApplication sharedApplication] registrationViewController:registrationViewController];
    ////            } else {
    ////                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"kTutorialShown"];
    ////                [[NSUserDefaults standardUserDefaults] synchronize];
    ////            }
    ////        };
    //
    //
    //        welcome.onClose = ^(id response){
    ////            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"kTutorialShown"];
    ////            [[NSUserDefaults standardUserDefaults] synchronize];
    ////            [navigationController setNavigationBarHidden:NO animated:YES];
    //            self.window.rootViewController = navigationController;
    //        };
    //        self.window.rootViewController = welcome;
    //
    //
    //
    //    } else {
    //        if (![self isLoggedIn]) {
    ////            [self processCountryCode:application registrationViewController:registrationViewController];
    //        }
    //        ContainerViewController * cont = [ContainerViewController sharedInstance];
    //        self.window.rootViewController = cont;
    //
    //        UILocalNotification *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    //        if (notification) {
    //            NSLog(@"app recieved notification from remote%@",notification);
    //
    //            self.appOpenedFromPush = YES;
    //            [self application:application didReceiveRemoteNotification:(NSDictionary*)notification];
    ////            self.window.alpha = 0;
    //
    //
    ////            ContainerViewController * cont = [ContainerViewController sharedInstance];
    //            //
    //
    ////            if([[NSUserDefaults standardUserDefaults] boolForKey:@"kUserLoggedIn"]){
    ////                self.window.rootViewController = glprof;
    ////            } else {
    ////                self.window.rootViewController = cont;
    ////            }
    //
    //
    //
    ////            NSString * pushType = [[(NSDictionary*)notification objectForKey:@"d"] objectForKey:@"type"];
    //////            long long int albumId = [[(NSDictionary*)notification objectForKey:@"d"] objectForKey:@"album_id"];
    ////            if([pushType isEqualToString:@"photo_comment"]){
    ////
    ////            } else if([pushType isEqualToString:@"photos_added"]){
    ////
    //////                [[ContainerViewController sharedInstance] transitToAlbumList:YES direction:UIPageViewControllerNavigationDirectionForward withAlbumId:5045 completion:^{
    //////
    //////                }];
    ////
    ////            }
    //
    //
    //
    ////            UIAlertView* failureAlert = [[UIAlertView alloc] initWithTitle:pushType
    ////                                                                   message:nil
    ////                                                                  delegate:nil
    ////                                                         cancelButtonTitle:@"OK"
    ////                                                         otherButtonTitles:nil];
    ////
    ////            [failureAlert show];
    //
    //
    ////            [[ContainerViewController sharedInstance] transitToAlbumList:YES direction:UIPageViewControllerNavigationDirectionForward withAlbumId:<#(long long)#> completion:^{
    ////
    ////            }];
    //
    //        }else{
    ////            UIAlertView* failureAlert = [[UIAlertView alloc] initWithTitle:@"2"
    ////                                                                   message:nil
    ////                                                                  delegate:nil
    ////                                                         cancelButtonTitle:@"OK"
    ////                                                         otherButtonTitles:nil];
    ////
    ////            [failureAlert show];
    ////            NSLog(@"app did not recieve notification");
    //
    ////            ContainerViewController * cont = [ContainerViewController sharedInstance];
    //////            GLProfilePictureController * glp = [[GLProfilePictureController alloc] init];
    ////            //
    ////            self.window.rootViewController = glprof;
    //        }
    //
    //
    //    }
    //
    ////    long t = ;
    //
    //    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
    //
    //        [[NSUserDefaults standardUserDefaults] setInteger:[[[ShotVibeAppDelegate sharedDelegate].albumManager getShotVibeAPI] getUserGlanceScoreWithLong:[[[[ShotVibeAppDelegate sharedDelegate].albumManager getShotVibeAPI] getAuthData] getUserId]] forKey:@"kUserScore"];
    //        [[NSUserDefaults standardUserDefaults] synchronize];
    //
    //    });
    
    
    
    //    [];
    
    //    sleep(3);
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
    
    long long userId = [[shotVibeAPI getAuthData] getUserId];
    ShotVibeCredentialsProvider *credentials = [[ShotVibeCredentialsProvider alloc] initWithShotVibeAPI:shotVibeAPI];
    self.uploadManager = [[UploadManager alloc] initWithAWSCredentialsProvider:credentials withUserId:userId];
    
    _albumManager = [[SLAlbumManager alloc] initWithSLShotVibeAPI:shotVibeAPI
                                                 withSLShotVibeDB:shotVibeDB
                                       withSLPhotoDownloadManager:_photoFilesManager
                                              withSLUploadManager:[uploadSystemDirector getUploadManager]
                                              withSLMediaUploader:self.uploadManager];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveUploadCompleteNotification:) name:@"GLUploadComplete" object:nil];
    
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
    [[[GLSharedCamera sharedInstance] videoCamera] stopCameraCapture];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    //    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
    //    [gpu]
    
    
    [[[GLPubNubManager sharedInstance] pubNubCLient]unsubscribeFromAll];
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    //    [[[GLSharedCamera sharedInstance] videoCamera] stopCameraCapture];
    RCLog(@"applicationDidEnterBackground fin");
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    // Restart any tasks that were paused (or not yet started) while the application was inactive.
    // If the application was previously in the background, optionally refresh the user interface.
    if(![[GLSharedCamera sharedInstance] isInFeedMode] ){
        [[[GLSharedCamera sharedInstance] videoCamera] startCameraCapture];
    }
    
    [[GLPubNubManager sharedInstance] reSubscribeToChannel];
    
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    //    [[[GLPubNubManager sharedInstance] pubNubCLient]unsubscribeFromAll];
    
}

- (void) receiveUploadCompleteNotification:(NSNotification *)notification
{
    NSLog(@"ShotVibeAppDelegate receiveUploadCompleteNotification");
    
    NSString *path = [NSString stringWithFormat:@"%@/dropsound.wav", [[NSBundle mainBundle] resourcePath]];
    NSURL *soundUrl = [NSURL fileURLWithPath:path];
    
    [self.theAudio stop];
    // Create audio player object and initialize with URL to sound
    self.theAudio = [[AVAudioPlayer alloc] initWithContentsOfURL:soundUrl error:nil];
    [self.theAudio play];
    
    
    
    
    // TODO ...
}


#pragma mark Remote notifications

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [pushNotificationsManager setAPNSDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    
    
    //    [userInfo];
    //    if ( application.applicationState == UIApplicationStateInactive || application.applicationState == UIApplicationStateBackground  )
    //    {
    //        //opened from a push notification when the app was on background
    //    }
    
    
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
static NSString *const appCountryLookupVersion = @"9";

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
        NSString *shotvibeAppInitUrl = @"https://i.useglance.com/app_init/?";
        
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

- (BOOL) platformTypeIsIphone5
{
    
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    
    
    //    if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    //    if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    //    if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    //    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    //    if ([platform isEqualToString:@"iPhone3,3"])    return @"Verizon iPhone 4";
    //    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone5,1"])    return YES;
    if ([platform isEqualToString:@"iPhone5,2"])    return YES;
    if ([platform isEqualToString:@"iPhone5,3"])    return YES;
    if ([platform isEqualToString:@"iPhone5,4"])    return YES;
    if ([platform isEqualToString:@"iPhone6,1"])    return YES;
    if ([platform isEqualToString:@"iPhone6,2"])    return YES;
    //    if ([platform isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    //    if ([platform isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
    //    if ([platform isEqualToString:@"iPhone8,1"])    return @"iPhone 6s";
    //    if ([platform isEqualToString:@"iPhone8,2"])    return @"iPhone 6s Plus";
    //    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    //    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    //    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    //    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    //    if ([platform isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G";
    //    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
    //    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    //    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    //    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    //    if ([platform isEqualToString:@"iPad2,4"])      return @"iPad 2 (WiFi)";
    //    if ([platform isEqualToString:@"iPad2,5"])      return @"iPad Mini (WiFi)";
    //    if ([platform isEqualToString:@"iPad2,6"])      return @"iPad Mini (GSM)";
    //    if ([platform isEqualToString:@"iPad2,7"])      return @"iPad Mini (GSM+CDMA)";
    //    if ([platform isEqualToString:@"iPad3,1"])      return @"iPad 3 (WiFi)";
    //    if ([platform isEqualToString:@"iPad3,2"])      return @"iPad 3 (GSM+CDMA)";
    //    if ([platform isEqualToString:@"iPad3,3"])      return @"iPad 3 (GSM)";
    //    if ([platform isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    //    if ([platform isEqualToString:@"iPad3,5"])      return @"iPad 4 (GSM)";
    //    if ([platform isEqualToString:@"iPad3,6"])      return @"iPad 4 (GSM+CDMA)";
    //    if ([platform isEqualToString:@"iPad4,1"])      return @"iPad Air (WiFi)";
    //    if ([platform isEqualToString:@"iPad4,2"])      return @"iPad Air (Cellular)";
    //    if ([platform isEqualToString:@"iPad4,3"])      return @"iPad Air";
    //    if ([platform isEqualToString:@"iPad4,4"])      return @"iPad Mini 2G (WiFi)";
    //    if ([platform isEqualToString:@"iPad4,5"])      return @"iPad Mini 2G (Cellular)";
    //    if ([platform isEqualToString:@"iPad4,6"])      return @"iPad Mini 2G";
    //    if ([platform isEqualToString:@"iPad4,7"])      return @"iPad Mini 3 (WiFi)";
    //    if ([platform isEqualToString:@"iPad4,8"])      return @"iPad Mini 3 (Cellular)";
    //    if ([platform isEqualToString:@"iPad4,9"])      return @"iPad Mini 3 (China)";
    //    if ([platform isEqualToString:@"iPad5,3"])      return @"iPad Air 2 (WiFi)";
    //    if ([platform isEqualToString:@"iPad5,4"])      return @"iPad Air 2 (Cellular)";
    //    if ([platform isEqualToString:@"AppleTV2,1"])   return @"Apple TV 2G";
    //    if ([platform isEqualToString:@"AppleTV3,1"])   return @"Apple TV 3";
    //    if ([platform isEqualToString:@"AppleTV3,2"])   return @"Apple TV 3 (2013)";
    //    if ([platform isEqualToString:@"i386"])         return @"Simulator";
    //    if ([platform isEqualToString:@"x86_64"])       return @"Simulator";
    //    
    //    NSLog(@"iPhone Device%@",[self platformType]);
    
    free(machine);
    
    return NO;
}


@end
