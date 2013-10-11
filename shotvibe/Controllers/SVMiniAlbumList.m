//
//  SVMiniAlbumList.m
//  shotvibe
//
//  Created by Baluta Cristian on 11/10/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVMiniAlbumList.h"
#import "AlbumSummary.h"
#import "AlbumPhoto.h"
#import "RCImageView.h"

@implementation SVMiniAlbumList

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
		//self.backgroundColor = [UIColor redColor];
		
    }
    return self;
}

- (void)setAlbums:(NSArray*)arr
{
	int i = 0;
    for (AlbumSummary *album in arr) {
		RCLogO(album);
		
		RCImageView *image = [[RCImageView alloc] initWithFrame:CGRectMake(10 + 100*i, 0, 80, 80) delegate:nil];
		image.image = [UIImage imageNamed:@"placeholderImage"];
		
//		if (album.latestPhotos.count > 0) {
//			AlbumPhoto *latestPhoto = [album.latestPhotos objectAtIndex:0];
//			if (latestPhoto.serverPhoto) {
//				NSString *fullsizePhotoUrl = latestPhoto.serverPhoto.url;
//				NSString *thumbnailSuffix = @"_thumb75.jpg";
//				NSString *thumbnailUrl = [[fullsizePhotoUrl stringByDeletingPathExtension] stringByAppendingString:thumbnailSuffix];
//				//[image loadNetworkImage:[NSURL URLWithString:thumbnailUrl]];
//			}
//		}
//		else {
//			image.image = [UIImage imageNamed:@"placeholderImage"];
//		}
		
		[self addSubview:image];
		i++;
	}
	self.contentSize = CGSizeMake(20+100*i, self.frame.size.height);
}


@end
