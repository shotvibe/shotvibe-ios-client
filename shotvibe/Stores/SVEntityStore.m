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
#import "AFJSONRequestOperation.h"
#import "SVDefines.h"
#import "SVEntityStore.h"
#import "SVBusinessDelegate.h"
#import "Member.h"

static NSString * const kShotVibeAPIBaseURLString = @"https://api.shotvibe.com";

#ifdef CONFIGURATION_Debug
static NSString * const kTestAuthToken = @"Token 8d437481bdf626a9e9cd6fa2236d113eb1c9786d";
#elif CONFIGURATION_Adhoc
static NSString * const kTestAuthToken = @"Token 1d591bfa90ed6aee747a5009ccf6ef27246f6ae6";
#endif

@interface SVEntityStore ()

@property (nonatomic, strong) NSOperationQueue *imageQueue;
@property (nonatomic, strong) NSURL *imageDataDirectory;

- (NSURL *)applicationDocumentsDirectory;

@end

@implementation SVEntityStore

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


#pragma mark - Private Methods

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


#pragma mark - FRC Methods

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


#pragma mark - Album Methods

- (void)setAllPhotosToHasViewedInAlbum:(Album *)anAlbum
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        Album *localAlbum = (Album *)[localContext objectWithID:anAlbum.objectID];
        
        NSArray *photos = [AlbumPhoto findAllWithPredicate:[NSPredicate predicateWithFormat:@"album.albumId == %@", localAlbum.albumId] inContext:localContext];
        
        for (AlbumPhoto *photo in photos) {
            [photo setHasViewed:[NSNumber numberWithBool:YES]];
        }
    }];
}


- (void)newAlbumWithName:(NSString *)albumName andUserID:(NSNumber *)userID
{    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        Album *localAlbum = [Album createInContext:localContext];
        
        // Create the first member too...
        Member *localMember = [Member createInContext:localContext];
        [localMember setUserId:userID];
        
        NSString *tempAlbumId = [[NSUUID UUID] UUIDString];
        
        [localAlbum setAlbumId:tempAlbumId];
        [localAlbum setTempAlbumId:tempAlbumId];
        [localAlbum setDate_created:[NSDate date]];
        [localAlbum setLast_updated:[NSDate date]];
        [localAlbum setName:albumName];
        [localAlbum setUrl:@""];
        [localAlbum setObjectSyncStatus:[NSNumber numberWithInteger:SVObjectSyncWaiting]];
        [localAlbum setEtag:@"0"];
        [localAlbum addMembersObject:localMember];

    }];
}


- (void)addPhotoWithID:(NSString *)photoId ToAlbumWithID:(NSString *)albumID WithCompletion:(void (^)(BOOL success, NSError *error))block
{
    Album *albumToAddPhotosTo = [Album findFirstByAttribute:@"albumId" withValue:albumID inContext:[NSManagedObjectContext defaultContext]];
    NSLog(@"The passed id is: %@", albumID);
    if (photoId && albumID) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            AlbumPhoto *localPhoto = [AlbumPhoto createInContext:localContext];
            Album *localAlbum = (Album *)[localContext objectWithID:albumToAddPhotosTo.objectID];
            
            [localPhoto setDate_created:[NSDate date]];
            [localPhoto setObjectSyncStatus:[NSNumber numberWithInteger:SVObjectSyncUploadNeeded]];
            [localPhoto setTempPhotoId:photoId];
            [localPhoto setPhoto_id:photoId];
            [localPhoto setImageWasDownloaded:[NSNumber numberWithBool:YES]];
            [localPhoto setPhoto_url:@""];
            
            [localAlbum addAlbumPhotosObject:localPhoto];
        } completion:^(BOOL success, NSError *error) {
            block(success, error);
        }];
    } else {
        NSLog(@"WE'VE LOST INTELLIGENCE SIR!! SO WE WON'T ADD ZOMBIE PHOTOS OK?");
    }
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
        
        NSMutableDictionary *confirmationCode = (NSMutableDictionary *)json;
        
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
    
    if (!self.imageQueue) {
        self.imageQueue = [[NSOperationQueue alloc] init];
    }
    
    __block AlbumPhoto *blockPhoto = (AlbumPhoto *)[[NSManagedObjectContext contextForCurrentThread] objectWithID:aPhoto.objectID];
    
    [self getImageDataForImageID:blockPhoto.photo_id WithCompletion:^(NSData *imageData) {
        if (imageData) {
            UIImage *image = [UIImage imageWithData:imageData];
            block(image);
            
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
                    }];
                    
                    UIImage *image = [UIImage imageWithData:data scale:0.25];
                    block(image);
                }
            }];
        }
    }];
}


- (void)getImageForPhotoData:(AlbumPhoto *)aPhoto WithCompletion:(void (^)(NSData *imageData, BOOL success))block
{
    if (!self.imageQueue) {
        self.imageQueue = [[NSOperationQueue alloc] init];
    }
    
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
                
                UIImage *originalImage = [UIImage imageWithContentsOfFile:[fileURL path]];
                
                CGSize newSize = CGSizeMake(100, 100);
                
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
@end
