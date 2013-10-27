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
#import "MFSideMenu.h"

#import "AlbumMember.h"

@interface SVSidebarMemberController () {
	ShotVibeAPI *shotvibeAPI;
	NSMutableArray *members;
}

@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UINavigationBar *sidebarNav;

- (IBAction)addFriendsButtonPressed:(id)sender;

@end



@implementation SVSidebarMemberController

#pragma mark - Actions

- (IBAction)addFriendsButtonPressed:(id)sender {
	// prepareForSegue is called in parentController SVAlbumGridViewController
    [self.parentController performSegueWithIdentifier:@"AddFriendsSegue" sender:sender];
}


#pragma mark - Properties

- (void)setAlbumContents:(AlbumContents *)albumContents {
    _albumContents = albumContents;
    [self searchForMemberWithName:nil];
}

- (void)setParentController:(SVAlbumGridViewController *)parentController {
	_parentController = parentController;
	shotvibeAPI = [self.parentController.albumManager getShotVibeAPI];
    [self searchForMemberWithName:nil];
}


#pragma mark - View Lifecycle

- (void)viewDidLoad {
	
    [super viewDidLoad];
    
	UIImage *baseImage = [UIImage imageNamed:@"sidebarMenuNavbar.png"];
	UIEdgeInsets insets = UIEdgeInsetsMake(5, 20, 0, 20);
	UIImage *resizableImage = [baseImage resizableImageWithCapInsets:insets];
	[self.sidebarNav setBackgroundImage:resizableImage forBarMetrics:UIBarMetricsDefault];
	self.tableView.delegate = self;
	[self.tableView setAllowsSelection:YES];
	self.wantsFullScreenLayout = NO;
	
	[self.searchBar setBackgroundImage:[UIImage imageNamed:@"SearchBlackBg.png"]];
	UIImage *search_bg = [UIImage imageNamed:@"searchFieldDarkBg.png"];
	UIImage *resizable_bg = [search_bg resizableImageWithCapInsets:UIEdgeInsetsMake(5, 20, 5, 20) resizingMode:UIImageResizingModeStretch];
	[self.searchBar setSearchFieldBackgroundImage:resizable_bg forState:UIControlStateNormal];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return members.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    SVSidebarAlbumMemberCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AlbumMemberCell"];

    AlbumMember *member = [members objectAtIndex:indexPath.row];
	
    [cell.profileImageView setImageWithURL:[NSURL URLWithString:member.avatarUrl]];
	[cell.memberLabel setText:member.nickname];
	
	if (shotvibeAPI.authData.userId == member.memberId) {
		
		cell.statusImageView.frame = CGRectMake(204-34, 14, 13, 13);
		cell.statusImageView.image = [UIImage imageNamed:@"AlbumInfoLeaveIcon.png"];
		cell.statusLabel.frame = CGRectMake(220-34, 0, 70, 41);
		cell.statusLabel.text = @"Leave Album";
		//cell.userInteractionEnabled = YES;
	}
	else {
		cell.statusImageView.frame = CGRectMake(204, 14, 13, 13);
		cell.statusImageView.image = [UIImage imageNamed:[member.inviteStatus isEqualToString:@"joined"] ? @"MemberJoined" : @"MemberInvited"];
		cell.statusLabel.frame = CGRectMake(220, 0, 70, 41);
		cell.statusLabel.text = [member.inviteStatus isEqualToString:@"joined"] ? @"joined" : @"invited";
		//cell.userInteractionEnabled = NO;
	}
	//RCLog(@"%lld == %lld member.avatarUrl %@", shotvibeAPI.authData.userId, member.memberId, member.avatarUrl);
    return cell;
}


#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
	if ([self.searchBar isFirstResponder])
		[self.searchBar resignFirstResponder];
	
	AlbumMember *member = [members objectAtIndex:indexPath.row];
	
	if (shotvibeAPI.authData.userId == member.memberId) {
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Leave album", @"")
														message:NSLocalizedString(@"Are you sure you want to leave this album?", @"")
													   delegate:nil
											  cancelButtonTitle:NSLocalizedString(@"No", @"")
											  otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
		alert.delegate = self;
		[alert show];
	}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	if (buttonIndex == 1) {
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
			BOOL success = [shotvibeAPI leaveAlbumWithId:self.albumContents.albumId];
			
			if (success) dispatch_async(dispatch_get_main_queue(), ^{
				[self.parentController.menuContainerViewController setMenuState:MFSideMenuStateClosed];
				[self.parentController.navigationController popViewControllerAnimated:YES];
			});
		});
	}
}



#pragma mark - UISearchbarDelegate Methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
	
	CGRect f = self.tableView.frame;
	f.size.height = [UIScreen mainScreen].bounds.size.height-216-20-44;
	
	[UIView animateWithDuration:0.3 animations:^{
		self.tableView.frame = f;
	}];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
	
	CGRect f = self.tableView.frame;
	f.size.height = [UIScreen mainScreen].bounds.size.height-20-44;
	
	[UIView animateWithDuration:0.2 animations:^{
		self.tableView.frame = f;
	}];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self searchForMemberWithName:searchBar.text];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [self searchForMemberWithName:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	[searchBar resignFirstResponder];
	searchBar.text = @"";
	[self searchForMemberWithName:nil];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)bar {
    return YES;
}

- (void)searchForMemberWithName:(NSString *)title
{
	members = [NSMutableArray arrayWithCapacity:[_albumContents.members count]];
	
    for (AlbumMember *member in _albumContents.members) {
		if (title == nil || [title isEqualToString:@""] || [[member.nickname lowercaseString] rangeOfString:title].location != NSNotFound) {
			[members addObject:member];
		}
    }
    [self.tableView reloadData];
}

- (BOOL) resignFirstResponder {
	return [self.searchBar resignFirstResponder];
}

@end
