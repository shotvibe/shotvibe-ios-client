//
//  AlbumPhotoBrowserDelegate.m
//  shotvibe
//
//  Created by benny on 8/26/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AlbumPhotoBrowserDelegate.h"

#import "MWPhotoBrowser.h"

#import "AlbumPhoto.h"

@implementation AlbumPhotoBrowserDelegate
{
    AlbumContents *albumContents_;
}

- (id)initWithAlbumContents:(AlbumContents *)albumContents
{
    self = [super init];

    if (self) {
        albumContents_ = albumContents;
    }

    return self;
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser
{
    return albumContents_.photos.count;
}

- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index
{
    AlbumPhoto *photo = [albumContents_.photos objectAtIndex:index];

    if (photo.serverPhoto) {
        NSString *fullsizePhotoUrl = photo.serverPhoto.url;
        NSString *displaySuffix = @"_r_dvgax.jpg";
        NSString *finalUrl = [[fullsizePhotoUrl stringByDeletingPathExtension] stringByAppendingString:displaySuffix];

        MWPhoto *p = [[MWPhoto alloc] initWithURL:[NSURL URLWithString:finalUrl]];
        p.caption = [NSString stringWithFormat:@"Added by %@\n%@", photo.serverPhoto.authorNickname, photo.serverPhoto.dateAdded];
        return p;
    }
    else if (photo.uploadingPhoto) {
        MWPhoto *p = [[MWPhoto alloc] initWithFilePath:[photo.uploadingPhoto getFilename]];
        p.caption = @"Uploading...";
        return p;
    }

    NSAssert(NO, @"Impossible photo: %@", photo);
    return nil;
}

/*
- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index
{
    AlbumPhoto *photo = [albumContents_.photos objectAtIndex:index];

}
*/

@end
