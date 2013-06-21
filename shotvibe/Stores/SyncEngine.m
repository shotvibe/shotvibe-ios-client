//
//  SyncEngine.m
//  shotvibe
//
//  Created by Peter Kasson on 6/18/13.
//
//  Parts taken from IFSyncEngine (Fred G.)
//
//  Copyright (c) 2013 Appiphany, Inc. All rights reserved.
//

#import "SVDefines.h"
#import "SyncEngine.h"
#import "SVEntityStore.h"
#import "SVBusinessDelegate.h"
#import "Album.h"
#import "AlbumPhoto.h"

@interface SyncEngine ()

@property (nonatomic, strong) __block NSManagedObjectContext *syncContext;
@property (nonatomic, strong) NSMutableArray *registeredClassesToSync;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (atomic, readonly) BOOL syncInProgress;
@property (nonatomic, strong) NSOperationQueue *parseSyncQueue;

@property (nonatomic, strong) NSOperationQueue *globalDownloadQueue;
@property (nonatomic, strong) NSMutableArray *project;

@end

@implementation SyncEngine

#pragma mark - Class Methods

+ (SyncEngine *)sharedEngine
{
 static SyncEngine *sharedEngine = nil;
 static dispatch_once_t engineToken;
 dispatch_once(&engineToken, ^{
  sharedEngine = [[SyncEngine alloc] init];
 });
 
 return sharedEngine;
}


#pragma mark - Instance Methods

- (void)registerNSManagedObjectClassToSync:(Class)aClass
{
 if (!self.registeredClassesToSync) {
  self.registeredClassesToSync = [NSMutableArray array];
 }
 
 if ([aClass isSubclassOfClass:[NSManagedObject class]]) {
  if (![self.registeredClassesToSync containsObject:NSStringFromClass(aClass)]) {
   [self.registeredClassesToSync addObject:NSStringFromClass(aClass)];
  } else {
   NSLog(@"Unable to register %@ as it is already registered", NSStringFromClass(aClass));
  }
 } else {
  NSLog(@"Unable to register %@ as it is not a subclass of NSManagedObject", NSStringFromClass(aClass));
 }
}


/*
 * sync - retrieve albums and photos
 */
- (void)startSync
{
 NSLog(@"start sync");
 
 if (!self.syncInProgress)
 {
  [self willChangeValueForKey:@"syncInProgress"];
 
  _syncInProgress = YES;
  
  [self didChangeValueForKey:@"syncInProgress"];
  
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

   [[SVEntityStore sharedStore] userAlbums];
   
//   [[SyncEngine sharedEngine] setInitialSyncCompleted];
   
   [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
   
  });
 }
}


#pragma mark - Private Methods


/*
 * sync albums with all/latest photos
 */
- (void) syncAlbums
{
 //
 // 20130619 - download all photos (thumbnails) for an album.  this provides the user with a better UX as the photos
 //            will be on the device after the initial launch, and any updates.  the initial load will take time depending
 //            on the number of photos
 //
 
 
 // 20130621 - changed to using NSOperationQueue - allows pausing of all worker threads more easily as well as stopping them
 //            if a memory issue occurs
 
 
 NSArray *albums = [self getAlbums];
 
 
 // make sure that for 1st time, get all, for 2nd time, only get updated or new albums, and then only those with new photos
 /// checking the etag
 
 
 BOOL photoExists = NO;
 
 for(Album *album in albums)
 {
  NSLog(@"album:  %@", album.name);
  
  for(AlbumPhoto *photo in album.albumPhotos)
  {
   //   NSLog(@"  photo:  %@", photo.photoId);
   
   photoExists = [SVBusinessDelegate doesPhotoExist:album.name :photo.photoId];
   
   if(!photoExists)
   {
    NSLog(@"photo DNE, downloading photo:  %@, %@", album.name, photo.photoId);
    
    if (self.globalDownloadQueue == nil)
    {
     self.globalDownloadQueue = [[NSOperationQueue alloc] init];
    }
    
    
    // set maximum operations possible
    //    [globalDownloadQueue setMaxConcurrentOperationCount:2];
    
    
    NSMutableArray *data = [[NSMutableArray alloc] init];
    
    [data addObject:album.name];
    [data addObject:photo];
    
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(downloadPhoto:) object:data];
    
    [operation setCompletionBlock:^
     {
      NSLog(@"NSOperation has finished downloading:  %@, %@", album.name, photo.photoId);
     }];
    
    
    [self.globalDownloadQueue addOperation:operation];
   }
  }
 }
}


/*
 * do the actual photo download
 */
- (void) downloadPhoto :(NSArray *) data
{
 NSString *albumName = [data objectAtIndex:0];
 AlbumPhoto *photo   = [data objectAtIndex:1];
 
 dispatch_async(dispatch_get_global_queue(0,0), ^{
  
  NSData * imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: photo.photoUrl]];
  UIImage *image = [UIImage imageWithData: imageData];
  
  if ( image == nil )
   return;
  
  NSLog(@"photo downloaded:  %@", photo.photoId);
  
  [SVBusinessDelegate saveImageAlbumPhoto:image forPhoto:photo :albumName];
 });
 
}


/*
 * get the latest album sync, compare to cached etags per album, use the diff between etags, to determine which albums to pull photos from
 */
- (NSArray *) getAlbums
{
 NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Album"];
 
 NSManagedObjectContext *managedObjectContext = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
 
 
 NSError *error;
 NSArray *array;
 NSMutableArray *updatedArray = [[NSMutableArray alloc] init];
 
 @try
 {
  array = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
 }
 @catch (NSException *e)
 {
  NSLog(@"error:  %@", e);
 }
 
 
 // find updates, via the etag changes ... this may not be the best approach, so removing for now
 // NSMutableArray *etagAlbums = [self getAlbumETags :array];
 //
 // for(NSArray *etagUpdates in etagAlbums)
 // {
 //  NSMutableDictionary *albumDetails = [etagUpdates objectAtIndex:0];
 //
 //  NSString *albumName = [albumDetails objectForKey:@"albumName"];
 //
 //  for(Album *album in array)
 //  {
 //   if([album.name isEqualToString:albumName])
 //   {
 //    [updatedArray addObject:album];
 //
 //    break;
 //   }
 //  }
 // }
 //
 // return updatedArray;
 
 return array;
}


/*
 * get the etags for the albums (stored as a plist)
 */
- (NSMutableArray *) getAlbumETags :(NSArray *) dbAlbums
{
 NSMutableArray *albumsUpdated = [[NSMutableArray alloc] init];
 
 self.project = [[NSMutableArray alloc] init];
 
 self.project = (NSMutableArray *)[self.project initWithContentsOfFile:[self getProjectFileNameAsPList:kApplicationName]];
 
 if(self.project == nil)                         // first time, presumably, just save the tags, and ALL albums need syncd
 {
  self.project = [[NSMutableArray alloc] init];
  
  for(Album *album in dbAlbums)
  {
   NSMutableDictionary *projectContents = [[NSMutableDictionary alloc] init];
   
   [projectContents setObject:album.albumId forKey:@"albumId"];
   [projectContents setObject:album.name forKey:@"albumName"];
   [projectContents setObject:album.etag forKey:@"etag"];
   [projectContents setObject:[[NSNumber alloc] initWithInt:[album.albumPhotos count]] forKey:@"count"];
   
   
   [self.project addObject:projectContents];             // this is saved to file system
   
   [albumsUpdated addObject:projectContents];       // this is returned
  }
 }
 else
 {
  BOOL albumFound = NO;
  
  NSMutableDictionary *albumWork;
  
  for(Album *album in dbAlbums)
  {
   for(albumWork in self.project)
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
 
 [self.project writeToFile:[self getProjectFileNameAsPList:kApplicationName] atomically:YES];
 
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



- (void)executeSyncCompletedOperations
{
 dispatch_async(dispatch_get_main_queue(), ^{
  [self setInitialSyncCompleted];
  [[NSNotificationCenter defaultCenter] postNotificationName:kSDSyncEngineSyncCompletedNotificationName object:nil];
  
  [self willChangeValueForKey:@"syncInProgress"];
  _syncInProgress = NO;
  [self didChangeValueForKey:@"syncInProgress"];
  
  //        [[IFSyncPollingBD sharedDelegate] startPolling];
 });
}


- (BOOL)initialSyncComplete
{
 BOOL boolToReturn = [[[NSUserDefaults standardUserDefaults] valueForKey:kSDSyncEngineInitialCompleteKey] boolValue];
 return boolToReturn;
}


- (void)setInitialSyncCompleted
{
 [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:kSDSyncEngineInitialCompleteKey];
 [[NSUserDefaults standardUserDefaults] synchronize];
}




#pragma mark - Date Handling

- (void)initializeDateFormatter
{
 if (!self.dateFormatter) {
  self.dateFormatter = [[NSDateFormatter alloc] init];
  [self.dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
  [self.dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
 }
}


#pragma mark - Memory Management

- (void)dealloc
{
 [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
