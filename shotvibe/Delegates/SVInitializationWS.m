//
//  SVInitializationWS.m
//  ShotVibe
//
//  Created by Fredrick Gabelmann on 1/23/13.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import "SVInitializationWS.h"

@interface SVInitializationWS ()

- (NSString *)urlForStoreName:(NSString *)storeFileName;

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
    
    // Create the managed object model
    NSURL *modelURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ShotVibe" ofType:@"momd"]];
    NSManagedObjectModel *managedObjectModel = [[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL] mutableCopy];
    
    // Create the managed object store
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
    objectManager.managedObjectStore = managedObjectStore;
    [managedObjectStore createPersistentStoreCoordinator];
    
    // Create the persistent store
    NSError *error = nil;
    NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:[RKApplicationDataDirectory() stringByAppendingPathComponent:@"ShotVibe.sqlite"] fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
    if (error) {
        RKLogError(@"%@", error);
    }
    NSAssert(persistentStore, @"Failed to add persistent store with error: %@", error);
    
    // Create the managed object contexts
    [managedObjectStore createManagedObjectContexts];
    
    // Configure a managed object cache to ensure we do not create duplicate objects
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    
    [RKObjectManager setSharedManager:objectManager];
    
    // Enable Activity Indicator Spinner
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
}


#pragma mark - Private Methods

- (NSString *)urlForStoreName:(NSString *)storeFileName
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *applicationStorageDirectory = [[[[NSBundle mainBundle] infoDictionary] valueForKey:(NSString *)kCFBundleNameKey] stringByAppendingPathComponent:[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject]];
    
    NSArray *paths = @[documentsDirectory, applicationStorageDirectory];
    NSFileManager *fm = [[NSFileManager alloc] init];
    
    for (NSString *path in paths)
    {
        NSString *filepath = [path stringByAppendingPathComponent:storeFileName];
        if ([fm fileExistsAtPath:filepath])
        {
            return filepath;
        }
    }
    
    //set default url
    return [applicationStorageDirectory stringByAppendingPathComponent:storeFileName];
}
@end
