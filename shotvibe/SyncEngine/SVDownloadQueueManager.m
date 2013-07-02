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
        [sharedManager.operationQueue addObserver:sharedManager forKeyPath:@"operations" options:0 context:NULL];
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
        
        
        [self processQueue];
    }
}


- (void)processQueue;
{
    NSLog(@"PROCESSING QUEUE");
    
    NSArray *photosToDownload = [AlbumPhoto findAllWithPredicate:[NSPredicate predicateWithFormat:@"objectSyncStatus == %i", SVObjectSyncDownloadNeeded] inContext:self.syncContext];
    
    NSLog(@"WE HAZ %i PHOTOZ TO DOWNLOAD", photosToDownload.count);
    
    for (AlbumPhoto *aPhoto in photosToDownload) {
        [self.operationQueue addOperationWithBlock:^{
            [[SVEntityStore sharedStore] getImageForPhoto:aPhoto WithCompletion:^(UIImage *image) {
                //no u
                
                AlbumPhoto *localPhoto = (AlbumPhoto *)[self.syncContext objectWithID:aPhoto.objectID];
                [localPhoto setObjectSyncStatus:[NSNumber numberWithInteger:SVObjectSyncCompleted]];
            }];
        }];
    }
        
    [self willChangeValueForKey:@"syncInProgress"];
    _syncInProgress = NO;
    [self didChangeValueForKey:@"syncInProgress"];
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
            //self.syncContext = nil;
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


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.operationQueue && [keyPath isEqualToString:@"operations"]) {
        if ([self.operationQueue.operations count] == 0) {
            // Do something here when your queue has completed
            NSLog(@"queue has completed");
            [self saveSyncContext];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object
                               change:change context:context];
    }
}
@end
