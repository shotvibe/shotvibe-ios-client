//
//  SVUploadQueueManager.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 7/6/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AFHTTPRequestOperation.h"
#import "AFJSONRequestOperation.h"
#import "Album.h"
#import "AlbumPhoto.h"
#import "SVDefines.h"
#import "SVEntityStore.h"
#import "SVUploadQueueManager.h"

static NSString * const kShotVibeAPIBaseURLString = @"https://api.shotvibe.com";

#ifdef CONFIGURATION_Debug
static NSString * const kTestAuthToken = @"Token 8d437481bdf626a9e9cd6fa2236d113eb1c9786d";
static NSUInteger const kTestUserId = 1;
#elif CONFIGURATION_Adhoc
static NSString * const kTestAuthToken = @"Token 1d591bfa90ed6aee747a5009ccf6ef27246f6ae6";
static NSUInteger const kTestUserId = 1;
#endif

@interface SVUploadQueueManager ()

@property (nonatomic, strong) NSURL *imageDataDirectory;
@property (nonatomic, strong) NSMutableArray *albumsToUpload;

- (void)prepareQueue;
- (void)processQueue;
- (void)executeSyncCompleteOperations;

- (void)getConcretePhotoIdsForPhotos:(NSArray *)photos forAlbum:(Album *)anAlbum;
- (void)uploadPhotos:(NSArray *)photosToUpload withConcreteIds:(NSArray *)concretePhotoIds forAlbum:(Album *)anAlbum;
- (void)addConcretePhotoIds:(NSArray *)concretePhotoIds ToExistingAlbum:(Album *)anAlbum;
- (void)addConcretePhotoIds:(NSArray *)concretePhotoIds ToNewAlbum:(Album *)anAlbum;

- (void)renameImageForPhoto:(AlbumPhoto *)aPhoto UsingID:(NSString *)imageId;
- (NSURL *)applicationDocumentsDirectory;
@end

@implementation SVUploadQueueManager

#pragma mark - Getters

- (NSURL *)imageDataDirectory
{
    if (!_imageDataDirectory) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        _imageDataDirectory = [NSURL URLWithString:@"SVImages/" relativeToURL:[self applicationDocumentsDirectory]];
        
        NSError *error = nil;
        if (![fileManager fileExistsAtPath:[_imageDataDirectory path]]) {
            [fileManager createDirectoryAtPath:[_imageDataDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        
        NSError *attributeError = nil;
        BOOL success = [_imageDataDirectory setResourceValue: [NSNumber numberWithBool: YES] forKey: NSURLIsExcludedFromBackupKey error: &error];
        if(!success){
            NSLog(@"Error excluding %@ from backup %@", [_imageDataDirectory lastPathComponent], attributeError);
        }
    }
    
    return _imageDataDirectory;
}


#pragma mark - Initialization

- (id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if (self) {
        [self registerHTTPOperationClass:[AFHTTPRequestOperation class]];
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [self setParameterEncoding:AFJSONParameterEncoding];
        [self setDefaultHeader:@"Authorization" value:[[NSUserDefaults standardUserDefaults] objectForKey:kApplicationUserAuthToken]];
    }
    
    return self;
}


#pragma mark - Class Methods

+ (SVUploadQueueManager *)sharedManager
{
    static SVUploadQueueManager *sharedManager = nil;
    static dispatch_once_t uploadQueueManagerToken;
    dispatch_once(&uploadQueueManagerToken, ^{
        sharedManager = [[SVUploadQueueManager alloc] initWithBaseURL:[NSURL URLWithString:kAPIBaseURLString]];
        [sharedManager.operationQueue addObserver:sharedManager forKeyPath:@"operations" options:NSKeyValueObservingOptionNew context:nil];
    });
    
    return sharedManager;
}


#pragma mark - Instance Methods

- (void)start
{
    if (!self.syncInProgress) {
        self.operationQueue.maxConcurrentOperationCount = 1;
        
        [self prepareQueue];
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

- (void)executeSyncCompleteOperations
{
    if (self.albumsToUpload.count < 1) {
        NSLog(@"UPLOAD SYNC COMPLETE");
        
        [self willChangeValueForKey:@"syncInProgress"];
        _syncInProgress = NO;
        [self didChangeValueForKey:@"syncInProgress"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        });
    } else {
        NSLog(@"UPLOAD SYNC IS NOT COMPLETE, PLEASE WAIT.");
    }
}


- (void)prepareQueue
{
    NSLog(@"PREPARING UPLOAD QUEUE");
    
    // Get all of the albums that need to be uploaded
    self.albumsToUpload = [NSMutableArray arrayWithArray:[Album findAllWithPredicate:[NSPredicate predicateWithFormat:@"objectSyncStatus == %i AND SUBQUERY(albumPhotos, $albumPhoto, $albumPhoto.objectSyncStatus == %i).@count > 0", SVObjectSyncUploadNeeded, SVObjectSyncUploadNeeded] inContext:[NSManagedObjectContext defaultContext]]];
    
    if (self.albumsToUpload.count > 0) {
        [self willChangeValueForKey:@"syncInProgress"];
        _syncInProgress = YES;
        [self didChangeValueForKey:@"syncInProgress"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        });
        [self processQueue];
    } else {
        [self executeSyncCompleteOperations];
    }
}


- (void)processQueue
{
    NSLog(@"PROCESSING UPLOAD QUEUE");
    
    for (Album *album in self.albumsToUpload) {
        
        // For each album get all the photos in the album that need to be uploaded
        NSArray *photosToUpload = [[album.albumPhotos filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.objectSyncStatus == %i", SVObjectSyncUploadNeeded]] allObjects];
        NSLog(@"We need to upload %d photos.", photosToUpload.count);
        
        if (photosToUpload.count > 0) {
            
            [self getConcretePhotoIdsForPhotos:photosToUpload forAlbum:album];
            
        }
        
    }
}


- (void)getConcretePhotoIdsForPhotos:(NSArray *)photos forAlbum:(Album *)anAlbum
{
    // Get the photo ids for the set of photos using POST /photos/upload_request/?num_photos={n}
    [self setDefaultHeader:@"Authorization" value:[[NSUserDefaults standardUserDefaults] objectForKey:kApplicationUserAuthToken]];
    
    NSString *photoIdPath = [NSString stringWithFormat:@"photos/upload_request/?num_photos=%d", photos.count];
    NSURLRequest *photoIDRequest = [self requestWithMethod:@"POST" path:photoIdPath parameters:nil];
    
    AFJSONRequestOperation *photoIDOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:photoIDRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        // For each photo, assign it an ID and upload it using PUT /photos/upload/{photo_id}/
        NSArray *photoIDs = (NSArray *)JSON;
        NSMutableArray *photoIdsToReturn = [NSMutableArray arrayWithCapacity:photoIDs.count];
        [photoIDs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            NSDictionary *photo = (NSDictionary *)obj;
            [photoIdsToReturn addObject:[photo objectForKey:@"photo_id"]];
            
        }];
        
        [self uploadPhotos:photos withConcreteIds:photoIdsToReturn forAlbum:anAlbum];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        if (error) {
            NSLog(@"There was an error retrieving photo IDs for the album photos: %@", error);
        }
        
    }];
    
    [self enqueueHTTPRequestOperation:photoIDOperation];
}


- (void)uploadPhotos:(NSArray *)photosToUpload withConcreteIds:(NSArray *)concretePhotoIds forAlbum:(Album *)anAlbum
{
    __block NSMutableArray *photoUploadBatch = [NSMutableArray arrayWithCapacity:photosToUpload.count];
    [concretePhotoIds enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSString *photoID = (NSString *)obj;
        AlbumPhoto *photo = [photosToUpload objectAtIndex:idx];
        
        [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
            
            AlbumPhoto *localPhoto = (AlbumPhoto *)[localContext objectWithID:photo.objectID];
            
            [localPhoto willChangeValueForKey:@"photoUploadStatus"];
            localPhoto.photoUploadStatus = [NSNumber numberWithInteger:SVPhotoUploadActive];
            [localPhoto didChangeValueForKey:@"photoUploadStatus"];
            
        }];
        
        [[SVEntityStore sharedStore] getFullsizeImageDataForImageID:photo.tempPhotoId WithCompletion:^(NSData *imageData) {
            
            if (imageData.length > 0) {
                NSString *photoUploadPath = [NSString stringWithFormat:@"photos/upload/%@/", photoID];
                NSMutableURLRequest *request = [self multipartFormRequestWithMethod:@"POST" path:photoUploadPath parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                    
                    //[formData throttleBandwidthWithPacketSize:kAFUploadStream3GSuggestedPacketSize delay:kAFUploadStream3GSuggestedDelay];
                    
                    if (imageData) {
                        [formData appendPartWithFileData:imageData name:@"photo" fileName:@"temp.jpeg" mimeType:@"image/jpeg"];
                    }
                    
                }];
                
                AFJSONRequestOperation *uploadOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                    
                    [self renameImageForPhoto:photo UsingID:photoID];
                    
                    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
                        
                        AlbumPhoto *localPhoto = (AlbumPhoto *)[localContext objectWithID:photo.objectID];
                        localPhoto.photo_id = photoID;
                        localPhoto.tempPhotoId = nil;
                        localPhoto.objectSyncStatus = [NSNumber numberWithInteger:SVObjectSyncCompleted];
                        
                        [localPhoto willChangeValueForKey:@"photoUploadStatus"];
                        localPhoto.photoUploadStatus = [NSNumber numberWithInteger:SVPhotoUploadCompleted];
                        [localPhoto didChangeValueForKey:@"photoUploadStatus"];
                        
                    }];
                    
                } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                    
                    NSLog(@"There was an error uploading the photo: %@", error);
                    NSLog(@"The error response JSON was: %@", JSON);
                    
                }];
                
                [photoUploadBatch addObject:uploadOperation];
            }
            
        }];
        
    }];
    
    [self enqueueBatchOfHTTPRequestOperations:photoUploadBatch progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
        
        // TODO: We should probably broadcast a system wide progress notification
        
    } completionBlock:^(NSArray *operations) {
        
        Album *localAlbum = (Album *)[[NSManagedObjectContext defaultContext] objectWithID:anAlbum.objectID];
        NSString *albumId = localAlbum.albumId;
        NSString *tempAlbumId = localAlbum.tempAlbumId;
        
        NSLog(@"We have finished uploading all the photos for this album!");
        if ([albumId isEqualToString:tempAlbumId]) {
            
            [self addConcretePhotoIds:concretePhotoIds ToNewAlbum:localAlbum];
            
        } else {
            
            [self addConcretePhotoIds:concretePhotoIds ToExistingAlbum:localAlbum];
            
        }
        
    }];
}


- (void)addConcretePhotoIds:(NSArray *)concretePhotoIds ToExistingAlbum:(Album *)anAlbum
{
    NSString *albumUploadPath = [NSString stringWithFormat:@"albums/%@/", anAlbum.albumId];
    NSMutableArray *addPhotosArray = [NSMutableArray arrayWithCapacity:concretePhotoIds.count];
    [anAlbum.albumPhotos enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        
        AlbumPhoto *aPhoto = (AlbumPhoto *)obj;
        if (![aPhoto.photo_id isEqualToString:aPhoto.tempPhotoId]) {
            
            [addPhotosArray addObject:@{@"photo_id": aPhoto.photo_id}];
            
        }
        
    }];
    NSURLRequest *albumUploadRequest = [self requestWithMethod:@"POST" path:albumUploadPath parameters:@{@"add_photos": addPhotosArray}];
    AFJSONRequestOperation *albumUploadOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:albumUploadRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        [self.operationQueue addOperationWithBlock:^{
            
            NSDictionary *album = (NSDictionary *)JSON;
            [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
                
                Album *localAlbum = (Album *)[localContext objectWithID:anAlbum.objectID];
                localAlbum.tempAlbumId = nil;
                localAlbum.etag = [[album objectForKey:@"etag"] stringValue];
                localAlbum.objectSyncStatus = [NSNumber numberWithInteger:SVObjectSyncCompleted];
                
            }];
            [self.albumsToUpload removeObject:anAlbum];
            
        }];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        NSLog(@"There was an error adding photos to the album: %@", error);
        NSLog(@"The error response JSON was: %@", JSON);
        
    }];
    
    __weak AFJSONRequestOperation *weakOperation = albumUploadOperation;
    [albumUploadOperation setShouldExecuteAsBackgroundTaskWithExpirationHandler:^{
        
        if (weakOperation.isFinished) {
            [self.operationQueue cancelAllOperations];
        }
        
    }];
    
    [self enqueueHTTPRequestOperation:albumUploadOperation];
}


- (void)addConcretePhotoIds:(NSArray *)concretePhotoIds ToNewAlbum:(Album *)anAlbum
{
    NSString *albumUploadPath = @"albums/";
    NSMutableArray *addPhotosArray = [NSMutableArray arrayWithCapacity:concretePhotoIds.count];
    NSMutableArray *addMembersArray = [NSMutableArray array];
    [anAlbum.members enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        
        Member *aMember = (Member *)obj;
        //[addMembersArray addObject:@{@"user_id": aMember.userId}];
        
    }];
    [anAlbum.albumPhotos enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        
        AlbumPhoto *aPhoto = (AlbumPhoto *)obj;
        NSString *photoId = aPhoto.photo_id;
        NSString *tempPhotoId = aPhoto.tempPhotoId;
        if (![photoId isEqualToString:tempPhotoId]) {
            
            [addPhotosArray addObject:@{@"photo_id": [NSString stringWithFormat:@"%@", photoId]}];
            
        }
        
    }];
    
    NSDictionary *parameters = @{@"album_name": anAlbum.name, @"members": addMembersArray, @"photos": addPhotosArray};
    
    NSURLRequest *albumUploadRequest = [self requestWithMethod:@"POST" path:albumUploadPath parameters:parameters];
    AFJSONRequestOperation *albumUploadOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:albumUploadRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        [self.operationQueue addOperationWithBlock:^{
            
            NSDictionary *album = (NSDictionary *)JSON;
            [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
                
                Album *localAlbum = (Album *)[localContext objectWithID:anAlbum.objectID];
                localAlbum.albumId = [[album objectForKey:@"id"] stringValue];
                localAlbum.tempAlbumId = nil;
                localAlbum.etag = [[album objectForKey:@"etag"] stringValue];
                localAlbum.objectSyncStatus = [NSNumber numberWithInteger:SVObjectSyncCompleted];
                
            }];
            [self.albumsToUpload removeObject:anAlbum];
            
        }];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        NSLog(@"There was an error adding photos to the album: %@", error);
        NSLog(@"The error response JSON was: %@", JSON);
        
    }];
    
    __weak AFJSONRequestOperation *weakOperation = albumUploadOperation;
    [albumUploadOperation setShouldExecuteAsBackgroundTaskWithExpirationHandler:^{
        
        if (weakOperation.isFinished) {
            [self.operationQueue cancelAllOperations];
        }
        
    }];
    
    [self enqueueHTTPRequestOperation:albumUploadOperation];
}


- (void)renameImageForPhoto:(AlbumPhoto *)aPhoto UsingID:(NSString *)imageId
{
    if (aPhoto && imageId) {
        
        NSURL *url = [NSURL URLWithString:aPhoto.photo_id relativeToURL:self.imageDataDirectory];
        if ([url path]) {
            NSURL *fileURL = [NSURL fileURLWithPath:[url path] isDirectory:NO];
            NSString *oldPath = [fileURL path];
            NSString *oldThumbnailPath = [[fileURL path] stringByAppendingString:@"_thumbnail"];
            
            NSURL *newUrl = [NSURL URLWithString:imageId relativeToURL:self.imageDataDirectory];
            NSURL *newFileURL = [NSURL fileURLWithPath:[newUrl path] isDirectory:NO];
            NSString *newPath = [newFileURL path];
            NSString *newThumbnailPath = [[newFileURL path] stringByAppendingString:@"_thumbnail"];
            
            NSError *moveError = nil;
            if ([[NSFileManager defaultManager] fileExistsAtPath:oldPath]) {
                [[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:newPath error:&moveError];
            }
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:oldThumbnailPath]) {
                [[NSFileManager defaultManager] moveItemAtPath:oldThumbnailPath toPath:newThumbnailPath error:&moveError];
            }
            
            if (moveError) {
                NSLog(@"%@", moveError);
            }
        }
    }
}


- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


#pragma mark - Key Value Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.operationQueue && [keyPath isEqualToString:@"operations"]) {
        if ([self.operationQueue.operations count] == 0) {
            // Do something here when your queue has completed
            NSLog(@"queue has completed");
            [self executeSyncCompleteOperations];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object
                               change:change context:context];
    }
}
@end
