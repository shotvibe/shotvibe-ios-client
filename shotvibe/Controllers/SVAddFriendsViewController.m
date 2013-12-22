//
//  SVAddFriendsViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 4/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVAddFriendsViewController.h"
#import "SVDefines.h"
#import "SVAddressBook.h"
#import "SVRecord.h"
#import "SVContactCell.h"
#import "AlbumContents.h"
#import "MBProgressHUD.h"
#import "UIImageView+AFNetworking.h"


@interface SVAddFriendsViewController ()

@property (nonatomic, strong) IBOutlet UIView *membersView;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIScrollView *addedContactsScrollView;
@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;
@property (nonatomic, weak) IBOutlet UIView *contactsSourceView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *contactsSourceSelector;
@property (nonatomic, weak) IBOutlet UIView *noContactsView;
@property (nonatomic, weak) IBOutlet UIButton *butOverlay;

- (void)cancelPressed:(id)sender;
- (IBAction)donePressed:(id)sender;
- (IBAction)overlayPressed:(id)sender;
- (IBAction)contactsSourceChanged:(UISegmentedControl *)sender;

@end


@implementation SVAddFriendsViewController {
	
	SVAddressBook *ab;
	NSMutableArray *contactsButtons;// list of selected contacts buttons
	NSMutableArray *selectedRecords;// list of ids of the contacts that were selected
	NSMutableArray *favorites;
	BOOL searching;
	NSIndexPath *tappedIndexPath;
}


#pragma mark - View Lifecycle

- (void)viewDidLoad {
	
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	self.noContactsView.hidden = YES;
	self.butOverlay.hidden = YES;
	searching = NO;
//	[[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"favorites"];
//	[[NSUserDefaults standardUserDefaults] synchronize];
	contactsButtons = [[NSMutableArray alloc] init];
	selectedRecords = [[NSMutableArray alloc] init];
	favorites = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"favorites"]];
	
	if (favorites == nil) {
		favorites = [[NSMutableArray alloc] init];
	}
	
	
	// IOS7
	if ([self.navigationController.navigationBar respondsToSelector:@selector(barTintColor)]) {
		self.navigationController.navigationBar.translucent = NO;
		self.view.frame = CGRectMake(0, 64, 320, 568-64);
	}
	
	self.contactsSourceView.hidden = YES;
	self.contactsSourceSelector.frame = IS_IOS7 ? CGRectMake(8, 7, 239, 30) : CGRectMake(5, 7, 233, 30);
    self.contactsSourceSelector.selectedSegmentIndex = 1;
	
	// Address book contacts was already initialized in SVAlbumListViewController and the contacts were cached
	ab = [SVAddressBook sharedBook];
	if (ab.granted) {
		[self handleSearchForText:nil];
	}
	else {
		self.noContactsView.hidden = NO;
	}
    
	// Setup back button
	UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelPressed:)];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self action:@selector(donePressed:)];
	
	self.navigationItem.leftBarButtonItem = backButton;
	self.navigationItem.rightBarButtonItem = doneButton;
	self.navigationItem.rightBarButtonItem.enabled = NO;
	self.title = @"Invite friends";
	if (IS_IOS7) {
		[self setNeedsStatusBarAppearanceUpdate];
	}
}
- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

#pragma mark -
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [ab.filteredKeys count] + ((favorites.count>0 && !searching) ? 1 : 0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0 && favorites.count > 0 && !searching) {
		return favorites.count;
	}
	int dif = (favorites.count > 0 && !searching) ? 1 : 0;
	NSArray *arr = [ab.filteredContacts objectForKey:[ab.filteredKeys objectAtIndex:section-dif]];
	return [arr count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SVContactCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
    
	SVRecord *record = nil;
	
	if (indexPath.section == 0 && favorites.count > 0 && !searching) {
		record = [ab recordOfPhoneId:[[favorites objectAtIndex:indexPath.row] longLongValue]];
	}
	else {
		int dif = (favorites.count > 0 && !searching) ? 1 : 0;
		NSArray *sectionRecords = [ab.filteredContacts objectForKey:[ab.filteredKeys objectAtIndex:indexPath.section-dif]];
		if (indexPath.row >= sectionRecords.count) {
			return cell;
		}
		record = sectionRecords[indexPath.row];
	}
	
    cell.titleLabel.text = record.fullname;
    cell.subtitleLabel.text = record.phone;
	//RCLog(@"record.iconRemotePath %@", record.iconRemotePath);
	if (record != nil && record.iconLocalData != nil) {
		[cell.contactIcon cancelImageRequestOperation];
		cell.contactIcon.image = [[UIImage alloc] initWithData:record.iconLocalData];
	}
	else {
		[cell.contactIcon setImageWithURL:[NSURL URLWithString:record.iconRemotePath!=nil?record.iconRemotePath:record.iconDefaultRemotePath]];
	}
	
	cell.isMemberImage.hidden = record.memberId == 0;
	
	BOOL contains = [selectedRecords containsObject:record];
	cell.checkmarkImage.image = [UIImage imageNamed:contains?@"imageSelected":@"imageUnselected"];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return ab.filteredKeys;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 26;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	
	UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 26)];
	v.backgroundColor = [UIColor colorWithRed:0.92 green:0.93 blue:0.94 alpha:1];
	
	UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 310, 26)];
	[v addSubview:l];
	l.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0];
	l.textColor = [UIColor grayColor];
	l.backgroundColor = [UIColor clearColor];
	
	if (section == 0 && favorites.count > 0 && !searching) {
		l.text = @"Favorites";
	}
	else {
		int dif = (favorites.count > 0 && !searching) ? 1 : 0;
		NSArray *arr = [ab.filteredContacts objectForKey:[ab.filteredKeys objectAtIndex:section-dif]];
		if (arr.count > 0) {
			l.text = [ab.filteredKeys objectAtIndex:section-dif];
		}
	}
	
	return v;
}


#pragma mark - TableviewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self.searchBar resignFirstResponder];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	tappedIndexPath = indexPath;
	RCLog(@"-----didSelect %@", tappedIndexPath);
	SVContactCell *tappedCell = (SVContactCell*)[tableView cellForRowAtIndexPath:indexPath];
	
	SVRecord *record = nil;
	BOOL contains = NO;
	
	if (indexPath.section == 0 && favorites.count > 0 && !searching) {
		record = [ab recordOfPhoneId:[[favorites objectAtIndex:indexPath.row] longLongValue]];
		for (SVRecord *selectedRecord in selectedRecords) {
			if (record.phoneId == selectedRecord.phoneId) {
				record = selectedRecord;
				contains = YES;
				break;
			}
		}
	}
	else {
		int dif = (favorites.count > 0 && !searching) ? 1 : 0;
		NSArray *sectionRecords = [ab.filteredContacts objectForKey:[ab.filteredKeys objectAtIndex:indexPath.section-dif]];
		record = sectionRecords[indexPath.row];
		contains = [selectedRecords containsObject:record];;
	}
	
	// Check if this contact has a phone number
	if (record.invalid) {
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
														message:NSLocalizedString(@"This user does not have a valid phone number, you can't invite him.", @"")
													   delegate:self
											  cancelButtonTitle:NSLocalizedString(@"Ok", @"")
											  otherButtonTitles:nil];
		[alert show];
		
		return;
	}
	
	// Check if the tapped contact is already used.
	// If yes, remove it
	RCLogO(selectedRecords);
	RCLogO(record);
	RCLog(@"phoneId %lli", record.phoneId);
	
	tappedCell.checkmarkImage.image = [UIImage imageNamed:contains?@"imageUnselected":@"imageSelected"];
	
	if (contains) {
		[self removeContactFromTable:record];
	}
	else {
        [self addToContactsList:record];
	}
}


#pragma mark -
#pragma mark Search

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
	[searchBar setShowsCancelButton:YES animated:YES];
	self.contactsSourceView.alpha = 0;
	self.contactsSourceView.hidden = NO;
	self.butOverlay.alpha = 0;
	self.butOverlay.hidden = NO;
	[UIView animateWithDuration:0.3 animations:^{
		self.tableView.frame = CGRectMake(0, 44+44, 320, self.view.frame.size.height-44-44-216);
		self.contactsSourceView.alpha = 1;
		self.butOverlay.alpha = 0.2;
	}];
}
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
	[searchBar setShowsCancelButton:NO animated:YES];
	self.contactsSourceView.hidden = YES;
	self.butOverlay.hidden = YES;
	[UIView animateWithDuration:0.3 animations:^{
		self.tableView.frame = CGRectMake(0, 44+75, 320, self.view.frame.size.height-44-75);
	}];
}
-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
	if (searchText.length == 0) {
		[searchBar resignFirstResponder];
    }
	[self handleSearchForText: searchText.length == 0 ? nil : searchText];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	[searchBar resignFirstResponder];
	searchBar.text = @"";
	[self handleSearchForText:nil];
}
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)bar {
    return YES;
}

- (void) handleSearchForText:(NSString*)str {
	
	searching = (str != nil && ![str isEqualToString:@""]);
	BOOL membersOny = self.contactsSourceSelector.selectedSegmentIndex == 0;
	
	[ab filterByKeyword:str membersOnly:membersOny completionBlock:^{
		[self.tableView reloadData];
	}];
}



#pragma mark - Private Methods

- (void)addToContactsList:(SVRecord*)record {
	
	NSString *shortName = [[record.fullname componentsSeparatedByString:@" "] objectAtIndex:0];
	
    //create a new dynamic button
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.frame = CGRectMake(0, 0, 100, 20);
	button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0];
	button.titleLabel.shadowColor = [UIColor clearColor];
	[button setTitle:shortName forState:UIControlStateNormal];
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[button setImage:[UIImage imageNamed:@"contactsX.png"] forState:UIControlStateNormal];
	[button setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
	[button setTag:record.phoneId];
	
	CGRect f = button.frame;
	f.size = button.intrinsicContentSize;
	f.size.width += 20;
	button.frame = f;
	
	UIImage *baseImage = [UIImage imageNamed:@"butInvitedContacts.png"];
	UIEdgeInsets insets = UIEdgeInsetsMake(5, 20, 5, 20);
	UIImage *resizableImage = [baseImage resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
	
	[button setBackgroundImage:resizableImage forState:UIControlStateNormal];
	[button addTarget:self action:@selector(removeContactFromList:) forControlEvents:UIControlEventTouchUpInside];
	[self.addedContactsScrollView addSubview:button];
	[contactsButtons addObject:button];
	button.alpha = 0;
	
	[selectedRecords addObject:record];
    [self updateContacts];
	
	// Scroll to right only after we add a new contact not on removal
	if (self.addedContactsScrollView.contentSize.width > self.addedContactsScrollView.frame.size.width) {
		[UIView animateWithDuration:0.3 animations:^{
			[self.addedContactsScrollView setContentOffset:CGPointMake(self.addedContactsScrollView.contentSize.width-self.addedContactsScrollView.frame.size.width, 0)];
		}];
	}
	
	[UIView animateWithDuration:0.6 animations:^{
		button.alpha = 1;
	}];
}

- (void)removeContactFromTable:(SVRecord*)record {
	
	NSMutableArray *arr = contactsButtons;
	for (UIButton *but in arr) {
		if (but.tag == record.phoneId) {
			[contactsButtons removeObject:but];
			[but removeFromSuperview];
			[selectedRecords removeObject:record];
			[self updateContacts];
			break;
		}
	}
}

- (void)removeContactFromList:(UIButton *)sender {
	
	NSMutableArray *arr = selectedRecords;
	for (SVRecord *record in arr) {
		if (record.phoneId == sender.tag) {
			[selectedRecords removeObject:record];
			break;
		}
	}
	
	[sender removeFromSuperview];
	[contactsButtons removeObject:sender];
	[self updateContacts];
	[self.tableView reloadData];
}

- (void)updateContacts {
	
	int i = 0;
	int x_1 = 80;
	int x_2 = 5;
	
	for (UIButton *but in contactsButtons) {
		
		CGRect frame;
		
		if (i % 2 == 0) {
			// Line 2
			frame = CGRectMake (x_2, 40, but.frame.size.width, 30);
			x_2 = x_2 + but.frame.size.width + 5;
		}
		else {
			// Line 1
			frame = CGRectMake (x_1, 5, but.frame.size.width, 30);
			x_1 = x_1 + but.frame.size.width + 5;
		}
		i++;
		
		[UIView animateWithDuration:0.3 animations:^{
			but.frame = frame;
		}];
	}
	
	[self.addedContactsScrollView setContentSize:(CGSizeMake(x_1 > x_2 ? x_1 : x_2, self.addedContactsScrollView.frame.size.height))];
	self.navigationItem.rightBarButtonItem.enabled = contactsButtons.count > 0;
}



#pragma mark - Actions

- (IBAction)donePressed:(id)sender {
    // add members to album
    //TODO if already shotvibe member just add to album else sent notification to user to join?
    RCLog(@"contacts to add >> ");
	
	[MBProgressHUD showHUDAddedTo:self.view animated:YES];
	
	NSMutableArray *contactsToInvite = [[NSMutableArray alloc] init];
	NSString *countryCode = [self.albumManager getShotVibeAPI].authData.defaultCountryCode;
	
	for (SVRecord *record in selectedRecords) {
		
		[contactsToInvite addObject:@{
		 @"phone_number":record.phone,
		 @"default_country":countryCode,
		 @"contact_nickname":record.fullname}];
		
		NSNumber *id_ = [NSNumber numberWithLongLong:record.phoneId];
		if (![favorites containsObject:id_]) {
			[favorites addObject:id_];
		}
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:favorites forKey:@"favorites"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	//[contactsToInvite addObject:@{@"phone_number": @"+40700000002", @"default_country":regionCode, @"contact_nickname":@"Cristi"}];
	//[contactsToInvite addObject:@{@"phone_number": @"(070) 000-0001", @"default_country":regionCode, @"contact_nickname":@"Cristi"}];
	
	if (contactsToInvite.count > 0) {
		
		__block NSDictionary *phoneNumbers = @{@"add_members": contactsToInvite};
		RCLog(@"contactsToInvite %@", phoneNumbers);
		
		// send request
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
			NSError *error;
			AlbumContents *r = [[self.albumManager getShotVibeAPI] albumAddMembers:self.albumId phoneNumbers:contactsToInvite withError:&error];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				RCLog(@"r.members %@", r.members);
				RCLog(@"invite sent - success/error: %@", error);
				[MBProgressHUD hideHUDForView:self.view animated:YES];
				[self.navigationController dismissViewControllerAnimated:YES completion:nil];
			});
		});
	}
}

- (void)cancelPressed:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)contactsSourceChanged:(UISegmentedControl *)sender {
	
    if (sender.selectedSegmentIndex == 2) {
		
    }
	else {
		[self handleSearchForText:nil];
    }
}

- (IBAction)overlayPressed:(id)sender {
	[self.searchBar resignFirstResponder];
}

@end
