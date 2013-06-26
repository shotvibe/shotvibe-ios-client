//
//  SVDownloadSyncEngine.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 6/25/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AFJSONRequestOperation.h"
#import "Album.h"
#import "SVAPIClient.h"
#import "SVDefines.h"
#import "SVDownloadSyncEngine.h"

@interface SVDownloadSyncEngine ()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSMutableArray *registeredClassesToSync;
@property (atomic, readonly) BOOL syncInProgress;

- (NSURL *)applicationCacheDirectory;
- (NSDate *)dateUsingStringFromAPI:(NSString *)dateString;
- (NSString *)dateStringForAPIUsingDate:(NSDate *)date;
- (void)deleteJSONDataRecordsForClassWithName:(NSString *)className;
- (void)downloadDataForRegisteredObjects:(BOOL)useLastRequestDate;
- (void)executeSyncCompletedOperations;
- (void)initializeDateFormatter;
- (BOOL)initialSyncComplete;
- (void)insertDataIntoCoreDataForClassName:(NSString *)className;
- (id)JSONDataForClassWithName:(NSString *)className;
- (NSURL *)JSONDataRecordsDirectory;
- (void)newManagedObjectWithClassName:(NSString *)className forRecord:(NSDictionary *)record;
- (NSURL *)photoUrlWithString:(NSString *)aString;
- (void)retrievePhotoObjects;
- (void)setInitialSyncCompleted;
- (void)setValue:(id)value forKey:(NSString *)key forManagedObject:(NSManagedObject *)managedObject;
- (void)writeJSONResponse:(id)response toDiskForClassWithName:(NSString *)className;
@end

@implementation SVDownloadSyncEngine

#pragma mark - Class Methods

+ (SVDownloadSyncEngine *)sharedEngine
{
    static SVDownloadSyncEngine *sharedEngine = nil;
    static dispatch_once_t downloadEngineToken;
    dispatch_once(&downloadEngineToken, ^{
        sharedEngine = [[SVDownloadSyncEngine alloc] init];
        if (sharedEngine.downloadQueue == nil) {
            sharedEngine.downloadQueue = [[NSOperationQueue alloc] init];
            sharedEngine.downloadQueue.maxConcurrentOperationCount = 1;
        }
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


- (void)startSync
{
    if (!self.syncInProgress) {
        [self willChangeValueForKey:@"syncInProgress"];
        _syncInProgress = YES;
        [self didChangeValueForKey:@"syncInProgress"];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            
            [self downloadDataForRegisteredObjects:YES];
            
        });
    }
}


#pragma mark - Private Methods


- (void)downloadDataForRegisteredObjects:(BOOL)useLastRequestDate
{
    NSMutableArray *operations = [NSMutableArray array];
    
    for (NSString *className in self.registeredClassesToSync) {
        
        NSDate *lastRequestDate = nil;
        NSString *path = nil;
        NSDictionary *parameters = nil;
        NSDictionary *headers = nil;
        
        if (useLastRequestDate) {
            lastRequestDate = [[NSUserDefaults standardUserDefaults] objectForKey:kUserAlbumsLastRequestedDate];
        }
        
        if ([className isEqualToString:@"Album"])
        {
            
            // Setup the Album request
            path = @"albums/";
            headers = nil;
            if (lastRequestDate) {
                headers = @{@"If-Modified-Since": lastRequestDate};
            }
            
        }
        
        NSMutableURLRequest *theRequest = [[SVAPIClient sharedClient] GETRequestForAllRecordsAtPath:path withParameters:parameters andHeaders:headers];
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:theRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            
            //NSLog(@"JSON Object Type: %@", [JSON class]);
            //NSLog(@"Response for %@: %@", className, JSON);
            
            if ([className isEqualToString:@"Album"]) {
                
                [[NSUserDefaults standardUserDefaults] setObject:[[response allHeaderFields] objectForKey:@"Date"] forKey:kUserAlbumsLastRequestedDate];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
            }
            
            if ([JSON isKindOfClass:[NSDictionary class]] || [JSON isKindOfClass:[NSArray class]]) {
                [self writeJSONResponse:JSON toDiskForClassWithName:className];
            }
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            
            NSLog(@"Request for class %@ failed with error: %@", className, error);
            
        }];
        
        [operations addObject:operation];
        
    }
    
    [[SVAPIClient sharedClient] enqueueBatchOfHTTPRequestOperations:operations progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
        
        //TODO: Post a progress notification for interested observers
        
    } completionBlock:^(NSArray *operations) {
        
        NSLog(@"All operations completed.");
        
        [self processJSONDataRecordsIntoCoreDataForClassName:@"Album"];
        
    }];
}


- (void)executeSyncCompletedOperations
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self setInitialSyncCompleted];
        [self willChangeValueForKey:@"syncInProgress"];
        _syncInProgress = NO;
        [self didChangeValueForKey:@"syncInProgress"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        });
        [[NSNotificationCenter defaultCenter] postNotificationName:kSVSyncEngineSyncCompletedNotification object:nil];
        
    });
}


- (BOOL)initialSyncComplete
{
    return [[[NSUserDefaults standardUserDefaults] valueForKey:kSVSyncEngineInitialSyncCompletedKey] boolValue];
}


- (void)retrievePhotoObjects
{
    //TODO: check the cache directory and delete any AlbumPhoto records
    
    NSArray *albums = [Album findAll];
    NSMutableArray *operations = [NSMutableArray array];
    
    for (Album *anAlbum in albums) {
        
        NSUInteger albumId = anAlbum.albumId.integerValue;
        NSString *path = [NSString stringWithFormat:@"albums/%d/", albumId];
        
        NSDictionary *headers = nil;
        if ([self initialSyncComplete]) {
            // Setup the Album request
            headers = @{@"If-None-Match": anAlbum.etag};
        }
        
        NSMutableURLRequest *theRequest = [[SVAPIClient sharedClient] GETRequestForAllRecordsAtPath:path withParameters:nil andHeaders:headers];
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:theRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            
            //NSLog(@"JSON Object Type: %@", [JSON class]);
            //NSLog(@"Response for AlbumPhoto: %@", JSON);
            
            if ([JSON isKindOfClass:[NSDictionary class]] || [JSON isKindOfClass:[NSArray class]]) {
                [self writeJSONResponse:JSON toDiskForClassWithName:[NSString stringWithFormat:@"AlbumPhoto-%@", anAlbum.albumId.stringValue]];
            }
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            
            NSLog(@"Request for class AlbumPhoto failed with error: %@", error);
            
        }];
        
        [operations addObject:operation];
    }
    
    [[SVAPIClient sharedClient] enqueueBatchOfHTTPRequestOperations:operations progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
        
        //TODO: Post a progress notification for interested observers
        
    } completionBlock:^(NSArray *operations) {
        
        NSLog(@"All operations completed.");
        
        [self processJSONDataRecordsIntoCoreDataForClassName:@"AlbumPhoto"];
        
    }];
}


- (void)setInitialSyncCompleted
{
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:kSVSyncEngineInitialSyncCompletedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (NSURL *)photoUrlWithString:(NSString *)aString
{
    NSString *photoURL = nil;
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2){
        if (IS_IPHONE_5) {
            photoURL = [[aString stringByDeletingPathExtension] stringByAppendingString:kPhotoIphone5Extension];
        }
        else
        {
            photoURL = [[aString stringByDeletingPathExtension] stringByAppendingString:kPhotoIphone4Extension];
        }
    }
    else
    {
        photoURL = [[aString stringByDeletingPathExtension] stringByAppendingString:kPhotoIphone3Extension];
    }
    
    return [NSURL URLWithString:photoURL];
}


#pragma mark - NSManagedObject Methods

- (void)newManagedObjectWithClassName:(NSString *)className forRecord:(NSDictionary *)record
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    });
    
    [self.downloadQueue addOperationWithBlock:^{
        
        [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
            
            NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:className inManagedObjectContext:localContext];
            
            [record enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [self setValue:obj forKey:key forManagedObject:newManagedObject];
            }];
            [record setValue:[NSNumber numberWithInt:SVObjectSyncCompleted] forKey:@"objectSyncStatus"];
            
        }];
        
    }];
}


- (void)updateManagedObject:(NSManagedObject *)managedObject withRecord:(NSDictionary *)record
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    });
    
    [self.downloadQueue addOperationWithBlock:^{
        
        [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
            
            [record enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                NSString *aKey = (NSString *)key;
                if (![aKey isEqualToString:@"albumPhotos"] && ![aKey isEqualToString:@"albums"] && ![aKey isEqualToString:@"members"] && ![aKey isEqualToString:@"album"] && ![aKey isEqualToString:@"author"]) {
                    [self setValue:obj forKey:key forManagedObject:managedObject];
                }
            }];
            
        }];
        
    }];
}


- (void)setValue:(id)value forKey:(NSString *)key forManagedObject:(NSManagedObject *)managedObject
{
    if (![key isEqualToString:@"latest_photos"] && ![key isEqualToString:@"author"]) {
        if ([[[managedObject entity] name] isEqualToString:@"Album"] && [key isEqualToString:@"id"])
        {
            [managedObject setValue:value forKey:@"albumId"];
        }
        else if ([[[managedObject entity] name] isEqualToString:@"Member"] && [key isEqualToString:@"id"])
        {
            [managedObject setValue:value forKey:@"userId"];
        }
        else if ([key isEqualToString:@"last_updated"] || [key isEqualToString:@"date_created"])
        {
            NSDate *date = [self dateUsingStringFromAPI:value];
            [managedObject setValue:date forKey:key];
        }
        else if ([key isEqualToString:@"avatar_url"] || [key isEqualToString:@"photo_url"])
        {
            @autoreleasepool {
                NSURL *url = [self photoUrlWithString:value];
                NSURLRequest *request = [NSURLRequest requestWithURL:url];
                NSURLResponse *response = nil;
                NSError *error = nil;
                NSData *dataResponse = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
                
                NSString *newKey = nil;
                if ([key isEqualToString:@"avatar_url"]) {
                    newKey = @"avatarData";
                } else if ([key isEqualToString:@"photo_url"]) {
                    newKey = @"photoData";
                }
                [managedObject setValue:dataResponse forKey:newKey];
                [managedObject setValue:value forKey:key];
            }
        }
        else
        {
            [managedObject setValue:value forKey:key];
        }
    }
}


- (NSArray *)managedObjectsForClass:(NSString *)className withSyncStatus:(SVObjectSyncStatus)syncStatus
{
    __block NSArray *results = nil;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:className];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectSyncStatus = %d", syncStatus];
    [fetchRequest setPredicate:predicate];
    
    [[NSManagedObjectContext contextForCurrentThread] performBlockAndWait:^{
        NSError *error = nil;
        results = [[NSManagedObjectContext contextForCurrentThread] executeFetchRequest:fetchRequest error:&error];
    }];
    
    return results;
}


- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key usingArrayOfIds:(NSArray *)idArray inArrayOfIds:(BOOL)inIds
{
    __block NSArray *results = nil;
    
    NSString *idString = nil;
    if ([className isEqualToString:@"Album"]) {
        idString = @"albumId";
    } else if ([className isEqualToString:@"AlbumPhoto"]) {
        idString = @"photo_id";
    } else if ([className isEqualToString:@"Member"]) {
        idString = @"userId";
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:className];
    NSPredicate *predicate;
    if (inIds) {
        predicate = [NSPredicate predicateWithFormat:@"%@ IN %@", idString, idArray];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"NOT (%@ IN %@)", idString, idArray];
    }
    
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:idString ascending:YES]]];
    
    [[NSManagedObjectContext contextForCurrentThread] performBlockAndWait:^{
        NSError *error = nil;
        results = [[NSManagedObjectContext contextForCurrentThread] executeFetchRequest:fetchRequest error:&error];
    }];
    
    return results;
}


- (void)insertDataIntoCoreDataForClassName:(NSString *)className
{
    if (![self initialSyncComplete]) // import all downloaded data to Core Data for initial sync
    {
        //
        // If this is the initial sync then the logic is pretty simple, you will fetch the JSON data from disk
        // for the class of the current iteration and create new NSManagedObjects for each record
        //
        id records = [self JSONDataForClassWithName:className];
        if ([records isKindOfClass:[NSArray class]]) {
            for (NSDictionary *record in records) {
                [self newManagedObjectWithClassName:className forRecord:record];
            }
        } else {
            NSDictionary *record = records;
            NSArray *members = [record objectForKey:@"members"];
            for (NSDictionary *aRecord in members) {
                [self newManagedObjectWithClassName:@"Member" forRecord:aRecord];
                //TODO: Set the Album relationship
            }
            NSArray *photos = [record objectForKey:@"photos"];
            for (NSDictionary *aRecord in photos) {
                [self newManagedObjectWithClassName:@"AlbumPhoto" forRecord:aRecord];
                //TODO: Set the Album relationship
                //TODO: Set the Author relationship
            }
        }
        
    }
    else
    {
        //
        // Otherwise you need to do some more logic to determine if the record is new or has been updated.
        // First get the downloaded records from the JSON response, verify there is at least one object in
        // the data, and then fetch all records stored in Core Data whose objectId matches those from the JSON response.
        //
        NSString *objectIdKey = nil;
        if ([className isEqualToString:@"Album"]) {
            objectIdKey = @"albumId";
        } else if ([className isEqualToString:@"AlbumPhoto"]) {
            objectIdKey = @"photo_id";
        } else if ([className isEqualToString:@"Member"]) {
            objectIdKey = @"userId";
        }
        NSArray *downloadedRecords = [self JSONDataRecordsForClass:className sortedByKey:objectIdKey];
        if ([downloadedRecords lastObject])
        {
            //
            // Now you have a set of objects from the remote service and all of the matching objects
            // (based on objectId) from your Core Data store. Iterate over all of the downloaded records
            // from the remote service.
            //
            NSArray *storedRecords = [self managedObjectsForClass:className sortedByKey:objectIdKey usingArrayOfIds:[downloadedRecords valueForKey:objectIdKey] inArrayOfIds:YES];
            int currentIndex = 0;
            //
            // If the number of records in your Core Data store is less than the currentIndex, you know that
            // you have a potential match between the downloaded records and stored records because you sorted
            // both lists by objectId, this means that an update has come in from the remote service
            //
            for (NSDictionary *record in downloadedRecords) {
                NSManagedObject *storedManagedObject = nil;
                
                // Make sure we don't access an index that is out of bounds as we are iterating over both collections together.
                if ([storedRecords count] > currentIndex) {
                    storedManagedObject = [storedRecords objectAtIndex:currentIndex];
                }
                
                if ([[storedManagedObject valueForKey:objectIdKey] isEqualToString:[record valueForKey:objectIdKey]]) {
                    //
                    // Do a quick spot check to validate the objectIds in fact do match, if they do update the stored
                    // object with the values received from the remote service
                    //
                    [self updateManagedObject:[storedRecords objectAtIndex:currentIndex] withRecord:record];
                } else {
                    // Otherwise you have a new object coming in from your remote service so create a new
                    // NSManagedObject to represent this remote object locally
                    [self newManagedObjectWithClassName:className forRecord:record];
                }
                currentIndex++;
                
            }
        }
    }
    
    [self deleteJSONDataRecordsForClassWithName:className];
}


- (void)processJSONDataRecordsIntoCoreDataForClassName:(NSString *)className
{
    if ([className isEqualToString:@"Album"]) {
        [self insertDataIntoCoreDataForClassName:className];
        NSLog(@"%d", self.downloadQueue.operationCount);
        [self.downloadQueue addOperationWithBlock:^{
            
            [self retrievePhotoObjects];
            
        }];
    } else {
        NSArray *albums = [Album findAll];
        for (Album *anAlbum in albums) {
            
            [self insertDataIntoCoreDataForClassName:[NSString stringWithFormat:@"%@-%@", className, anAlbum.albumId.stringValue]];
            
        }
        [self executeSyncCompletedOperations];
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


- (NSString *)dateStringForAPIUsingDate:(NSDate *)date
{
    [self initializeDateFormatter];
    NSString *dateString = [self.dateFormatter stringFromDate:date];
    return dateString;
}


- (NSDate *)dateUsingStringFromAPI:(NSString *)dateString
{
    [self initializeDateFormatter];
    dateString = [dateString substringWithRange:NSMakeRange(0, [dateString length]-5)];
    return [self.dateFormatter dateFromString:dateString];
}


#pragma mark - File Management

- (NSURL *)applicationCacheDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
}


- (NSURL *)JSONDataRecordsDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *url = [NSURL URLWithString:@"SVJSONRecords/" relativeToURL:[self applicationCacheDirectory]];
    NSError *error = nil;
    if (![fileManager fileExistsAtPath:[url path]]) {
        [fileManager createDirectoryAtPath:[url path] withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    return url;
}


- (id)JSONDataForClassWithName:(NSString *)className
{
    NSURL *fileURL = [NSURL URLWithString:className relativeToURL:[self JSONDataRecordsDirectory]];
    id objectToReturn = nil;
    if ([className isEqualToString:@"Album"]) {
        objectToReturn = [NSArray arrayWithContentsOfURL:fileURL];
    } else {
        objectToReturn = [NSDictionary dictionaryWithContentsOfURL:fileURL];
    }
    
    return objectToReturn;
}


- (id)JSONDataRecordsForClass:(NSString *)className sortedByKey:(NSString *)key
{
    id objectToSort = [self JSONDataForClassWithName:className];
    
    id recordsToReturn = [objectToSort sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:key ascending:YES]]];
    
    return recordsToReturn;
}


- (void)deleteJSONDataRecordsForClassWithName:(NSString *)className
{
    NSURL *url = [NSURL URLWithString:className relativeToURL:[self JSONDataRecordsDirectory]];
    NSError *error = nil;
    BOOL deleted = [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
    if (!deleted) {
        NSLog(@"Unable to delete JSON Records at %@, reason: %@", url, error);
    }
}


- (void)writeJSONResponse:(id)response toDiskForClassWithName:(NSString *)className
{
    NSURL *fileURL = [NSURL URLWithString:className relativeToURL:[self JSONDataRecordsDirectory]];
    
    if (![(NSDictionary *)response writeToFile:[fileURL path] atomically:YES]) {
        NSLog(@"Error saving response to disk, will attempt to remove NSNull values and try again.");
        
        // remove NSNulls and try again...
        NSArray *records = [response objectForKey:@"results"];
        NSMutableArray *nullFreeRecords = [NSMutableArray array];
        for (NSDictionary *record in records) {
            NSMutableDictionary *nullFreeRecord = [NSMutableDictionary dictionaryWithDictionary:record];
            [record enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if ([obj isKindOfClass:[NSNull class]]) {
                    [nullFreeRecord setValue:nil forKey:key];
                }
            }];
            [nullFreeRecords addObject:nullFreeRecord];
        }
        
        NSDictionary *nullFreeDictionary = [NSDictionary dictionaryWithObject:nullFreeRecords forKey:@"results"];
        
        if (![nullFreeDictionary writeToFile:[fileURL path] atomically:YES]) {
            NSLog(@"Failed all attempts to save response to disk: %@", response);
        }
    }
}


#pragma mark - Memory Management

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
