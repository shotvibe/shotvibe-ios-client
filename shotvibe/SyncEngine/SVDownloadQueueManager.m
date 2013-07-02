//
//  SVDownloadAPIClient.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 7/1/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AFHTTPRequestOperation.h"
#import "Album.h"
#import "AlbumPhoto.h"
#import "SVDefines.h"
#import "SVDownloadOperation.h"
#import "SVDownloadQueueManager.h"
#import "SVEntityStore.h"

#ifdef CONFIGURATION_Debug
static NSString * const kTestAuthToken = @"Token 8d437481bdf626a9e9cd6fa2236d113eb1c9786d";
#elif CONFIGURATION_Adhoc
static NSString * const kTestAuthToken = @"Token 1d591bfa90ed6aee747a5009ccf6ef27246f6ae6";
#endif

@interface SVDownloadQueueManager ()
{
    dispatch_queue_t saveQueue;
}

@property (nonatomic, strong) NSManagedObjectContext *syncContext;

@property (nonatomic, strong) NSTimer *queueTimer;

@property (atomic, readonly) BOOL syncInProgress;

- (void)prepareQueue:(NSTimer *)timer;
- (void)processQueue;

- (void)saveSyncContext;
@end

@implementation SVDownloadQueueManager

#pragma mark - Initialization

- (id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if (self) {
        [self registerHTTPOperationClass:[AFHTTPRequestOperation class]];
    }
    
    return self;
}


#pragma mark - Class Methods

+ (SVDownloadQueueManager *)sharedManager
{
    static SVDownloadQueueManager *sharedManager = nil;
    static dispatch_once_t downloadQueueManagerToken;
    dispatch_once(&downloadQueueManagerToken, ^{
        sharedManager = [[SVDownloadQueueManager alloc] initWithBaseURL:[NSURL URLWithString:kAPIBaseURLString]];
    });
    
    return sharedManager;
}


#pragma mark - Instance Methods

- (void)start
{   
    self.operationQueue.maxConcurrentOperationCount = 1;
    
    // Create a timer to process the queue
    if (!self.queueTimer) {
        self.queueTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(prepareQueue:) userInfo:nil repeats:YES];
        
        [[NSRunLoop mainRunLoop] addTimer:self.queueTimer forMode:NSDefaultRunLoopMode];
        [self.queueTimer fire];
    }
}


- (void)stop
{
    
}


- (void)pause
{
    self.operationQueue.maxConcurrentOperationCount = 0;
    
    // Kill the timer
    [self.queueTimer invalidate];
    self.queueTimer = nil;
}


#pragma mark - Private Methods

- (void)prepareQueue:(NSTimer *)timer
{
    NSLog(@"PREPARING QUEUE");
    
    if (!self.syncInProgress) {
        [self willChangeValueForKey:@"syncInProgress"];
        _syncInProgress = YES;
        [self didChangeValueForKey:@"syncInProgress"];
        
        if (!self.syncContext) {
            self.syncContext = [NSManagedObjectContext context];
            [self.syncContext.userInfo setValue:@"DownloadSaveContext" forKey:@"kNSManagedObjectContextWorkingName"];
            self.syncContext.undoManager = nil;
        }
        
        // Get all Albums who are marked with needing sync
        /*NSArray *albumsToSync = [Album findByAttribute:@"objectSyncStatus" withValue:[NSNumber numberWithInteger:SVObjectSyncDownloadNeeded] inContext:self.syncContext];
        NSMutableArray *photosToSync = [NSMutableArray array];
        
        // For each album needing sync, get it's photos marked as needing sync
        for (Album *album in albumsToSync) {
            
            NSArray *photos = [album.albumPhotos allObjects];
            for (AlbumPhoto *photo in photos) {
                if ([photo.objectSyncStatus integerValue] == SVObjectSyncDownloadNeeded) {
                    [photosToSync addObject:photo];
                }
            }
            
        }
        
        // For each photo needing sync, create an SVDownloaderOperation entity
        for (AlbumPhoto *photo in photosToSync) {
            
            // First check to see if there is already an operation in the queue for this photo.
            SVDownloadOperation *existingOperation = [SVDownloadOperation findFirstWithPredicate:[NSPredicate predicateWithFormat:@"albumId = %@ AND photoId = %@", photo.album.albumId, photo.photo_id] inContext:self.syncContext];
            if (!existingOperation) {
                
                [MagicalRecord saveUsingCurrentThreadContextWithBlock:^(NSManagedObjectContext *localContext) {
                    
                    SVDownloadOperation *localOperation = [SVDownloadOperation createInContext:localContext];
                    localOperation.albumId = photo.album.albumId;
                    localOperation.photoId = photo.photo_id;
                    
                } completion:^(BOOL success, NSError *error) {
                    
                    NSLog(@"We should have an operation saved.");
                    
                }];
                
            }
            
        }*/
        
        [self processQueue];
    }
}


- (void)processQueue;
{
    NSLog(@"PROCESSING QUEUE");
    
    NSArray *photosToDownload = [AlbumPhoto findAllWithPredicate:[NSPredicate predicateWithFormat:@"objectSyncStatus == %i", SVObjectSyncDownloadNeeded]];
    
    NSLog(@"WE HAZ %i PHOTOZ TO DOWNLOAD", photosToDownload.count);
    
    for (AlbumPhoto *aPhoto in photosToDownload) {
        [self.operationQueue addOperationWithBlock:^{
            [[SVEntityStore sharedStore] getImageForPhoto:aPhoto WithCompletion:^(UIImage *image) {
                //no u
            }];
        }];
    }
    
    // For each SVDownloaderOperation entity create an AFHTTPRequestOperation and add it to the operation queue
    /*NSArray *downloadOperations = [SVDownloadOperation findAll];
    //NSMutableArray *operations = [NSMutableArray arrayWithCapacity:downloadOperations.count];
    for (SVDownloadOperation *downloadOperation in downloadOperations) {
        
        // Get the photo
        __block AlbumPhoto *photo = [AlbumPhoto findFirstByAttribute:@"photo_id" withValue:downloadOperation.photoId inContext:self.syncContext];
        __block Album *album = photo.album;
        
        [[SVEntityStore sharedStore] getImageForPhotoData:photo WithCompletion:^(NSData *imageData, BOOL success) {
            
            if (success) {
                
                [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                   
                    SVDownloadOperation *localDownloadOperation = (SVDownloadOperation *)[localContext objectWithID:downloadOperation.objectID];
                    [localDownloadOperation deleteInContext:localContext];
                    AlbumPhoto *localPhoto = (AlbumPhoto *)[localContext objectWithID:photo.objectID];
                    localPhoto.objectSyncStatus = [NSNumber numberWithInteger:SVObjectSyncCompleted];
                    Album *localAlbum = (Album *)[localContext objectWithID:album.objectID];
                    localAlbum.objectSyncStatus = [NSNumber numberWithInteger:SVObjectSyncCompleted];
                    
                }];
                
            }
            
        }];*/
        
        /*// Get the album
        Album *album = photo.album;
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:photo.photo_url] cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:20];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
        [operation setCacheResponseBlock:^NSCachedURLResponse *(NSURLConnection *connection, NSCachedURLResponse *cachedResponse) {
           
            return nil;
            
        }];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSLog(@"We got an image back, now we need to write it to disk!");
            @autoreleasepool {
                [[SVEntityStore sharedStore] writeImageData:responseObject toDiskForImageID:photo.photo_id WithCompletion:^(BOOL success, NSURL *fileURL, NSError *error) {
                    
                    if (success) {
                        NSLog(@"We successfully saved the image");
                        [MagicalRecord saveUsingCurrentThreadContextWithBlock:^(NSManagedObjectContext *localContext) {
                            
                            Album *localAlbum = (Album *)[localContext objectWithID:album.objectID];
                            AlbumPhoto *localPhoto = (AlbumPhoto *)[localContext objectWithID:photo.objectID];
                            
                            localAlbum.objectSyncStatus = [NSNumber numberWithInteger:SVObjectSyncCompleted];
                            localPhoto.objectSyncStatus = [NSNumber numberWithInteger:SVObjectSyncCompleted];
                            
                            [downloadOperation deleteInContext:localContext];
                            
                        } completion:^(BOOL success, NSError *error) {
                            
                            if (success) {
                                NSLog(@"We successfully deleted the download operation.");
                            } else {
                                NSLog(@"There was an error deleting the download operation: %@", error);
                            }
                            
                        }];
                    } else {
                        if (error) {
                            NSLog(@"There was an error saving the image: %@", error);
                        }
                    }
                    
                }];
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            NSLog(@"Request for the image failed: %@", error);
            
        }];
        
        __weak AFHTTPRequestOperation *weakOperation = operation;
        [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:^{
            
            if (weakOperation.isFinished) {
                NSLog(@"The image download operation is finished, cleanup.");
                [self.operationQueue cancelAllOperations];
            } else {
                NSLog(@"The operation did not finish.");
            }
            
        }];
        [operation start];
        //[self.operationQueue addOperation:operation];
        
        //[operations addObject:operation];
        
    }*/
    
    [self willChangeValueForKey:@"syncInProgress"];
    _syncInProgress = NO;
    [self didChangeValueForKey:@"syncInProgress"];
    
    /*if (!saveQueue) {
        saveQueue = dispatch_queue_create("com.picsonair.shotvibe.downloadqueue", DISPATCH_QUEUE_CONCURRENT);
    }
    dispatch_async(saveQueue, ^{
        
        [self enqueueBatchOfHTTPRequestOperations:operations progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
            
            
        } completionBlock:^(NSArray *operations) {
            
            [self willChangeValueForKey:@"syncInProgress"];
            _syncInProgress = NO;
            [self didChangeValueForKey:@"syncInProgress"];
            
        }];
        
    });*/
}


- (void)saveSyncContext
{
    if (!saveQueue) {
        saveQueue = dispatch_queue_create("com.picsonair.shotvibe.downloadqueue", DISPATCH_QUEUE_CONCURRENT);
    }
    
    [self.syncContext saveWithOptions:MRSaveParentContexts onQueue:saveQueue completion:^(BOOL success, NSError *error) {
        
        if (success) {
            NSLog(@"Wheeeeeeee ahaHAH, we've saved ALBUMS successfully");
            [NSManagedObjectContext resetContextForCurrentThread];
            [NSManagedObjectContext resetDefaultContext];
            [self.syncContext reset];
            self.syncContext = nil;
        }
        else
        {
            if (error) {
                NSLog(@"%@", error);
            }
            NSLog(@"We no can haz save right now");
        }
        
    }];
}
@end
