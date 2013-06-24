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

#import "SVDefines.h"
#import "DownloadSyncEngine.h"
#import "SVEntityStore.h"
#import "SVBusinessDelegate.h"
#import "Album.h"
#import "AlbumPhoto.h"
#import "SVUploaderDelegate.h"

typedef enum {
    SVObjectSyncCompleted = 0,
    SVObjectSyncWaiting,
    SVObjectSyncActive,
    SVObjectSyncNeeded,
} SVObjectSyncStatus;

@interface DownloadSyncEngine ()

@property (atomic, readonly) BOOL syncInProgress;
@property (nonatomic, strong) NSOperationQueue *globalDownloadQueue;

- (void)syncAlbums;
- (NSArray *)getAlbums;
- (void)photosForAlbumWithID:(NSNumber *)albumId;
- (void)syncPhotos;
- (NSArray *)getPhotos;
- (void)executeSyncCompletedOperations;
- (void)photoWasSuccessfullySavedToDiskWithId:(NSNotification *)notification;

@end


@implementation DownloadSyncEngine

#pragma mark - Class Methods

+ (DownloadSyncEngine *)sharedEngine
{
    static DownloadSyncEngine *sharedEngine = nil;
    static dispatch_once_t engineToken;
    dispatch_once(&engineToken, ^{
        sharedEngine = [[DownloadSyncEngine alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:sharedEngine selector:@selector(syncAlbums) name:kUserAlbumsLoadedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:sharedEngine selector:@selector(photoWasSuccessfullySavedToDiskWithId:) name:kSDSyncEnginePhotoSavedToDiskNotification object:nil];
    });
    
    return sharedEngine;
}


#pragma mark - Instance Methods


/*
 * sync - retrieve albums and photos
 */
- (void)startSync
{
    NSLog(@"start sync");
    
    if (!self.syncInProgress)
    {
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


/*
 * sync albums with all/latest photos
 */
- (void)syncAlbums
{
    // TODO: We should only update albums that need to be updated rather than all the albums each time.
    NSArray *albums = [self getAlbums];
    
    // Register to observe the object manager's operation queue.
    [[RKObjectManager sharedManager].operationQueue addObserver:self forKeyPath:@"operations" options:0 context:NULL];
    
    for(Album *album in albums)           // call to get all photos for the given album
    {
        //[[SVEntityStore sharedStore] photosForAlbumWithID:album.albumId];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            
            [self photosForAlbumWithID:album.albumId];
            
        });
    }
}


- (NSArray *)getAlbums
{    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Album"];
    
    NSManagedObjectContext *managedObjectContext = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
    
    NSError *error = nil;
    NSArray *array = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (!error) {
        NSLog(@"%@", [error userInfo]);
    }
    
    return array;
}


- (void)photosForAlbumWithID:(NSNumber *)albumId
{
    // Setup Photo Mapping
    RKEntityMapping *photoMapping = [RKEntityMapping mappingForEntityForName:@"AlbumPhoto" inManagedObjectStore:[RKObjectManager sharedManager].managedObjectStore];
    [photoMapping addAttributeMappingsFromDictionary:@{
     @"photo_id": @"photoId",
     @"photo_url": @"photoUrl",
     @"date_created": @"dateCreated",
     }];
    photoMapping.identificationAttributes = @[@"photoId"];
    
    // Setup Member Mapping
    RKEntityMapping *memberMapping = [RKEntityMapping mappingForEntityForName:@"Member" inManagedObjectStore:[RKObjectManager sharedManager].managedObjectStore];
    [memberMapping addAttributeMappingsFromDictionary:@{
     @"id": @"userId",
     @"url": @"url",
     @"nickname": @"nickname",
     @"avatar_url": @"avatarUrl"
     }];
    memberMapping.identificationAttributes = @[@"userId"];
    
    // Setup Album Mapping
    RKEntityMapping *albumMapping = [RKEntityMapping mappingForEntityForName:@"Album" inManagedObjectStore:[RKObjectManager sharedManager].managedObjectStore];
    [albumMapping addAttributeMappingsFromDictionary:@{
     @"id": @"albumId",
     @"name": @"name",
     @"date_created": @"dateCreated",
     @"last_updated": @"lastUpdated"
     }];
    albumMapping.identificationAttributes = @[@"albumId"];
    
    // Relationship Connections
    [photoMapping addRelationshipMappingWithSourceKeyPath:@"author" mapping:memberMapping];
    [photoMapping addRelationshipMappingWithSourceKeyPath:@"album" mapping:albumMapping];
    [albumMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"photos" toKeyPath:@"albumPhotos" withMapping:photoMapping]];
    [memberMapping addRelationshipMappingWithSourceKeyPath:@"albums" mapping:albumMapping];
    [albumMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"members" toKeyPath:@"members" withMapping:memberMapping]];
    
    // Configure the response descriptor
    RKResponseDescriptor *albumResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:albumMapping pathPattern:@"/albums/:id/" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    [[RKObjectManager sharedManager] addResponseDescriptor:albumResponseDescriptor];
    
    // Get the albums
    NSString *path = [NSString stringWithFormat:@"/albums/%@/", [albumId stringValue]];
    [[RKObjectManager sharedManager] getObjectsAtPath:path parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        
        RKLogInfo(@"Load complete: Table should refresh with: %@", mappingResult.array);
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        
        RKLogError(@"Load failed with error: %@", error);
        
    }];
}


- (void)syncPhotos
{
    // Initialize the operation queue
    if (self.globalDownloadQueue == nil)
    {
        self.globalDownloadQueue = [[NSOperationQueue alloc] init];
        self.globalDownloadQueue.maxConcurrentOperationCount = 4;
        [self.globalDownloadQueue addObserver:self forKeyPath:@"operations" options:0 context:NULL];
    } else {
        [self.globalDownloadQueue cancelAllOperations];
    }
    
    NSManagedObjectContext *localContext = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
    
    NSArray *photos = [self getPhotos];
    
    if (photos.count > 0) {
        
        for(AlbumPhoto *photo in photos)
        {
            
            Album *localAlbum = photo.album;
            
            if (localAlbum != nil) {
                
                BOOL photoExists = [SVBusinessDelegate doesPhotoWithId:photo.photoId existForAlbumId:localAlbum.albumId];
                
                if(!photoExists)
                {
                    NSLog(@"photo DNE, downloading photo:  %@, %@", localAlbum.name, photo.photoId);
                    
                    [self.globalDownloadQueue addOperationWithBlock:^{
                        
                        AlbumPhoto *localPhoto = (AlbumPhoto *)[localContext objectWithID:photo.objectID];
                        Album *innerAlbum = (Album *)[localContext objectWithID:localAlbum.objectID];
                        
                        NSString *photoURL = nil;
                        
                        if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2){
                            if (IS_IPHONE_5) {
                                photoURL = [[photo.photoUrl stringByDeletingPathExtension] stringByAppendingString:kPhotoIphone5Extension];
                            }
                            else
                            {
                                photoURL = [[photo.photoUrl stringByDeletingPathExtension] stringByAppendingString:kPhotoIphone4Extension];
                            }
                        }
                        else
                        {
                            photoURL = [[photo.photoUrl stringByDeletingPathExtension] stringByAppendingString:kPhotoIphone3Extension];
                        }
                        
                        NSData * imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:photoURL]];
                        
                        if ( imageData != nil ) {
                            NSLog(@"photo downloaded:  %@", localPhoto.photoId);
                            
                            [SVBusinessDelegate saveImageData:imageData forPhoto:localPhoto inAlbumWithId:innerAlbum.albumId];
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [[NSNotificationCenter defaultCenter] postNotificationName:kSDSyncEngineSyncAlbumCompletedNotification object:innerAlbum];
                            });
                        }
                        
                    }];
                }
                
            }
        }
        
    } else {
        NSLog(@"The photos could not be retrieved fromt he persistent store.");
    }
}


- (NSArray *)getPhotos
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"AlbumPhoto"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectSyncStatus = %d", SVObjectSyncCompleted];
    fetchRequest.predicate = predicate;
    
    NSManagedObjectContext *managedObjectContext = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
    
    NSError *error = nil;
    NSArray *array = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (!error) {
        NSLog(@"%@", [error userInfo]);
    }
    
    return array;
}


- (void)executeSyncCompletedOperations
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.globalDownloadQueue removeObserver:self forKeyPath:@"operations"];
        [[RKObjectManager sharedManager].operationQueue removeObserver:self forKeyPath:@"operations"];
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:kSDSyncEngineSyncCompletedNotification object:nil];
        
        [self willChangeValueForKey:@"syncInProgress"];
        _syncInProgress = NO;
        [self didChangeValueForKey:@"syncInProgress"];
        
    });
}


- (void)photoWasSuccessfullySavedToDiskWithId:(NSNotification *)notification
{
    NSString *photoId = [notification object];
    
    NSManagedObjectContext *localContext = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"AlbumPhoto"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"photoId = %@", photoId];
    fetchRequest.predicate = predicate;
    
    NSError *fetchError = nil;
    
    AlbumPhoto *localPhoto = (AlbumPhoto *)[[localContext executeFetchRequest:fetchRequest error:&fetchError] lastObject];
    
    if (!fetchError && localPhoto != nil) {
        
        [localPhoto setImageWasDownloaded:[NSNumber numberWithBool:YES]];
        
        NSError *saveError = nil;
        [localContext saveToPersistentStore:&saveError];
        
    } else {
        NSLog(@"The image was not saved to disk");
    }
}


#pragma mark - Key Value Observing

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == self.globalDownloadQueue && [keyPath isEqualToString:@"operations"])
    {
        if (self.globalDownloadQueue.operationCount == 0) {
            [self executeSyncCompletedOperations];
        }
    }
    else if (object == [RKObjectManager sharedManager].operationQueue && [keyPath isEqualToString:@"operations"])
    {
        if ([RKObjectManager sharedManager].operationQueue.operationCount == 0) {
            [self syncPhotos];
        }
    }
    else
    {
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
