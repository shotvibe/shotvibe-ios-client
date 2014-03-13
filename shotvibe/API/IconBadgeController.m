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

@implementation IconBadgeController {
    NSMutableDictionary *albumNrOfNewPhotos_; // Dictionary: NSNumber *AlbumId (int64_t) -> NSNumber *nrOfNewPhotos (int64_t)

    // Keep track of all new photos for each album in a dictionary using list and content listeners. We need to keep track of the value for each album because when one album changes, the list listener is not notified, so we need to keep the number of new photos for each album somewhere in order to compute the new total.

    // TODO: Maybe some refactoring can make this a little simpler.
}


- (id)init
{
    self = [super init];
    if (self) {
        albumNrOfNewPhotos_ = [[NSMutableDictionary alloc] init];
        [[ShotVibeAppDelegate sharedDelegate].albumManager addAlbumListListener:self];
    }
    return self;
}


- (void)setIconBadge
{
    int64_t totalNrOfNewPhotos = 0;
    for (NSNumber *nrOfNewInAlbum in albumNrOfNewPhotos_.allValues) {
        totalNrOfNewPhotos += [nrOfNewInAlbum longLongValue];
    }
    [Notification notify:[NSString stringWithFormat:@"Setting badge to %llu", totalNrOfNewPhotos] withMessage:[albumNrOfNewPhotos_ description]];
    [UIApplication sharedApplication].applicationIconBadgeNumber = totalNrOfNewPhotos;
}


#pragma mark - AlbumListListener

- (void)onAlbumListBeginRefresh
{
}


- (void)onAlbumListRefreshComplete:(NSArray *)allAlbums
{
    NSMutableArray *oldAlbumIds = [NSMutableArray arrayWithArray:albumNrOfNewPhotos_.allKeys];

    NSMutableArray *removedAlbumIds = [NSMutableArray arrayWithArray:oldAlbumIds]; // compute albums that were removed

    for (SLAlbumSummary *album in allAlbums) {
        [removedAlbumIds removeObject:@([album getId])]; // remove each current id from old ids to get the removed ids

        if (![oldAlbumIds containsObject:@([album getId])]) { // if it's not in oldAlbumIds, this is a new album
            [[ShotVibeAppDelegate sharedDelegate].albumManager addAlbumContentsListener:[album getId] listener:self];
            albumNrOfNewPhotos_[@([album getId])] = @([album getNumNewPhotos]);
            RCLog(@"Added badge listener for album %llu", [album getId]);
        }
    }

    for (NSNumber *albumId in removedAlbumIds) { // remove listener for removed albumIds
        [[ShotVibeAppDelegate sharedDelegate].albumManager removeAlbumContentsListener:[albumId longLongValue] listener:self];
        [albumNrOfNewPhotos_ removeObjectForKey:albumId];
        RCLog(@"Removed badge listener for album %llu", [albumId longLongValue]);
    }

    [self setIconBadge];
}


- (void)onAlbumListRefreshError:(SLAPIException *)exception
{
}


#pragma mark - AlbumContentsListener

- (void)onAlbumContentsBeginRefresh:(int64_t)albumId
{

}


- (void)onAlbumContentsRefreshComplete:(int64_t)albumId albumContents:(SLAlbumContents *)album
{
    albumNrOfNewPhotos_[@(albumId)] = @([album getNumNewPhotos]);
    [self setIconBadge];
}


- (void)onAlbumContentsRefreshError:(int64_t)albumId error:(SLAPIException *)error
{
}


- (void)onAlbumContentsPhotoUploadProgress:(int64_t)albumId
{
}


@end
