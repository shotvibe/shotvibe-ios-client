//
//  SVUploadManager.m
//  shotvibe
//
//  Created by Baluta Cristian on 06/08/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVUploadManager.h"

@implementation SVUploadManager


+ (SVUploadManager *)sharedManager
{
    static SVUploadManager *sharedManager = nil;
    static dispatch_once_t downloadEngineToken;
    dispatch_once(&downloadEngineToken, ^{
        sharedManager = [[SVUploadManager alloc] init];
    });
    
    return sharedManager;
}

- (id) init {
	self = [super init];
	if (self) {
		uploader = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kAPIBaseURLString]];
		uploader.operationQueue.maxConcurrentOperationCount = 1;
        [uploader registerHTTPOperationClass:[AFHTTPRequestOperation class]];
        [uploader registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [uploader setParameterEncoding:AFJSONParameterEncoding];
        [uploader setDefaultHeader:@"Authorization" value:[[NSUserDefaults standardUserDefaults] objectForKey:kApplicationUserAuthToken]];
		
		_queue = [[NSOperationQueue alloc] init];
		
		albumsToUpload = [[NSMutableArray alloc] init];
		busy = NO;
	}
	return self;
}



- (void)uploadAlbums {
	
	NSLog(@"########################### upload albums ########################");
	
	if (busy) {
		NSLog(@"Uploader is busy");
		return;
	}
	busy = YES;
	
	if (!ctxAlbums) {
        ctxAlbums = [NSManagedObjectContext context];
        [ctxAlbums.userInfo setValue:@"UploadAlbumsContext" forKey:@"kNSManagedObjectContextWorkingName"];
        ctxAlbums.undoManager = nil;
    }
	
	
}



- (void) uploadPhotos {
	
	NSLog(@"########################### upload photos ########################");
    if (busy) {
		NSLog(@"Uploader is busy");
		return;
	}
	busy = YES;
	
	// Get all of the albums that have photos to upload
	NSArray *arr = [Album findAllWithPredicate:[NSPredicate predicateWithFormat:@"SUBQUERY(albumPhotos, $albumPhoto, $albumPhoto.objectSyncStatus == %i).@count > 0", SVObjectSyncUploadNeeded]
									 inContext:[NSManagedObjectContext defaultContext]];
	albumsToUpload = [NSMutableArray arrayWithArray:arr];
    
	NSLog(@"albumsToUpload %@", albumsToUpload);

	[_queue addOperationWithBlock:^{
		[self uploadNextAlbumPhotos];
	}];
}



// 1. Upload request: POST /photos/upload_request/?num_photos={n}

- (void) uploadNextAlbumPhotos {
	
	if (albumsToUpload.count > 0) {
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
		});
		
		activeAlbum = [albumsToUpload lastObject];
		[albumsToUpload removeLastObject];
		
		[self requestIdsForAlbum:activeAlbum];
	}
	else {
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		});
		busy = NO;
	}
}

- (void) requestIdsForAlbum:(Album*)album {
	
	photosToUpload = [NSMutableDictionary dictionary];// Dictionary of AlbumPhoto
	NSArray *arr = [AlbumPhoto findAllWithPredicate:[NSPredicate predicateWithFormat:@"objectSyncStatus == %i AND album.albumId == %@", SVObjectSyncUploadNeeded, album.albumId]
										  inContext:[NSManagedObjectContext defaultContext]];
	NSLog(@"need to upload %i photos in album %@", arr.count, album.name);
	
    NSString *photoIdPath = [NSString stringWithFormat:@"photos/upload_request/?num_photos=%d", arr.count];
    NSURLRequest *photoIDRequest = [uploader requestWithMethod:@"POST" path:photoIdPath parameters:nil];
    
    AFJSONRequestOperation *photoIDOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:photoIDRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		
		NSLog(@"uploadRequest response %@", JSON);
        // For each photo, assign it an ID and upload it using PUT /photos/upload/{photo_id}/
        NSArray *photoIDs = (NSArray *)JSON;
       
        [photoIDs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            NSDictionary *photo = (NSDictionary *)obj;
            [photosToUpload setObject:[arr objectAtIndex:idx] forKey:photo[@"photo_id"]];
            
        }];
        
        [self uploadNextPhoto];
		
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        if (error) {
            NSLog(@"There was an error retrieving photo IDs for the album photos: %@", error);
        }
		[self uploadNextAlbumPhotos];
        
    }];
    
    [uploader enqueueHTTPRequestOperation:photoIDOperation];
}


// 2. Upload each photo one at a time, by calling: PUT /photos/upload/{photo_id}/

- (void) uploadNextPhoto {
	
	if ([[photosToUpload allKeys] count] > 0) {
		
		[_queue addOperationWithBlock:^{
			
			NSString *key = [[photosToUpload allKeys] lastObject];
			AlbumPhoto *photo = [photosToUpload objectForKey:key];
			[photosToUpload removeObjectForKey:key];
			
			[self uploadPhoto:photo withId:key];
		}];
	}
	else {
		[self addPhotosToAlbum:activeAlbum];
	}
}

- (void) uploadPhoto:(AlbumPhoto*)photo withId:(NSString*)photoID {
	
	NSLog(@">>>>>>>>>>>>>>>>>>>>>>>>>> uploading photo with id %@", photoID);
	
	[MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
		
		AlbumPhoto *localPhoto = (AlbumPhoto *)[localContext objectWithID:photo.objectID];
		
		[localPhoto willChangeValueForKey:@"objectSyncStatus"];
		localPhoto.objectSyncStatus = [NSNumber numberWithInteger:SVObjectSyncUploadProgress];
		[localPhoto didChangeValueForKey:@"objectSyncStatus"];
		
	}];
	
	[[SVEntityStore sharedStore] getFullsizeImageDataForImageID:photo.tempPhotoId WithCompletion:^(NSData *imageData) {
		
		if (imageData.length > 0) {
			NSString *photoUploadPath = [NSString stringWithFormat:@"photos/upload/%@/", photoID];
			// Using PUT is not working
			NSMutableURLRequest *request = [uploader multipartFormRequestWithMethod:@"POST"
																			   path:photoUploadPath
																		 parameters:nil
														  constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
				
				if (imageData) {
					[formData appendPartWithFileData:imageData name:@"photo" fileName:@"temp.jpeg" mimeType:@"image/jpeg"];
				}
				
			}];
			
			AFJSONRequestOperation *uploadOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
				
				NSLog(@"Photo was uploaded successfuly: %@", JSON);
				[self renameImageForPhoto:photo UsingID:photoID];
				
				[MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
					
					AlbumPhoto *localPhoto = (AlbumPhoto *)[localContext objectWithID:photo.objectID];
					localPhoto.photo_id = photoID;
					
					[localPhoto willChangeValueForKey:@"objectSyncStatus"];
					localPhoto.objectSyncStatus = [NSNumber numberWithInteger:SVObjectSyncUploadComplete];
					[localPhoto didChangeValueForKey:@"objectSyncStatus"];
					
				}];
				
				[self uploadNextPhoto];
				
			} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
				
				NSLog(@"There was an error uploading the photo: %@", error);
				NSLog(@"The error response JSON was: %@", JSON);
				
				[self uploadNextPhoto];
			}];
			
			[uploader enqueueHTTPRequestOperation:uploadOperation];
		}
		
	}];
}


// 3. When all photos are finished uploading, add them all to the album by calling: POST /albums/{aid}/

- (void)addPhotosToAlbum:(Album *)anAlbum
{
    NSString *albumUploadPath = [NSString stringWithFormat:@"/albums/%@/", anAlbum.albumId];
	NSLog(@">>>>>>>>>>>>>>>>>>> addPhotosToAlbum albumUploadPath %@", albumUploadPath);
    NSMutableArray *addPhotosArray = [NSMutableArray array];
	
    [anAlbum.albumPhotos enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        
        AlbumPhoto *aPhoto = (AlbumPhoto *)obj;
        if (![aPhoto.photo_id isEqualToString:aPhoto.tempPhotoId]) {
            
            [addPhotosArray addObject:@{@"photo_id": aPhoto.photo_id}];
        }
        
    }];
	NSLog(@"addPhotosArray %@", addPhotosArray);
    NSURLRequest *albumUploadRequest = [uploader requestWithMethod:@"POST" path:albumUploadPath parameters:@{@"add_photos": addPhotosArray}];
    AFJSONRequestOperation *albumUploadOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:albumUploadRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
		__block NSDictionary *album = (NSDictionary *)JSON;
		NSLog(@"addPhotosArray response: %@", JSON);
        [_queue addOperationWithBlock:^{
            
            [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
                
                Album *localAlbum = (Album *)[localContext objectWithID:anAlbum.objectID];
                localAlbum.etag = [[album objectForKey:@"etag"] stringValue];
                localAlbum.objectSyncStatus = [NSNumber numberWithInteger:SVObjectSyncCompleted];
                
            }];
            
        }];
		
		[self uploadNextAlbumPhotos];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        NSLog(@"There was an error adding photos to the album: %@", error);
        NSLog(@"The error response JSON was: %@", JSON);
		[self uploadNextAlbumPhotos];
        
    }];
    
    __weak AFJSONRequestOperation *weakOperation = albumUploadOperation;
    [albumUploadOperation setShouldExecuteAsBackgroundTaskWithExpirationHandler:^{
        NSLog(@";;;;;;;;;;;;;;;");
        if (weakOperation.isFinished) {
            //[self.operationQueue cancelAllOperations];
        }
        
    }];
    
    [uploader enqueueHTTPRequestOperation:albumUploadOperation];
}




- (void)renameImageForPhoto:(AlbumPhoto *)aPhoto UsingID:(NSString *)imageId
{
    if (aPhoto && imageId) {
        
        NSURL *url = [NSURL URLWithString:aPhoto.photo_id relativeToURL:[[SVDownloadManager sharedManager] imageDataDirectory]];
        if ([url path]) {
            NSURL *fileURL = [NSURL fileURLWithPath:[url path] isDirectory:NO];
            NSString *oldPath = [fileURL path];
            NSString *oldThumbnailPath = [[fileURL path] stringByAppendingString:@"_thumbnail"];
            
            NSURL *newUrl = [NSURL URLWithString:imageId relativeToURL:[[SVDownloadManager sharedManager] imageDataDirectory]];
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




- (void) deleteAlbums {
	
}
- (void) deletePhotos {
	
}

@end
