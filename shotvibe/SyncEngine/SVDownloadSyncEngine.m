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
{
    dispatch_queue_t saveQueue;
}

@property (nonatomic, strong) NSManagedObjectContext *syncContext;
@property (nonatomic, strong) NSMutableArray *albumsWithUpdates;
@property (nonatomic, strong) NSMutableArray *imagesToFetch;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (atomic, readonly) BOOL syncInProgress;

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
- (id)JSONDataForClassWithName:(NSString *)className;
- (NSURL *)JSONDataRecordsDirectory;
- (NSURL *)photoUrlWithString:(NSString *)aString;
- (void)processAlbumsJSON;
- (void)processPhotosJSON;
- (void)saveContext;
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
        sharedEngine.downloadQueue = [SVAPIClient sharedClient].operationQueue;
    });
    
    return sharedEngine;
}


#pragma mark - Instance Methods

- (void)startSync
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        if (!self.syncInProgress) {
            [self willChangeValueForKey:@"syncInProgress"];
            _syncInProgress = YES;
            [self didChangeValueForKey:@"syncInProgress"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            });
            [self downloadAlbums:YES];
        }
        
    });
}


#pragma mark - Private Methods


- (void)downloadAlbums:(BOOL)useLastRequestDate
{
    NSString *lastRequestDate = nil;
    
    // Setup the Album request
    NSString *path = @"albums/";
    NSDictionary *parameters = nil;
    NSDictionary *headers = nil;
    
    if (useLastRequestDate) {
        lastRequestDate = [[NSUserDefaults standardUserDefaults] objectForKey:kUserAlbumsLastRequestedDate];
        if (lastRequestDate) {
            headers = @{@"If-Modified-Since": lastRequestDate};
        }
    }
    
    NSMutableURLRequest *theRequest = [[SVAPIClient sharedClient] GETRequestForAllRecordsAtPath:path withParameters:parameters andHeaders:headers];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:theRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        
        
    }];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (useLastRequestDate) {
            [[NSUserDefaults standardUserDefaults] setObject:[[operation.response allHeaderFields] objectForKey:@"Date"] forKey:kUserAlbumsLastRequestedDate];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        if ([responseObject isKindOfClass:[NSDictionary class]] || [responseObject isKindOfClass:[NSArray class]]) {
            [self writeJSONResponse:responseObject toDiskForClassWithName:@"Album"];
            [self processAlbumsJSON];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
       
        //TODO: we should still check the caches folder and process anything that is in there
        // in case the app quite before it could finish.
        //NSLog(@"Request for class %@ failed with error: %@", @"Album", error);
        [self executeSyncCompletedOperations];
        
    }];
    
    [[SVAPIClient sharedClient] enqueueBatchOfHTTPRequestOperations:@[operation] progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
        
        //TODO: Post a progress notification for interested observers
        
    } completionBlock:^(NSArray *operations) {
        
        
        
    }];
}


- (void)downloadPhotos
{
    NSMutableArray *operations = [NSMutableArray array];
    NSLog(@"We need to update %d Albums", self.albumsWithUpdates.count);
    
    for (Album *anAlbum in self.albumsWithUpdates) {
        
        NSUInteger albumId = anAlbum.albumId.integerValue;
        NSString *path = [NSString stringWithFormat:@"albums/%d/", albumId];
        
        NSDictionary *headers = nil;
        if ([self initialSyncComplete]) {
            headers = @{@"If-None-Match": anAlbum.etag};
        }
        
        NSMutableURLRequest *theRequest = [[SVAPIClient sharedClient] GETRequestForAllRecordsAtPath:path withParameters:nil andHeaders:headers];
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:theRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            
            
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            
            
            
        }];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            if ([responseObject isKindOfClass:[NSDictionary class]] || [responseObject isKindOfClass:[NSArray class]]) {
                [self writeJSONResponse:responseObject toDiskForClassWithName:[NSString stringWithFormat:@"AlbumPhoto-%@", anAlbum.albumId.stringValue]];
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
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
    NSArray *members = [Member findAllInContext:self.syncContext];
    
    NSMutableArray *operations = [NSMutableArray arrayWithCapacity:members.count];
    
    for (Member *member in members) {
        
        NSURL *imageUrl = [self photoUrlWithString:member.avatar_url];
        NSURLRequest *imageRequest = [NSURLRequest requestWithURL:imageUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20.0];
        
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:imageRequest];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            Member *localMember = (Member *)[self.syncContext objectWithID:member.objectID];
            localMember.avatarData = operation.responseData;
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            //NSLog(@"The operation was a failure: %@", error);
            
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
    NSMutableArray *operations = [NSMutableArray arrayWithCapacity:self.imagesToFetch.count];
    
    for (AlbumPhoto *photo in self.imagesToFetch) {
        
        NSURL *imageUrl = [self photoUrlWithString:photo.photo_url];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:imageUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20];
        
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            AlbumPhoto *localPhoto = (AlbumPhoto *)[self.syncContext objectWithID:photo.objectID];
            [localPhoto setPhotoData:operation.responseData];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            //NSLog(@"The operation was a failure: %@", error);
            
        }];
        [operations addObject:operation];
        
    }
    //TODO: We MUST figure out how to add all these operations into a queue so that we can
    // know when to call executeSyncCompletedOperations.
    [[SVAPIClient sharedClient] enqueueBatchOfHTTPRequestOperations:operations progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
        
        //TODO: Post a progress notification for interested observers
        
    } completionBlock:^(NSArray *operations) {
        
        self.imagesToFetch = nil;
        [self executeSyncCompletedOperations];
        
    }];
}


- (void)executeSyncCompletedOperations
{
    [self saveContext];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self setInitialSyncCompleted];
        [self willChangeValueForKey:@"syncInProgress"];
        _syncInProgress = NO;
        [self didChangeValueForKey:@"syncInProgress"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kSVSyncEngineSyncCompletedNotification object:nil];
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
    });
}


- (BOOL)initialSyncComplete
{
    return [[[NSUserDefaults standardUserDefaults] valueForKey:kSVSyncEngineInitialSyncCompletedKey] boolValue];
}


- (NSURL *)photoUrlWithString:(NSString *)aString
{
    NSString *photoURL = nil;
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2){
        if (IS_IPHONE_5) {
            photoURL = [aString stringByReplacingOccurrencesOfString:@".jpg" withString:kPhotoIphone5Extension];
        }
        else
        {
            photoURL = [aString stringByReplacingOccurrencesOfString:@".jpg" withString:kPhotoIphone4Extension];
        }
    }
    else
    {
        photoURL = [aString stringByReplacingOccurrencesOfString:@".jpg" withString:kPhotoIphone3Extension];
    }
    
    return [NSURL URLWithString:photoURL];
}


- (void)saveContext
{
    if (!saveQueue) {
        saveQueue = dispatch_queue_create("com.picsonair.shotvibe.savequeue", DISPATCH_QUEUE_CONCURRENT);
    }
    
    dispatch_async(saveQueue, ^{
        
        [self.syncContext saveWithOptions:MRSaveParentContexts completion:^(BOOL success, NSError *error) {
            
            if (success) {
                NSLog(@"Wheeeeeeee ahaHAH, we've saved successfully");
                [NSManagedObjectContext resetContextForCurrentThread];
                [NSManagedObjectContext resetDefaultContext];
                self.syncContext = nil;
            }
            else
            {
                NSLog(@"We no can haz save right now");
            }
            
        }];
        
    });
}


- (void)setInitialSyncCompleted
{
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:kSVSyncEngineInitialSyncCompletedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark - NSManagedObject Methods

- (void)processAlbumsJSON
{
    NSLog(@"PROCESSING ALBUMS JSON");
    
    if (!self.syncContext) {
        self.syncContext = [NSManagedObjectContext context];
        [self.syncContext.userInfo setValue:@"AlbumSaveContext" forKey:@"kNSManagedObjectContextWorkingName"];
        self.syncContext.undoManager = nil;
    }
    
    id albums = [self JSONDataForClassWithName:@"Album"];
    
    if ([albums isKindOfClass:[NSArray class]])
    {
        for (NSDictionary *anAlbum in albums) {
            
            Album *newAlbum = [Album findFirstByAttribute:@"albumId" withValue:[anAlbum objectForKey:@"id"] inContext:self.syncContext];
            
            if (!newAlbum) {
                
                newAlbum = [Album createInContext:self.syncContext];
                
            }
            
            // Process the album
            [anAlbum enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [self setValue:obj forKey:key forManagedObject:newAlbum];
            }];
            [newAlbum setValue:[NSNumber numberWithInt:SVObjectSyncCompleted] forKey:@"objectSyncStatus"];
            
            // Process recent Photos
            NSArray *recentPhotos = [anAlbum objectForKey:@"latest_photos"];
            for (NSDictionary *photo in recentPhotos) {
                
                AlbumPhoto *photoToSave = [AlbumPhoto findFirstByAttribute:@"photo_id" withValue:[photo objectForKey:@"photo_id"] inContext:self.syncContext];
                
                if (!photoToSave) {
                    
                    photoToSave = [AlbumPhoto createInContext:self.syncContext];
                    
                }
                
                [photo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    [self setValue:obj forKey:key forManagedObject:photoToSave];
                }];
                [photoToSave setValue:[NSNumber numberWithInt:SVObjectSyncCompleted] forKey:@"objectSyncStatus"];
                [newAlbum addAlbumPhotosObject:photoToSave];
                
                Member *authorToSave = [Member findFirstByAttribute:@"userId" withValue:[[photo objectForKey:@"author"] objectForKey:@"id"] inContext:self.syncContext];
                if (!authorToSave) {
                    
                    authorToSave = [Member createInContext:self.syncContext];
                    
                }
                [[photo objectForKey:@"author"] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    [self setValue:obj forKey:key forManagedObject:authorToSave];
                }];
                [photoToSave setValue:authorToSave forKey:@"author"];
                [newAlbum addMembersObject:authorToSave];
                
            }
            
            if (!self.albumsWithUpdates) {
                self.albumsWithUpdates = [[NSMutableArray alloc] initWithCapacity:[albums count]];
            }
            [self.albumsWithUpdates addObject:newAlbum];
            
        }
        
        [self deleteJSONDataRecordsForClassWithName:@"Album"];
        [self saveContext];
        [self downloadPhotos];
    }
}


- (void)processPhotosJSON
{
    NSLog(@"PROCESSING PHOTOS JSON");
    
    if (!self.syncContext) {
        self.syncContext = [NSManagedObjectContext context];
        [self.syncContext.userInfo setValue:@"PhotoSaveContext" forKey:@"kNSManagedObjectContextWorkingName"];
        self.syncContext.undoManager = nil;
    }
    
    for (Album *anAlbum in self.albumsWithUpdates) {
        
        NSDictionary *data = [self JSONDataForClassWithName:[NSString stringWithFormat:@"AlbumPhoto-%@", anAlbum.albumId.stringValue]];
        
        // Process each member object
        NSArray *members = [data objectForKey:@"members"];
        for (NSDictionary *member in members) {
            
            Member *outerMember = [Member findFirstByAttribute:@"userId" withValue:[member objectForKey:@"id"] inContext:self.syncContext];
            
            Member *memberToSave = nil;
            if (outerMember) {
                memberToSave = outerMember;
            }
            else
            {
                memberToSave = [Member createInContext:self.syncContext];
            }
            
            [member enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [self setValue:obj forKey:key forManagedObject:memberToSave];
            }];
            Album *localAlbum = (Album *)[self.syncContext objectWithID:anAlbum.objectID];
            [localAlbum addMembersObject:memberToSave];
            
        }

        // Process each photo object
        NSArray *photosArray = [data objectForKey:@"photos"];
        for (NSDictionary *photo in photosArray) {
            
            AlbumPhoto *outerPhoto = [AlbumPhoto findFirstByAttribute:@"photo_id" withValue:[photo objectForKey:@"photo_id"] inContext:self.syncContext];
            
            AlbumPhoto *photoToSave = nil;
            if (outerPhoto) {
                photoToSave = outerPhoto;
            } else {
                photoToSave = [AlbumPhoto createInContext:self.syncContext];
            }
            
            [photo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [self setValue:obj forKey:key forManagedObject:photoToSave];
            }];
            [photoToSave setValue:[NSNumber numberWithInt:SVObjectSyncCompleted] forKey:@"objectSyncStatus"];
            
            Album *localAlbum = (Album *)[self.syncContext objectWithID:anAlbum.objectID];
            Member *localAuthor = [Member findFirstByAttribute:@"userId" withValue:[[photo objectForKey:@"author"] objectForKey:@"id"] inContext:self.syncContext];
            
            [localAlbum addAlbumPhotosObject:photoToSave];
            
            if (localAuthor) {
                [photoToSave setValue:localAuthor forKey:@"author"];
            }
            
            if (!self.imagesToFetch) {
                self.imagesToFetch = [[NSMutableArray alloc] init];
            }
            [self.imagesToFetch addObject:photoToSave];
            
        }
        
        [self deleteJSONDataRecordsForClassWithName:[NSString stringWithFormat:@"AlbumPhoto-%@", anAlbum.albumId.stringValue]];
        
    }
    
    [self saveContext];
    
    // Download images
    //[self downloadAvatars];
    //[self executeSyncCompletedOperations];
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
            [self executeSyncCompletedOperations];
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
