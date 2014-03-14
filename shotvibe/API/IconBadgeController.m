//
//  IconBadgeController.m
//  shotvibe
//
//  Created by Oblosys on 13-03-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "IconBadgeController.h"
#import "AlbumSummary.h"
#import "ShotVibeAppDelegate.h"
#import "ArrayList.h"

@implementation IconBadgeController

- (id)init
{
    self = [super init];
    if (self) {
        [[ShotVibeAppDelegate sharedDelegate].albumManager addAlbumListListener:self];
    }
    return self;
}


#pragma mark - AlbumListListener

- (void)onAlbumListBeginRefresh
{
}


- (void)onAlbumListRefreshComplete:(NSArray *)allAlbums
{
    int64_t totalNrOfNewPhotos = 0;
    for (SLAlbumSummary *album in allAlbums) {
        totalNrOfNewPhotos += [album getNumNewPhotos];
    }
    [Notification notify:[NSString stringWithFormat:@"Setting badge to %llu", totalNrOfNewPhotos]];
    [UIApplication sharedApplication].applicationIconBadgeNumber = totalNrOfNewPhotos;
}


- (void)onAlbumListRefreshError:(SLAPIException *)exception
{
}


@end
