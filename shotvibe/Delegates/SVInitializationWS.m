//
//  SVInitializationWS.m
//  ShotVibe
//
//  Created by Fredrick Gabelmann on 1/23/13.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import "SVInitializationWS.h"

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
    NSURL *baseURL = [NSURL URLWithString:@"https://api.shotvibe.com"];
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:baseURL];
    NSURL *modelURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ShotVibe" ofType:@"momd"]];
    NSManagedObjectModel *managedObjectModel = [[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL] mutableCopy];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
    objectManager.managedObjectStore = managedObjectStore;
}
@end
