//
//  SVAlbumGridSection.h
//  shotvibe
//
//  Created by Baluta Cristian on 29/09/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SVAlbumGridSection : UICollectionReusableView

@property(nonatomic) int section;
@property(nonatomic, retain) IBOutlet UILabel *dateLabel;

@end
