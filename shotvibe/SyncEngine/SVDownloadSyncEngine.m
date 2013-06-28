//
//  SVDownloadSyncEngine.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 6/25/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AFJSONRequestOperation.h"
#import "AFImageRequestOperation.h"
#import "Album.h"
#import "AlbumPhoto.h"
#import "Member.h"
#import "NSFileManager+Helper.h"
#import "SVAPIClient.h"
#import "SVDefines.h"
#import "SVDownloadSyncEngine.h"

@interface SVDownloadSyncEngine ()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (atomic, readonly) BOOL syncInProgress;

@property (atomic, strong) NSOperationQueue *internalQueue;

@property (atomic, strong) NSManagedObjectContext *savingContext;

- (NSURL *)applicationCacheDirectory;
- (NSDate *)dateUsingStringFromAPI:(NSString *)dateString;
- (NSString *)dateStringForAPIUsingDate:(NSDate *)date;
- (void)deleteJSONDataRecordsForClassWithName:(NSString *)className;
- (void)deleteJSONDataRecordsForPhotos;
- (void)downloadAlbums:(BOOL)useLastRequestDate;
- (void)downloadPhotos;
- (void)downloadImages;
- (void)downloadAvatars;
- (void)executeSyncCompletedOperations;
- (void)initializeDateFormatter;
- (BOOL)initialSyncComplete;
- (void)insertDataIntoCoreDataForClassName:(NSString *)className;
- (id)JSONDataForClassWithName:(NSString *)className;
- (NSURL *)JSONDataRecordsDirectory;
- (NSURL *)photoUrlWithString:(NSString *)aString;
- (void)processAlbumsJSON;
- (void)processPhotosJSON;
- (void)processMembersData:(NSDictionary *)data withAlbum:(Album *)anAlbum;
- (void)processPhotosData:(NSDictionary *)data withAlbum:(Album *)anAlbum;
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
        if (sharedEngine.internalQueue == nil) {
            sharedEngine.internalQueue = [[NSOperationQueue alloc] init];
            sharedEngine.internalQueue.maxConcurrentOperationCount = 1;
            [sharedEngine.internalQueue addObserver:sharedEngine forKeyPath:@"operations" options:NSKeyValueObservingOptionNew context:NULL];
        }
    });
    
    return sharedEngine;
}


#pragma mark - Instance Methods

- (void)startSync
{
    if (!self.syncInProgress) {
        [self willChangeValueForKey:@"syncInProgress"];
        _syncInProgress = YES;
        [self didChangeValueForKey:@"syncInProgress"];
        
        [self downloadAlbums:NO];
    }
}


#pragma mark - Private Methods


- (void)downloadAlbums:(BOOL)useLastRequestDate
{
    NSMutableArray *operations = [NSMutableArray array];
    
    NSDate *lastRequestDate = nil;
    
    // Setup the Album request
    NSString *path = @"albums/";
    NSDictionary *parameters = nil;
    NSDictionary *headers = nil;
    
    if (lastRequestDate) {
        headers = @{@"If-Modified-Since": lastRequestDate};
    }
    
    NSMutableURLRequest *theRequest = [[SVAPIClient sharedClient] GETRequestForAllRecordsAtPath:path withParameters:parameters andHeaders:headers];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:theRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        if (useLastRequestDate) {
            [[NSUserDefaults standardUserDefaults] setObject:[[response allHeaderFields] objectForKey:@"Date"] forKey:kUserAlbumsLastRequestedDate];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        if ([JSON isKindOfClass:[NSDictionary class]] || [JSON isKindOfClass:[NSArray class]]) {
            [self writeJSONResponse:JSON toDiskForClassWithName:@"Album"];
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        //TODO: we should still check the caches folder and process anything that is in there
        // in case the app quite before it could finish.
        NSLog(@"Request for class %@ failed with error: %@", @"Album", error);
        
    }];
    
    [operations addObject:operation];
    
    [[SVAPIClient sharedClient] enqueueBatchOfHTTPRequestOperations:operations progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
        
        //TODO: Post a progress notification for interested observers
        
    } completionBlock:^(NSArray *operations) {
        
        [self processAlbumsJSON];
        
    }];
}


- (void)downloadPhotos
{
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
        
        //TODO: check the cache directory and delete any AlbumPhoto records
        if (![[NSFileManager defaultManager] isEmptyDirectoryAtURL:[self JSONDataRecordsDirectory]]) {
            [self processPhotosJSON];
        }
        
    }];
}


- (void)downloadAvatars
{
    NSArray *members = [Member findAll];
    
    NSMutableArray *operations = [NSMutableArray arrayWithCapacity:members.count];
    
    for (Member *member in members) {
        
        NSURL *imageUrl = [self photoUrlWithString:member.avatar_url];
        NSURLRequest *imageRequest = [NSURLRequest requestWithURL:imageUrl];
        
        AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:imageRequest success:^(UIImage *image) {
            
            NSLog(@"We have an image.");
            
        }];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSLog(@"The object we got back was a %@", [responseObject class]);
            NSLog(@"The operation was a success!");
            
            @autoreleasepool {
                UIImage *image = (UIImage *)responseObject;
                
                [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                    
                    Member *localMember = (Member *)[localContext objectWithID:member.objectID];
                    localMember.avatarData = UIImageJPEGRepresentation(image, 1);
                    
                }];
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            NSLog(@"The operation was a failure: %@", error);
            
        }];
        [operations addObject:operation];
        
    }
    
    [[SVAPIClient sharedClient] enqueueBatchOfHTTPRequestOperations:operations progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
        
        //TODO: Post a progress notification for interested observers
        
    } completionBlock:^(NSArray *operations) {
        
        [self downloadImages];
        
    }];
}


- (void)downloadImages
{
    NSArray *photos = [AlbumPhoto findAll];
    
    NSMutableArray *operations = [NSMutableArray arrayWithCapacity:photos.count];
    
    for (AlbumPhoto *photo in photos) {
        
        // Image
        NSURL *imageUrl = [self photoUrlWithString:photo.photo_url];
        NSURLRequest *imageRequest = [NSURLRequest requestWithURL:imageUrl];
        
        AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:imageRequest success:^(UIImage *image) {
            
            NSLog(@"We have an image.");
            
        }];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSLog(@"The object we got back was a %@", [responseObject class]);
            NSLog(@"The operation was a success!");
            
            UIImage *image = (UIImage *)responseObject;
            
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                
                @autoreleasepool {
                    AlbumPhoto *localPhoto = (AlbumPhoto *)[localContext objectWithID:photo.objectID];
                    localPhoto.photoData = UIImageJPEGRepresentation(image, 1);
                    
                    CGSize newSize = CGSizeMake(100, 100);
                    float oldWidth = image.size.width;
                    float scaleFactor = newSize.width / oldWidth;
                    float newHeight = image.size.height * scaleFactor;
                    float newWidth = oldWidth * scaleFactor;
                    
                    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
                    [image drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
                    UIImage *thumbImage = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    
                    NSData *thumbnailData = UIImageJPEGRepresentation(thumbImage, 1.0);
                    localPhoto.thumbnailPhotoData = thumbnailData;
                }
                
            }];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            NSLog(@"The operation was a failure: %@", error);
            
        }];
        [operations addObject:operation];
        
    }
    
    [[SVAPIClient sharedClient] enqueueBatchOfHTTPRequestOperations:operations progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
        
        //TODO: Post a progress notification for interested observers
        
    } completionBlock:^(NSArray *operations) {
        
        [self executeSyncCompletedOperations];
        
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

- (void)processAlbumsJSON
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    });
    
    id albums = [self JSONDataForClassWithName:@"Album"];
    
    if ([albums isKindOfClass:[NSArray class]])
    {
        [MagicalRecord saveUsingCurrentThreadContextWithBlock:^(NSManagedObjectContext *localContext) {
            
            for (NSDictionary *anAlbum in albums) {
                
                Album *newAlbum = [Album createInContext:localContext];
                [anAlbum enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    [self setValue:obj forKey:key forManagedObject:newAlbum];
                }];
                [newAlbum setValue:[NSNumber numberWithInt:SVObjectSyncCompleted] forKey:@"objectSyncStatus"];
            }
            
        } completion:^(BOOL success, NSError *error) {
            
            
            [self deleteJSONDataRecordsForClassWithName:@"Album"];
            [self downloadPhotos];
            
        }];
    }
}


- (void)processPhotosJSON
{
    NSArray *albums = [Album findAll];
    for (Album *anAlbum in albums) {
        
        NSDictionary *data = [self JSONDataForClassWithName:[NSString stringWithFormat:@"AlbumPhoto-%@", anAlbum.albumId.stringValue]];
        
        // Process each member object
        [self processMembersData:data withAlbum:anAlbum];
        
    }
}


- (void)processMembersData:(NSDictionary *)data withAlbum:(Album *)anAlbum
{
    NSArray *members = [data objectForKey:@"members"];
    
    for (NSDictionary *member in members) {
        
        [self.internalQueue addOperationWithBlock:^{
            
            [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
                
                Member *existingMember = [Member findFirstByAttribute:@"userId" withValue:[member objectForKey:@"id"] inContext:localContext];
                
                if (!existingMember) {
                    
                    Member *newMember = [Member createInContext:localContext];
                    [member enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                        [self setValue:obj forKey:key forManagedObject:newMember];
                    }];
                    
                    Album *localAlbum = (Album *)[localContext objectWithID:anAlbum.objectID];
                    [localAlbum addMembersObject:newMember];
                    
                } else {
                    
                    Member *localMember = (Member *)[localContext objectWithID:existingMember.objectID];
                    Album *localAlbum = (Album *)[localContext objectWithID:anAlbum.objectID];
                    [localAlbum addMembersObject:localMember];
                    
                }
                
            }];
            
        }];
        
    }
    
    // Process each photo object
    [self processPhotosData:data withAlbum:anAlbum];
}


- (void)processPhotosData:(NSDictionary *)data withAlbum:(Album *)anAlbum
{
    //self.internalQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    NSArray *photosArray = [data objectForKey:@"photos"];
    
    for (NSDictionary *photo in photosArray) {
        
        [self.internalQueue addOperationWithBlock:^{
            
            [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
                
                AlbumPhoto *existingPhoto = [AlbumPhoto findFirstByAttribute:@"photo_id" withValue:[photo objectForKey:@"photo_id"] inContext:localContext];
                
                if (!existingPhoto) {
                    
                    AlbumPhoto *newPhoto = [AlbumPhoto createInContext:localContext];
                    
                    [photo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                        [self setValue:obj forKey:key forManagedObject:newPhoto];
                    }];
                    [newPhoto setValue:[NSNumber numberWithInt:SVObjectSyncCompleted] forKey:@"objectSyncStatus"];
                    
                    Album *localAlbum = (Album *)[localContext objectWithID:anAlbum.objectID];
                    Member *localAuthor = [Member findFirstByAttribute:@"userId" withValue:[[photo objectForKey:@"author"] objectForKey:@"id"] inContext:localContext];
                    
                    [localAlbum addAlbumPhotosObject:newPhoto];
                    
                    if (localAuthor) {
                        [newPhoto setValue:localAuthor forKey:@"author"];
                    }
                    
                } else {
                    
                    AlbumPhoto *localPhoto = (AlbumPhoto *)[localContext objectWithID:existingPhoto.objectID];
                    Album *localAlbum = (Album *)[localContext objectWithID:anAlbum.objectID];
                    [localAlbum addAlbumPhotosObject:localPhoto];
                    
                }
                
            }];
            
        }];
        
    }
    
    [self deleteJSONDataRecordsForClassWithName:[NSString stringWithFormat:@"AlbumPhoto-%@", anAlbum.albumId.stringValue]];
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
            [managedObject setValue:value forKey:key];
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
        
        if (objectIdKey != nil) {
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
                        
                    } else {
                        // Otherwise you have a new object coming in from your remote service so create a new
                        // NSManagedObject to represent this remote object locally
                    }
                    currentIndex++;
                    
                }
            }
        }
        
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


- (void)deleteJSONDataRecordsForPhotos
{
    NSArray *albums = [Album findAll];
    for (Album *album in albums) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"AlbumPhoto-%@", album.albumId.stringValue] relativeToURL:[self JSONDataRecordsDirectory]];
        NSError *error = nil;
        BOOL deleted = [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
        if (!deleted) {
            NSLog(@"Unable to delete JSON Records at %@, reason: %@", url, error);
        }
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


#pragma mark - Key Value Observing

- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                        context:(void *)context
{
    if (object == self.downloadQueue && [keyPath isEqualToString:@"operations"]) {
        if ([self.downloadQueue.operations count] == 0) {
            // Do something here when your queue has completed
            NSLog(@"queue has completed");
        }
    }
    else if (object == self.internalQueue && [keyPath isEqualToString:@"operations"]) {
        if ([self.internalQueue.operations count] == 0) {
            NSLog(@"We should be done writing to disk now!");
            [self downloadAvatars];
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
