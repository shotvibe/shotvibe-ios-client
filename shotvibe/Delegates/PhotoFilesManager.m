//
//  PhotoFilesManager.m
//  shotvibe
//
//  Created by benny on 10/30/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "PhotoFilesManager.h"
#import "PhotoView.h"
#import "PhotoSize.h"
#import "FileUtils.h"


@interface PhotoLoadObserver : NSObject

- (id)initWithPhotoSize:(PhotoSize *)photoSize observer:(PhotoView *)observer;

@property (nonatomic, readonly, strong) PhotoSize *photoSize;
@property (nonatomic, readonly, weak) PhotoView *weakObserver;

@end

@implementation PhotoLoadObserver

- (id)initWithPhotoSize:(PhotoSize *)photoSize observer:(PhotoView *)observer
{
    self = [super init];

    if (self) {
        _photoSize = photoSize;
        _weakObserver = observer;
    }

    return self;
}

@end

// This is thread-safe as it is a thin wrapper around thread-safe NSCache
@interface PhotoImageCache : NSObject

- (id)init;

- (void)setPhotoImage:(NSString *)photoId photoSize:(PhotoSize *)photoSize image:(UIImage *)image;

// Returns nil if image is not available in the cache
- (UIImage *)getPhotoImage:(NSString *)photoId photoSize:(PhotoSize *)photoSize;

@end

@implementation PhotoImageCache
{
    // Both caches are dictionaries from `NSString` objects to `UIImage` objects.
    //
    // The `NSString` key is in the format "<photo_id>_<photo_size>"

    NSCache *thumbnailCache_;
    NSCache *largeImageCache_;
}

- (id)init
{
    self = [super init];

    if (self) {
        thumbnailCache_ = [[NSCache alloc] init];
        largeImageCache_ = [[NSCache alloc] init];
    }

    return self;
}

+ (NSString *)makeKey:(NSString *)photoId photoSize:(PhotoSize *)photoSize
{
    return [[photoId stringByAppendingString:@"_"] stringByAppendingString:photoSize.extension];
}

// An approximate estimation of the size in bytes that an image occupies in memory
+ (NSUInteger)imageCost:(UIImage *)image
{
    int w = image.size.width * image.scale;
    int h = image.size.height * image.scale;

    const int BYTES_PER_PIXEL = 4;

    return w * h * BYTES_PER_PIXEL;
}

- (void)setPhotoImage:(NSString *)photoId photoSize:(PhotoSize *)photoSize image:(UIImage *)image
{
    NSString *key = [PhotoImageCache makeKey:photoId photoSize:photoSize];
    NSUInteger imageCost = [PhotoImageCache imageCost:image];

    if (photoSize == [PhotoSize Thumb75]) {
        [thumbnailCache_ setObject:image forKey:key cost:imageCost];
    }
    else {
        [largeImageCache_ setObject:image forKey:key cost:imageCost];
    }
}

- (UIImage *)getPhotoImage:(NSString *)photoId photoSize:(PhotoSize *)photoSize
{
    NSString *key = [PhotoImageCache makeKey:photoId photoSize:photoSize];

    if (photoSize == [PhotoSize Thumb75]) {
        UIImage *img = [thumbnailCache_ objectForKey:key];
        if (img) {
            return img;
        }
    }
    else {
        UIImage *img = [largeImageCache_ objectForKey:key];
        if (img) {
            return img;
        }
    }

    // Image not found in any of the caches
    return nil;
}

@end

@interface PhotoJob : NSObject

// photoUrl may be nil if it is not needed
- (id)initWithPhotoId:(NSString *)photoId photoSize:(PhotoSize *)photoSize photoUrl:(NSString *)photoUrl;

@property (nonatomic, readonly, strong) NSString *photoId;
@property (nonatomic, readonly, strong) PhotoSize *photoSize;

// may be nil
@property (nonatomic, readonly, strong) NSString *photoUrl;

@end

@implementation PhotoJob

- (id)initWithPhotoId:(NSString *)photoId photoSize:(PhotoSize *)photoSize photoUrl:(NSString *)photoUrl
{
    self = [super init];

    if (self) {
        _photoId = photoId;
        _photoSize = photoSize;
        _photoUrl = photoUrl;
    }

    return self;
}

- (BOOL)isEqual:(id)object
{
    if (object == self) {
        return YES;
    }
    if (![object isKindOfClass:[PhotoJob class]]) {
        return NO;
    }

    PhotoJob *other = object;

    // photoUrl is not relevant in the comparison

    return [self.photoId isEqualToString:other.photoId] && self.photoSize == other.photoSize;
}

@end

@interface CurrentlyDownloadingPhoto : NSObject

- (id)initWithPhotoJob:(PhotoJob *)photoJob;

@property (nonatomic, readonly, strong) NSString *photoId;
@property (nonatomic, readonly, strong) PhotoSize *photoSize;

@property (atomic, readwrite, assign) float progress;

@end

@implementation CurrentlyDownloadingPhoto

- (id)initWithPhotoJob:(PhotoJob *)photoJob
{
    self = [super init];

    if (self) {
        _photoId = photoJob.photoId;
        _photoSize = photoJob.photoSize;

        _progress = 0.0f;
    }

    return self;
}

@end

@interface PhotoFilesManager ()

- (NSArray *)photoObservers:(NSString *)photoId forSize:(PhotoSize *)photoSize;
- (NSString *)photoFilePath:(NSString *)photoId photoSize:(PhotoSize *)photoSize;
- (void)photoDownloadProgress:(CurrentlyDownloadingPhoto *)currentlyDownloadingPhoto;
- (void)photoDownloadCompleted:(CurrentlyDownloadingPhoto *)currentlyDownloadingPhoto;
- (void)photoDownloadFailed:(CurrentlyDownloadingPhoto *)currentlyDownloadingPhoto url:(NSURL *)url error:(NSError *)error;

@end

@interface PhotoDownloadDelegate : NSObject<NSURLConnectionDataDelegate>

- (id)initWithPhotoFilesManager:(PhotoFilesManager *)photoFilesManager currentlyDownloadingPhoto:(CurrentlyDownloadingPhoto *)currentlyDownloadingPhoto;

@end

@implementation PhotoDownloadDelegate
{
    PhotoFilesManager *photoFilesManager_;
    CurrentlyDownloadingPhoto *currentlyDownloadingPhoto_;

    NSFileHandle *dataHandle_;

    long long downloadedContentLength_;
    long long expectedContentLength_;
}

- (id)initWithPhotoFilesManager:(PhotoFilesManager *)photoFilesManager currentlyDownloadingPhoto:(CurrentlyDownloadingPhoto *)currentlyDownloadingPhoto
{
    self = [super init];

    if (self) {
        photoFilesManager_ = photoFilesManager;
        currentlyDownloadingPhoto_ = currentlyDownloadingPhoto;

        dataHandle_ = nil;

        downloadedContentLength_ = 0;

        // expectedContentLength_ is initialized later
    }

    return self;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [dataHandle_ closeFile];
    dataHandle_ = nil;

    // The file is completely downloaded, so atomically rename it to its final destination
    NSString *savingFile = [photoFilesManager_ photoFilePath:currentlyDownloadingPhoto_.photoId photoSize:currentlyDownloadingPhoto_.photoSize];
    NSString *savingFilePart = [savingFile stringByAppendingString:@".part"];

    NSError *error;
    if (![[NSFileManager defaultManager] moveItemAtPath:savingFilePart toPath:savingFile error:&error]) {
        NSLog(@"ERROR MOVING FILE: %@", error.description);
        // TODO Handle error...
        return;
    }

    [FileUtils addSkipBackupAttributeToItemAtURL:savingFile];

    [photoFilesManager_ photoDownloadCompleted:currentlyDownloadingPhoto_];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [dataHandle_ writeData:data];
    downloadedContentLength_ += data.length;

    currentlyDownloadingPhoto_.progress = (float)downloadedContentLength_ / (float)expectedContentLength_;

    [photoFilesManager_ photoDownloadProgress:currentlyDownloadingPhoto_];

}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (dataHandle_) {
        [dataHandle_ closeFile];
        dataHandle_ = nil;

        // There was an error downloading, so delete the partially downloaded file
        NSString *savingFile = [photoFilesManager_ photoFilePath:currentlyDownloadingPhoto_.photoId photoSize:currentlyDownloadingPhoto_.photoSize];
        NSString *savingFilePart = [savingFile stringByAppendingString:@".part"];

        NSError *error;
        if (![[NSFileManager defaultManager] removeItemAtPath:savingFilePart error:&error]) {
            NSLog(@"ERROR DELETING FILE: %@", error.description);
            // TODO Handle error...
        }
    }

    [photoFilesManager_ photoDownloadFailed:currentlyDownloadingPhoto_ url:connection.originalRequest.URL error:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    expectedContentLength_ = response.expectedContentLength;

    NSString *savingFile = [photoFilesManager_ photoFilePath:currentlyDownloadingPhoto_.photoId photoSize:currentlyDownloadingPhoto_.photoSize];
    NSString *savingFilePart = [savingFile stringByAppendingString:@".part"];

    // Save the file to a .part file and only when finished move it to the final save location.
    // This is done in case the app is killed, to prevent the app getting confused with a
    // partially downloaded file and thinking that it is complete.
    if (![[NSFileManager defaultManager] createFileAtPath:savingFilePart contents:nil attributes:nil]) {
        NSLog(@"ERROR CREATING FILE: %@", savingFilePart);
        // TODO Handle error...
        return;
    }

    dataHandle_ = [NSFileHandle fileHandleForWritingAtPath:savingFilePart];

    if (!dataHandle_) {
        NSLog(@"ERROR OPENING FILE: %@", savingFilePart);
        // TODO Handle error...
        return;
    }

    [FileUtils addSkipBackupAttributeToItemAtURL:savingFilePart];

}

@end

@implementation PhotoFilesManager
{
    // The directory in the file system where photos are stored for offline viewing
    NSString *photosDirectory_;

    PhotoSize *deviceDisplayPhotoSize_;

    // Dictionary from `NSString` objects to `NSMutableArray` objects
    // The `NSMutableArray` contains objects of type `PhotoLoadObserver`
    //
    // This is only allowed to be touched from the main thread!
    NSMutableDictionary *photoLoadObservers_;

    PhotoImageCache *photoImageCache_;

    // The elements are `CurrentlyDownloadingPhoto` instances
    NSMutableArray *currentlyDownloading_;

    // The elements are `PhotoJob` instances
    NSMutableArray *downloadQueue_;

    // The elements are `PhotoJob` instances
    NSMutableArray *currentlyDecoding_;

    int numActiveDownloads_;

    NSOperationQueue *downloadOperationQueue_;

    // Must be aquired only at the top-level. Protects all member variables above except photoLoadObservers_
    NSObject *mainLock;

    // May be aquired at the top-level, or within the mainLock. Protects photoLoadObservers_
    NSObject *observersLock;
}

static NSString * const PHOTOS_DIRECTORY = @"photos";

- (id)init
{
    self = [super init];

    if (self) {
        NSString *applicationSupportDirectory = [FileUtils getApplicationSupportDirectory];

        photosDirectory_ = [applicationSupportDirectory stringByAppendingPathComponent:PHOTOS_DIRECTORY];

        // Create the directory if it doesn't exist:
        NSFileManager *manager = [NSFileManager defaultManager];
        if (![manager fileExistsAtPath:photosDirectory_]) {
            NSError *error;
            if (![manager createDirectoryAtPath:photosDirectory_ withIntermediateDirectories:NO attributes:nil error:&error]) {
                NSAssert(NO, @"Error creating Photos Directory: %@", [error localizedDescription]);
            }
        }

        [self initDeviceDisplayPhotoSize];

        photoLoadObservers_ = [[NSMutableDictionary alloc] init];

        photoImageCache_ = [[PhotoImageCache alloc] init];

        currentlyDownloading_ = [[NSMutableArray alloc] init];

        downloadQueue_ = [[NSMutableArray alloc] init];

        currentlyDecoding_ = [[NSMutableArray alloc] init];

        numActiveDownloads_ = 0;

        downloadOperationQueue_ = [[NSOperationQueue alloc] init];

        mainLock = [[NSObject alloc] init];
        observersLock = [[NSObject alloc] init];
    }

    return self;
}

- (void)initDeviceDisplayPhotoSize
{
    UIScreen *screen = [UIScreen mainScreen];
    CGRect screenBounds = screen.bounds;
    CGFloat screenScale = screen.scale;

    int width;
    int height;
    if (screenBounds.size.width > screenBounds.size.height) {
        width = screenBounds.size.width * screenScale;
        height = screenBounds.size.height * screenScale;
    }
    else {
        width = screenBounds.size.height * screenScale;
        height = screenBounds.size.width * screenScale;
    }
    deviceDisplayPhotoSize_ = [PhotoFilesManager getAppropriatePhotoSizeWithDisplayWidth:width displayHeight:height];
    NSLog(@"Display Resolution: %d x %d", width, height);
    NSLog(@"Display Photo Size: %@", deviceDisplayPhotoSize_.extension);
}

+ (PhotoSize *)getAppropriatePhotoSizeWithDisplayWidth:(int)displayWidth displayHeight:(int)displayHeight
{
    // [PhotoSize allPhotoSizes] are ordered from best quality to worst
    // Loop through them in reverse, starting with the worst, until an acceptable one is found
    for (int i = [PhotoSize allPhotoSizes].count - 1; i >= 0; --i) {
        PhotoSize *photoSize = [[PhotoSize allPhotoSizes] objectAtIndex:i];
        if (photoSize.width >= displayWidth && photoSize.height >= displayHeight) {
            return photoSize;
        }
    }
    // If no acceptable PhotoSize was found, we just return the first one, which is the highest quality available
    return [[PhotoSize allPhotoSizes] objectAtIndex:0];
}

- (PhotoSize *)DeviceDisplayPhotoSize
{
    return deviceDisplayPhotoSize_;
}

- (void)registerPhotoLoadObserver:(NSString *)photoId photoSize:(PhotoSize *)photoSize photoObserver:(PhotoView *)photoObserver
{
    PhotoLoadObserver *photoLoadObserver = [[PhotoLoadObserver alloc] initWithPhotoSize:photoSize observer:photoObserver];

    @synchronized (observersLock) {
        NSMutableArray *observerList = [photoLoadObservers_ objectForKey:photoId];
        if (observerList) {
            [observerList addObject:photoLoadObserver];
        }
        else {
            NSMutableArray *newObserverList = [[NSMutableArray alloc] initWithObjects:photoLoadObserver, nil];
            [photoLoadObservers_ setObject:newObserverList forKey:photoId];
        }
    }
}

- (NSArray *)photoObservers:(NSString *)photoId forSize:(PhotoSize *)photoSize
{
    NSMutableArray *result = [[NSMutableArray alloc] init];

    @synchronized (observersLock) {
        NSMutableArray *observerList = [photoLoadObservers_ objectForKey:photoId];
        if (!observerList) {
            return result;
        }
        for (PhotoLoadObserver *observer in observerList) {
            if (observer.photoSize == photoSize) {
                PhotoView *o = observer.weakObserver;
                if (o) {
                    [result addObject:o];
                }
                else {
                    // TODO Remove the nil observer
                }
            }
        }
    }

    return result;
}

- (NSArray *)photoObservers:(NSString *)photoId forSizeBetterThan:(PhotoSize *)photoSize
{
    NSMutableArray *result = [[NSMutableArray alloc] init];

    @synchronized (observersLock) {

        NSMutableArray *observerList = [photoLoadObservers_ objectForKey:photoId];
        if (!observerList) {
            return result;
        }
        for (PhotoLoadObserver *observer in observerList) {
            if ([photoSize isWorseThan:observer.photoSize]) {
                PhotoView *o = observer.weakObserver;
                if (o) {
                    [result addObject:o];
                }
                else {
                    // TODO Remove the nil observer
                }
            }
        }
    }

    return result;
}

- (void)removePhotoObserver:(NSString *)photoId photoSize:(PhotoSize *)photoSize photoObserver:(PhotoView *)photoObserver
{
    @synchronized (observersLock) {
        NSMutableArray *observerList = [photoLoadObservers_ objectForKey:photoId];
        if (observerList) {
            for (int i = 0; i < observerList.count; ++i) {
                PhotoLoadObserver *o = [observerList objectAtIndex:i];
                if (o.photoSize == photoSize && o.weakObserver == photoObserver) {
                    if (observerList.count == 1) {
                        [photoLoadObservers_ removeObjectForKey:photoId];
                    }
                    else {
                        [observerList removeObjectAtIndex:i];
                    }
                    return;
                }
            }
        }
    }
}

- (NSString *)photoFilePath:(NSString *)photoId photoSize:(PhotoSize *)photoSize
{
    return [photosDirectory_ stringByAppendingPathComponent:[photoId stringByAppendingString:[photoSize getFullExtension]]];
}

// Must be called only within `mainLock`
//
// Returns `nil` if not currently downloading
- (CurrentlyDownloadingPhoto *)getCurrentlyDownloadingPhoto:(PhotoJob *)photoJob
{
    for (CurrentlyDownloadingPhoto *c in currentlyDownloading_) {
        if ([c.photoId isEqualToString:photoJob.photoId] &&
            c.photoSize == photoJob.photoSize) {
            return c;
        }
    }

    return nil;
}

- (void)loadBitmap:(NSString *)photoId photoUrl:(NSString *)photoUrl photoSize:(PhotoSize *)photoSize photoObserver:(PhotoView *)photoObserver
{
    NSAssert([NSThread isMainThread], @"verify main thread");
    NSLog(@"loadBitmap: %@", photoId);

    UIImage *cachedImage = [photoImageCache_ getPhotoImage:photoId photoSize:photoSize];

    if (cachedImage) {
        PhotoBitmap *bmp = [[PhotoBitmap alloc] initAsLoaded:cachedImage];
        [photoObserver onPhotoLoadUpdate:bmp];
        return;
    }

    // TODO load any size that is available, not just Thumb75
    UIImage *cachedLowQualityImage = [photoImageCache_ getPhotoImage:photoId photoSize:[PhotoSize Thumb75]];

    [photoObserver onPhotoLoadUpdate:[[PhotoBitmap alloc] initAsLoading:cachedLowQualityImage]];

    [self registerPhotoLoadObserver:photoId photoSize:photoSize photoObserver:photoObserver];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        PhotoJob *photoJob = [[PhotoJob alloc] initWithPhotoId:photoId photoSize:photoSize photoUrl:photoUrl];

        @synchronized (mainLock) {

            // TODO DECODE THE THUMBNAIL ANYWAY!

            // Check if the photo is currently downloading
            CurrentlyDownloadingPhoto *currentlyDownloading = [self getCurrentlyDownloadingPhoto:photoJob];
            if (currentlyDownloading) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    PhotoBitmap *bmp = [[PhotoBitmap alloc] initAsDownloading:currentlyDownloading.progress lowQualityBmp:cachedLowQualityImage];
                    [photoObserver onPhotoLoadUpdate:bmp];
                });
                return;
            }

            // Check if the photo is already in the downloadQueue
            NSUInteger downloadQueueIndex = [downloadQueue_ indexOfObject:photoJob];
            if (downloadQueueIndex != NSNotFound) {
                // Remove the old existing PhotoJob from the queue ...
                [downloadQueue_ removeObjectAtIndex:downloadQueueIndex];

                // ... And move it to the beginning of the queue:
                [downloadQueue_ insertObject:photoJob atIndex:0];

                dispatch_async(dispatch_get_main_queue(), ^{
                    PhotoBitmap *bmp = [[PhotoBitmap alloc] initAsQueuedForDownload:cachedLowQualityImage];
                    [photoObserver onPhotoLoadUpdate:bmp];
                });
                return;
            }

            // Check if the photo is already being decoded
            if ([currentlyDecoding_ containsObject:photoJob]) {
                return;
            }

            // Check if the photo has already been downloaded
            BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[self photoFilePath:photoId photoSize:photoSize]];
            if (fileExists) {
                NSLog(@"fileExists: %@", photoId);
                [currentlyDecoding_ addObject:photoJob];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    [self decodePhoto:photoJob loadLowQuality:NO];
                });
            }
            else {
                if (photoSize != [PhotoSize Thumb75]) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                        [self decodePhoto:photoJob loadLowQuality:YES];
                    });
                }

                NSLog(@"Adding to download queue: %@", photoId);
                // Add the photoJob to the beginning of the download queue
                [downloadQueue_ insertObject:photoJob atIndex:0];
                [self triggerDownload];
            }
        }

    });
}

- (void)decodePhoto:(PhotoJob *)photoJob loadLowQuality:(BOOL)loadLowQuality
{
    NSLog(@"decodePhoto: %@ %d", photoJob.photoId, loadLowQuality);
    UIImage *img;

    if (!loadLowQuality) {
        // A simple optimization: Before decoding make sure that there is still some observer that is interested!
//        @synchronized (observersLock) {
//            if ([self photoObservers:photoJob.photoId forSize:photoJob.photoSize].count == 0) {
//                return;
//            }
//        }

        img = [self loadLocalPhoto:photoJob.photoId photoSize:photoJob.photoSize];

        if (!img) {
            // TODO This is bad!
            NSLog(@"Error loading photo: %@", photoJob.photoId);
            return;
        }

    }
    else {
        // A simple optimization: Before decoding make sure that there is still some observer that is interested!
//        @synchronized (observersLock) {
//            if ([self photoObservers:photoJob.photoId forSizeBetterThan:photoJob.photoSize].count == 0) {
//                return;
//            }
//        }

        img = [self loadBestLocalPhoto:photoJob.photoId maxSize:photoJob.photoSize];

        if (!img) {
            // No low quality photo available, nothing to do
            return;
        }
    }

    NSArray *observers;
    @synchronized (mainLock) {
        if (!loadLowQuality)
        [currentlyDecoding_ removeObject:photoJob];

        @synchronized (observersLock) {
            if (!loadLowQuality) {
                observers = [self photoObservers:photoJob.photoId forSize:photoJob.photoSize];

                // The photo is load process is complete, so there is no a need to continue to observer it
                for (PhotoView *observer in observers) {
                    [self removePhotoObserver:photoJob.photoId photoSize:photoJob.photoSize photoObserver:observer];
                }
            }
            else {
                observers = [self photoObservers:photoJob.photoId forSizeBetterThan:photoJob.photoSize];
            }
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!loadLowQuality) {
            PhotoBitmap *bmp = [[PhotoBitmap alloc] initAsLoaded:img];
            for (PhotoView *observer in observers) {
                [observer onPhotoLoadUpdate:bmp];
            }
        }
        else {
            // TODO !!!
        }
    });
}

const int MAX_CONCURRENT_DOWNLOADS = 4;

// Must be called only within `mainLock`
- (void)triggerDownload
{
    if (numActiveDownloads_ < MAX_CONCURRENT_DOWNLOADS) {
        numActiveDownloads_++;
        [self downloadNextPhoto];
    }
}

// Must be called only within `mainLock`
- (void)downloadNextPhoto
{
    PhotoJob *job = [downloadQueue_ objectAtIndex:0];
    [downloadQueue_ removeObjectAtIndex:0];

    CurrentlyDownloadingPhoto *currentlyDownloadingPhoto = [[CurrentlyDownloadingPhoto alloc] initWithPhotoJob:job];
    [currentlyDownloading_ addObject:currentlyDownloadingPhoto];

    NSString *photoUrlNoExtension = [job.photoUrl substringToIndex:job.photoUrl.length - 4];
    NSString *ext = [job.photoSize getFullExtension];

    NSString *url = [photoUrlNoExtension stringByAppendingString:ext];

    [self startDownload:currentlyDownloadingPhoto url:[[NSURL alloc] initWithString:url]];
}

- (void)startDownload:(CurrentlyDownloadingPhoto *)currentlyDownloadingPhoto url:(NSURL *)url
{
    NSLog(@"Downloading photo: %@", url);

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"GET"];

    [self photoDownloadProgress:currentlyDownloadingPhoto];

    PhotoDownloadDelegate *photoDownloadDelegate = [[PhotoDownloadDelegate alloc] initWithPhotoFilesManager:self
                                                                                  currentlyDownloadingPhoto:currentlyDownloadingPhoto];

    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:photoDownloadDelegate startImmediately:NO];
    [connection setDelegateQueue:downloadOperationQueue_];
    [connection start];
}

- (void)photoDownloadProgress:(CurrentlyDownloadingPhoto *)currentlyDownloadingPhoto
{
    NSArray *observers;
    @synchronized (observersLock) {
        observers = [self photoObservers:currentlyDownloadingPhoto.photoId forSize:currentlyDownloadingPhoto.photoSize];
    }

    if (observers.count > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // TODO load any size that is available, not just Thumb75
            UIImage *cachedLowQualityImage = [photoImageCache_ getPhotoImage:currentlyDownloadingPhoto.photoId photoSize:[PhotoSize Thumb75]];

            PhotoBitmap *bmp = [[PhotoBitmap alloc] initAsDownloading:currentlyDownloadingPhoto.progress lowQualityBmp:cachedLowQualityImage];

            for (PhotoView *observer in observers) {
                [observer onPhotoLoadUpdate:bmp];
            }
        });
    }
}

- (void)photoDownloadCompleted:(CurrentlyDownloadingPhoto *)currentlyDownloadingPhoto
{
    @synchronized (mainLock) {
        NSLog(@"DownloadCompleted: %@", currentlyDownloadingPhoto.photoId);
        numActiveDownloads_--;

        [currentlyDownloading_ removeObjectIdenticalTo:currentlyDownloadingPhoto];

        NSArray *observers;
        @synchronized (observersLock) {
            observers = [self photoObservers:currentlyDownloadingPhoto.photoId forSize:currentlyDownloadingPhoto.photoSize];
        }

        if (observers.count > 0) {
            PhotoJob *photoJob = [[PhotoJob alloc] initWithPhotoId:currentlyDownloadingPhoto.photoId photoSize:currentlyDownloadingPhoto.photoSize photoUrl:nil];
            [currentlyDecoding_ addObject:photoJob];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [self decodePhoto:photoJob loadLowQuality:NO];
            });
        }

        if (downloadQueue_.count > 0) {
            [self triggerDownload];
        }
    }
}

- (void)photoDownloadFailed:(CurrentlyDownloadingPhoto *)currentlyDownloadingPhoto url:(NSURL *)url error:(NSError *)error
{
    NSLog(@"DownloadFailed: %@ %@", currentlyDownloadingPhoto.photoId, error.description);

    // TODO report downloadFailed

    const double RETRY_TIME = 5.0;

    double delayInSeconds = RETRY_TIME;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void){
        currentlyDownloadingPhoto.progress = 0.0f;
        [self startDownload:currentlyDownloadingPhoto url:url];
    });
}

- (void)queuePhotoDownload:(NSString *)photoId photoUrl:(NSString *)photoUrl photoSize:(PhotoSize *)photoSize highPriority:(BOOL)highPriority
{
    NSAssert([NSThread isMainThread], @"verify main thread");

    UIImage *cachedImage = [photoImageCache_ getPhotoImage:photoId photoSize:photoSize];
    if (cachedImage) {
        // The photo is in the image cache so it is definitely already downloaded: nothing more needed
        return;
    }
}

- (UIImage *)loadBestLocalPhoto:(NSString *)photoId maxSize:(PhotoSize *)maxSize
{
    for (PhotoSize *photoSize in [PhotoSize iteratePhotoSizes:maxSize]) {
        UIImage *bmp = [self loadLocalPhoto:photoId photoSize:photoSize];
        if (bmp) {
            return bmp;
        }
    }

    return nil;
}

- (UIImage *)loadLocalPhoto:(NSString *)photoId photoSize:(PhotoSize *)photoSize
{
    NSString *fileName = [self photoFilePath:photoId photoSize:photoSize];
    UIImage *img = [[UIImage alloc] initWithContentsOfFile:fileName];

    if (img) {
        [photoImageCache_ setPhotoImage:photoId photoSize:photoSize image:img];
    }

    return img;
}

@end
