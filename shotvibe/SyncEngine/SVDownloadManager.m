//
//  SVDownloadManager.m
//  shotvibe
//
//  Created by Baluta Cristian on 06/08/2013.
//  Copyright (c) 2013 ralcr.com. All rights reserved.
//

#import "SVDownloadManager.h"
#define FORCE_RELOAD NO

@implementation SVDownloadManager

+ (SVDownloadManager *)sharedManager
{
    static SVDownloadManager *sharedManager = nil;
    static dispatch_once_t downloadEngineToken;
    dispatch_once(&downloadEngineToken, ^{
        sharedManager = [[SVDownloadManager alloc] init];
    });
    
    return sharedManager;
}

- (id) init {
	self = [super init];
	if (self) {
		saveQueue = dispatch_queue_create("com.shotvibe", DISPATCH_QUEUE_CONCURRENT);
		_queue = [[NSOperationQueue alloc] init];
		albumsWithUpdates = [[NSMutableArray alloc] init];
		busy = NO;
	}
	return self;
}


- (void) downloadAlbums {
	
	if (busy) {
		NSLog(@"SVDownloadManager is busy");
		return;
	}
	NSLog(@"SVDownloadManager downloadAlbums");
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	});
	
	ctxAlbums = [NSManagedObjectContext context];
	busy = YES;
	
	// Setup the Album request
    NSMutableURLRequest *theRequest = [[SVHttpClient sharedClient] requestWithMethod:@"GET" path:@"albums/" parameters:nil];
    
	NSString *lastRequestDate = [[NSUserDefaults standardUserDefaults] objectForKey:kUserAlbumsLastRequestedDate];
	if ((lastRequestDate && !FORCE_RELOAD) || !FORCE_RELOAD) {
		[theRequest setValue:lastRequestDate forHTTPHeaderField:@"If-Modified-Since"];
	}
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:theRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        NSLog(@"Got response code: %d Date: %@", response.statusCode, [response allHeaderFields]);
		
		[[NSUserDefaults standardUserDefaults] setObject:[[response allHeaderFields] objectForKey:@"Date"] forKey:kUserAlbumsLastRequestedDate];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		[self processAlbumsJSON:JSON];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
		NSLog(@"Got response error or there are no changes");
		dispatch_async(dispatch_get_main_queue(), ^{
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		});
		busy = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:kSVSyncEngineDownloadCompletedNotification object:nil];
    }];
    
//    __weak AFJSONRequestOperation *weakOperation = operation;
//    [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:^{
//        
//        if (weakOperation.isFinished) {
//            [[SVHttpClient sharedClient].operationQueue cancelAllOperations];
//        } else {
//            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kUserAlbumsLastRequestedDate];
//            [[NSUserDefaults standardUserDefaults] synchronize];
//        }
//        
//	}];
	
	[[SVHttpClient sharedClient] enqueueHTTPRequestOperation:operation];
}


- (void)processAlbumsJSON:(NSArray*)albums
{
    NSLog(@"PROCESSING ALBUMS JSON");
	[albumsWithUpdates removeAllObjects];
    
	NSLog(@"processAlbumsJSON albums count %i ", albums.count);
	
	[_queue addOperationWithBlock:^{
		
		for (NSDictionary *anAlbum in albums) {
			
			// Create an Album from NSDictionary
			Album *album = [Album findFirstByAttribute:@"albumId" withValue:anAlbum[@"id"] inContext:ctxAlbums];
			
			if (!album) {
				album = [Album createInContext:ctxAlbums];
				album.objectSyncStatus = [NSNumber numberWithInt:SVObjectSyncDownloadNeeded];
			}
			else if (album.objectSyncStatus.integerValue == SVObjectSyncUploadNeeded) {
				continue;
			}
			
			if ( ! [album.etag isEqualToString:anAlbum[@"etag"]] || FORCE_RELOAD) {
				// Mark this album as having changes, so you need to download photos from it
				[albumsWithUpdates addObject:anAlbum[@"id"]];
			}
			NSLog(@"etag local and server %@ == %@ ", album.etag, anAlbum[@"etag"]);
			
			// Populate fields of the managed object dynamically
			
			[anAlbum enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
				
				if ([key isEqualToString:@"id"]) {
					[self setValue:[NSString stringWithFormat:@"%@", obj] forKey:key forManagedObject:album];
				} else {
					[self setValue:obj forKey:key forManagedObject:album];
				}
			}];
		}
		
		[self deleteAlbumsNotOnServer:albums];
		[self saveAlbumsContext];
	}];
}

- (void)deleteAlbumsNotOnServer:(NSArray*)albums {
	
	// Fetch local albums
	
	NSError *error;
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Album" inManagedObjectContext:ctxAlbums];
	[fetchRequest setEntity:entity];
	NSArray *localAlbums = [ctxAlbums executeFetchRequest:fetchRequest error:&error];
	NSMutableArray *albumsToDelete = [NSMutableArray arrayWithArray:localAlbums];
	
	NSLog(@"SVDownloadManager count locally: %i = %i", localAlbums.count, albums.count);
	
	for (NSDictionary *serverAlbum in albums) {
		for (Album *localAlbum in albumsToDelete) {
			//NSLog(@"xxxxxxxxxxxxxxxxx   propose for deletion: %@ %@", [serverAlbum objectForKey:@"id"], localAlbum.albumId);
			if ([[NSString stringWithFormat:@"%@", [serverAlbum objectForKey:@"id"]] isEqualToString:localAlbum.albumId]) {
				[albumsToDelete removeObject:localAlbum];
				break;
			}
		}
	}
	
	NSLog(@"albumsToDelete: %@", albumsToDelete);
	for (Album *localAlbum in albumsToDelete) {
		NSLog(@"delete %@", localAlbum.albumId);
		[localAlbum deleteInContext:ctxAlbums];
	}
}

// Save all the changes you've made to the albums

- (void)saveAlbumsContext
{
    [ctxAlbums saveWithOptions:MRSaveParentContexts onQueue:saveQueue completion:^(BOOL success, NSError *error) {
        
        if (success) {
            [NSManagedObjectContext resetContextForCurrentThread];
            [NSManagedObjectContext resetDefaultContext];
			[ctxAlbums reset];
            ctxAlbums = nil;
        }
        else {
            NSLog(@"%@", error);
        }
		[_queue addOperationWithBlock:^{
			[self downloadAlbumsDetails];
		}];
        
    }];
}



// running in the queue

- (void) downloadAlbumsDetails {
	
	NSLog(@"########################### download album details ########################");
    if (!ctxPhotos) {
        ctxPhotos = [NSManagedObjectContext context];
        [ctxPhotos.userInfo setValue:@"PhotoSaveContext" forKey:@"kNSManagedObjectContextWorkingName"];
        ctxPhotos.undoManager = nil;
    }
	
	//dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		[self downloadNextAlbumDetails];
	//});
}

- (void) downloadNextAlbumDetails {
	
	if (albumsWithUpdates.count > 0) {
		NSString *albumId = [albumsWithUpdates lastObject];
		[albumsWithUpdates removeLastObject];
		[_queue addOperationWithBlock:^{
			[self downloadAlbumDetails:albumId];
		}];
	}
	else {
		NSLog(@"WE HAVE NO MORE ALBUMS TO PROCESS");
		dispatch_async(dispatch_get_main_queue(), ^{
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		});
		[self savePhotosContext];
	}
}

- (void) downloadAlbumDetails:(NSString*)albumId {
	
    Album *album = [Album findFirstByAttribute:@"albumId" withValue:albumId inContext:ctxPhotos];
	
	NSString *path = [NSString stringWithFormat:@"albums/%@/", albumId];
	NSMutableURLRequest *theRequest = [[SVHttpClient sharedClient] requestWithMethod:@"GET" path:path parameters:nil];
	NSLog(@"-----------> Album with creation date. %@", album.date_created);
	
	// The album has no date if it's the first sync
	if (album.date_created != nil && album.etag != nil) {
		[theRequest setValue:album.etag forHTTPHeaderField:[NSString stringWithUTF8String:"If-None-Match"]];
	}
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:theRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		
		[_queue addOperationWithBlock:^{
			
			NSLog(@"executing processAlbumsDetailsJSON operation with status code %i", response.statusCode);
			[self processAlbumsDetailsJSON:JSON];
			[self downloadNextAlbumDetails];
		}];
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		
		if (response.statusCode == 304) {
			NSLog(@"-----------> This album has no updates.");
			[self downloadNextAlbumDetails];
		}
		
	}];
	
//	__weak AFJSONRequestOperation *weakOperation = operation;
//	[operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:^{
//		
//		if (weakOperation.isFinished) {
//			NSLog(@"The photo json operation finished, cleanup and save the remaining operations so they can be resumed.");
//			
//		} else {
//			NSLog(@"The operation did not finished, clean up and requeue this operation with the remaining operations so they can be resumed later.");
//		}
//		
//	}];
    
	[[SVHttpClient sharedClient] enqueueHTTPRequestOperation:operation];
	
//    [[SVJSONAPIClient sharedClient] enqueueBatchOfHTTPRequestOperations:operations
//														  progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations)
//	{
//        
//        //TODO: Post a progress notification for interested observers
//		NSLog(@"Operations progress %i/%i", numberOfFinishedOperations, totalNumberOfOperations);
//        
//    } completionBlock:^(NSArray *operations) {
//		
//		NSLog(@"Operations completed. savecontext");
//		[self savePhotosContext];
//		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
//		
//		
//		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//			
//			// Start the efective download?
//			
//		});
//        
//    }];
}

- (void)processAlbumsDetailsJSON:(NSDictionary*)albumData
{
    NSLog(@">>>>>>>>>>>>>>>>>>>>>>> PROCESSING PHOTOS for Album: %@", albumData[@"name"]);
    
    Album *localAlbum = [Album findFirstByAttribute:@"albumId" withValue:albumData[@"id"] inContext:ctxPhotos];
	
	[self setValue:[albumData objectForKey:@"date_created"] forKey:@"date_created" forManagedObject:localAlbum];
	
	if (albumData) {
		NSLog(@"albumData %@", albumData[@"name"]);
		
		// Process members
		NSArray *members = albumData[@"members"];
		
		for (NSDictionary *member in members) {
			
			OldMember *outerMember = [OldMember findFirstByAttribute:@"userId" withValue:[member objectForKey:@"id"] inContext:ctxPhotos];
			
			if (!outerMember) {
				outerMember = [OldMember createInContext:ctxPhotos];
			}
			
			[member enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
				[self setValue:obj forKey:key forManagedObject:outerMember];
			}];
			
			outerMember.objectSyncStatus = [NSNumber numberWithInt:SVObjectSyncDownloadNeeded];
			
			[localAlbum addMembersObject:outerMember];
			
		}
		
		// Process each photo object from server
		NSArray *photosArray = albumData[@"photos"];
		
		for (NSDictionary *photo in photosArray) {
			
			OldAlbumPhoto *outerPhoto = [OldAlbumPhoto findFirstByAttribute:@"photo_id" withValue:photo[@"photo_id"] inContext:ctxPhotos];
			
			if (!outerPhoto) {
				outerPhoto = [OldAlbumPhoto createInContext:ctxPhotos];
				outerPhoto.hasViewed = [NSNumber numberWithBool:NO];
				//outerPhoto.isNew = [NSNumber numberWithBool:YES];
			}
			
			[photo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
				[self setValue:obj forKey:key forManagedObject:outerPhoto];
			}];
			
			outerPhoto.objectSyncStatus = [NSNumber numberWithInt:SVObjectSyncDownloadNeeded];
			
			// Add members to database
			
			OldMember *localAuthor = [OldMember findFirstByAttribute:@"userId" withValue:[[photo objectForKey:@"author"] objectForKey:@"id"] inContext:ctxPhotos];
			
			[localAlbum addAlbumPhotosObject:outerPhoto];
			
			if (localAuthor) {
				outerPhoto.author = localAuthor;
			}
			
		}
	}
	
	NSLog(@">>>>>>>>>>>>>>>>>>>>>>> FIN PROCESSING PHOTOS for Album %@ ", albumData[@"name"]);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kSVSyncEngineAlbumProcessedNotification object:localAlbum];
}

- (void)savePhotosContext
{
    
    [ctxPhotos saveWithOptions:MRSaveParentContexts onQueue:saveQueue completion:^(BOOL success, NSError *error) {
        
        if (success) {
			NSLog(@"TERMINATE ctxPhotos context and start downloading the photos");
            [NSManagedObjectContext resetContextForCurrentThread];
            [NSManagedObjectContext resetDefaultContext];
            [ctxPhotos reset];
            ctxPhotos = nil;
            
            // Download images
            [self downloadPhotos];
        }
        else
        {
            if (error) {
                NSLog(@"%@", error);
            }
            NSLog(@"Nothing to save.");
            [self downloadPhotos];
        }
    }];
}

- (void)downloadPhotos {
	
	NSLog(@"###########################download photos########################");
    if (!ctxDownload) {
        ctxDownload = [NSManagedObjectContext context];
        [ctxDownload.userInfo setValue:@"DownloadContext" forKey:@"kNSManagedObjectContextWorkingName"];
        ctxDownload.undoManager = nil;
    }
	
	if (!downloader) {
		downloader = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kAPIBaseURLString]];
		downloader.operationQueue.maxConcurrentOperationCount = 4;
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	});
	
	[self downloadNextPhoto];
}

- (void)downloadNextPhoto {
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectSyncStatus == %i", SVObjectSyncDownloadNeeded];
	OldAlbumPhoto *photo = [OldAlbumPhoto findFirstWithPredicate:predicate inContext:ctxDownload];
	
	if (photo == nil) {
		[self saveDownloadContext];
    }
	else {
		//dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		[_queue addOperationWithBlock:^{
			[self downloadPhoto:photo];
		}];
		//});
	}
}

- (void)downloadPhoto:(OldAlbumPhoto*)aPhoto {
	
    NSLog(@"***********************  downloading photo %@ ", aPhoto.photo_id);
	
	[[SVEntityStore sharedStore] getImageForPhoto:aPhoto WithCompletion:^(UIImage *image) {
		
		OldAlbumPhoto *localPhoto = (OldAlbumPhoto *)[ctxDownload objectWithID:aPhoto.objectID];
		[localPhoto setObjectSyncStatus:[NSNumber numberWithInteger:SVObjectSyncCompleted]];
		
		//localPhoto.album.objectSyncStatus = [NSNumber numberWithInteger:SVObjectSyncCompleted];
		[[NSNotificationCenter defaultCenter] postNotificationName:kSVSyncEngineDownloadIndividualCompletedNotification object:aPhoto.objectID];
		
		//dispatch_async(dispatch_get_main_queue(), ^{
			[self downloadNextPhoto];
		//});
		
	}];
}
- (void)saveDownloadContext
{
    [ctxDownload saveWithOptions:MRSaveParentContexts onQueue:saveQueue completion:^(BOOL success, NSError *error) {
        
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
        
		dispatch_async(dispatch_get_main_queue(), ^{
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		});
		busy = NO;
		
        [[NSNotificationCenter defaultCenter] postNotificationName:kSVSyncEngineDownloadCompletedNotification object:nil];
        
    }];
}




// Method to set fields in the ManagedObject from a NSDictionary

- (void)setValue:(id)value forKey:(NSString *)key forManagedObject:(NSManagedObject *)managedObject {
	
    if ([key isEqualToString:@"latest_photos"] || [key isEqualToString:@"author"]) return;
	
	if ([[[managedObject entity] name] isEqualToString:@"Album"] && [key isEqualToString:@"id"])
	{
		[managedObject setValue:value forKey:@"albumId"];
	}
	else if ([[[managedObject entity] name] isEqualToString:@"OldMember"] && [key isEqualToString:@"id"])
	{
		[managedObject setValue:value forKey:@"userId"];
	}
	else if ([key isEqualToString:@"last_updated"] || [key isEqualToString:@"date_created"])
	{
		NSDate *date = [self dateUsingStringFromAPI:value];
		[managedObject setValue:date forKey:key];
	}
	else
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



#pragma mark Saving photos to disk

- (NSURL *)imageDataDirectory {
	
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationDocumentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *url = [NSURL URLWithString:@"SVImages/" relativeToURL:applicationDocumentsDirectory];
    NSURL *fileURL = [NSURL fileURLWithPath:[url path] isDirectory:YES];
    
    NSError *error = nil;
    if (![fileManager fileExistsAtPath:[fileURL path]]) {
        [fileManager createDirectoryAtPath:[fileURL path] withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    NSError *attributeError = nil;
    BOOL success = [fileURL setResourceValue: [NSNumber numberWithBool: YES] forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
        NSLog(@"Error excluding %@ from backup %@", [fileURL lastPathComponent], attributeError);
    }
    
    return fileURL;
}


@end
