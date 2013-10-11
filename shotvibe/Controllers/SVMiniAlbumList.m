//
//  SVMiniAlbumList.m
//  shotvibe
//
//  Created by Baluta Cristian on 11/10/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVMiniAlbumList.h"

@implementation SVMiniAlbumList

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
		
		NSArray *albums = [self.albumManager addAlbumListListener:nil];
		
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
