//
//  SVImagePickerListViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 5/2/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OldAlbum;

@interface SVImagePickerListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) OldAlbum *selectedAlbum;

@end
