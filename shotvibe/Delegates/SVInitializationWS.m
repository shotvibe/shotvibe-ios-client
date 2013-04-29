//
//  SVInitializationWS.m
//  ShotVibe
//
//  Created by Fredrick Gabelmann on 1/23/13.
//

#import "SVInitializationWS.h"
#import "SVDefines.h"

#ifdef DEBUG
#endif
static NSString * const kTestAuthToken = @"Token 8d437481bdf626a9e9cd6fa2236d113eb1c9786d";


@interface SVInitializationWS ()


@end

@implementation SVInitializationWS

#pragma mark - Instance Methods

- (void)initializeVendorLibraries
{
    
}


- (void)configureAppearanceProxies
{
    // Customize appearance of the navigation bar    
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], UITextAttributeTextColor, [UIFont fontWithName:@"HelveticaNeue-Bold" size:16.0], UITextAttributeFont, nil]];
    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:1.0 forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:0.0 forBarMetrics:UIBarMetricsLandscapePhone];
    
    {
        UIImage *baseImage = [UIImage imageNamed:@"navBarBg.png"];
        UIEdgeInsets insets = UIEdgeInsetsMake(5, 20, 0, 20);
        
        UIImage *resizableImage = nil;
        if (IS_IOS6_OR_GREATER) {
            resizableImage = [baseImage resizableImageWithCapInsets:insets];
        }
        else
        {
            resizableImage = [baseImage resizableImageWithCapInsets:insets];
        }
        
        [[UINavigationBar appearance] setBackgroundImage:resizableImage forBarMetrics:UIBarMetricsDefault];
    }
    
    // Customize back barbuttonitem for nav bar
    /*[[UIBarButtonItem appearance] setBackButtonBackgroundVerticalPositionAdjustment:3.0 forBarMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackButtonBackgroundVerticalPositionAdjustment:1.0 forBarMetrics:UIBarMetricsLandscapePhone];*/
    {
        UIImage *baseImage = [UIImage imageNamed:@"navbarBackButton.png"];
        UIEdgeInsets insets = UIEdgeInsetsMake(25, 0, 5, 5);
        
        UIImage *resizableImage = nil;
        if (IS_IOS6_OR_GREATER) {
            resizableImage = [baseImage resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
            
            // Why on earth is the position different depending on version?
        }
        else
        {
            resizableImage = [baseImage stretchableImageWithLeftCapWidth:0 topCapHeight:5];
            
            // iOS5 back buttons are messed up :/
        }
        
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:resizableImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    }
    {
        UIImage *baseImage = [UIImage imageNamed:@"navbarBackButtonLandscape.png"];
        UIEdgeInsets insets = UIEdgeInsetsMake(25, 0, 5, 5);
        
        UIImage *resizableImage = nil;
        if (IS_IOS6_OR_GREATER) {
            resizableImage = [baseImage resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
        }
        else
        {
            resizableImage = [baseImage stretchableImageWithLeftCapWidth:0 topCapHeight:5];
        }
        
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:resizableImage forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
    }
    
    // Customize regular barbuttonitem for navbar
    [[UIBarButtonItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], UITextAttributeTextColor, [UIFont fontWithName:@"HelveticaNeue-Bold" size:12.0], UITextAttributeFont, nil] forState:UIControlStateNormal];
    /*[[UIBarButtonItem appearance] setBackgroundVerticalPositionAdjustment:3.0 forBarMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackgroundVerticalPositionAdjustment:1.0 forBarMetrics:UIBarMetricsLandscapePhone];
    [[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(0, 1) forBarMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(0, 1) forBarMetrics:UIBarMetricsLandscapePhone];*/
    {
        UIImage *baseImage = [UIImage imageNamed:@"navbarButton.png"];
        UIEdgeInsets insets = UIEdgeInsetsMake(10, 10, 10, 10);
        
        UIImage *resizableImage = nil;
        if (IS_IOS6_OR_GREATER) {
            resizableImage = [baseImage resizableImageWithCapInsets:insets];
        }
        else
        {
            resizableImage = [baseImage resizableImageWithCapInsets:insets];
        }
        
        [[UIBarButtonItem appearance] setBackgroundImage:resizableImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    }
    
    {
        UIImage *baseImage = [UIImage imageNamed:@"navbarButtonLandscape.png"];
        UIEdgeInsets insets = UIEdgeInsetsMake(15, 10, 15, 10);
        
        UIImage *resizableImage = nil;
        if (IS_IOS6_OR_GREATER) {
            resizableImage = [baseImage resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
        }
        else
        {
            resizableImage = [baseImage resizableImageWithCapInsets:insets];
        }
        
        [[UIBarButtonItem appearance] setBackgroundImage:resizableImage forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
    }
    
    
    // Customize UIToolbar
    [[UIToolbar appearance] setBackgroundImage:[UIImage imageNamed:@"pictureDetailToolbarBg.png"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [[UIToolbar appearance] setBackgroundImage:[UIImage imageNamed:@"pictureDetailToolbarBg.png"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsLandscapePhone];
    
    // Customize UISearchBar
    {
        UIImage *baseImage = [UIImage imageNamed:@"searchBarBg.png"];
        UIEdgeInsets insets = UIEdgeInsetsMake(5, 20, 0, 20);
        
        UIImage *resizableImage = nil;
        if (IS_IOS6_OR_GREATER) {
            resizableImage = [baseImage resizableImageWithCapInsets:insets];
        }
        else
        {
            resizableImage = [baseImage resizableImageWithCapInsets:insets];
        }
        
        [[UISearchBar appearance] setBackgroundImage:resizableImage];
    }
}


- (void)processAnalytics
{
    
}


- (void)initializeLocalSettingsDefaults
{
    // Setup defaults for general notification settings (not for individual albums)
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HAS_SET_NOTIFICATION_DEFAULTS"]) {
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"GENERAL_NOTIFICATION"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"GENERAL_VIBRATION"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"GENERAL_SOUND"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"GENERAL_PREVIEW_MODE"];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HAS_SET_NOTIFICATION_DEFAULTS"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}


- (void)initializeManagedObjectModel
{
    // Create the object manager
    NSURL *baseURL = [NSURL URLWithString:@"https://api.shotvibe.com"];
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:baseURL];
    [objectManager.HTTPClient setDefaultHeader:@"Authorization" value:kTestAuthToken];
    
    // Enable Activity Indicator Spinner
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    // Create the managed object model
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
    objectManager.managedObjectStore = managedObjectStore;
    
    // Instantiate Core Data Stack
    [managedObjectStore createPersistentStoreCoordinator];
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"ShotVibe.sqlite"];
    NSError *error = nil;
    NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
    NSAssert(persistentStore, @"Failed to add persistent store with error: %@", error);
    
    // Create the managed object contexts
    [managedObjectStore createManagedObjectContexts];
    [managedObjectStore.persistentStoreManagedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    
    // Configure a managed object cache to ensure we do not create duplicate objects
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
}


#pragma mark - Private Methods
@end
