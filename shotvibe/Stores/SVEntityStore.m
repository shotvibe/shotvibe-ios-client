//
//  SVEntityStore.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/7/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "Album.h"
#import "AlbumPhoto.h"
#import "AFHTTPRequestOperation.h"
#import "SVDefines.h"
#import "SVEntityStore.h"
#import "SVBusinessDelegate.h"

static NSString * const kShotVibeAPIBaseURLString = @"https://api.shotvibe.com";

#ifdef CONFIGURATION_Debug
static NSString * const kTestAuthToken = @"Token 8d437481bdf626a9e9cd6fa2236d113eb1c9786d";
#elif CONFIGURATION_Adhoc
static NSString * const kTestAuthToken = @"Token 1d591bfa90ed6aee747a5009ccf6ef27246f6ae6";
#endif

@interface SVEntityStore ()

- (NSURL *)applicationDocumentsDirectory;
- (NSURL *)imageDataDirectory;

@end

@implementation SVEntityStore

#pragma mark - Class Methods

+ (SVEntityStore *)sharedStore
{
    static SVEntityStore *entityStore = nil;
    static dispatch_once_t storeQueue;
    
    dispatch_once(&storeQueue, ^{
        entityStore = [[SVEntityStore alloc] initWithBaseURL:[NSURL URLWithString:kShotVibeAPIBaseURLString]];
        [entityStore setDefaultHeader:@"Authorization" value:kTestAuthToken];
        [entityStore setParameterEncoding:AFJSONParameterEncoding];
    });
    
    return entityStore;
}


#pragma mark - Instance Methods

- (NSFetchedResultsController *)allAlbumsForCurrentUserWithDelegate:(id)delegate
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Album"];
    NSSortDescriptor *lastUpdatedDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"last_updated" ascending:NO];
    
    fetchRequest.sortDescriptors = @[lastUpdatedDescriptor];
        
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[NSManagedObjectContext defaultContext] sectionNameKeyPath:nil cacheName:nil];
    fetchedResultsController.delegate = delegate;
    
    NSError *fetchError = nil;
    if (![fetchedResultsController performFetch:&fetchError]) {
        NSLog(@"There was an error fetching the results: %@", fetchError.userInfo);
    }
    
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
    
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[NSManagedObjectContext defaultContext] sectionNameKeyPath:nil cacheName:nil];
    fetchedResultsController.delegate = delegate;
    
    NSError *fetchError = nil;
    if (![fetchedResultsController performFetch:&fetchError]) {
        NSLog(@"There was an error fetching the results: %@", fetchError.userInfo);
    }
    
    return fetchedResultsController;
}


- (NSFetchedResultsController *)allPhotosForAlbum:(Album *)anAlbum WithDelegate:(id)delegate
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"AlbumPhoto"];
    NSSortDescriptor *datecreatedDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date_created" ascending:NO];
    NSSortDescriptor *idDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"photo_id" ascending:YES];
    
    fetchRequest.sortDescriptors = @[datecreatedDescriptor, idDescriptor];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"album == %@", anAlbum];
    fetchRequest.predicate = predicate;
    
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[NSManagedObjectContext defaultContext] sectionNameKeyPath:nil cacheName:nil];
    fetchedResultsController.delegate = delegate;
    
    NSError *fetchError = nil;
    if (![fetchedResultsController performFetch:&fetchError]) {
        NSLog(@"There was an error fetching the results: %@", fetchError.userInfo);
    }
    
    return fetchedResultsController;
}


- (void)photosForAlbumWithID:(NSNumber *)albumId
{
    // TODO: Return all photos for the album with the supplied ID
}


- (void)newAlbumWithName:(NSString *)albumName
{
    // TODO: Add a new album with the supplied name
}


- (void)addPhotoWithID:(NSString *)photoId ToAlbumWithID:(NSNumber *)albumID WithCompletion:(void (^)(BOOL success, NSError *error))block
{
    NSManagedObjectContext *localContext = [NSManagedObjectContext defaultContext]; //TODO
    
    AlbumPhoto *localPhoto = [NSEntityDescription insertNewObjectForEntityForName:@"AlbumPhoto" inManagedObjectContext:localContext];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Album"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"albumId = %@", albumID];
    fetchRequest.predicate = predicate;
    Album *localAlbum = (Album *)[[localContext executeFetchRequest:fetchRequest error:nil] lastObject];
    
    [localPhoto setDate_created:[NSDate date]];
    [localPhoto setObjectSyncStatus:[NSNumber numberWithInteger:SVObjectSyncNeeded]];
    [localPhoto setTempPhotoId:photoId];
    [localPhoto setPhoto_id:photoId];
    [localPhoto setImageWasDownloaded:[NSNumber numberWithBool:YES]];
    [localPhoto setPhoto_url:@""];
    
    [localAlbum addAlbumPhotosObject:localPhoto];
    
    NSError *saveError = nil;
    [localContext save:&saveError];
    
    if (saveError) {
        if (block) {
            block(NO, saveError);
        }
    }
    else
    {
        if (block) {
            block(YES, nil);
        }
    }
}


/*
 * register the users phone number (and they will get a confirmation code)
 */
- (void) registerPhoneNumber:(NSString *) phoneNumber withCountryCode:(NSString *) countryCode WithCompletion:(void (^)(BOOL success, NSString *confirmationCode, NSError *error))block
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


/*
 * register the users phone number (and they will get a confirmation code)
 */
- (void) validateRegistrationCode:(NSString *) registrationCode withConfirmationCode:(NSString *) confirmationCode WithCompletion:(void (^)(BOOL success, NSString *authToken, NSString *userId, NSError *error))block
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


/*
 * upload a photo
 */
-(void) uploadPhoto :(NSString *) photoId withImageData:(NSData *) imageData
{
    NSMutableArray *requestOperationBatch = [NSMutableArray arrayWithCapacity:1];
 
    NSString *uploadPath = [NSString stringWithFormat:@"/photos/upload/%@/", photoId];
    
    NSMutableURLRequest *request =
    [self multipartFormRequestWithMethod:@"POST" path:uploadPath parameters:nil constructingBodyWithBlock: ^(id <AFMultipartFormData>formData)
     {
         [formData appendPartWithFileData:imageData name:@"photo" fileName:@"temp.jpeg" mimeType:@"image/jpeg"];
     }
     ];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    [requestOperationBatch addObject:operation];
    
    
    // Enque the upload batch
    [self enqueueBatchOfHTTPRequestOperations:requestOperationBatch progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations)
     {
         
         //TODO: We need to send some progress notifications
         //  CGFloat uploadProgress = numberOfFinishedOperations / totalNumberOfOperations;
         //  [[NSNotificationCenter defaultCenter] postNotificationName:kUploadPhotosToAlbumProgressNotification object:[NSNumber numberWithFloat:uploadProgress]];
         //  if (uploadProgress >= 1.0)
         //  {
         //   block(YES, nil);
         //  }
         
     }
     
                              completionBlock:^(NSArray *operations)
     {
         
     }];
}


- (void)getImageForPhoto:(AlbumPhoto *)aPhoto WithCompletion:(void (^)(UIImage *))block
{
    __block AlbumPhoto *blockPhoto = aPhoto;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSURL *photoURL = [SVBusinessDelegate getURLForPhoto:blockPhoto];
        
        if (photoURL) {
            NSURLRequest *request = [NSURLRequest requestWithURL:photoURL];
            NSURLResponse *response = nil;
            NSError *error = nil;
            NSData *dataResponse = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            
            if (dataResponse) {
                
                [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                    
                    AlbumPhoto *localPhoto = (AlbumPhoto *)[localContext objectWithID:blockPhoto.objectID];
                    
                    [localPhoto setPhotoData:dataResponse];
                    
                } completion:^(BOOL success, NSError *error) {
                    UIImage *image = [UIImage imageWithData:dataResponse scale:0.25];
                    block(image);
                }];
            }
        }
        else
        {
            block(nil);
        }


    });
}


- (void)getImageDataForImageID:(NSString *)imageID WithCompletion:(void (^)(NSData *imageData))block
{
    NSURL *fileURL = [NSURL URLWithString:imageID relativeToURL:[self imageDataDirectory]];
    NSData *dataToReturn = [NSData dataWithContentsOfURL:fileURL];
    
    if (dataToReturn) {
        block(dataToReturn);
    } else {
        block(nil);
    }
}


- (void)writeImageData:(NSData *)imageData toDiskForImageID:(NSString *)imageID WithCompletion:(void (^)(BOOL success, NSURL *fileURL, NSError *error))block
{
    NSURL *fileURL = [NSURL URLWithString:imageID relativeToURL:[self imageDataDirectory]];
        
    if (![imageData writeToFile:[fileURL path] atomically:YES]) {
        NSError *error = [NSError errorWithDomain:@"SVImageSaveError" code:000 userInfo:nil];
        block(NO, nil, error);
    } else {
        block(YES, fileURL, nil);
    }
}


#pragma mark - Private Methods

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


- (NSURL *)imageDataDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *url = [NSURL URLWithString:@"SVImages/" relativeToURL:[self applicationDocumentsDirectory]];
    NSError *error = nil;
    if (![fileManager fileExistsAtPath:[url path]]) {
        [fileManager createDirectoryAtPath:[url path] withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    NSError *attributeError = nil;
    BOOL success = [url setResourceValue: [NSNumber numberWithBool: YES] forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
        NSLog(@"Error excluding %@ from backup %@", [url lastPathComponent], attributeError);
    }
    
    return url;
}
@end
