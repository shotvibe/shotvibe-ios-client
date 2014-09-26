//
//  SVMiniAlbumList.h
//  shotvibe
//
//  Created by Baluta Cristian on 11/10/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SL/AlbumManager.h"

@interface SVMiniAlbumList : UIScrollView <UIScrollViewDelegate>

@property (nonatomic, strong) NSArray *albums;

@end
