//
//  UploadSyncEngine.m
//  shotvibe
//
//  Created by Peter Kasson on 6/22/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVUploaderOperationQueue.h"
#import "UploadSyncEngine.h"

@interface UploadSyncEngine ()

@property (nonatomic, strong) SVUploaderOperationQueue *operationQueue;
@property (nonatomic, assign) BOOL syncInProgress;
@property (nonatomic, assign) BOOL queueIsProcessing;

- (void)processQueue;
@end

@implementation UploadSyncEngine


#pragma mark - Class Methods

+ (UploadSyncEngine *)sharedEngine
{
    static UploadSyncEngine *sharedEngine = nil;
    static dispatch_once_t engineToken;
    dispatch_once(&engineToken, ^{
        sharedEngine = [[UploadSyncEngine alloc] init];
    });
    
    return sharedEngine;
}


#pragma mark - Instance Methods

/*
 * sync - upload albums and photos that need to be uploaded
 */
- (void)startSync
{
    NSLog(@"start sync");
    
    if (!self.syncInProgress)
    {
        if (self.operationQueue != nil) {
            [self willChangeValueForKey:@"syncInProgress"];
            _syncInProgress = YES;
            [self didChangeValueForKey:@"syncInProgress"];
            
            [self.operationQueue addObserver:self forKeyPath:@"operations" options:NSKeyValueObservingOptionNew context:nil];
        }
    }
}


#pragma mark - Private Methods

- (SVUploaderOperationQueue *)operationQueue
{
    NSManagedObjectContext *localContext = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"SVUploaderOperationQueue"];
    
    NSError *fetchError = nil;
    
    _operationQueue = [[localContext executeFetchRequest:fetchRequest error:&fetchError] lastObject];
    
    if (_operationQueue == nil) {
        
        _operationQueue = [localContext insertNewObjectForEntityForName:@"SVUploaderOperationQueue"];
        
        NSError *saveError = nil;
        if (![localContext saveToPersistentStore:&saveError]) {
            NSLog(@"Failed to save to the persistent store: %@", [saveError userInfo]);
        }
        
    }
    
    return _operationQueue;
}


- (void)processQueue
{
    if (!self.queueIsProcessing)
    {
        [self willChangeValueForKey:@"queueIsProcessing"];
        _queueIsProcessing = YES;
        [self didChangeValueForKey:@"queueIsProcessing"];
        
        //TODO: Start processing the each operation in the operationQueue
    }
}


#pragma mark - Key Value Observing

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == self.operationQueue && [keyPath isEqualToString:@"operations"]) {
        if (self.operationQueue.operations.count > 0) {
            [self processQueue];
        } else {
            [self willChangeValueForKey:@"queueIsProcessing"];
            _queueIsProcessing = NO;
            [self didChangeValueForKey:@"queueIsProcessing"];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
@end
