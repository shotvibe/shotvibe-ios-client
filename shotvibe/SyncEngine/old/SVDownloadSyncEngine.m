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
#import "SVJSONAPIClient.h"
#import "SVDefines.h"
#import "SVDownloadSyncEngine.h"
#import "SVEntityStore.h"
#import "SVDownloadQueueManager.h"
#import "SVUploadQueueManager.h"
#import "MagicalRecordShorthand.h"
#import "MagicalRecord+Actions.h"

@interface SVDownloadSyncEngine ()
{
    dispatch_queue_t saveQueue;
}

@property (nonatomic, strong) NSManagedObjectContext *syncAlbumsContext;
@property (nonatomic, strong) NSManagedObjectContext *syncPhotosContext;
@property (nonatomic, strong) NSMutableArray *albumsWithUpdates;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSTimer *syncTimer;

@property (atomic, readonly) BOOL syncInProgress;

- (NSURL *)applicationCacheDirectory;
- (NSURL *)applicationDocumentsDirectory;
- (NSDate *)dateUsingStringFromAPI:(NSString *)dateString;
- (void)deleteJSONDataRecordsForClassWithName:(NSString *)className;
- (void)downloadAlbums;
- (void)downloadPhotos;
- (void)executeSyncCompletedOperations;
- (void)initializeDateFormatter;
- (BOOL)initialSyncComplete;
- (NSURL *)imageDataDirectory;
- (id)JSONDataForClassWithName:(NSString *)className;
- (NSURL *)JSONDataRecordsDirectory;
- (void)processAlbumsJSON;
- (void)processPhotosJSON;
- (void)saveAlbumsContext;
- (void)savePhotosContext;
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
    });
    
    return sharedEngine;
}


#pragma mark - Instance Methods

- (void)startSync
{
    if (!self.syncTimer) {
        self.syncTimer = [NSTimer scheduledTimerWithTimeInterval:30.0
														  target:self
														selector:@selector(start)
														userInfo:nil
														 repeats:NO];
    }
}
- (void)stopSync
{
    if (self.syncTimer) {
        [self.syncTimer invalidate];
		self.syncTimer = nil;
    }
}


#pragma mark - Private Methods

- (void)start
{
    if (![[SVUploadQueueManager sharedManager] syncInProgress]) {
		NSLog(@"Timer Fire when !syncInProgress");
        if (!self.syncInProgress) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                
                [self willChangeValueForKey:@"syncInProgress"];
                _syncInProgress = YES;
                [self didChangeValueForKey:@"syncInProgress"];
				
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
                });
                [self downloadAlbums];
                
            });
        }
    } else {
        NSLog(@"The upload queue manager is busy, please wait!");
    }
}


- (void)downloadAlbums
{
	
    // Setup the Album request
    NSString *path = @"albums/";
    NSDictionary *parameters = nil;
    
    NSMutableURLRequest *theRequest = [[SVJSONAPIClient sharedClient] requestWithMethod:@"GET" path:path parameters:parameters];
    
	NSString *lastRequestDate = [[NSUserDefaults standardUserDefaults] objectForKey:kUserAlbumsLastRequestedDate];
	
	NSLog(@"Request albums with lastRequestDate %@", lastRequestDate);
	
	if (lastRequestDate) {
		[theRequest setValue:lastRequestDate forHTTPHeaderField:@"If-Modified-Since"];
	}
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:theRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        NSLog(@"Got response code: %d Date: %@", response.statusCode, [response allHeaderFields]);
		
		[[NSUserDefaults standardUserDefaults] setObject:[[response allHeaderFields] objectForKey:@"Date"] forKey:kUserAlbumsLastRequestedDate];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		if ([JSON isKindOfClass:[NSDictionary class]] || [JSON isKindOfClass:[NSArray class]]) {
			[self writeJSONResponse:JSON toDiskForClassWithName:@"Album"];
			[self processAlbumsJSON];
		}
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        [self executeSyncCompletedOperations];
        
    }];
    
    __weak AFJSONRequestOperation *weakOperation = operation;
    [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:^{
        
        if (weakOperation.isFinished) {
            [[SVJSONAPIClient sharedClient].operationQueue cancelAllOperations];
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kUserAlbumsLastRequestedDate];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
    }];
    
    [[SVJSONAPIClient sharedClient] enqueueHTTPRequestOperation:operation];
}


- (void)downloadPhotos
{
	NSLog(@"download photos");
    if (!self.syncPhotosContext) {
        self.syncPhotosContext = [NSManagedObjectContext context];
        [self.syncPhotosContext.userInfo setValue:@"PhotoSaveContext" forKey:@"kNSManagedObjectContextWorkingName"];
        self.syncPhotosContext.undoManager = nil;
    }

    NSMutableArray *operations = [NSMutableArray array];
    
    for (NSNumber *anAlbumID in self.albumsWithUpdates) {
        
        Album *anAlbum = [Album findFirstByAttribute:@"albumId" withValue:anAlbumID inContext:self.syncPhotosContext];
        __block NSUInteger albumId = anAlbum.albumId.integerValue;
        NSString *path = [NSString stringWithFormat:@"albums/%d/", albumId];
        
        NSMutableURLRequest *theRequest = [[SVJSONAPIClient sharedClient] requestWithMethod:@"GET" path:path parameters:nil];
        NSString *etagString = anAlbum.etag;
        NSString *headerString = [NSString stringWithUTF8String:"If-None-Match"];
        if ([self initialSyncComplete] && etagString != nil) {
            [theRequest setValue:etagString forHTTPHeaderField:headerString];
        }
        
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:theRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            
            NSLog(@"Photos downloaded with: %@", request.allHTTPHeaderFields);
			NSLog(@"Photos %@", JSON);
            if ([JSON isKindOfClass:[NSDictionary class]] || [JSON isKindOfClass:[NSArray class]]) {
                [self writeJSONResponse:JSON toDiskForClassWithName:[NSString stringWithFormat:@"AlbumPhoto-%d", albumId]];
            }
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            
            if (response.statusCode == 304) {
                NSLog(@"-----------> This album has no updates.");
            }
            
        }];
        
        __weak AFJSONRequestOperation *weakOperation = operation;
        [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:^{
            
            if (weakOperation.isFinished) {
                NSLog(@"The photo json operation finished, cleanup and save the remaining operations so they can be resumed.");
                
            } else {
                NSLog(@"The operation did not finished, clean up and requeue this operation with the remaining operations so they can be resumed later.");
            }
            
        }];
        
        [operations addObject:operation];
    }
    
    [[SVJSONAPIClient sharedClient] enqueueBatchOfHTTPRequestOperations:operations progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
        
        //TODO: Post a progress notification for interested observers
        
    } completionBlock:^(NSArray *operations) {
        
        //TODO: check the cache directory and delete any AlbumPhoto records
        if (![[NSFileManager defaultManager] isEmptyDirectoryAtURL:[self JSONDataRecordsDirectory]]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                
                [self processPhotosJSON];
                
            });
        } else {
            [self executeSyncCompletedOperations];
        }
        
    }];
}


- (void)executeSyncCompletedOperations
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        [[SVDownloadQueueManager sharedManager] start];

        [self setInitialSyncCompleted];
        [self willChangeValueForKey:@"syncInProgress"];
        _syncInProgress = NO;
        [self didChangeValueForKey:@"syncInProgress"];
        
    });
}


- (BOOL)initialSyncComplete
{
    return [[[NSUserDefaults standardUserDefaults] valueForKey:kSVSyncEngineInitialSyncCompletedKey] boolValue];
}


- (void)saveAlbumsContext
{
    if (!saveQueue) {
        saveQueue = dispatch_queue_create("com.picsonair.shotvibe.savequeue", DISPATCH_QUEUE_CONCURRENT);
    }
    
    [self.syncAlbumsContext saveWithOptions:MRSaveParentContexts onQueue:saveQueue completion:^(BOOL success, NSError *error) {
        
        if (success) {
            [NSManagedObjectContext resetContextForCurrentThread];
            [NSManagedObjectContext resetDefaultContext];
            [self.syncAlbumsContext reset];
            self.syncAlbumsContext = nil;
            [self downloadPhotos];
        }
        else
        {
            if (error) {
                NSLog(@"%@", error);
            }
            [self executeSyncCompletedOperations];
        }
        
    }];
}


- (void)savePhotosContext
{
    if (!saveQueue) {
        saveQueue = dispatch_queue_create("com.picsonair.shotvibe.savequeue", DISPATCH_QUEUE_CONCURRENT);
    }
    
    [self.syncPhotosContext saveWithOptions:MRSaveParentContexts onQueue:saveQueue completion:^(BOOL success, NSError *error) {
        
        if (success) {
            [NSManagedObjectContext resetContextForCurrentThread];
            [NSManagedObjectContext resetDefaultContext];
            [self.syncPhotosContext reset];
            self.syncPhotosContext = nil;
            
            // Download images
            [self executeSyncCompletedOperations];
        }
        else
        {
            if (error) {
                NSLog(@"%@", error);
            }
            NSLog(@"Nothing to save.");
            [self executeSyncCompletedOperations];
        }
        
    }];
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
    
    if (!self.syncAlbumsContext) {
        self.syncAlbumsContext = [NSManagedObjectContext context];
        [self.syncAlbumsContext.userInfo setValue:@"AlbumSaveContext" forKey:@"kNSManagedObjectContextWorkingName"];
        self.syncAlbumsContext.undoManager = nil;
    }
    
    id albums = [self JSONDataForClassWithName:@"Album"];
	NSLog(@"albums %@", albums);
    
    if ([albums isKindOfClass:[NSArray class]])
    {
        for (NSDictionary *anAlbum in albums) {
            
            Album *newAlbum = [Album findFirstByAttribute:@"albumId" withValue:[anAlbum objectForKey:@"id"] inContext:self.syncAlbumsContext];
            
            if (!newAlbum) {
                
                newAlbum = [Album createInContext:self.syncAlbumsContext];
            } else if (newAlbum.objectSyncStatus.integerValue == SVObjectSyncUploadNeeded) {
                continue;
            }
            
            [newAlbum setValue:[NSNumber numberWithInt:SVObjectSyncDownloadNeeded] forKey:@"objectSyncStatus"];
            
            // Process the album
            [anAlbum enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                
                if ([key isEqualToString:@"id"]) {
                    [self setValue:[NSString stringWithFormat:@"%@", obj] forKey:key forManagedObject:newAlbum];
                }
                else
                {
                    [self setValue:obj forKey:key forManagedObject:newAlbum];
                }
            }];
            
            // Process recent Photos
            NSArray *recentPhotos = [anAlbum objectForKey:@"latest_photos"];
            for (NSDictionary *photo in recentPhotos) {
                
                AlbumPhoto *photoToSave = [AlbumPhoto findFirstByAttribute:@"photo_id" withValue:[photo objectForKey:@"photo_id"] inContext:self.syncAlbumsContext];
                
                if (!photoToSave) {
                    
                    photoToSave = [AlbumPhoto createInContext:self.syncAlbumsContext];
                    
                }
                
                [photoToSave setValue:[NSNumber numberWithInt:SVObjectSyncDownloadNeeded] forKey:@"objectSyncStatus"];
                
                [photo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    [self setValue:obj forKey:key forManagedObject:photoToSave];
                }];
                [newAlbum addAlbumPhotosObject:photoToSave];
                
                Member *authorToSave = [Member findFirstByAttribute:@"userId" withValue:[[photo objectForKey:@"author"] objectForKey:@"id"] inContext:self.syncAlbumsContext];
                if (!authorToSave) {
                    
                    authorToSave = [Member createInContext:self.syncAlbumsContext];
                    
                }
                
                [authorToSave setValue:[NSNumber numberWithInt:SVObjectSyncDownloadNeeded] forKey:@"objectSyncStatus"];
                [[photo objectForKey:@"author"] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    [self setValue:obj forKey:key forManagedObject:authorToSave];
                }];
                [photoToSave setValue:authorToSave forKey:@"author"];
                [newAlbum addMembersObject:authorToSave];
                
            }
            
            if (!self.albumsWithUpdates) {
                self.albumsWithUpdates = [[NSMutableArray alloc] initWithCapacity:[albums count]];
            }
            [self.albumsWithUpdates addObject:newAlbum.albumId];
            
        }
        
        [self deleteJSONDataRecordsForClassWithName:@"Album"];
    }
    [self saveAlbumsContext];
}


- (void)processPhotosJSON
{
    NSLog(@"PROCESSING PHOTOS JSON");
    
    for (NSNumber *anAlbumId in self.albumsWithUpdates) {
        
        Album *localAlbum = [Album findFirstByAttribute:@"albumId" withValue:anAlbumId inContext:self.syncPhotosContext];
        NSUInteger albumId = localAlbum.albumId.integerValue;
        NSDictionary *data = [self JSONDataForClassWithName:[NSString stringWithFormat:@"AlbumPhoto-%d", albumId]];
        
        if (data) {
            // Process each member object
            NSArray *members = [data objectForKey:@"members"];
            for (NSDictionary *member in members) {
                
                Member *outerMember = [Member findFirstByAttribute:@"userId" withValue:[member objectForKey:@"id"] inContext:self.syncPhotosContext];
                
                Member *memberToSave = nil;
                if (outerMember) {
                    memberToSave = outerMember;
                }
                else
                {
                    memberToSave = [Member createInContext:self.syncPhotosContext];
                }
                
                [member enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    [self setValue:obj forKey:key forManagedObject:memberToSave];
                }];
                [memberToSave setValue:[NSNumber numberWithInt:SVObjectSyncDownloadNeeded] forKey:@"objectSyncStatus"];
                [localAlbum addMembersObject:memberToSave];
                
            }
            
            // Process each photo object
            NSArray *photosArray = [data objectForKey:@"photos"];
            for (NSDictionary *photo in photosArray) {
                
                AlbumPhoto *outerPhoto = [AlbumPhoto findFirstByAttribute:@"photo_id" withValue:[photo objectForKey:@"photo_id"] inContext:self.syncPhotosContext];
                
                AlbumPhoto *photoToSave = nil;
                if (outerPhoto) {
                    photoToSave = outerPhoto;
                } else {
                    photoToSave = [AlbumPhoto createInContext:self.syncPhotosContext];
                    photoToSave.hasViewed = [NSNumber numberWithBool:NO];
                }
                
                [photo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    [self setValue:obj forKey:key forManagedObject:photoToSave];
                }];
                NSURL *imageURL = [NSURL URLWithString:[photo objectForKey:@"photo_id"] relativeToURL:[self imageDataDirectory]];
                [photoToSave setValue:[imageURL absoluteString] forKey:@"local_url"];
                [photoToSave setValue:[NSNumber numberWithInt:SVObjectSyncDownloadNeeded] forKey:@"objectSyncStatus"];
                
                Member *localAuthor = [Member findFirstByAttribute:@"userId" withValue:[[photo objectForKey:@"author"] objectForKey:@"id"] inContext:self.syncPhotosContext];
                
                [localAlbum addAlbumPhotosObject:photoToSave];
                
                if (localAuthor) {
                    [photoToSave setValue:localAuthor forKey:@"author"];
                }
                
            }
            
            [self deleteJSONDataRecordsForClassWithName:[NSString stringWithFormat:@"AlbumPhoto-%d", albumId]];
        }
        
    }
    
    [self savePhotosContext];
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
        else
        {
            [managedObject setValue:value forKey:key];
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


- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


- (NSURL *)imageDataDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSURL *url = [NSURL URLWithString:@"SVImages/" relativeToURL:[self applicationDocumentsDirectory]];
    NSURL *fileURL = [NSURL fileURLWithPath:[url path] isDirectory:YES];
    
    NSError *error = nil;
    if (![fileManager fileExistsAtPath:[fileURL path]]) {
        [fileManager createDirectoryAtPath:[fileURL path] withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    NSError *attributeError = nil;
    BOOL success = [fileURL setResourceValue: [NSNumber numberWithBool: YES] forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
        NSLog(@"Error excluding %@ from backup %@", [fileURL lastPathComponent], attributeError);
    }
    
    return fileURL;
}


#pragma mark - Memory Management

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
