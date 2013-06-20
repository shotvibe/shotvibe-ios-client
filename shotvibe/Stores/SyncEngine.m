//
//  SyncEngine.m
//  shotvibe
//
//  Created by Peter Kasson on 6/18/13.
//
//  Parts taken from IFSyncEngine (Fred G.)
//
//  Copyright (c) 2013 Appiphany, Inc. All rights reserved.
//

//#import "AFHTTPRequestOperation.h"
#import "SVDefines.h"
#import "SyncEngine.h"
//#import "IFSyncPollingBD.h"
//#import "PFObjectParent.h"
#import "SVEntityStore.h"


@interface SyncEngine ()

@property (nonatomic, strong) __block NSManagedObjectContext *syncContext;
@property (nonatomic, strong) NSMutableArray *registeredClassesToSync;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (atomic, readonly) BOOL syncInProgress;
@property (nonatomic, strong) NSOperationQueue *parseSyncQueue;

//- (NSURL *)applicationCacheDirectory;
//- (NSString *)dateStringForAPIUsingDate:(NSDate *)date;
//- (NSDate *)dateUsingStringFromAPI:(NSString *)dateString;
//- (void)downloadDataForRegisteredObjects:(BOOL)useUpdatedAtDate toDeleteLocalRecords:(BOOL)toDelete;
//- (void)executeSyncCompletedOperations;
//- (void)initializeDateFormatter;
//- (NSArray *)managedObjectsForClass:(NSString *)className withSyncStatus:(IFObjectSyncStatus)syncStatus;
//- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key usingArrayOfIds:(NSArray *)idArray inArrayOfIds:(BOOL)inIds;
//- (NSDate *)mostRecentUpdatedAtDateForEntityWithName:(NSString *)entityName;
//- (void)newManagedObjectWithClassName:(NSString *)className forRecord:(NSDictionary *)record;
//- (void)repairCoreDataRelationships;
//- (void)setValue:(id)value forKey:(NSString *)key forManagedObject:(NSManagedObject *)managedObject;
//- (void)updateManagedObject:(NSManagedObject *)managedObject withRecord:(NSDictionary *)record;
@end

@implementation SyncEngine

#pragma mark - Class Methods

+ (SyncEngine *)sharedEngine
{
 static SyncEngine *sharedEngine = nil;
 static dispatch_once_t engineToken;
 dispatch_once(&engineToken, ^{
  sharedEngine = [[SyncEngine alloc] init];
 });
 
 return sharedEngine;
}


#pragma mark - Instance Methods

- (void)registerNSManagedObjectClassToSync:(Class)aClass
{
 if (!self.registeredClassesToSync) {
  self.registeredClassesToSync = [NSMutableArray array];
 }
 
 if ([aClass isSubclassOfClass:[NSManagedObject class]]) {
  if (![self.registeredClassesToSync containsObject:NSStringFromClass(aClass)]) {
   [self.registeredClassesToSync addObject:NSStringFromClass(aClass)];
  } else {
   NSLog(@"Unable to register %@ as it is already registered", NSStringFromClass(aClass));
  }
 } else {
  NSLog(@"Unable to register %@ as it is not a subclass of NSManagedObject", NSStringFromClass(aClass));
 }
}


/*
 * sync - retrieve albums and photos
 */
- (void)startSync
{
 if (!self.syncInProgress) {
  [self willChangeValueForKey:@"syncInProgress"];
  _syncInProgress = YES;
  [self didChangeValueForKey:@"syncInProgress"];
  
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

   [[SVEntityStore sharedStore] userAlbums];
   
  });
 }
}


#pragma mark - Private Methods


- (void)executeSyncCompletedOperations
{
 dispatch_async(dispatch_get_main_queue(), ^{
  [self setInitialSyncCompleted];
  [[NSNotificationCenter defaultCenter] postNotificationName:kSDSyncEngineSyncCompletedNotificationName object:nil];
  
  [self willChangeValueForKey:@"syncInProgress"];
  _syncInProgress = NO;
  [self didChangeValueForKey:@"syncInProgress"];
  
  //        [[IFSyncPollingBD sharedDelegate] startPolling];
 });
}


- (BOOL)initialSyncComplete
{
 BOOL boolToReturn = [[[NSUserDefaults standardUserDefaults] valueForKey:kSDSyncEngineInitialCompleteKey] boolValue];
 return boolToReturn;
}


- (NSDate *)mostRecentUpdatedAtDateForEntityWithName:(NSString *)entityName
{
 __block NSDate *date = nil;
 
 //
 // Create a new fetch request for the specified entity
 //
 NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
 
 //
 // Set the sort descriptors on the request to sort by updatedAt in descending order
 //
 [request setSortDescriptors:[NSArray arrayWithObject:
                              [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO]]];
 
 //
 // You are only interested in 1 result so limit the request to 1
 //
 //    [request setFetchLimit:1];
 //    [[NSManagedObjectContext contextForCurrentThread] performBlockAndWait:^{
 //        NSError *error = nil;
 //        NSArray *results = [[NSManagedObjectContext contextForCurrentThread] executeFetchRequest:request error:&error];
 //        if ([results lastObject])   {
 //            //
 //            // Set date to the fetched result
 //            //
 //            date = [[results lastObject] valueForKey:@"updatedAt"];
 //        }
 //    }];
 
 return date;
}



- (void)setInitialSyncCompleted
{
 [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:kSDSyncEngineInitialCompleteKey];
 [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark - NSManagedObject Methods

- (void)newManagedObjectWithClassName:(NSString *)className forRecord:(NSDictionary *)record
{
 NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:className inManagedObjectContext:self.syncContext];
 
 [record enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
  [self setValue:obj forKey:key forManagedObject:newManagedObject];
 }];
 [record setValue:[NSNumber numberWithInt:IFObjectSynced] forKey:@"syncStatus"];
 if ([className isEqualToString:@"Category"]) {
  [self setValue:[NSNumber numberWithInt:IFObjectRelationshipNeeded] forKey:@"relationshipSyncStatus" forManagedObject:newManagedObject];
 }
}


- (void)updateManagedObject:(NSManagedObject *)managedObject withRecord:(NSDictionary *)record
{
 [record enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
  NSString *aKey = (NSString *)key;
  if (![aKey isEqualToString:@"category"] && ![aKey isEqualToString:@"igUsers"] && ![aKey isEqualToString:@"subcategories"]) {
   [self setValue:obj forKey:key forManagedObject:managedObject];
  }
 }];
 
 //    if ([managedObject isKindOfClass:[Category class]]) {
 //        [self setValue:[NSNumber numberWithInt:IFObjectRelationshipNeeded] forKey:@"relationshipSyncStatus" forManagedObject:managedObject];
 //    }
}


- (void)setValue:(id)value forKey:(NSString *)key forManagedObject:(NSManagedObject *)managedObject
{
 if ([key isEqualToString:@"createdAt"] || [key isEqualToString:@"updatedAt"])
 {
  NSDate *date = [self dateUsingStringFromAPI:value];
  [managedObject setValue:date forKey:key];
 }
 else if ([value isKindOfClass:[NSDictionary class]])
 {
  if ([value objectForKey:@"__type"]) {
   NSString *dataType = [value objectForKey:@"__type"];
   if ([dataType isEqualToString:@"Date"]) {
    NSString *dateString = [value objectForKey:@"iso"];
    NSDate *date = [self dateUsingStringFromAPI:dateString];
    [managedObject setValue:date forKey:key];
   } else if ([dataType isEqualToString:@"File"]) {
    NSString *urlString = [value objectForKey:@"url"];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *dataResponse = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    [managedObject setValue:dataResponse forKey:key];
   } else {
    NSLog(@"Unknown Data Type Received");
    [managedObject setValue:nil forKey:key];
   }
  }
 }
 else
 {
  [managedObject setValue:value forKey:key];
 }
}




#pragma mark - Date Handling

- (void)initializeDateFormatter
{
 if (!self.dateFormatter) {
  self.dateFormatter = [[NSDateFormatter alloc] init];
  [self.dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
  [self.dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
 }
}


- (NSDate *)dateUsingStringFromAPI:(NSString *)dateString
{
 [self initializeDateFormatter];
 // NSDateFormatter does not like ISO 8601 so strip the milliseconds and timezone
 dateString = [dateString substringWithRange:NSMakeRange(0, [dateString length]-5)];
 
 return [self.dateFormatter dateFromString:dateString];
}


- (NSString *)dateStringForAPIUsingDate:(NSDate *)date
{
 [self initializeDateFormatter];
 NSString *dateString = [self.dateFormatter stringFromDate:date];
 // remove Z
 dateString = [dateString substringWithRange:NSMakeRange(0, [dateString length]-1)];
 // add milliseconds and put Z back on
 dateString = [dateString stringByAppendingFormat:@".000Z"];
 
 return dateString;
}


#pragma mark - File Management

- (NSURL *)applicationCacheDirectory
{
 return [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
}



#pragma mark - Key Value Observing

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                         change:(NSDictionary *)change context:(void *)context
{
 if (object == self.parseSyncQueue && [keyPath isEqualToString:@"operations"]) {
  if (self.parseSyncQueue.operationCount == 0) {
   [[NSNotificationCenter defaultCenter] postNotificationName:kCategoryBadgeUpdatedNotification object:nil];
  }
 }
 else {
  [super observeValueForKeyPath:keyPath ofObject:object
                         change:change context:context];
 }
}


#pragma mark - Memory Management

- (void)dealloc
{
 [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
