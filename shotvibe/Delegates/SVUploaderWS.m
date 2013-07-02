//
//  SVUploaderWS.m
//  shotvibe
//
//  Created by Peter Kasson on 6/22/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVUploaderWS.h"

#import "AlbumPhoto.h"
#import "SVUploaderOperationQueue.h"
#import "SVUploadOperation.h"
#import "SVBusinessDelegate.h"
#import "SVEntityStore.h"

@implementation SVUploaderWS



/*
 * look for photos to upload
 */
- (void) startSync
{
 /*NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"SVOperationQueue"];
 
 NSError *error;
 
 NSArray *objects = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:fetchRequest error:&error];
 
 SVUploaderOperationQueue *operationQueue = [objects objectAtIndex:0];
 
 NSSet *operations = operationQueue.operations;
 
 for(SVUploaderOperation *operation in operations)
 {
  Album *album;
  
  
  // TODO - get album from Album entity to start upload ...
  
  [self uploadPhoto:operation.photoId withAlbum:album];
 }*/
 
}


- (void)addPhoto:(NSString *)photoId withAlbumId:(NSNumber *)albumId
{
// SVOperationQueue *operationQueue = (SVOperationQueue *)[[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext objectWithID:loadedPhoto.objectID];

 SVUploaderOperationQueue *operationQueue = [NSEntityDescription insertNewObjectForEntityForName:@"SVOperationQueue" inManagedObjectContext:[NSManagedObjectContext defaultContext]];

 SVUploadOperation *operation = [NSEntityDescription insertNewObjectForEntityForName:@"SVOperation" inManagedObjectContext:[NSManagedObjectContext defaultContext]];

 operation.albumId = albumId;
 operation.photoId = photoId;
 
 operation.queue = operationQueue;

 [[NSManagedObjectContext defaultContext] save:nil];
}


/*
 * change the sync status for the photo
 */
- (void)changeStatusForPhoto:(NSString *)photoId withAlbumId:(NSNumber *)albumId toStatus:(NSNumber *) syncStatus
{
 NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"AlbumPhoto"];
 
 NSPredicate *predicate = [NSPredicate predicateWithFormat:@"albumId == %@ and tempPhotoId = %@", [albumId intValue], photoId];
 fetchRequest.predicate = predicate;
 
 NSError *error;
 
 NSArray *objects = [[NSManagedObjectContext defaultContext] executeFetchRequest:fetchRequest error:&error];
 
 AlbumPhoto *albumPhoto = [objects objectAtIndex:0];
 albumPhoto.objectSyncStatus = syncStatus;
 
 [[NSManagedObjectContext defaultContext] save:nil];
}



- (void)deletePhoto:(NSString *)photoId withAlbumId:(NSNumber *)albumId
{
 
 
}



/*
 * upload the photo
 */
- (void) uploadPhoto :(NSString *) photoId withAlbum :(Album *) album
{
 
 // TODO - the master queue and album queue needs work .. this is not complete
 
 
 
 NSOperationQueue *albumOperationQueue = [[NSOperationQueue alloc] init];
 [albumOperationQueue setMaxConcurrentOperationCount:1];                          // single thread photo uploads
 
 [albumOperationQueue addOperationWithBlock:^{
  
  // get photo as image data
  
  UIImageView *imageView;
  
  [SVBusinessDelegate loadImageFromAlbum:album withPath:photoId WithCompletion:^(UIImage *image, NSError *error) {
   if (image) {
    [imageView setImage:image];
   }
  }];
  
  NSData *imageData = UIImagePNGRepresentation(imageView.image);
  
  [[SVEntityStore sharedStore] uploadPhoto:photoId withImageData:imageData];
  
 }];

}





@end
