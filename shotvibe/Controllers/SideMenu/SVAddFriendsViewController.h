//
//  SVAddFriendsViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 4/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SL/PhoneContactsManager.h"
#import "SL/AlbumManager.h"
#import "SVAlbumListViewController.h"

@protocol AddFriendsDelegate <NSObject>

@optional

- (void)goToPage:(int)num;
- (void)goToAlbumId:(long long)num;

@end

@interface SVAddFriendsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, SLPhoneContactsManager_Listener>

@property (nonatomic, assign) id<AddFriendsDelegate> delegate;
@property (nonatomic, assign) int64_t albumId;
@property (assign, nonatomic) NSInteger indexNumber;

@end
