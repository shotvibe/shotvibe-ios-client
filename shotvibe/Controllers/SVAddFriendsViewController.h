//
//  SVAddFriendsViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 4/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import "AlbumManager.h"

@interface SVAddFriendsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (nonatomic, assign) int64_t albumId;
@property (nonatomic, strong) AlbumManager *albumManager;

@end
