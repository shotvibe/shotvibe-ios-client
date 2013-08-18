//
//  SVUploadManager.h
//  shotvibe
//
//  Created by Baluta Cristian on 06/08/2013.
//  Copyright (c) 2013 ralcr.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SVDefines.h"
#import "SVHttpClient.h"
#import "SVEntityStore.h"
#import "AFJSONRequestOperation.h"
#import "AFImageRequestOperation.h"
#import "OldAlbum.h"
#import "OldAlbumPhoto.h"
#import "OldMember.h"
#import "SVDownloadManager.h"

@interface SVUploadManager : NSObject {
	
	NSManagedObjectContext *ctxAlbums;
	NSManagedObjectContext *ctxPhotos;
	NSManagedObjectContext *ctxUpload;
	NSMutableArray *albumsToUpload;
	NSMutableDictionary *photosToUpload;
	AFHTTPClient *uploader;
	NSOperationQueue *_queue;
	BOOL busy;
	OldAlbum *activeAlbum;
}

+ (SVUploadManager *)sharedManager;

- (void) uploadAlbums;// this will create albums on server that were not created because of internet connection
- (void) uploadPhotos;// upload all the photos that are marked as needed to upload
- (void) deleteAlbums;
- (void) deletePhotos;

@end
