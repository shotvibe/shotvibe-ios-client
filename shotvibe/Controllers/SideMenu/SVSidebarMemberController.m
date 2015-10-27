//
//  SVSidebarMenuViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 2/15/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <AddressBook/AddressBook.h>

#import "SVAlbumGridViewController.h"
#import "SVDefines.h"
#import "SVSidebarAlbumMemberCell.h"
#import "SVSidebarMemberController.h"
#import "SVAddFriendsViewController.h"
#import "UIImageView+WebCache.h"
#import "MFSideMenu.h"
#import "ShotVibeAppDelegate.h"
#import "SL/AuthData.h"
#import "SL/ShotVibeAPI.h"
#import "SL/AlbumMember.h"
#import "SL/AlbumContents.h"
#import "SL/ArrayList.h"
#import "SL/AlbumUser.h"
#import "MBProgressHUD.h"

@interface SVSidebarMemberController () {
    SLShotVibeAPI *shotvibeAPI;
	NSMutableArray *members;
    SLAlbumMember *owner;
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

- (void)viewDidLoad
{
    [super viewDidLoad];

    // IOS7
    if (IS_IOS7) {
        self.sidebarNav.tintColor = [UIColor blackColor];
        self.sidebarNav.barTintColor = BLUE;

        UIView *background = [[UIView alloc] initWithFrame:CGRectMake(0, -20, 568, 20)];
        background.backgroundColor = BLUE;
        [self.view addSubview:background];
    } else {
        self.wantsFullScreenLayout = NO;
        UIImage *baseImage = [UIImage imageNamed:@"sidebarMenuNavbar.png"];
        UIEdgeInsets insets = UIEdgeInsetsMake(5, 20, 0, 20);
        UIImage *resizableImage = [baseImage resizableImageWithCapInsets:insets];
        [self.sidebarNav setBackgroundImage:resizableImage forBarMetrics:UIBarMetricsDefault];
    }

    self.tableView.backgroundColor = [UIColor clearColor];
    [self.tableView setAllowsSelection:YES];

    self.noMembersView.hidden = YES;

    ownerCell = [self.tableView dequeueReusableCellWithIdentifier:@"AlbumMemberCell"];
    ownerCell.frame = CGRectMake(0, 0, 320, 52);
    ownerCell.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    ownerCell.userInteractionEnabled = NO;
    [self.butOwner addSubview:ownerCell];

    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [[NSNotificationCenter defaultCenter] addObserverForName:MFSideMenuStateNotificationEvent
                                                      object:nil
                                                       queue:queue
                                                  usingBlock:^(NSNotification *note)
    {
        if ([note.userInfo[@"eventType"] integerValue] == MFSideMenuStateEventMenuDidOpen) {
            [[Mixpanel sharedInstance] track:@"Members Panel Opened"
                                  properties:@{ @"album_id" : [NSString stringWithFormat:@"%lld", [self.albumContents getId]] }];
        }

        // This is called when you open and close the side menu
        if ([note.userInfo[@"eventType"] integerValue] == MFSideMenuStateEventMenuDidClose) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self resignFirstResponder];
            }


                           );
        }
    }


    ];
}


#pragma mark - Actions


- (void)navigateToAddFriends:(id)sender
{
    // prepareForSegue is called in parentController SVAlbumGridViewController
    [self.parentController performSegueWithIdentifier:@"AddFriendsSegue" sender:sender];
}


- (IBAction)addFriendsButtonPressed:(id)sender
{
    NSLog(@"contacts auth status: %ld", ABAddressBookGetAuthorizationStatus());

    [[Mixpanel sharedInstance] track:@"Add Friends Button Pressed"
                          properties:@{ @"album_id" : [NSString stringWithFormat:@"%lld", [self.albumContents getId]] }];

    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        [self navigateToAddFriends:sender];
    } else {
        CFErrorRef error;
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
        NSLog(@"addressBook: %@", addressBook);

        // This is needed to block the UI until the completion block is called (prevents a possible race condition)
        MBProgressHUD *invisibleBlockingHUD = [MBProgressHUD showHUDAddedTo:self.view.window animated:NO];
        invisibleBlockingHUD.mode = MBProgressHUDModeText; // This gets rid of the default activity indicator
        invisibleBlockingHUD.opacity = 0.0f;

        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            NSLog(@"complete addressBook: %@", addressBook);
            NSLog(@"complete granted: %d", granted);
            NSLog(@"complete error: %@", error);

            dispatch_async(dispatch_get_main_queue(), ^{
                // Unblock the UI:
                [invisibleBlockingHUD hide:NO];

                if (granted) {
                    [self navigateToAddFriends:sender];
                } else {
                    [[Mixpanel sharedInstance] track:@"Add Friends Permission Denied"
                                          properties:@{ @"album_id" : [NSString stringWithFormat:@"%lld", [self.albumContents getId]] }];

                    NSString *errorMessage =
                        @"In order to invite people we need access to your contacts list.\n\n"
                        @"To enable it go to Settings/Privacy/Contacts";

                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                    message:errorMessage
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                    [alert show];
                }
            });
        });
    }
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

- (void)setAlbumContents:(SLAlbumContents *)albumContents
{
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
        [ownerCell.profileImageView setImageWithURL:[NSURL URLWithString:[[owner getUser] getMemberAvatarUrl]]];
        ownerCell.profileImageView.layer.cornerRadius = roundf(ownerCell.profileImageView.frame.size.width / 2.0);
        ownerCell.profileImageView.layer.masksToBounds = YES;
        [ownerCell.memberLabel setText:[[owner getUser] getMemberNickname]];
        ownerCell.statusImageView.image = [UIImage imageNamed:@"AlbumInfoLeaveIcon.png"];
        ownerCell.statusLabel.text = NSLocalizedString(@"Leave", nil);
        CGSize size = [ownerCell.statusLabel.text sizeWithFont:ownerCell.statusLabel.font];
        ownerCell.statusImageView.frame = CGRectMake(ownerCell.statusLabel.frame.origin.x + ownerCell.statusLabel.frame.size.width - size.width - 4 - ownerCell.statusImageView.frame.size.width, ownerCell.statusImageView.frame.origin.y, 13, 13);
    } else {
        // There are some members
        self.noMembersView.hidden = YES;
        self.tableView.hidden = NO;
        self.searchBar.userInteractionEnabled = YES;
        self.butOwner.enabled = NO;
        self.butAddFriends.frame = CGRectMake(16, 55, 240, 40);

        ownerCell.hidden = YES;
    }
}

- (void)setParentController:(GLFeedViewController *)parentController {
	RCLog(@"setParentController %@", parentController);
	_parentController = parentController;
    shotvibeAPI = [[ShotVibeAppDelegate sharedDelegate].albumManager getShotVibeAPI];
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

    SLAlbumMember *member = [members objectAtIndex:indexPath.row];
	
    [cell.profileImageView setImageWithURL:[NSURL URLWithString:[[member getUser] getMemberAvatarUrl]]];
    [cell.memberLabel setText:[[member getUser] getMemberNickname]];

    if ([[shotvibeAPI getAuthData] getUserId] == [[member getUser] getMemberId]) {
		
		cell.statusImageView.image = [UIImage imageNamed:@"AlbumInfoLeaveIcon.png"];
		cell.statusLabel.text = NSLocalizedString(@"Leave", nil);
        CGSize size = [cell.statusLabel.text sizeWithFont:cell.statusLabel.font];
        cell.statusImageView.frame = CGRectMake(cell.statusLabel.frame.origin.x + cell.statusLabel.frame.size.width - size.width - 4 - cell.statusImageView.frame.size.width, cell.statusImageView.frame.origin.y, 13, 13);
	}
	else {
        if (![member getInviteStatus]) {
            cell.statusImageView.image = nil;
            cell.statusLabel.text = @"";
        } else {
            switch ([member getInviteStatus].ordinal) {
                case SLAlbumMember_InviteStatus_JOINED:
                    cell.statusImageView.image = [UIImage imageNamed:@"MemberJoined"];
                    cell.statusLabel.text = NSLocalizedString(@"Joined", nil);
                    break;

                case SLAlbumMember_InviteStatus_SMS_SENT:
                case SLAlbumMember_InviteStatus_INVITATION_VIEWED:
                    cell.statusImageView.image = [UIImage imageNamed:@"MemberInvited"];
                    cell.statusLabel.text = NSLocalizedString(@"Invited", nil);
                    break;
            }
            CGSize size = [cell.statusLabel.text sizeWithFont:cell.statusLabel.font];
            cell.statusImageView.frame = CGRectMake(175 + cell.statusLabel.frame.size.width - size.width - 4 - cell.statusImageView.frame.size.width, cell.statusImageView.frame.origin.y, 13, 13);
        }
	}
	//RCLog(@"%lld == %lld member.avatarUrl %@", shotvibeAPI.authData.userId, member.memberId, member.avatarUrl);
    return cell;
}


#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if ([self.searchBar isFirstResponder])
		[self.searchBar resignFirstResponder];
	
    SLAlbumMember *member = [members objectAtIndex:indexPath.row];
	
    if ([[shotvibeAPI getAuthData] getUserId] == [[member getUser] getMemberId]) {
		
		[self ownerButtonPressed:nil];
	}
}


#pragma mark UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	if (buttonIndex == 1) {
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            // TODO
            // - Show spinner while loading
            // - If failed, then show dialog with "retry" button

            SLAPIException *apiException;
            @try {
                [shotvibeAPI leaveAlbumWithLong:[self.albumContents getId]];
            } @catch (SLAPIException *exception) {
                apiException = exception;
            }

            if (!apiException) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.parentController.menuContainerViewController setMenuState:MFSideMenuStateClosed];
                    [self.parentController.navigationController popViewControllerAnimated:YES];
                });
            }
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
    members = [NSMutableArray arrayWithCapacity:[_albumContents getMembers].array.count];
	
    if ([_albumContents getMembers].array.count == 1) {
        owner = [_albumContents getMembers].array[0];
	}
	else {
        for (SLAlbumMember *member in [_albumContents getMembers].array) {
            if (title == nil || [title isEqualToString:@""] || [[[[member getUser] getMemberNickname] lowercaseString] rangeOfString:title].location != NSNotFound) {
				[members addObject:member];
			}
		}
	}
    
    [self.tableView reloadData];
}

- (BOOL) resignFirstResponder {
	return [self.searchBar resignFirstResponder];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.superview.frame.size.height - self.view.superview.frame.origin.y);
}


@end
