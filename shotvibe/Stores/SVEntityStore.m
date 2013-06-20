//
//  SVEntityStore.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/7/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "Album.h"
#import "AlbumPhoto.h"
#import "SVDefines.h"
#import "SVEntityStore.h"

static NSString * const kShotVibeAPIBaseURLString = @"https://api.shotvibe.com";

#ifdef CONFIGURATION_Debug
static NSString * const kTestAuthToken = @"Token 8d437481bdf626a9e9cd6fa2236d113eb1c9786d";
#elif CONFIGURATION_Adhoc
static NSString * const kTestAuthToken = @"Token 1d591bfa90ed6aee747a5009ccf6ef27246f6ae6";
#endif

@implementation SVEntityStore


NSMutableArray *project;



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
        
       // RKLogInfo(@"Load complete: Table should refresh with: %@", mappingResult.array);
     
     [[NSNotificationCenter defaultCenter] postNotificationName:kUserAlbumsLoadedNotification object:[self getUpdatedAlbums]];   // get etags
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        
        RKLogError(@"Load failed with error: %@", error);
        
    }];
}


- (void)photosForAlbumWithID:(NSNumber *)albumID
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
    NSString *path = [NSString stringWithFormat:@"/albums/%@/", [albumID stringValue]];
    [[RKObjectManager sharedManager] getObjectsAtPath:path parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        
        //RKLogInfo(@"Load complete: Table should refresh with: %@", mappingResult.array);
        [[NSNotificationCenter defaultCenter] postNotificationName:kPhotosLoadedNotification object:nil];
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        
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
 
    
    
    // If successful return the block
}



/*
 * get the latest album sync, compare to cached etags per album, use the diff between etags, to determine which albums to pull photos from
 */
- (NSMutableArray *) getUpdatedAlbums
{
 NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Album"];
 
 NSManagedObjectContext *managedObjectContext = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
 
 NSMutableArray *dbAlbums = [[NSMutableArray alloc] init];
 
 NSError *error;
 NSArray *array;
 
 @try
 {
  array = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
 }
 @catch (NSException *e)
 {
  NSLog(@"error:  %@", e);
 }
 
 for(Album *album in array)
 {
  [dbAlbums addObject:album];
 }
 
 return [self getAlbumETags :dbAlbums];
}


/*
 * get the etags for the albums (stored as a plist)
 */
- (NSMutableArray *) getAlbumETags :(NSMutableArray *) dbAlbums
{
 NSMutableArray *albumsUpdated = [[NSMutableArray alloc] init];
 
 project = [[NSMutableArray alloc] init];
 
 project = (NSMutableArray *)[project initWithContentsOfFile:[self getProjectFileNameAsPList:kApplicationName]];
 
 if(project == nil)                         // first time, presumably, just save the tags, and ALL albums need syncd
 {
  project = [[NSMutableArray alloc] init];
  
  for(Album *album in dbAlbums)
  {
   NSMutableDictionary *projectContents = [[NSMutableDictionary alloc] init];
   
   [projectContents setObject:album.albumId forKey:@"albumId"];
   [projectContents setObject:album.name forKey:@"albumName"];
   [projectContents setObject:album.etag forKey:@"etag"];
   [projectContents setObject:[[NSNumber alloc] initWithInt:[album.albumPhotos count]] forKey:@"count"];
   
   
   [project addObject:projectContents];             // this is saved to file system
   
   [albumsUpdated addObject:projectContents];       // this is returned
  }
 }
 else
 {
  BOOL albumFound = NO;
  
  NSMutableDictionary *albumWork;
  
  for(Album *album in dbAlbums)
  {
   for(albumWork in project)
   {
    albumFound = NO;
    
    //    NSLog(@"db -vs- dict:  %@ (%@), %@ (%@)", album.name, album.albumId, [albumWork objectForKey:@"albumName"], [albumWork objectForKey:@"albumId"]);
    
    if([album.albumId intValue] == [[albumWork objectForKey:@"albumId"]intValue] )
    {
     albumFound = YES;                   // if this is not set, as we have a match here, then this is a new album
     
     int albumETag     = [album.etag intValue];
     int albumWorkETag = [[albumWork objectForKey:@"etag"] intValue];
     
     //     NSLog(@"db -vs- dict:  %@ (%@), %@ (%@)", album.name, album.albumId, [albumWork objectForKey:@"albumName"], [albumWork objectForKey:@"albumId"]);
     //     NSLog(@"db.etag -vs- dict.etag:  %@, %@", album.etag, [albumWork objectForKey:@"etag"]);
     
     if(albumETag > albumWorkETag)        // this album has been updated, sync photos within
     {
      NSLog(@"etag has changed");
      
      [albumWork setObject:album.etag forKey:@"etag"];    // update file, with new etag
      [albumWork setObject:[[NSNumber alloc] initWithInt:[album.albumPhotos count]] forKey:@"count"];
      
      [albumsUpdated addObject:albumWork];            // this is returned to the synchronizer
      //      [albumsUpdated addObject:album.albumPhotos];    // as this is an existing album, only get the updated photos
     }
     
     break;
    }
   }
   
   if(!albumFound)                       // new album
   {
    NSMutableDictionary *newAlbum = [[NSMutableDictionary alloc] init];
    
    NSLog(@"new album:  %@", album.name);
    
    [newAlbum setObject:album.albumId forKey:@"albumId"];
    [newAlbum setObject:album.name forKey:@"albumName"];
    [newAlbum setObject:album.etag forKey:@"etag"];
    [newAlbum setObject:[[NSNumber alloc] initWithInt:[album.albumPhotos count]] forKey:@"count"];
    
    [albumsUpdated addObject:newAlbum];             // this is returned to the synchronizer, and is a new album, get all pictures
    //    [albumsUpdated addObject:album.albumPhotos];    // as this is an existing album, only get the updated photos
   }
  }
 }
 
 [project writeToFile:[self getProjectFileNameAsPList:kApplicationName] atomically:YES];
 
 return albumsUpdated;
}


/*
 * get the project file name, as a PList
 */
- (NSString *) getProjectFileNameAsPList :(NSString *) projectName
{
 NSLog(@"project:  %@", [@"" stringByAppendingFormat:@"%@%@.plist", [self getDocumentsDirectory], projectName]);
 
 return [@"" stringByAppendingFormat:@"%@%@.plist", [self getDocumentsDirectory], projectName];
}


/*
 * get the documents directory for the app / bundle
 */
- (NSString *) getDocumentsDirectory
{
 return [@"" stringByAppendingFormat:@"%@/%@/", NSHomeDirectory(), @"Documents"];
}


@end
