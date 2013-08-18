//
//  SVSidebarMenuViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 2/15/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "Album.h"
#import "SVAlbumGridViewController.h"
#import "SVDefines.h"
#import "SVSidebarAlbumMemberCell.h"
#import "SVSidebarAlbumMemberViewController.h"
#import "OldMember.h"

@interface SVSidebarAlbumMemberViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UINavigationBar *sidebarNav;
@property (nonatomic, strong) NSArray *members;

- (IBAction)addFriendsButtonPressed:(id)sender;

@end

@implementation SVSidebarAlbumMemberViewController

#pragma mark - Actions

- (IBAction)addFriendsButtonPressed:(id)sender
{
    // Do other stuff
    [self.parentController performSegueWithIdentifier:@"AddFriendsSegue" sender:nil];
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
    
    [self refreshMembers];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.members.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SVSidebarAlbumMemberCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AlbumMemberCell"];
    
    OldMember *currentMember = [self.members objectAtIndex:indexPath.row];
	
	[cell.profileImageView setImage:nil];
	[cell.profileImageView loadNetworkImage:currentMember.avatar_url];
    cell.memberLabel.text = currentMember.nickname;
	
    return cell;
}


- (void)refreshMembers
{
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"nickname" ascending:YES];
    self.members = [[self.selectedAlbum.members allObjects] sortedArrayUsingDescriptors:@[descriptor]];
    [self.tableView reloadData];
}


@end
