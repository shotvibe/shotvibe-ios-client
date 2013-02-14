//
//  SVAlbumGridViewController.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/13/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Album;

@interface SVAlbumGridViewController : UIViewController

#pragma mark - Properties

@property (nonatomic, strong) Album *selectedAlbum;

@end
