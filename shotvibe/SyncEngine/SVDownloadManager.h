//
//  SVDownloadManager.h
//  shotvibe
//
//  Created by Baluta Cristian on 06/08/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
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

@interface SVDownloadManager : NSObject {
	
	dispatch_queue_t saveQueue;
	NSOperationQueue *_queue;
	NSManagedObjectContext *ctxAlbums;
	NSManagedObjectContext *ctxPhotos;
	NSManagedObjectContext *ctxDownload;
	NSMutableArray *albumsWithUpdates;
	AFHTTPClient *downloader;
	BOOL busy;
}

+ (SVDownloadManager *)sharedManager;

- (void) download;

@end
