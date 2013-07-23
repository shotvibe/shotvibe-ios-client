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
#import "SVUploadQueueManager.h"

@interface SVDownloadQueueManager ()
{
    dispatch_queue_t saveQueue;
}

@property (nonatomic, strong) NSManagedObjectContext *syncContext;
@property (atomic, readonly) BOOL syncInProgress;

- (void)prepareQueue;
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
        [sharedManager.operationQueue addObserver:sharedManager forKeyPath:@"operations" options:0 context:NULL];
    });
    
    return sharedManager;
}


#pragma mark - Instance Methods

- (void)start
{
    if (![[SVUploadQueueManager sharedManager] syncInProgress]) {
        self.operationQueue.maxConcurrentOperationCount = 1;
        
        [self prepareQueue];
    } else {
        NSLog(@"The upload queue manager is busy, please wait!");
    }
}


- (void)stop
{
    self.operationQueue.maxConcurrentOperationCount = 0;
    [self.operationQueue cancelAllOperations];
}


- (void)pause
{
    self.operationQueue.maxConcurrentOperationCount = 0;
}


#pragma mark - Private Methods

- (void)prepareQueue
{
    NSLog(@"PREPARING QUEUE");
    
    if (!self.syncContext) {
        self.syncContext = [NSManagedObjectContext context];
        [self.syncContext.userInfo setValue:@"DownloadSaveContext" forKey:@"kNSManagedObjectContextWorkingName"];
        self.syncContext.undoManager = nil;
    }
    
    
    [self processQueue];
}


- (void)processQueue;
{
    NSLog(@"PROCESSING QUEUE");
    
    NSArray *photosToDownload = [AlbumPhoto findAllWithPredicate:[NSPredicate predicateWithFormat:@"objectSyncStatus == %i", SVObjectSyncDownloadNeeded] inContext:self.syncContext];
    
    if (photosToDownload.count > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        });
    } else {
        [self saveSyncContext];
    }
    
    for (AlbumPhoto *aPhoto in photosToDownload) {
        [self.operationQueue addOperationWithBlock:^{
            [[SVEntityStore sharedStore] getImageForPhoto:aPhoto WithCompletion:^(UIImage *image) {
                //no u
                
                AlbumPhoto *localPhoto = (AlbumPhoto *)[self.syncContext objectWithID:aPhoto.objectID];
                [localPhoto setObjectSyncStatus:[NSNumber numberWithInteger:SVObjectSyncCompleted]];
                
                localPhoto.album.objectSyncStatus = [NSNumber numberWithInteger:SVObjectSyncCompleted];
            }];
        }];
    }
}


- (void)saveSyncContext
{
    if (!saveQueue) {
        saveQueue = dispatch_queue_create("com.picsonair.shotvibe.downloadqueue", DISPATCH_QUEUE_CONCURRENT);
    }
    
    [self.syncContext saveWithOptions:MRSaveParentContexts onQueue:saveQueue completion:^(BOOL success, NSError *error) {
        
        if (success) {
            NSLog(@"All photos have downloaded successfully.");
        }
        else
        {
            if (error) {
                NSLog(@"%@", error);
            }
            NSLog(@"There is nothing to save at this time.");
        }
        
        [[SVUploadQueueManager sharedManager] start];
        [[NSNotificationCenter defaultCenter] postNotificationName:kSVSyncEngineSyncCompletedNotification object:nil];
        
    }];
}


#pragma mark - Key Value Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.operationQueue && [keyPath isEqualToString:@"operations"]) {
        if ([self.operationQueue.operations count] == 0) {
            NSLog(@"queue has completed");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            });
            
            [self saveSyncContext];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object
                               change:change context:context];
    }
}
@end
