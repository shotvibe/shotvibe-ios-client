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
#import "UIImageView+WebCache.h"

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
		
		UIImageView *image = [[UIImageView alloc] initWithFrame:CGRectMake(100*i + 15, 0, 60, 60)];
		image.contentMode = UIViewContentModeScaleAspectFill;
		image.clipsToBounds = YES;
		image.image = [UIImage imageNamed:@"placeholderImage"];
		
		if (album.latestPhotos.count > 0) {
			AlbumPhoto *latestPhoto = [album.latestPhotos objectAtIndex:0];
			
			if (latestPhoto.serverPhoto) {
				NSString *fullsizePhotoUrl = latestPhoto.serverPhoto.url;
				NSString *thumbnailSuffix = @"_thumb75.jpg";
				NSString *thumbnailUrl = [[fullsizePhotoUrl stringByDeletingPathExtension] stringByAppendingString:thumbnailSuffix];
				[image setImageWithURL:[[NSURL alloc] initWithString:thumbnailUrl]];
			}
		}
		
		[self addSubview:image];
		
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0 + 100*i, 60, 90, 15)];
		label.textColor = [UIColor darkGrayColor];
		label.numberOfLines = 1;
		label.textAlignment = NSTextAlignmentCenter;
		label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:10];
		label.text = album.name;
		[self addSubview:label];
		
		i++;
	}
	self.contentSize = CGSizeMake(13+100*i, self.frame.size.height);
}


@end
