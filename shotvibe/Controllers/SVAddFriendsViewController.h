//
//  SVAddFriendsViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 4/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVEntityStore.h"
#import "Album.h"

@interface SVAddFriendsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
{
	BOOL shouldBeginEditing;
}

@property (nonatomic, strong) NSString *albumId;
@property (strong, nonatomic) Album *selectedAlbum;

@end
