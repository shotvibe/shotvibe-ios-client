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

- (void)setObjectMappingsWithMangedObjectStore:(RKManagedObjectStore *)managedObjectStore;

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
    [managedObjectStore createManagedObjectContexts];
    
    // Configure a managed object cache to ensure we do not create duplicate objects
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    
    [RKObjectManager setSharedManager:objectManager];
    
    // Enable Activity Indicator Spinner
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
}


#pragma mark - Private Methods

- (void)setObjectMappingsWithMangedObjectStore:(RKManagedObjectStore *)managedObjectStore
{
    // Member mapping
    RKEntityMapping *memberMapping = [RKEntityMapping mappingForEntityForName:@"Member" inManagedObjectStore:managedObjectStore];
    memberMapping.identificationAttributes = @[@"userId"];
    
    // Album mapping
    RKEntityMapping *albumMapping = [RKEntityMapping mappingForEntityForName:@"Album" inManagedObjectStore:managedObjectStore];
    albumMapping.identificationAttributes = @[@"albumId"];
    [albumMapping addAttributeMappingsFromDictionary:@{
     @"id": @"albumId",
     @"url": @"url",
     @"name": @"name",
     @"last_updated": @"lastUpdated",
     @"etag": @"etag",
     @"date_created": @"dateCreated"
     }];
    
    // Photo mapping
    RKEntityMapping *photoMapper = [RKEntityMapping mappingForEntityForName:@"Photo" inManagedObjectStore:managedObjectStore];
    photoMapper.identificationAttributes = @[@"photoId"];
}
@end
