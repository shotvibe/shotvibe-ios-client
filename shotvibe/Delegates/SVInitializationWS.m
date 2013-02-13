//
//  SVInitializationWS.m
//  ShotVibe
//
//  Created by Fredrick Gabelmann on 1/23/13.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import "SVInitializationWS.h"

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
