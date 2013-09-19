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
#import "SVAddFriendsViewController.h"
#import "UIImageView+WebCache.h"

#import "AlbumMember.h"

@interface SVSidebarMemberController () {
	ShotVibeAPI *shotvibeAPI;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UINavigationBar *sidebarNav;

- (IBAction)addFriendsButtonPressed:(id)sender;

@end



@implementation SVSidebarMemberController

#pragma mark - Actions

- (IBAction)addFriendsButtonPressed:(id)sender
{
	// prepareForSegue is called in parentController SVAlbumGridViewController
    [self.parentController performSegueWithIdentifier:@"AddFriendsSegue" sender:sender];
}


#pragma mark - Properties

- (void)setAlbumContents:(AlbumContents *)albumContents
{
    _albumContents = albumContents;
    [self.tableView reloadData];
}

- (void)setParentController:(SVAlbumGridViewController *)parentController
{
	_parentController = parentController;
	
	shotvibeAPI = [self.parentController.albumManager getShotVibeAPI];
	//	int64_t userId = shotvibeAPI.authData.userId;
	NSLog(@"shotvibeAPI.authData.userId %@ %@ %lld", shotvibeAPI, shotvibeAPI.authData, shotvibeAPI.authData.userId);
	
	[self.tableView reloadData];
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	UIImage *baseImage = [UIImage imageNamed:@"sidebarMenuNavbar.png"];
	UIEdgeInsets insets = UIEdgeInsetsMake(5, 20, 0, 20);
	UIImage *resizableImage = [baseImage resizableImageWithCapInsets:insets];
	[self.sidebarNav setBackgroundImage:resizableImage forBarMetrics:UIBarMetricsDefault];
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
	NSLog(@"%lld == %lld member.avatarUrl %@", shotvibeAPI.authData.userId, member.memberId, member.avatarUrl);
    [cell.profileImageView setImageWithURL:[NSURL URLWithString:member.avatarUrl]];
	//cell.profileImageView.backgroundColor = [UIColor redColor];
    cell.memberLabel.text = member.nickname;
	cell.statusImageView.image = [UIImage imageNamed:[member.inviteStatus isEqualToString:@"joined"] ? @"MemberJoined" : @"MemberInvited"];
	cell.statusLabel.text = [member.inviteStatus isEqualToString:@"joined"] ? @"joined" : @"invited";
	
    return cell;
}


#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Leave album", @"")
													message:NSLocalizedString(@"Are you sure you want to leave this album?", @"")
												   delegate:nil
										  cancelButtonTitle:NSLocalizedString(@"No", @"")
										  otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
	alert.delegate = self;
	[alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	if (buttonIndex == 1) {
		NSLog(@"Leave album");
		ShotVibeAPI *shotvibeAPI = [self.parentController.albumManager getShotVibeAPI];
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
			[shotvibeAPI leaveAlbumWithId:self.albumContents.albumId];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				
			});
		});
	}
}


@end
