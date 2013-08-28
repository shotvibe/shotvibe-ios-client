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
		
		albumsToUpload = [[NSMutableArray alloc] init];
		busy = NO;
		restartUploadWhenFinished = NO;
	}
	return self;
}



- (void)upload {
	
	NSLog(@"########################### upload ########################");
	
	if (busy) {
		NSLog(@"Uploader is busy. We'll restart it when current operations finishes");
		restartUploadWhenFinished = YES;
		return;
	}
	busy = YES;
	restartUploadWhenFinished = NO;
	
	if (!ctxAlbums) {
        ctxAlbums = [NSManagedObjectContext context];
        [ctxAlbums.userInfo setValue:@"UploadAlbumsContext" forKey:@"kNSManagedObjectContextWorkingName"];
        ctxAlbums.undoManager = nil;
    }
	
	// Get all of the albums that have photos to upload
	NSArray *arr = [OldAlbum findAllWithPredicate:[NSPredicate predicateWithFormat:@"objectSyncStatus == %@", [NSNumber numberWithInteger:SVObjectSyncUploadNeeded]]
									 inContext:ctxAlbums];
	NSLog(@"arr %@", arr);
	albumsToUpload = [NSMutableArray arrayWithArray:arr];
	
	[self uploadAlbums];
}

- (void) uploadAlbums {
	NSLog(@"########################### upload albums ######################## %i", albumsToUpload.count);
	// Write the albums to server
	
	NSMutableArray *operations = [[NSMutableArray alloc] init];
	
	
	for (OldAlbum *anAlbum in albumsToUpload) {
		
		NSDictionary *parameters = @{@"album_name": anAlbum.name, @"photos": @[], @"members": @[]};
		NSURLRequest *albumUploadRequest = [uploader requestWithMethod:@"POST" path:@"/albums/" parameters:parameters];
		AFJSONRequestOperation *albumUploadOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:albumUploadRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
			
			NSLog(@"upload complete: %@", JSON);
			NSLog(@"update the local object with the new data");
//			NSManagedObjectContext *mainContext  = [NSManagedObjectContext MR_rootSavingContext];
//			NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextWithParent:mainContext];
			NSDictionary *a = JSON;
			OldAlbum *album = anAlbum;//[Album findFirstByAttribute:@"albumId" withValue:a[@"id"] inContext:ctxAlbums];
			NSLog(@"update the local album %@ with the one from server %@", album, a);
			
			if (album) {
				[a enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
					
					if ([key isEqualToString:@"id"]) {
						[self setValue:[NSString stringWithFormat:@"%@", obj] forKey:key forManagedObject:album];
					} else {
						[self setValue:obj forKey:key forManagedObject:album];
					}
				}];
				album.objectSyncStatus = [NSNumber numberWithInteger:SVObjectSyncCompleted];
				[ctxAlbums saveToPersistentStoreAndWait];
			}
			
			
		} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
			
			NSLog(@"upload failed: %@", JSON);
			
		}];
		
		__weak AFJSONRequestOperation *weakOperation = albumUploadOperation;
		[albumUploadOperation setShouldExecuteAsBackgroundTaskWithExpirationHandler:^{
			if (weakOperation.isFinished) {
				//[self.operationQueue cancelAllOperations];
			}
		}];
		[operations addObject:albumUploadOperation];
	}
    
    [uploader enqueueBatchOfHTTPRequestOperations:operations
									progressBlock:^(NSUInteger executed, NSUInteger total){
										NSLog(@"progressBlock. uploaded albums %i / %i", executed, total);
									}
								  completionBlock:^(NSArray *operations){
									  NSLog(@"completionBlock");
									 [self uploadPhotos]; 
								  }];
}


- (void) uploadPhotos {
	
	NSLog(@"########################### upload photos ########################");
	
	// Get all of the albums that have photos to upload
	NSArray *arr = [OldAlbum findAllWithPredicate:[NSPredicate predicateWithFormat:@"SUBQUERY(albumPhotos, $albumPhoto, $albumPhoto.objectSyncStatus == %i).@count > 0", SVObjectSyncUploadNeeded]
									 inContext:[NSManagedObjectContext defaultContext]];
	albumsToUpload = [NSMutableArray arrayWithArray:arr];
    
	NSLog(@"albumsToUpload, albums with updates %@", albumsToUpload);

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND,0),^{
		[self uploadNextAlbumPhotos];
	});
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
		if (restartUploadWhenFinished) {
			restartUploadWhenFinished = NO;
			[self upload];
		}
	}
}

- (void) requestIdsForAlbum:(OldAlbum*)album {
	
	photosToUpload = [NSMutableDictionary dictionary];// Dictionary of AlbumPhoto
	NSArray *arr = [OldAlbumPhoto findAllWithPredicate:[NSPredicate predicateWithFormat:@"objectSyncStatus == %i AND album.albumId == %@", SVObjectSyncUploadNeeded, album.albumId]
										  inContext:[NSManagedObjectContext defaultContext]];
	NSLog(@"@@@@@@@@@@@@@@@@@@@@@@@@ Need to upload %i photos in album %@", arr.count, album.name);
	
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
	NSLog(@">>>>>>>>>>>>>>>>>>>>>>>>>> 0. uploadNextPhoto from %i remaining", [[photosToUpload allKeys] count]);
	if ([[photosToUpload allKeys] count] > 0) {
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND,0),^{
			
			NSString *key = [[photosToUpload allKeys] lastObject];
			OldAlbumPhoto *photo = [photosToUpload objectForKey:key];
			[photosToUpload removeObjectForKey:key];
			
			[self uploadPhoto:photo withId:key];
		});
	}
	else {
		[self addPhotosToAlbum:activeAlbum];
	}
}

- (void) uploadPhoto:(OldAlbumPhoto*)photo withId:(NSString*)photoID {
	
	NSLog(@">>>>>>>>>>>>>>>>>>>>>>>>>> 0. uploading photo with id %@", photoID);
	
	[MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
		
		OldAlbumPhoto *localPhoto = (OldAlbumPhoto *)[localContext objectWithID:photo.objectID];
		
		[localPhoto willChangeValueForKey:@"objectSyncStatus"];
		localPhoto.objectSyncStatus = [NSNumber numberWithInteger:SVObjectSyncUploadProgress];
		[localPhoto didChangeValueForKey:@"objectSyncStatus"];
		
	}];
	
	[[SVEntityStore sharedStore] getFullsizeImageDataForImageID:photo.tempPhotoId WithCompletion:^(NSData *imageData) {
		// Not main thread
		NSLog(@">>>>>>>>>>>>>>>>>>> 1. getFullsizeImageDataForImageID: %@", photo.tempPhotoId);
		NSLog(@"=================== 1. %@", [NSThread isMainThread] ? @"isMainThread":@"isNotMainThread");
		if (imageData && imageData.length > 0) {
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
				// This is main thread
				NSLog(@">>>>>>>>>>>>>>>>>>> 2. Photo was uploaded successfuly: %@", JSON);
				NSLog(@"=================== 2. %@", [NSThread isMainThread] ? @"isMainThread":@"isNotMainThread");
				[self renameImageForPhoto:photo UsingID:photoID];
				
				[MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
					NSLog(@">>>>>>>>>>>>>>>>>>> 3. Photo was uploaded successfuly, change status to SVObjectSyncUploadComplete");
					OldAlbumPhoto *localPhoto = (OldAlbumPhoto *)[localContext objectWithID:photo.objectID];
					localPhoto.photo_id = photoID;
					
					[localPhoto willChangeValueForKey:@"objectSyncStatus"];
					localPhoto.objectSyncStatus = [NSNumber numberWithInteger:SVObjectSyncUploadComplete];
					[localPhoto didChangeValueForKey:@"objectSyncStatus"];
					
				}];
				
				[self uploadNextPhoto];
				
			} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
				
				NSLog(@">>>>>>>>>>>>>>>>>>> 2. There was an error uploading the photo: %@", error);
				NSLog(@"The error response JSON was: %@", JSON);
				[self uploadNextPhoto];
			}];
			
			[uploader enqueueHTTPRequestOperation:uploadOperation];
		}
		else {
			NSLog(@">>>>>>>>>>>>>>>>>>> 2. Problems finding the image to upload. try to upload the next photo");
			[self uploadNextPhoto];
		}
	}];
}


// 3. When all photos are finished uploading, add them all to the album by calling: POST /albums/{aid}/

- (void)addPhotosToAlbum:(OldAlbum *)anAlbum
{
    NSString *albumUploadPath = [NSString stringWithFormat:@"/albums/%@/", anAlbum.albumId];
	NSLog(@">>>>>>>>>>>>>>>>>>> 5. addPhotosToAlbum albumUploadPath %@", albumUploadPath);
    NSMutableArray *addPhotosArray = [NSMutableArray array];
	
    [anAlbum.albumPhotos enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        
        OldAlbumPhoto *aPhoto = (OldAlbumPhoto *)obj;
        if (![aPhoto.photo_id isEqualToString:aPhoto.tempPhotoId]) {
            
            [addPhotosArray addObject:@{@"photo_id": aPhoto.photo_id}];
        }
        
    }];
	NSLog(@"addPhotosArray %@", addPhotosArray);
    NSURLRequest *albumUploadRequest = [uploader requestWithMethod:@"POST" path:albumUploadPath parameters:@{@"add_photos": addPhotosArray}];
    AFJSONRequestOperation *albumUploadOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:albumUploadRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
		__block NSDictionary *album = (NSDictionary *)JSON;
		NSLog(@">>>>>>>>>>>>>>>>>>> addPhotosArray response: %@", JSON);
		//dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND,0),^{
            
			[MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
                NSLog(@">>>>>>>>>>>>>>>>>>> photo upload completed, update Album model");
                OldAlbum *localAlbum = (OldAlbum *)[localContext objectWithID:anAlbum.objectID];
                localAlbum.etag = [[album objectForKey:@"etag"] stringValue];
                localAlbum.objectSyncStatus = [NSNumber numberWithInteger:SVObjectSyncCompleted];
            }];
            
        //});
		
		[self uploadNextAlbumPhotos];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        NSLog(@">>>>>>>>>>>>>>>>>>> There was an error adding photos to the album: %@", error);
        NSLog(@">>>>>>>>>>>>>>>>>>> The error response JSON was: %@", JSON);
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




- (void)renameImageForPhoto:(OldAlbumPhoto *)aPhoto UsingID:(NSString *)imageId
{
	NSLog(@">>>>>>>>>>>>>>>>>>> 2.2 rename image %@", imageId);
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND,0),^{
		if (aPhoto && imageId) {
			
			NSURL *url = [NSURL URLWithString:aPhoto.photo_id relativeToURL:[[SVEntityStore sharedStore] imageDataDirectory]];
			if ([url path]) {
				NSURL *fileURL = [NSURL fileURLWithPath:[url path] isDirectory:NO];
				NSString *oldPath = [fileURL path];
				NSString *oldThumbnailPath = [[fileURL path] stringByAppendingString:@"_thumbnail"];
				
				NSURL *newUrl = [NSURL URLWithString:imageId relativeToURL:[[SVEntityStore sharedStore] imageDataDirectory]];
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
	});
}




- (void) deleteAlbums {
	
}
- (void) deletePhotos {
	
}




- (void)setValue:(id)value forKey:(NSString *)key forManagedObject:(NSManagedObject *)managedObject {
	
    if ([key isEqualToString:@"latest_photos"] || [key isEqualToString:@"author"]) return;
	
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
	else if (![key isEqualToString:@"photos"] && ![key isEqualToString:@"members"])
	{
		[managedObject setValue:value forKey:key];
	}
}

- (NSDate *)dateUsingStringFromAPI:(NSString *)dateString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
	[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
	
    dateString = [dateString substringWithRange:NSMakeRange(0, [dateString length]-5)];
    return [dateFormatter dateFromString:dateString];
}


@end
