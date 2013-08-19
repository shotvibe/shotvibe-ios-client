//
//  SVEntityStore.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/7/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVEntityStore.h"

static NSString * const kShotVibeAPIBaseURLString = @"https://api.shotvibe.com";


@interface SVEntityStore ()

@property (nonatomic, strong) NSOperationQueue *imageQueue;

@end

@implementation SVEntityStore

#pragma mark - Getters

- (NSURL *)imageDataDirectory {
	
    if (!_imageDataDirectory) {
        
        _imageDataDirectory = [NSURL URLWithString:@"SVImages/" relativeToURL:[self applicationDocumentsDirectory]];
		
        NSFileManager *fileManager = [NSFileManager defaultManager];
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
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)wipe {
	
	dispatch_async(dispatch_get_global_queue(0,0),^{
		NSError *error = nil;
		[[NSFileManager defaultManager] removeItemAtURL:_imageDataDirectory error:&error];
		_imageDataDirectory = nil;
	});
	
	//[NSManagedObject truncateAll];
	NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
	[Member MR_truncateAllInContext:localContext];
	[Album MR_truncateAllInContext:localContext];
	[AlbumPhoto MR_truncateAllInContext:localContext];
	[localContext MR_saveToPersistentStoreAndWait];
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

+ (SVEntityStore *)sharedStore
{
    static SVEntityStore *entityStore = nil;
    static dispatch_once_t storeQueue;
    
    dispatch_once(&storeQueue, ^{
        entityStore = [[SVEntityStore alloc] initWithBaseURL:[NSURL URLWithString:kShotVibeAPIBaseURLString]];
    });
    
    return entityStore;
}


#pragma mark - FRC Methods

- (NSFetchedResultsController *)allAlbumsForCurrentUserWithDelegate:(id)delegate
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Album"];
	NSSortDescriptor *lastUpdatedDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"last_updated" ascending:NO];
    fetchRequest.sortDescriptors = @[lastUpdatedDescriptor];
	NSManagedObjectContext *dc = [NSManagedObjectContext MR_defaultContext];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																							   managedObjectContext:dc
																								 sectionNameKeyPath:nil
																										  cacheName:nil];
    fetchedResultsController.delegate = delegate;
	
    NSError *fetchError = nil;
    if (![fetchedResultsController performFetch:&fetchError]) {
        NSLog(@"There was an error fetching the results: %@", fetchError.userInfo);
    }
    NSLog(@"get the allAlbumsForCurrentUserWithDelegate");
    return fetchedResultsController;
}


- (NSFetchedResultsController *)allAlbumsMatchingSearchTerm:(NSString *)searchTerm WithDelegate:(id)delegate
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Album"];
    NSSortDescriptor *lastUpdatedDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"last_updated" ascending:NO];
    
    fetchRequest.sortDescriptors = @[lastUpdatedDescriptor];
    
    if (![searchTerm isEqualToString:@""]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", searchTerm];
        fetchRequest.predicate = predicate;
    }
    
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																							   managedObjectContext:[NSManagedObjectContext defaultContext]
																								 sectionNameKeyPath:nil
																										  cacheName:nil];
    fetchedResultsController.delegate = delegate;
    
    NSError *fetchError = nil;
    if (![fetchedResultsController performFetch:&fetchError]) {
        NSLog(@"There was an error fetching the results: %@", fetchError.userInfo);
    }
    
    return fetchedResultsController;
}


- (NSFetchedResultsController *)allPhotosForAlbum:(Album *)anAlbum WithDelegate:(id)delegate
{
	NSLog(@"NSFetchedResultsController *)allPhotosForAlbum %@", anAlbum.name);
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"AlbumPhoto"];
    NSSortDescriptor *datecreatedDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date_created" ascending:YES];
    //NSSortDescriptor *idDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"photo_id" ascending:YES];
    
    fetchRequest.sortDescriptors = @[datecreatedDescriptor];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"album.albumId == %@ AND objectSyncStatus != %i", anAlbum.albumId, SVObjectSyncDeleteNeeded];
    fetchRequest.predicate = predicate;
    
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																							   managedObjectContext:[NSManagedObjectContext defaultContext]
																								 sectionNameKeyPath:nil
																										  cacheName:nil];
    fetchedResultsController.delegate = delegate;
    
    NSError *fetchError = nil;
    if (![fetchedResultsController performFetch:&fetchError]) {
        NSLog(@"There was an error fetching the album photos: %@", fetchError.userInfo);
    }
	NSLog(@"fetched objects count: %i", [[fetchedResultsController fetchedObjects] count]);
    
    return fetchedResultsController;
}


#pragma mark - Album Methods

- (void)setAllPhotosToNotNew
{
	NSLog(@"setAllPhotosToNotNew");
	
//    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
//		
//		NSArray *ar = [AlbumPhoto findAllWithPredicate:[NSPredicate predicateWithFormat:@"isNew == YES"]
//											 inContext:localContext];
//		NSLog(@"setAllPhotosToNotNew new ar : %i", ar.count);
//		for (AlbumPhoto *p in ar) {
//			p.isNew = [NSNumber numberWithBool:NO];
//		}
//    }];
}
- (void)setPhotosInAlbumToNotNew:(Album*)album {
	
//	[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
//		
//		NSArray *ar = [AlbumPhoto findAllWithPredicate:[NSPredicate predicateWithFormat:@"isNew == YES AND album.albumId == %@", album.albumId]
//											 inContext:localContext];
//		for (AlbumPhoto *p in ar) {
//			p.isNew = [NSNumber numberWithBool:NO];
//		}
//    }];
}

- (void)setPhotoAsViewed:(NSString *)photoId
{
	NSLog(@"setPhotoIdAsViewed %@", photoId);
	
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
		
		AlbumPhoto *p = [AlbumPhoto findFirstWithPredicate:[NSPredicate predicateWithFormat:@"photo_id == %@", photoId]
												 inContext:localContext];
		[p setHasViewed:[NSNumber numberWithBool:YES]];
    }];
}


- (void)newAlbumWithName:(NSString *)albumName andUserID:(NSNumber *)userID
{    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
		
        Album *localAlbum = [Album createInContext:localContext];
        
        // Create the first member too...
        Member *localMember = [Member createInContext:localContext];
		localMember.nickname = @"Me";
        [localMember setUserId:userID];
        
        NSString *tempAlbumId = [[NSUUID UUID] UUIDString];
        
        [localAlbum setAlbumId:tempAlbumId];
        [localAlbum setDate_created:[NSDate date]];
        [localAlbum setLast_updated:[NSDate date]];
        [localAlbum setName:albumName];
        [localAlbum setUrl:@""];
        [localAlbum setObjectSyncStatus:[NSNumber numberWithInteger:SVObjectSyncUploadNeeded]];
        [localAlbum setEtag:@"0"];
        [localAlbum addMembersObject:localMember];

    }];
}


- (void)addPhotoWithID:(NSString *)photoId ToAlbumWithID:(NSString *)albumID WithCompletion:(void (^)(BOOL success, NSError *error))block
{
    Album *albumToAddPhotosTo = [Album findFirstByAttribute:@"albumId" withValue:albumID inContext:[NSManagedObjectContext defaultContext]];
    NSLog(@"addPhotoWithID to database: albumId %@, photoId: %@", albumID, photoId);
    if (photoId && albumID) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            AlbumPhoto *localPhoto = [AlbumPhoto createInContext:localContext];
            Album *localAlbum = (Album *)[localContext objectWithID:albumToAddPhotosTo.objectID];
            
            [localPhoto setDate_created:[NSDate date]];
            [localPhoto setObjectSyncStatus:[NSNumber numberWithInteger:SVObjectSyncUploadNeeded]];
            [localPhoto setTempPhotoId:photoId];
            [localPhoto setPhoto_id:photoId];
            [localPhoto setPhoto_url:@""];
            
            [localAlbum addAlbumPhotosObject:localPhoto];
			
        } completion:^(BOOL success, NSError *error) {
            block(success, error);
        }];
    } else {
        NSLog(@"WE'VE LOST INTELLIGENCE SIR!! photoId or albumId missing");
    }
}
- (void)leaveAlbum:(Album*)album completion:(void (^)(BOOL success, NSError *error))block {
	
	NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:0];
    NSString *path = [NSString stringWithFormat:@"/albums/%@/leave/", album.albumId];
    
    [self postPath:path
		parameters:parameters
		   success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
			   //NSData *responseData = (NSData *)responseObject;
        
			   //id json = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
			   NSLog(@"response ok %@", responseObject);
			   
			   block (YES, nil);
    }
		   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               NSLog(@"response error %@", error);
			   block (NO, error);
               
	}];
}


#pragma mark - Registration Methods

- (void)registerPhoneNumber:(NSString *) phoneNumber withCountryCode:(NSString *) countryCode WithCompletion:(void (^)(BOOL success, NSString *confirmationCode, NSError *error))block
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:2];
    [parameters setValue:phoneNumber forKey:@"phone_number"];
    [parameters setValue:countryCode forKey:@"default_country"];
    
    // send a phone number registration request using: POST /auth/authorize_phone_number/
    NSString *path = [NSString stringWithFormat:@"/auth/authorize_phone_number/"];
    
    [self postPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSData *responseData = (NSData *)responseObject;
        
        id json = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
        
        NSMutableDictionary *confirmationCode = (NSMutableDictionary *)json;
        
        NSLog(@"confirmation code:  %@", [confirmationCode objectForKey:@"confirmation_key"]);
        
        block(YES, [confirmationCode objectForKey:@"confirmation_key"], nil);
    }
     
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               
               block(NO, nil, nil);
               
           }];
}


- (void)validateRegistrationCode:(NSString *) registrationCode withConfirmationCode:(NSString *) confirmationCode WithCompletion:(void (^)(BOOL success, NSString *authToken, NSString *userId, NSError *error))block
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:2];
    [parameters setValue:registrationCode forKey:@"confirmation_code"];
    [parameters setValue:@"testing"       forKey:@"device_description"];
    
    
    // send a confirmation code request using: POST /auth/confirm_sms_code/{confirmation_key}/
    NSString *path = [NSString stringWithFormat:@"/auth/confirm_sms_code/%@/", confirmationCode];
    
    NSLog(@"confirmation url:  %@", path);
    
    [self postPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSData *responseData = (NSData *)responseObject;
        
        id json = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
        
        NSMutableDictionary *confirmationCode = (NSMutableDictionary *)json;
        
        //  "auth_token": "de7415aabe33cea5d85ac87562c92a18530b0847",
        //  "user_id": 613008887
        
        NSString *authToken = [confirmationCode objectForKey:@"auth_token"];
        NSString *userId    = [confirmationCode objectForKey:@"user_id"];
        
        //  NSLog(@"authToken:  %@, userId:  %@", authToken, userId);
        
        block(YES, authToken, userId, nil);
    }
     
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               
               NSLog(@"failed to register");
               
               block(NO, nil, nil, nil);
               
           }];
}


#pragma mark - Invite friends

- (void)invitePhoneNumbers:(NSDictionary*)phoneNumbers toAlbumId:(NSString *)albumId WithCompletion:(void (^)(BOOL success, NSError *error))block
{
	
    // send invites to phone numbers using: POST /albums/id/
    NSString *path = [NSString stringWithFormat:@"/albums/%@/", albumId];
	NSLog(@"path:  %@", path);
    
    [self postPath:path parameters:phoneNumbers success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSData *responseData = (NSData *)responseObject;
        
        id json = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
        
        //NSMutableDictionary *confirmationCode = (NSMutableDictionary *)json;
        
        NSLog(@"invitePhoneNumbers album content response:  %@", json);
        
        block(YES, nil);
    }
     
	failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"invite failed %@", error);
		block(NO, nil);
	
	}];
}




#pragma mark - Image Methods

- (void)getImageForPhoto:(AlbumPhoto *)aPhoto WithCompletion:(void (^)(UIImage *))block
{
	__block AlbumPhoto *blockPhoto = (AlbumPhoto *)aPhoto;
	
    dispatch_async(dispatch_get_global_queue(0,0),^{
		
		[self getImageDataForImageID:aPhoto.photo_id WithCompletion:^(NSData *imageData) {
			NSLog(@"get photo with id %@", aPhoto.photo_id);
			if (imageData) {
				block ( [UIImage imageWithData:imageData] );
			}
			else {
				[self getImageDataForImageID:aPhoto.tempPhotoId WithCompletion:^(NSData *imageData) {
					NSLog(@"photo not found, get photo with temp id %@", aPhoto.tempPhotoId);
					if (imageData) {
						block ( [UIImage imageWithData:imageData] );
					}
					else {
						NSURL *photoURL = [SVBusinessDelegate getURLForPhoto:blockPhoto];
						NSURLResponse *response = nil;
						NSError *err = nil;
						NSURLRequest *request = [NSURLRequest requestWithURL:photoURL];
						NSLog(@"temp photo not found, get photo from server %@", photoURL);
						
						NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
						if (data) {
							[self writeImageData:data toDiskForImageID:blockPhoto.photo_id WithCompletion:^(BOOL success, NSURL *fileURL, NSError *error) {
								// don't care >:O
							}];
							block ( [UIImage imageWithData:data scale:0.25] );
						}
					}
				}];
			}
		}];
	});
}


- (void)getImageForPhotoData:(AlbumPhoto *)aPhoto WithCompletion:(void (^)(NSData *imageData, BOOL success))block
{
    __block AlbumPhoto *blockPhoto = (AlbumPhoto *)[[NSManagedObjectContext contextForCurrentThread] objectWithID:aPhoto.objectID];
    
    [self getImageDataForImageID:blockPhoto.photo_id WithCompletion:^(NSData *imageData) {
		
        if (imageData) {
            block(imageData, YES);
            
            imageData = nil;
        }
        else
        {
            NSURL *photoURL = [SVBusinessDelegate getURLForPhoto:blockPhoto];
            
            NSURLRequest *request = [NSURLRequest requestWithURL:photoURL];
            [NSURLConnection sendAsynchronousRequest:request queue:self.imageQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                if (data) {
                    [self writeImageData:data toDiskForImageID:blockPhoto.photo_id WithCompletion:^(BOOL success, NSURL *fileURL, NSError *error) {
                        // don't care >:O
                        block(data, success);
                    }];
                } else {
                    block(nil, NO);
                }
            }];
        }
    }];
}


- (UIImage *)getImageForPhoto:(AlbumPhoto *)aPhoto
{
    NSURL *url = [NSURL URLWithString:aPhoto.photo_id relativeToURL:self.imageDataDirectory];
    NSString *path = [url path];
    
    if (path) {
        NSURL *fileURL = [NSURL fileURLWithPath:path isDirectory:NO];
        NSError *readingError = nil;
        
        @autoreleasepool {
            NSData *dataToReturn = [[NSData alloc] initWithContentsOfFile:[fileURL path] options:NSDataReadingMappedIfSafe error:&readingError];
            
            if (dataToReturn) {
                UIImage *image = [UIImage imageWithData:dataToReturn];
                return image;
            } else {
                if (readingError) {
                    NSLog(@"%@", readingError);
                }
                return nil;
            }
            
            dataToReturn = nil;
        }
    }
    else
    {
        return nil;
    }
}


- (void)getImageDataForImageID:(NSString *)imageID WithCompletion:(void (^)(NSData *imageData))block
{
    NSURL *url = [NSURL URLWithString:imageID relativeToURL:self.imageDataDirectory];
    NSString *path = [url path];
    
    if (path) {
        NSURL *fileURL = [NSURL fileURLWithPath:[path stringByAppendingString:@"_thumbnail"] isDirectory:NO];
        NSError *readingError = nil;
        
        @autoreleasepool {
            NSData *dataToReturn = [[NSData alloc] initWithContentsOfFile:[fileURL path] options:NSDataReadingMappedIfSafe error:&readingError];
            
            if (dataToReturn) {
                block(dataToReturn);
            } else {
                if (readingError) {
                    //NSLog(@"%@", readingError);
                }
                block(nil);
            }
            
            dataToReturn = nil;
        }
    }
    else
    {
        block(nil);
    }
    
}


- (void)getFullsizeImageDataForImageID:(NSString *)imageID WithCompletion:(void (^)(NSData *imageData))block
{
    NSURL *url = [NSURL URLWithString:imageID relativeToURL:self.imageDataDirectory];
    NSString *path = [url path];
    
    if (path) {
        NSURL *fileURL = [NSURL fileURLWithPath:path isDirectory:NO];
        NSError *readingError = nil;
        
        @autoreleasepool {
            NSData *dataToReturn = [[NSData alloc] initWithContentsOfFile:[fileURL path] options:NSDataReadingMappedIfSafe error:&readingError];
            
            if (dataToReturn) {
                block(dataToReturn);
            } else {
                if (readingError) {
                    //NSLog(@"%@", readingError);
                }
                block(nil);
            }
            
            dataToReturn = nil;
        }
    }
    else
    {
        block(nil);
    }
}


- (void)writeImageData:(NSData *)imageData toDiskForImageID:(NSString *)imageID WithCompletion:(void (^)(BOOL success, NSURL *fileURL, NSError *error))block
{
    if (imageID) {
        NSURL *url = [NSURL URLWithString:imageID relativeToURL:self.imageDataDirectory];
        NSString *path = [url path];
        
        if (path) {
            NSURL *fileURL = [NSURL fileURLWithPath:path isDirectory:NO];
            
            if (![imageData writeToFile:[fileURL path] atomically:YES]) {
                NSError *error = [NSError errorWithDomain:@"SVImageSaveError" code:000 userInfo:nil];
                block(NO, nil, error);
            } else {
                
				// Now that the image is saved create a thumb
                UIImage *originalImage = [UIImage imageWithContentsOfFile:[fileURL path]];
                
                CGSize newSize = CGSizeMake(200, 200);
                
                float oldWidth = originalImage.size.width;
                float scaleFactor = newSize.width / oldWidth;
                
                float newHeight = originalImage.size.height * scaleFactor;
                float newWidth = oldWidth * scaleFactor;
                
                UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
                [originalImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
                UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                [UIImageJPEGRepresentation(image, 0.5) writeToFile:[[fileURL path] stringByAppendingString:@"_thumbnail"] atomically:YES];
                
                block(YES, fileURL, nil);
            }
        }
        else
        {
            NSError *error = [NSError errorWithDomain:@"SVImageSaveError" code:000 userInfo:nil];
            block(NO, nil, error);
        }

    } else {
        NSError *error = [NSError errorWithDomain:@"SVImageSaveError" code:000 userInfo:nil];
        block(NO, nil, error);
    }
}

- (void)deletePhoto:(AlbumPhoto *)aPhoto {
	NSLog(@"Delete photo %@", aPhoto.photo_id);
	// Remove photo from disk first
	NSError *error = nil;
	NSURL *url = [_imageDataDirectory URLByAppendingPathComponent:aPhoto.photo_id];
	NSURL *url_thumb = [_imageDataDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@_thumbnail", aPhoto.photo_id]];
	
	[[NSFileManager defaultManager] removeItemAtURL:url error:&error];
	[[NSFileManager defaultManager] removeItemAtURL:url_thumb error:&error];
	
	NSManagedObjectContext *localContext = [NSManagedObjectContext defaultContext];
	AlbumPhoto *pp = [AlbumPhoto findFirstByAttribute:@"photo_id" withValue:aPhoto.photo_id inContext:localContext];
	NSLog(@"objectSyncStatus before: %@", pp.objectSyncStatus);
	[pp willChangeValueForKey:@"objectSyncStatus"];
	pp.objectSyncStatus = [NSNumber numberWithInt:SVObjectSyncDeleteNeeded];
	[pp didChangeValueForKey:@"objectSyncStatus"];
	
	error = nil;
	[localContext save:&error];
	
	if (error) {
		NSLog(@"error marking photo for deletion %@", error);
	}
	
	AlbumPhoto *ppp = [AlbumPhoto findFirstByAttribute:@"photo_id" withValue:aPhoto.photo_id inContext:localContext];
	NSLog(@"objectSyncStatus after: %@", ppp.objectSyncStatus);
	
//	return;
//	__block AlbumPhoto *p = aPhoto;
//	
//	[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
//		
//		AlbumPhoto *pp = [AlbumPhoto findFirstByAttribute:@"photo_id" withValue:p.photo_id inContext:localContext];
//		
//		[pp willChangeValueForKey:@"objectSyncStatus"];
//		pp.objectSyncStatus = [NSNumber numberWithInt:SVObjectSyncDeleteNeeded];
//		[pp didChangeValueForKey:@"objectSyncStatus"];
//		
//		[localContext save:nil];
//    }];
}

@end
