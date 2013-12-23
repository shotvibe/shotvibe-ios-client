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
	AlbumMember *owner;
	SVSidebarAlbumMemberCell *ownerCell;
}

@property (nonatomic, strong) IBOutlet UINavigationBar *sidebarNav;
@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIView *noMembersView;
@property (nonatomic, strong) IBOutlet UIButton *butAddFriends;
@property (nonatomic, strong) IBOutlet UIButton *butOwner;

- (IBAction)addFriendsButtonPressed:(id)sender;
- (IBAction)ownerButtonPressed:(id)sender;

@end



@implementation SVSidebarMemberController


#pragma mark - View Lifecycle

- (void)viewDidLoad {
	RCLog(@"VIEWDIDLOAD");
    [super viewDidLoad];
	
	// IOS7
	if (IS_IOS7) {
		self.sidebarNav.tintColor = [UIColor blackColor];
		self.sidebarNav.barTintColor = BLUE;
		
		UIView *background = [[UIView alloc] initWithFrame:CGRectMake(0, -20, 568, 20)];
		background.backgroundColor = BLUE;
		[self.view addSubview:background];
	}
	else {
		self.wantsFullScreenLayout = NO;
		UIImage *baseImage = [UIImage imageNamed:@"sidebarMenuNavbar.png"];
		UIEdgeInsets insets = UIEdgeInsetsMake(5, 20, 0, 20);
		UIImage *resizableImage = [baseImage resizableImageWithCapInsets:insets];
		[self.sidebarNav setBackgroundImage:resizableImage forBarMetrics:UIBarMetricsDefault];
	}
	
	//CGRect inf = self.view.frame;
	self.view.frame = [UIScreen mainScreen].bounds;
	self.tableView.delegate = self;
	[self.tableView setAllowsSelection:YES];
	
	self.noMembersView.hidden = YES;
	
	self.searchBar.backgroundImage = [UIImage imageNamed:@"SearchBlackBg.png"];
	UIImage *search_bg = [UIImage imageNamed:@"searchFieldDarkBg.png"];
	UIImage *resizable_bg = [search_bg resizableImageWithCapInsets:UIEdgeInsetsMake(5, 20, 5, 20) resizingMode:UIImageResizingModeStretch];
	[self.searchBar setSearchFieldBackgroundImage:resizable_bg forState:UIControlStateNormal];
	
	// hack to set the color of the search text to white only in this screen
	for (UIView *subView in self.searchBar.subviews) {
		if (IS_IOS7) {
			for (UIView *ndLeveSubView in subView.subviews) {
				if ([ndLeveSubView isKindOfClass:[UITextField class]]) {
					((UITextField *)ndLeveSubView).textColor = [UIColor whiteColor];
				}
			}
		}
		else {
			if ([subView isKindOfClass:[UITextField class]]) {
				((UITextField *)subView).textColor = [UIColor whiteColor];
			}
		}
	}
	
	ownerCell = [self.tableView dequeueReusableCellWithIdentifier:@"AlbumMemberCell"];
	ownerCell.frame = CGRectMake(0, 0, 320, 42);
	ownerCell.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	ownerCell.userInteractionEnabled = NO;
    [self.butOwner addSubview:ownerCell];
	
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	[[NSNotificationCenter defaultCenter] addObserverForName:MFSideMenuStateNotificationEvent
													  object:nil
													   queue:queue
												  usingBlock:^(NSNotification *note)
	{
		RCLog(@"MFSideMenuStateNotificationEvent");
		// TODO Forgot when is this called, write a comment when you find
		if ([note.userInfo[@"eventType"] integerValue] == 3) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self resignFirstResponder];
			});
		}
	}];
}



#pragma mark - Actions

- (IBAction)addFriendsButtonPressed:(id)sender {
	// prepareForSegue is called in parentController SVAlbumGridViewController
    [self.parentController performSegueWithIdentifier:@"AddFriendsSegue" sender:sender];
}

- (IBAction)ownerButtonPressed:(id)sender {
	
	if ([self.searchBar isFirstResponder])
		[self.searchBar resignFirstResponder];
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Leave album", @"")
													message:NSLocalizedString(@"Are you sure you want to leave this album?", @"")
												   delegate:nil
										  cancelButtonTitle:NSLocalizedString(@"No", @"")
										  otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
	alert.delegate = self;
	[alert show];
}



#pragma mark - Properties

- (void)setAlbumContents:(AlbumContents *)albumContents {
	RCLog(@"setAlbumContents ");
    _albumContents = albumContents;
	
    [self searchForMemberWithName:nil];
	
	if (members.count == 0) {
		// No members
		self.noMembersView.hidden = NO;
		self.tableView.hidden = YES;
		self.searchBar.userInteractionEnabled = NO;
		self.butOwner.enabled = YES;
		self.butAddFriends.frame = CGRectMake(16, 280, 240, 40);
		
		ownerCell.hidden = NO;
		[ownerCell.profileImageView setImageWithURL:[NSURL URLWithString:owner.user.avatarUrl]];
		[ownerCell.memberLabel setText:owner.user.nickname];
		ownerCell.statusImageView.frame = CGRectMake(204-34, 14, 13, 13);
		ownerCell.statusImageView.image = [UIImage imageNamed:@"AlbumInfoLeaveIcon.png"];
		ownerCell.statusLabel.frame = CGRectMake(220-34, 0, 70, 41);
		ownerCell.statusLabel.text = @"Leave Album";
	}
	else {
		// There are some members
		self.noMembersView.hidden = YES;
		self.tableView.hidden = NO;
		self.searchBar.userInteractionEnabled = YES;
		self.butOwner.enabled = NO;
		self.butAddFriends.frame = CGRectMake(16, 54, 240, 40);
		
		ownerCell.hidden = YES;
	}
}

- (void)setParentController:(SVAlbumGridViewController *)parentController {
	RCLog(@"setParentController %@", parentController);
	_parentController = parentController;
	shotvibeAPI = [self.parentController.albumManager getShotVibeAPI];
    [self searchForMemberWithName:nil];
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
	
    [cell.profileImageView setImageWithURL:[NSURL URLWithString:member.user.avatarUrl]];
	[cell.memberLabel setText:member.user.nickname];

	if (shotvibeAPI.authData.userId == member.user.memberId) {
		
		cell.statusImageView.frame = CGRectMake(204-34, 14, 13, 13);
		cell.statusImageView.image = [UIImage imageNamed:@"AlbumInfoLeaveIcon.png"];
		cell.statusLabel.frame = CGRectMake(220-34, 0, 70, 41);
		cell.statusLabel.text = @"Leave Album";
		//cell.userInteractionEnabled = YES;
	}
	else {
		cell.statusImageView.frame = CGRectMake(204, 14, 13, 13);
		cell.statusLabel.frame = CGRectMake(220, 0, 70, 41);
        switch (member.inviteStatus) {
            case AlbumMemberInviteStatusUnknown:
                cell.statusImageView.image = nil;
                cell.statusLabel.text = @"";
                break;

            case AlbumMemberJoined:
                cell.statusImageView.image = [UIImage imageNamed:@"MemberJoined"];
                cell.statusLabel.text = @"joined";
                break;

            case AlbumMemberSmsSent:
            case AlbumMemberInvitationViewed:
                cell.statusImageView.image = [UIImage imageNamed:@"MemberInvited"];
                cell.statusLabel.text = @"invited";
                break;
        }
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
	
	if (shotvibeAPI.authData.userId == member.user.memberId) {
		
		[self ownerButtonPressed:nil];
	}
}


#pragma mark UIAlertView delegate

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
	
	[self.searchBar setShowsCancelButton:YES animated:YES];
	CGRect f = self.tableView.frame;
	f.size.height = [UIScreen mainScreen].bounds.size.height-216-20-135;
	
	[UIView animateWithDuration:0.3 animations:^{
		self.tableView.frame = f;
	}];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
	
	[self.searchBar setShowsCancelButton:NO animated:YES];
	CGRect f = self.tableView.frame;
	f.size.height = [UIScreen mainScreen].bounds.size.height-20-135;
	
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

- (void)searchForMemberWithName:(NSString *)title {
	RCLog(@"search for members with name %@", title);
	members = [NSMutableArray arrayWithCapacity:[_albumContents.members count]];
	
	if (_albumContents.members.count == 1) {
		owner = _albumContents.members[0];
	}
	else {
		for (AlbumMember *member in _albumContents.members) {
			if (title == nil || [title isEqualToString:@""] || [[member.user.nickname lowercaseString] rangeOfString:title].location != NSNotFound) {
				[members addObject:member];
			}
		}
	}
    
    [self.tableView reloadData];
}

- (BOOL) resignFirstResponder {
	return [self.searchBar resignFirstResponder];
}


@end