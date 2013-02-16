//
//  SVInitializationWS.m
//  ShotVibe
//
//  Created by Fredrick Gabelmann on 1/23/13.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import "SVInitializationWS.h"
#import "SVDefines.h"

#ifdef DEBUG
static NSString * const kTestAuthToken = @"Token 8d437481bdf626a9e9cd6fa2236d113eb1c9786d";
#endif

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
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], UITextAttributeTextColor, [UIFont fontWithName:@"HelveticaNeue-Light" size:22.0], UITextAttributeFont, nil]];
    {
        UIImage *baseImage = [UIImage imageNamed:@"navbarBg.png"];
        UIEdgeInsets insets = UIEdgeInsetsMake(5, 5, 5, 5);
        
        UIImage *resizableImage = nil;
        if (IS_IOS6_OR_GREATER) {
            resizableImage = [baseImage resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
        }
        else
        {
            resizableImage = [baseImage resizableImageWithCapInsets:insets];
        }
        
        [[UINavigationBar appearance] setBackgroundImage:resizableImage forBarMetrics:UIBarMetricsDefault];
    }
    
    // Customize back barbuttonitem for nav bar
    {
        UIImage *baseImage = [UIImage imageNamed:@"navbarBackButton.png"];
        UIEdgeInsets insets = UIEdgeInsetsMake(25, 0, 5, 5);
        
        UIImage *resizableImage = nil;
        if (IS_IOS6_OR_GREATER) {
            resizableImage = [baseImage resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
            
            // Why on earth is the position different depending on version?
            [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(2, -2) forBarMetrics:UIBarMetricsDefault];
        }
        else
        {
            resizableImage = [baseImage stretchableImageWithLeftCapWidth:0 topCapHeight:5];
            
            // iOS5 back buttons are messed up :/
            [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(2, -4) forBarMetrics:UIBarMetricsDefault];
        }
        
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:resizableImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    }
    
    // Customize regular barbuttonitem for navbar
    [[UIBarButtonItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor colorWithRed:0.00 green:0.67 blue:0.93 alpha:1.0], UITextAttributeTextColor, [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0], UITextAttributeFont, nil] forState:UIControlStateNormal];
    
    {
        UIImage *baseImage = [UIImage imageNamed:@"navbarButton.png"];
        UIEdgeInsets insets = UIEdgeInsetsMake(5, 5, 5, 5);
        
        UIImage *resizableImage = nil;
        if (IS_IOS6_OR_GREATER) {
            resizableImage = [baseImage resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
        }
        else
        {
            resizableImage = [baseImage resizableImageWithCapInsets:insets];
        }
        
        [[UIBarButtonItem appearance] setBackgroundImage:resizableImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    }
}


- (void)processAnalytics
{
    
}


- (void)initializeLocalSettingsDefaults
{
    
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
    
    // Configure a managed object cache to ensure we do not create duplicate objects
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
}


#pragma mark - Private Methods
@end
