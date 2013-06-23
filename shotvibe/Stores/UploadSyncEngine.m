//
//  UploadSyncEngine.m
//  shotvibe
//
//  Created by Peter Kasson on 6/22/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "UploadSyncEngine.h"

@implementation UploadSyncEngine


#pragma mark - Class Methods

+ (UploadSyncEngine *)sharedEngine
{
 static UploadSyncEngine *sharedEngine = nil;
 static dispatch_once_t engineToken;
 dispatch_once(&engineToken, ^{
  sharedEngine = [[UploadSyncEngine alloc] init];
  
//  [[NSNotificationCenter defaultCenter] addObserver:sharedEngine selector:@selector(syncAlbums) name:kUserAlbumsLoadedNotification object:nil];
 });
 
 return sharedEngine;
}


#pragma mark - Instance Methods

/*
 * sync - retrieve albums and photos
 */
- (void)startSync
{
 NSLog(@"start sync");
 
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
   
//   [[SVEntityStore sharedStore] userAlbums];
   
  });
}

@end
