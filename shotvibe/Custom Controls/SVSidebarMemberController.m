//
//  SVSidebarMenuViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 2/15/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVAlbumGridViewController.h"
#import "SVDefines.h"
#import "SVSidebarAlbumMemberCell.h"
#import "SVSidebarMemberController.h"
#import "UIImageView+WebCache.h"

#import "AlbumMember.h"

@interface SVSidebarMemberController ()

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UINavigationBar *sidebarNav;

- (IBAction)addFriendsButtonPressed:(id)sender;

@end

@implementation SVSidebarMemberController

#pragma mark - Actions

- (IBAction)addFriendsButtonPressed:(id)sender
{
    // Do other stuff
    [self.parentController performSegueWithIdentifier:@"AddFriendsSegue" sender:nil];
}

#pragma mark - Properties

- (void)setAlbumContents:(AlbumContents *)albumContents
{
    _albumContents = albumContents;

    [self.tableView reloadData];
}

- (void)setParentController:(SVAlbumGridViewController *)parentController {
	_parentController = parentController;
	[self.tableView reloadData];
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    {
        UIImage *baseImage = [UIImage imageNamed:@"sidebarMenuNavbar.png"];
        UIEdgeInsets insets = UIEdgeInsetsMake(5, 20, 0, 20);
        UIImage *resizableImage = [baseImage resizableImageWithCapInsets:insets];
        
        [self.sidebarNav setBackgroundImage:resizableImage forBarMetrics:UIBarMetricsDefault];
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.albumContents.members.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SVSidebarAlbumMemberCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AlbumMemberCell"];

    AlbumMember *member = [self.albumContents.members objectAtIndex:indexPath.row];

    [cell.profileImageView setImageWithURL:[NSURL URLWithString:member.avatarUrl]];
    cell.memberLabel.text = member.nickname;

    return cell;
}


@end
