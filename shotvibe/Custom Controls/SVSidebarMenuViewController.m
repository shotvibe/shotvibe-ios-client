//
//  SVSidebarMenuViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 2/15/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import <QuartzCore/QuartzCore.h>
#import "SVSidebarMenuViewController.h"
#import "SVAlbumGridViewController.h"
#import "Album.h"
#import "SVDefines.h"
#import "SVSidebarAlbumMemberCell.h"
#import "Member.h"

@interface SVSidebarMenuViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UINavigationBar *sidebarNav;
@property (nonatomic, strong) NSArray *members;

- (IBAction)addFriendsButtonPressed:(id)sender;
- (void)configureCell:(SVSidebarAlbumMemberCell *)cell atIndexPath:(NSIndexPath *)indexPath;

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
        
        UIImage *resizableImage = nil;
        if (IS_IOS6_OR_GREATER) {
            resizableImage = [baseImage resizableImageWithCapInsets:insets];
        }
        else
        {
            resizableImage = [baseImage resizableImageWithCapInsets:insets];
        }
        
        [self.sidebarNav setBackgroundImage:resizableImage forBarMetrics:UIBarMetricsDefault];
    }
    
    [self refreshMembers];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}



#pragma mark - Private Methods

- (void)configureCell:(SVSidebarAlbumMemberCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [cell.profileImageView prepareForReuse];
    cell.profileImageView.sizeForDisplay = YES;
    cell.profileImageView.scaleOptions = NINetworkImageViewScaleToFillLeavesExcess;
    cell.profileImageView.interpolationQuality = kCGInterpolationHigh;
    cell.profileImageView.initialImage = nil;
    cell.profileImageView.layer.masksToBounds = YES;
    cell.profileImageView.layer.cornerRadius = 2;
    
    Member *currentMember = [self.members objectAtIndex:indexPath.row];
    [cell.profileImageView setPathToNetworkImage:currentMember.avatarUrl contentMode:UIViewContentModeScaleAspectFill];
    
    cell.memberLabel.text = currentMember.nickname;
}


- (void)refreshMembers
{
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"nickname" ascending:NO];
    self.members = [[self.selectedAlbum.members allObjects] sortedArrayUsingDescriptors:@[descriptor]];
    [self.tableView reloadData];
}


@end