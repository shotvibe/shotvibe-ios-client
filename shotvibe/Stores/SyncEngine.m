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
#import "SyncEngine.h"
#import "SVEntityStore.h"
#import "SVBusinessDelegate.h"
#import "Album.h"
#import "AlbumPhoto.h"
#import "SVUploaderDelegate.h"

@interface SyncEngine ()

@property (atomic, readonly) BOOL syncInProgress;

@property (nonatomic, strong) NSOperationQueue *globalDownloadQueue;
@property (nonatomic, strong) NSMutableArray *project;
@property (nonatomic, strong) NSMutableArray *uploadQueue;
@property (nonatomic, strong) NSMutableDictionary *globalUploadQueue;


- (void)syncAlbums;
- (void)syncPhotos:(NSNotification *)notification;
- (NSArray *)getAlbums;
- (void)executeSyncCompletedOperations;
- (void)photoWasSuccessfullySavedToDiskWithId:(NSNotification *)notification;

@end


@implementation SyncEngine

#pragma mark - Class Methods

+ (SyncEngine *)sharedEngine
{
    static SyncEngine *sharedEngine = nil;
    static dispatch_once_t engineToken;
    dispatch_once(&engineToken, ^{
        sharedEngine = [[SyncEngine alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:sharedEngine selector:@selector(syncAlbums) name:kUserAlbumsLoadedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:sharedEngine selector:@selector(syncPhotos:) name:kPhotosLoadedNotification object:nil];
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
        
        // Initialize the operation queue
        if (self.globalDownloadQueue == nil)
        {
            self.globalDownloadQueue = [[NSOperationQueue alloc] init];
            self.globalDownloadQueue.maxConcurrentOperationCount = 4;
            [self.globalDownloadQueue addObserver:self forKeyPath:@"operations" options:0 context:NULL];
        } else {
            [self.globalDownloadQueue cancelAllOperations];
        }
        
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
    //
    // 20130619 - download all photos (thumbnails) for an album.  this provides the user with a better UX as the photos
    //            will be on the device after the initial launch, and any updates.  the initial load will take time depending
    //            on the number of photos
    //
    
    
    // 20130621 - changed to using NSOperationQueue - allows pausing of all worker threads more easily as well as stopping them
    //            if a memory issue occurs
    
    // TODO: We should only update albums that need to be updated rather than all the albums each time.
    NSArray *albums = [self getAlbums];
    
    for(Album *album in albums)           // call to get all photos for the given album
    {
        NSLog(@"album:  %@", album.name);
        
        [[SVEntityStore sharedStore] photosForAlbumWithID:album.albumId];
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


- (void)syncPhotos:(NSNotification *)notification
{
    NSNumber *albumId = notification.object;
    
    NSManagedObjectContext *localContext = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Album"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"albumId = %d", albumId.integerValue];
    fetchRequest.predicate = predicate;
    
    NSError *fetchError = nil;
    
    Album *localAlbum = (Album *)[[localContext executeFetchRequest:fetchRequest error:&fetchError] lastObject];
    
    if (!fetchError && localAlbum != nil) {
        
        for(AlbumPhoto *photo in localAlbum.albumPhotos)
        {
            // NOTE: If the photo does not exist, then will not require uploading
            BOOL photoExists = [SVBusinessDelegate doesPhotoWithId:photo.photoId existForAlbumId:localAlbum.albumId];
            
            if(!photoExists)
            {
                NSLog(@"photo DNE, downloading photo:  %@, %@", localAlbum.name, photo.photoId);
                
                [self.globalDownloadQueue addOperationWithBlock:^{
                    
                    AlbumPhoto *localPhoto = (AlbumPhoto *)[localContext objectWithID:photo.objectID];
                    Album *innerAlbum = (Album *)[localContext objectWithID:localAlbum.objectID];
                    
                    NSData * imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:localPhoto.photoUrl]];
                    
                    if ( imageData != nil ) {
                        NSLog(@"photo downloaded:  %@", localPhoto.photoId);
                        
                        [SVBusinessDelegate saveImageData:imageData forPhoto:localPhoto inAlbumWithId:innerAlbum.albumId];
                        
                        // This album has finished syncing
                        [[NSNotificationCenter defaultCenter] postNotificationName:kSDSyncEngineSyncAlbumCompletedNotification object:innerAlbum];
                    }
                    
                }];
            } else {
                
                if ([photo.objectSyncStatus integerValue] == SVObjectSyncNeeded) {
                    
                    //[SVUploaderDelegate addPhoto:photo.photoId withAlbumId:album.albumId];
                    
                    //TODO: This photo already exists in the file system, AND it is marked as needing to be synced.
                    
                    //TODO: First, check to make sure that the album this photo belongs to is already in the queue,
                    // If so, you need to add this photo to the appropriate batch
                    
                    //TODO: If the album this photo belongs to is not already in the queue, you need to create a new
                    // batch queue, add the photo to the batch, and add this batch queue to the master queue.
                    
                    //NOTE: Remember, this master upload queue needs to save it's state such that it resumes where
                    // it left off when the application is quit and then resumed.
                    
                    //NOTE: The upload batches will also need to correctly set the photo.objectSyncStatus property
                    // to the appropriate status as each upload is completed.
                    
                }
                
            }
        }
        
    } else {
        NSLog(@"The album could not be retrieved fromt he persistent store.");
    }
}


- (void)executeSyncCompletedOperations
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self willChangeValueForKey:@"syncInProgress"];
        _syncInProgress = NO;
        [self didChangeValueForKey:@"syncInProgress"];
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kSDSyncEngineSyncCompletedNotification object:nil];
        
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    if (object == self.globalDownloadQueue && [keyPath isEqualToString:@"operations"]) {
        if (self.globalDownloadQueue.operationCount == 0) {
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
