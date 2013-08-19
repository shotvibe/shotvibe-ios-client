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
#import "Album.h"
#import "AlbumPhoto.h"
#import "Member.h"

@interface SVUploadManager : NSObject {
	
	NSManagedObjectContext *ctxAlbums;
	NSManagedObjectContext *ctxPhotos;
	NSManagedObjectContext *ctxUpload;
	NSMutableArray *albumsToUpload;
	NSMutableDictionary *photosToUpload;
	AFHTTPClient *uploader;
	BOOL busy;
	BOOL restartUploadWhenFinished;
	Album *activeAlbum;
}

+ (SVUploadManager *)sharedManager;

- (void) upload;// this will create albums on server that were not created because of internet connection
//- (void) uploadPhotos;// upload all the photos that are marked as needed to upload
- (void) deleteAlbums;
- (void) deletePhotos;

@end
