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

#ifdef CONFIGURATION_Debug
static NSString * const kTestAuthToken = @"Token 8d437481bdf626a9e9cd6fa2236d113eb1c9786d";
#elif CONFIGURATION_Adhoc
static NSString * const kTestAuthToken = @"Token 1d591bfa90ed6aee747a5009ccf6ef27246f6ae6";
#endif

@interface SVDownloadQueueManager ()

@property (nonatomic, strong) NSTimer *queueTimer;

- (void)prepareQueue:(NSTimer *)timer;
- (void)processQueue;
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
    self.operationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    
    // Create a timer to process the queue
    if (!self.queueTimer) {
        self.queueTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(prepareQueue:) userInfo:nil repeats:YES];
        
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
    
    // Get all Albums who are marked with needing sync
    NSArray *albumsToSync = [Album findByAttribute:@"objectSyncStatus" withValue:[NSNumber numberWithInteger:SVObjectSyncDownloadNeeded]];
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
        SVDownloadOperation *existingOperation = [SVDownloadOperation findFirstWithPredicate:[NSPredicate predicateWithFormat:@"albumId = %@ AND photoId = %@", photo.album.albumId, photo.photo_id]];
        if (!existingOperation) {
            
            [MagicalRecord saveUsingCurrentThreadContextWithBlock:^(NSManagedObjectContext *localContext) {
                
                SVDownloadOperation *localOperation = [SVDownloadOperation createInContext:localContext];
                localOperation.albumId = photo.album.albumId;
                localOperation.photoId = photo.photo_id;
                
            } completion:^(BOOL success, NSError *error) {
               
                NSLog(@"We should have an operation saved.");
                
            }];
            
        }
        
    }
    
    [self processQueue];    
}


- (void)processQueue;
{
    NSLog(@"PROCESSING QUEUE");
    
    // For each SVDownloaderOperation entity create an AFHTTPRequestOperation and add it to the operation queue
    NSArray *downloadOperations = [SVDownloadOperation findAll];
    for (SVDownloadOperation *downloadOperation in downloadOperations) {
        
        // Get the photo
        AlbumPhoto *photo = [AlbumPhoto findFirstByAttribute:@"photo_id" withValue:downloadOperation.photoId];
        
        // Get the album
        Album *album = photo.album;
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:photo.photo_url]];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSLog(@"We got an image back, now we need to write it to disk!");
            
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
        
        [self enqueueHTTPRequestOperation:operation];
        
    }
    
}
@end
