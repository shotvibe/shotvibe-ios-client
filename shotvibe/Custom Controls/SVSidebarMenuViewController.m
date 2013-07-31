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
#import "SVSidebarMenuViewController.h"
#import "Member.h"

@interface SVSidebarMenuViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UINavigationBar *sidebarNav;
@property (nonatomic, strong) NSArray *members;

- (IBAction)addFriendsButtonPressed:(id)sender;

@end

@implementation SVSidebarMenuViewController

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
    
	[cell.profileImageView prepareForReuse];
    cell.profileImageView.sizeForDisplay = YES;
    cell.profileImageView.scaleOptions = NINetworkImageViewScaleToFillLeavesExcess;
    cell.profileImageView.interpolationQuality = kCGInterpolationHigh;
    cell.profileImageView.initialImage = nil;
    cell.profileImageView.layer.masksToBounds = YES;
    cell.profileImageView.layer.cornerRadius = 2;
    
    Member *currentMember = [self.members objectAtIndex:indexPath.row];
    [cell.profileImageView setPathToNetworkImage:currentMember.avatar_url contentMode:UIViewContentModeScaleAspectFill];
    NSLog(@"currentMember.avatar_url %@", currentMember.avatar_url);
	
    cell.memberLabel.text = currentMember.nickname;
	
    return cell;
}


- (void)refreshMembers
{
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"nickname" ascending:NO];
    self.members = [[self.selectedAlbum.members allObjects] sortedArrayUsingDescriptors:@[descriptor]];
    [self.tableView reloadData];
}


@end
