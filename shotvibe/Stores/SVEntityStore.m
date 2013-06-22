//
//  SVEntityStore.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/7/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "Album.h"
#import "AlbumPhoto.h"
#import "Photo.h"
#import "SVDefines.h"
#import "SVEntityStore.h"
#import "SVBusinessDelegate.h"
#import "SyncEngine.h"

static NSString * const kShotVibeAPIBaseURLString = @"https://api.shotvibe.com";

#ifdef CONFIGURATION_Debug
static NSString * const kTestAuthToken = @"Token 8d437481bdf626a9e9cd6fa2236d113eb1c9786d";
#elif CONFIGURATION_Adhoc
static NSString * const kTestAuthToken = @"Token 1d591bfa90ed6aee747a5009ccf6ef27246f6ae6";
#endif



@implementation SVEntityStore


//NSMutableArray *project;


int callCount = 0;


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

- (void)userAlbums
{
    NSLog(@"userAlbums - start sync from remote");
 
    callCount++;
 
    if(callCount > 1)
    {
     NSLog(@"can only call userAlbums once");
     
     return;
    }
 
    // Setup Member Mapping
    RKEntityMapping *memberMapping = [RKEntityMapping mappingForEntityForName:@"Member" inManagedObjectStore:[RKObjectManager sharedManager].managedObjectStore];
    [memberMapping addAttributeMappingsFromDictionary:@{
     @"id": @"userId",
     @"url": @"url",
     @"nickname": @"nickname",
     @"avatar_url": @"avatarUrl"
     }];
    memberMapping.identificationAttributes = @[@"userId"];
    
    // Setup Photo Mapping
    RKEntityMapping *photoMapping = [RKEntityMapping mappingForEntityForName:@"AlbumPhoto" inManagedObjectStore:[RKObjectManager sharedManager].managedObjectStore];
    [photoMapping addAttributeMappingsFromDictionary:@{
     @"photo_id": @"photoId",
     @"photo_url": @"photoUrl",
     @"date_created": @"dateCreated",
     }];
    photoMapping.identificationAttributes = @[@"photoId"];
    
    // Setup Album Mapping
    RKEntityMapping *albumMapping = [RKEntityMapping mappingForEntityForName:@"Album" inManagedObjectStore:[RKObjectManager sharedManager].managedObjectStore];
    [albumMapping addAttributeMappingsFromDictionary:@{
     @"id": @"albumId",
     @"url": @"url",
     @"name": @"name",
     @"last_updated": @"lastUpdated",
     @"etag": @"etag"
     }];
    albumMapping.identificationAttributes = @[@"albumId"];
    
    // Relationship Connections
    [photoMapping addRelationshipMappingWithSourceKeyPath:@"author" mapping:memberMapping];
    [photoMapping addRelationshipMappingWithSourceKeyPath:@"album" mapping:albumMapping];
    [albumMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"latest_photos" toKeyPath:@"albumPhotos" withMapping:photoMapping]];
    
    // Configure the response descriptor
    RKResponseDescriptor *albumResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:albumMapping pathPattern:@"/albums/" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    [[RKObjectManager sharedManager] addResponseDescriptor:albumResponseDescriptor];
    
    // Get the albums
    [[RKObjectManager sharedManager] getObjectsAtPath:@"/albums/" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kUserAlbumsLoadedNotification object:nil];   // get etags
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        
        NSLog(@"error");
        
        RKLogError(@"Load failed with error: %@", error);
        
    }];
}


- (void)photosForAlbumWithID:(NSNumber *)albumId
{
    // Setup Photo Mapping
    RKEntityMapping *photoMapping = [RKEntityMapping mappingForEntityForName:@"Photo" inManagedObjectStore:[RKObjectManager sharedManager].managedObjectStore];
    [photoMapping addAttributeMappingsFromDictionary:@{
     @"photo_id": @"photoId",
     @"photo_url": @"photoUrl",
     @"date_created": @"dateCreated",
     }];
    photoMapping.identificationAttributes = @[@"photoId"];
    
    // Setup Member Mapping
    RKEntityMapping *memberMapping = [RKEntityMapping mappingForEntityForName:@"Member" inManagedObjectStore:[RKObjectManager sharedManager].managedObjectStore];
    [memberMapping addAttributeMappingsFromDictionary:@{
     @"id": @"userId",
     @"url": @"url",
     @"nickname": @"nickname",
     @"avatar_url": @"avatarUrl"
     }];
    memberMapping.identificationAttributes = @[@"userId"];
    
    // Setup Album Mapping
    RKEntityMapping *albumMapping = [RKEntityMapping mappingForEntityForName:@"Album" inManagedObjectStore:[RKObjectManager sharedManager].managedObjectStore];
    [albumMapping addAttributeMappingsFromDictionary:@{
     @"id": @"albumId",
     @"name": @"name",
     @"date_created": @"dateCreated",
     @"last_updated": @"lastUpdated"
     }];
    albumMapping.identificationAttributes = @[@"albumId"];
    
    // Relationship Connections
    [photoMapping addRelationshipMappingWithSourceKeyPath:@"author" mapping:memberMapping];
    [photoMapping addRelationshipMappingWithSourceKeyPath:@"album" mapping:albumMapping];
    [albumMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"photos" toKeyPath:@"photos" withMapping:photoMapping]];
    [memberMapping addRelationshipMappingWithSourceKeyPath:@"albums" mapping:albumMapping];
    [albumMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"members" toKeyPath:@"members" withMapping:memberMapping]];
    
    // Configure the response descriptor
    RKResponseDescriptor *albumResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:albumMapping pathPattern:@"/albums/:id/" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    [[RKObjectManager sharedManager] addResponseDescriptor:albumResponseDescriptor];
    
    // Get the albums
    NSString *path = [NSString stringWithFormat:@"/albums/%@/", [albumId stringValue]];
    [[RKObjectManager sharedManager] getObjectsAtPath:path parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        
        //RKLogInfo(@"Load complete: Table should refresh with: %@", mappingResult.array);
     
     NSLog(@"notify for photos, album:  %@", albumId);
     
    [[NSNotificationCenter defaultCenter] postNotificationName:kPhotosLoadedNotification object:albumId];
     
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {

     NSLog(@"error for photos, album:  %@", albumId);

        RKLogError(@"Load failed with error: %@", error);
        
    }];
}


// Album *anAlbum

// - (void)photosForAlbumWithID:(NSNumber *)albumID atIndexPath:(NSIndexPath *)indexPath
- (void)photosForAlbumWithID:(Album *) anAlbum atIndexPath:(NSIndexPath *)indexPath
{
    
    NSNumber *albumID = anAlbum.albumId;
    
    // Setup Photo Mapping
    RKEntityMapping *photoMapping = [RKEntityMapping mappingForEntityForName:@"Photo" inManagedObjectStore:[RKObjectManager sharedManager].managedObjectStore];
    [photoMapping addAttributeMappingsFromDictionary:@{
     @"photo_id": @"photoId",
     @"photo_url": @"photoUrl",
     @"date_created": @"dateCreated",
     }];
    photoMapping.identificationAttributes = @[@"photoId"];
    
    // Setup Member Mapping
    RKEntityMapping *memberMapping = [RKEntityMapping mappingForEntityForName:@"Member" inManagedObjectStore:[RKObjectManager sharedManager].managedObjectStore];
    [memberMapping addAttributeMappingsFromDictionary:@{
     @"id": @"userId",
     @"url": @"url",
     @"nickname": @"nickname",
     @"avatar_url": @"avatarUrl"
     }];
    memberMapping.identificationAttributes = @[@"userId"];
    
    // Setup Album Mapping
    RKEntityMapping *albumMapping = [RKEntityMapping mappingForEntityForName:@"Album" inManagedObjectStore:[RKObjectManager sharedManager].managedObjectStore];
    [albumMapping addAttributeMappingsFromDictionary:@{
     @"id": @"albumId",
     @"name": @"name",
     @"date_created": @"dateCreated",
     @"last_updated": @"lastUpdated"
     }];
    albumMapping.identificationAttributes = @[@"albumId"];
    
    // Relationship Connections
    [photoMapping addRelationshipMappingWithSourceKeyPath:@"author" mapping:memberMapping];
    [photoMapping addRelationshipMappingWithSourceKeyPath:@"album" mapping:albumMapping];
    [albumMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"photos" toKeyPath:@"photos" withMapping:photoMapping]];
    [memberMapping addRelationshipMappingWithSourceKeyPath:@"albums" mapping:albumMapping];
    [albumMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"members" toKeyPath:@"members" withMapping:memberMapping]];
    
    // Configure the response descriptor
    RKResponseDescriptor *albumResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:albumMapping pathPattern:@"/albums/:id/" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    [[RKObjectManager sharedManager] addResponseDescriptor:albumResponseDescriptor];
    
    // Get the albums
    NSString *path = [NSString stringWithFormat:@"/albums/%@/", [albumID stringValue]];
    [[RKObjectManager sharedManager] getObjectsAtPath:path parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        
        NSMutableArray *data = [[NSMutableArray alloc] init];
        
        [data addObject:indexPath];
        [data addObject:anAlbum];
        
        //RKLogInfo(@"Load complete: Table should refresh with: %@", mappingResult.array);
        [[NSNotificationCenter defaultCenter] postNotificationName:kPhotosLoadedForIndexPathNotification object:data];
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        
        RKLogError(@"Load failed with error: %@", error);
        
    }];
}


- (void)newAlbumWithName:(NSString *)albumName
{
    // Setup Member Mapping
    RKEntityMapping *memberMapping = [RKEntityMapping mappingForEntityForName:@"Member" inManagedObjectStore:[RKObjectManager sharedManager].managedObjectStore];
    [memberMapping addAttributeMappingsFromDictionary:@{
     @"id": @"userId",
     @"url": @"url",
     @"nickname": @"nickname",
     @"avatar_url": @"avatarUrl"
     }];
    memberMapping.identificationAttributes = @[@"userId"];
    
    // Setup Photo Mapping
    RKEntityMapping *photoMapping = [RKEntityMapping mappingForEntityForName:@"AlbumPhoto" inManagedObjectStore:[RKObjectManager sharedManager].managedObjectStore];
    [photoMapping addAttributeMappingsFromDictionary:@{
     @"photo_id": @"photoId",
     @"photo_url": @"photoUrl",
     @"date_created": @"dateCreated",
     }];
    photoMapping.identificationAttributes = @[@"photoId"];
    
    // Setup Album Mapping
    RKEntityMapping *albumMapping = [RKEntityMapping mappingForEntityForName:@"Album" inManagedObjectStore:[RKObjectManager sharedManager].managedObjectStore];
    [albumMapping addAttributeMappingsFromDictionary:@{
     @"id": @"albumId",
     @"url": @"url",
     @"name": @"name",
     @"last_updated": @"lastUpdated",
     @"etag": @"etag"
     }];
    albumMapping.identificationAttributes = @[@"albumId"];
    
    // Relationship Connections
    [photoMapping addRelationshipMappingWithSourceKeyPath:@"author" mapping:memberMapping];
    [photoMapping addRelationshipMappingWithSourceKeyPath:@"album" mapping:albumMapping];
    [albumMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"latest_photos" toKeyPath:@"albumPhotos" withMapping:photoMapping]];
    
    // Configure the response descriptor
    RKResponseDescriptor *albumResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:albumMapping pathPattern:@"/albums/" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    [[RKObjectManager sharedManager] addResponseDescriptor:albumResponseDescriptor];
    
    // Post the albums
    [[RKObjectManager sharedManager] postObject:nil path:@"/albums/" parameters:@{@"album_name": albumName, @"photos": [NSNull null], @"members": [NSNull null]} success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        
        [[SVEntityStore sharedStore] userAlbums];
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        
        RKLogError(@"Load failed with error: %@", error);
        
    }];
}


- (void)addPhotos:(NSArray *)photos ToAlbumWithID:(NSNumber *)albumID WithCompletion:(void (^)(BOOL success, NSError *error))block
{
 // Generate an upload photos request using: POST /photos/upload_request/?num_photos={n}
 NSString *path = [NSString stringWithFormat:@"/photos/upload_request/?num_photos=%d", photos.count];
 [self postPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
  
  // You have to serialize the response object first!
  NSData *responseData = (NSData *)responseObject;
  
  id json = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
  
  
  NSArray *uploadRequestData = (NSArray *)json;
  NSMutableArray *requestOperationBatch = [NSMutableArray arrayWithCapacity:uploadRequestData.count];
  NSMutableArray *photoIds = [NSMutableArray arrayWithCapacity:uploadRequestData.count];
  for (NSInteger index = 0; index < uploadRequestData.count; index++) {
   
   // Given API Response, add photos to album using: POST /albums/{aid}/
   NSDictionary *uploadRequest = [uploadRequestData objectAtIndex:index];
   NSString *photoId = [uploadRequest objectForKey:@"photo_id"];
   [photoIds addObject:@{@"photo_id": photoId}];
   
   NSData *imageToUpload = [photos objectAtIndex:index];
   NSString *uploadPath = [NSString stringWithFormat:@"/photos/upload/%@/", photoId];
   NSMutableURLRequest *request = [self multipartFormRequestWithMethod:@"POST" path:uploadPath parameters:nil constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
    [formData appendPartWithFileData:imageToUpload name:@"photo" fileName:@"temp.jpeg" mimeType:@"image/jpeg"];
   }];
   
   AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
   [requestOperationBatch addObject:operation];
   
  }
  
  // Enque the upload batch
  [self enqueueBatchOfHTTPRequestOperations:requestOperationBatch progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
   
   //TODO: We need to send some progress notifications
   CGFloat uploadProgress = numberOfFinishedOperations / totalNumberOfOperations;
   [[NSNotificationCenter defaultCenter] postNotificationName:kUploadPhotosToAlbumProgressNotification object:[NSNumber numberWithFloat:uploadProgress]];
   
   if (uploadProgress >= 1.0) {
    block(YES, nil);
   }
   
  } completionBlock:^(NSArray *operations) {
   
   // Add the photos to the album
   NSString *addToAlbumPath = [NSString stringWithFormat:@"/albums/%@/", [albumID stringValue]];
   
   NSLog(@"%@", [@{@"add_photos": photoIds} description]);
   
   [self postPath:addToAlbumPath parameters:@{@"add_photos": photoIds} success:^(AFHTTPRequestOperation *operation, id responseObject) {
    
    [[SVEntityStore sharedStore] userAlbums];
    
   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    
    block(NO, error);
    
   }];
   
  }];
  
 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
  
  block(NO, error);
  
 }];
 
 
 // If successful return the block ... not any more
}


/*
 * save the photo to DB so it will appear in the album ... this is a temporary store until the actual photo id can be retreived
 */
-(void)newUploadedPhotoForAlbum:(Album *) album withPhotoId:(NSString *) photoId
{
 Album *albumObject = (Album *)[[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext objectWithID:album.objectID];
 
 NSLog(@"saving temp photo to album: %@, %@", photoId, album.name);
 
// AlbumPhoto *albumPhoto = (AlbumPhoto *)[[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext 

 if(albumObject != nil)
 {
  NSMutableSet *newAlbumPhotos = [[NSMutableSet alloc] initWithSet:albumObject.albumPhotos];
  
  AlbumPhoto *albumPhoto = [NSEntityDescription insertNewObjectForEntityForName:@"AlbumPhoto" inManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext];
  
  albumPhoto.album = albumObject;
//  albumPhoto.albumId = albumObject.albumId;
//  albumPhoto.author = [[NSNumber alloc] initWithInt:1];
//  albumPhoto.hasViewed = [[NSNumber alloc] initWithInt:0];
  albumPhoto.photoId = photoId;
  albumPhoto.photoUrl = @"n/a";
  albumPhoto.dateCreated = [NSDate date];
  
  [newAlbumPhotos addObject:albumPhoto];
  
  NSError *error;
  
  [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext saveToPersistentStore:&error];
  
  
  if(error)
  {
   NSLog(@"error saving temp photo:  %@", error);
  }
  else
  {
   NSLog(@"temp photo saved successfully");

  }
   
 }
 
}



@end
