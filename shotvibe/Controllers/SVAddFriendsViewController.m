//
//  SVAddFriendsViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 4/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVAddFriendsViewController.h"
#import "SVAddressBook.h"
#import "SVContactCell.h"
#import "SVDefines.h"
#import "AlbumContents.h"
#import "MBProgressHUD.h"
#import "UIImageView+AFNetworking.h"


@interface SVAddFriendsViewController ()<UISearchBarDelegate>

@property (nonatomic, strong) IBOutlet UIView *membersView;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIScrollView *addedContactsScrollView;
@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, weak) IBOutlet UISegmentedControl *segmentControl;
@property (nonatomic, weak) IBOutlet UIView *noContactsView;

- (IBAction)cancelPressed:(id)sender;
- (IBAction)donePressed:(id)sender;

@end

@implementation SVAddFriendsViewController
{
	SVAddressBook *ab;
	NSMutableArray *contactsButtons;// list of selected contacts buttons
	NSMutableArray *selectedIds;// list of ids of the contacts that were selected
}

#pragma mark - Actions

- (IBAction)donePressed:(id)sender {
    // add members to album
    //TODO if already shotvibe member just add to album else sent notification to user to join?
    RCLog(@"contacts to add >> ");
	
	[MBProgressHUD showHUDAddedTo:self.view animated:YES];
	
	NSMutableArray *contactsToInvite = [[NSMutableArray alloc] init];
	NSString *countryCode = [self.albumManager getShotVibeAPI].authData.defaultCountryCode;
	
	for (id record in selectedIds) {
		
		ABMultiValueRef phoneNumbers = ABRecordCopyValue((__bridge ABRecordRef)(record), kABPersonPhoneProperty);
		NSString *name = (__bridge_transfer NSString*) ABRecordCopyCompositeName((__bridge ABRecordRef)(record));
		
		[contactsToInvite addObject:@{
		 @"phone_number":(__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, 0),
		 @"default_country":countryCode,
		 @"contact_nickname":name==nil?@"":name}];
		
		CFRelease(phoneNumbers);
	}
	
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


- (IBAction)cancelPressed:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)segmentChanged:(UISegmentedControl *)sender
{
    if (sender.selectedSegmentIndex == 0) {
        //show shotvibe
        [self loadShotVibeContacts];
    }else{
        //show phone contacts
        [self loadAddressbookContacts];
    }
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	self.noContactsView.hidden = YES;
	
	contactsButtons = [[NSMutableArray alloc] init];
	selectedIds = [[NSMutableArray alloc] init];
	ab = [[SVAddressBook alloc] initWithBlock:^(BOOL granted, NSError *error) {
		if (granted) {
			//[self loadShotVibeContacts];
			[self loadAddressbookContacts];
		}
		else {
			self.noContactsView.hidden = NO;
		}
	}];
    
    CGRect segmentFrame = self.segmentControl.frame;
    segmentFrame.origin.y -= 1.5;
    self.segmentControl.frame = segmentFrame;
    self.segmentControl.selectedSegmentIndex = 1;
	
	
//	[self.segmentControl setDividerImage:[UIImage imageNamed:@"SegmentSeparator.png"] forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
//	[self.segmentControl setDividerImage:[UIImage imageNamed:@"SegmentSeparator.png"] forLeftSegmentState:UIControlStateSelected rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
//	[self.segmentControl setDividerImage:[UIImage imageNamed:@"SegmentSeparator.png"] forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
	
	
	// Setup back button
	UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelPressed:)];
    NSDictionary *att = @{UITextAttributeFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:16.0], UITextAttributeTextShadowColor:[UIColor clearColor]};
	[backButton setTitleTextAttributes:att forState:UIControlStateNormal];
	[backButton setTitlePositionAdjustment:UIOffsetMake(-5,2) forBarMetrics:UIBarMetricsDefault];
	
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self action:@selector(donePressed:)];
	[doneButton setTitleTextAttributes:att forState:UIControlStateNormal];
	[doneButton setTitlePositionAdjustment:UIOffsetMake(0,2) forBarMetrics:UIBarMetricsDefault];
	
	self.navigationItem.leftBarButtonItem = backButton;
	self.navigationItem.rightBarButtonItem = doneButton;
	self.navigationItem.rightBarButtonItem.enabled = NO;
	self.title = @"Invite friends";
}


#pragma mark -
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [ab.filteredKeys count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSArray *arr = [ab.filteredContacts objectForKey:[ab.filteredKeys objectAtIndex:section]];
	return [arr count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SVContactCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
    
	NSArray *sectionRecords = [ab.filteredContacts objectForKey:[ab.filteredKeys objectAtIndex:indexPath.section]];
	ABRecordRef record = (__bridge ABRecordRef)sectionRecords[indexPath.row];
	NSString *name = (__bridge_transfer NSString*) ABRecordCopyCompositeName(record);
	ABMultiValueRef phoneNumbers = ABRecordCopyValue(record, kABPersonPhoneProperty);
	NSString* phoneNumber = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, 0);
	
    cell.titleLabel.text = [NSString stringWithFormat:@"%@", name==nil?@"":name];
    cell.subtitleLabel.text = [NSString stringWithFormat:@"%@", phoneNumber==nil?@"":phoneNumber];
	
	if (record != nil && ABPersonHasImageData(record)) {
		NSData *contactImageData = (__bridge_transfer NSData*) ABPersonCopyImageDataWithFormat(record, kABPersonImageFormatThumbnail);
		[cell.contactIcon cancelImageRequestOperation];
		cell.contactIcon.image = [[UIImage alloc] initWithData:contactImageData];
	}
	else {
//		int lowerBound = 1;
//		int upperBound = 78;
//		int rndValue = lowerBound + arc4random() % (upperBound - lowerBound);
		int i = 1 + indexPath.row;
		if (i>78) {
			i = 1 + i%78;
		}
		//cell.contactIcon.image = [UIImage imageNamed:[NSString stringWithFormat:@"default-avatar-0%i.png", rndValue]];
		[cell.contactIcon setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://shotvibe-avatars-01.s3.amazonaws.com/default-avatar-00%@%i.jpg", i<10?@"0":@"", i]]];
	}
	if (phoneNumbers != nil) CFRelease(phoneNumbers);
	
	BOOL contains = [selectedIds containsObject:(__bridge id)(record)];
	cell.checkmarkImage.image = [UIImage imageNamed:contains?@"imageSelected":@"imageUnselected"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}


- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
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
	
	NSArray *arr = [ab.filteredContacts objectForKey:[ab.filteredKeys objectAtIndex:section]];
	
    if ([arr count] > 0) {
        l.text = [ab.filteredKeys objectAtIndex:section];
    }
	
	return v;
}


#pragma mark - TableviewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self.searchBar resignFirstResponder];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	SVContactCell *tappedCell = (SVContactCell*)[tableView cellForRowAtIndexPath:indexPath];
	
	NSMutableArray *sectionRecords = [ab.filteredContacts objectForKey:[ab.filteredKeys objectAtIndex:indexPath.section]];
	ABRecordRef record = (__bridge ABRecordRef)(sectionRecords[indexPath.row]);
	ABMultiValueRef phoneNumbers = ABRecordCopyValue(record, kABPersonPhoneProperty);
	NSString* phoneNumber = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, 0);
	NSString* phoneNumericNumber = [phoneNumber stringByTrimmingCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
	CFRelease(phoneNumbers);
	//RCLog(@"%@ %@", phoneNumber, phoneNumericNumber);
	
	// Check if this contact has a phone number
	if (phoneNumber == nil || phoneNumericNumber.length == 0) {
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
														message:NSLocalizedString(@"This user has no mobile phone number, you can't invite him.", @"")
													   delegate:self
											  cancelButtonTitle:NSLocalizedString(@"Ok", @"")
											  otherButtonTitles:nil];
		[alert show];
		
		return;
	}
	
	// Check if the tapped contact is already used.
	// If yes, remove it
	
	BOOL contains = [selectedIds containsObject:(__bridge id)(record)];
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
	[UIView animateWithDuration:0.3 animations:^{
		self.tableView.frame = CGRectMake(0, 44, 320, self.view.frame.size.height-44-216);
	}];
}
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
	[searchBar setShowsCancelButton:NO animated:YES];
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
	RCLog(@"cancel clicked");
	[searchBar resignFirstResponder];
	searchBar.text = @"";
	[self handleSearchForText:nil];
}
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)bar {
    return YES;
}



- (void) handleSearchForText:(NSString*)str {
	RCLog(@"handle search %@", str);
	
	[ab filterByKeyword:str completionBlock:^{
		[self.tableView reloadData];
	}];
}



#pragma mark - Private Methods

-(void)addToContactsList:(ABRecordRef)record
{
	//CFStringRef firstName = ABRecordCopyValue(record, kABPersonFirstNameProperty);
	//CFStringRef lastName = ABRecordCopyValue(record, kABPersonLastNameProperty);
	NSString *name = (__bridge_transfer NSString*) ABRecordCopyCompositeName(record);
	long long tag = [ab idOfRecord:record];
	
    //create a new dynamic button
	UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0];
	button.titleLabel.shadowColor = [UIColor clearColor];
	[button setTitle:(name==nil?@"":name) forState:UIControlStateNormal];
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[button setImage:[UIImage imageNamed:@"contactsX.png"] forState:UIControlStateNormal];
	[button setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
	[button setTag:tag];
	[button sizeToFit];
	RCLog(@"add %lli", (long long)button.tag);
	
	UIImage *baseImage = [UIImage imageNamed:@"butInvitedContacts.png"];
	UIEdgeInsets insets = UIEdgeInsetsMake(5, 20, 5, 20);
	UIImage *resizableImage = [baseImage resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
	
	[button setBackgroundImage:resizableImage forState:UIControlStateNormal];
	[button addTarget:self action:@selector(removeContactFromList:) forControlEvents:UIControlEventTouchUpInside];
	[self.addedContactsScrollView addSubview:button];
	[contactsButtons addObject:button];
	button.alpha = 0;
	
	[selectedIds addObject:(__bridge id)(record)];
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
-(void)removeContactFromTable:(ABRecordRef)record
{
	NSMutableArray *arr = contactsButtons;
	for (UIButton *but in arr) {
		if (but.tag == [ab idOfRecord:record]) {
			RCLog(@"remove 1 %i", but.tag);
			[contactsButtons removeObject:but];
			[but removeFromSuperview];
			[selectedIds removeObject:(__bridge id)(record)];
			[self updateContacts];
			break;
		}
	}
}

-(void)removeContactFromList:(UIButton *)sender
{
	for (id record in selectedIds) {
		if ([ab idOfRecord:(__bridge ABRecordRef)(record)] == sender.tag) {
			RCLog(@"remove 2 %i", sender.tag);
			[selectedIds removeObject:record];
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


-(void)loadShotVibeContacts
{
    [self.tableView reloadData];
}

-(void)loadAddressbookContacts
{
	[self handleSearchForText:nil];
}

@end
