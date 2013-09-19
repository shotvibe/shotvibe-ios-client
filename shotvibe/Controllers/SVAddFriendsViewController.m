//
//  SVAddFriendsViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 4/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVAddFriendsViewController.h"
#import "SVAddressBookBD.h"
#import "SVDefines.h"
#import "AlbumContents.h"
#import "MBProgressHUD.h"


@interface SVAddFriendsViewController ()<UISearchBarDelegate>

@property (nonatomic, strong) IBOutlet UIView *membersView;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIScrollView *addedContactsScrollView;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;

@property (nonatomic, strong) NSArray *allContacts;
@property (nonatomic, strong) NSMutableDictionary *records;// dictionary of arrays
@property (nonatomic, strong) NSMutableArray *contactsButtons;

- (IBAction)cancelPressed:(id)sender;
- (IBAction)donePressed:(id)sender;

@end

@implementation SVAddFriendsViewController
{
    NSArray *alphabet;
    NSArray *keys;
	BOOL stopCurrentSearch;
}

#pragma mark - Actions

- (IBAction)donePressed:(id)sender {
    // add members to album
    //TODO if already shotvibe member just add to album else sent notification to user to join?
    NSLog(@"contacts to add >> ");
	
	[MBProgressHUD showHUDAddedTo:self.view animated:YES];
	
	NSMutableArray *contactsToInvite = [[NSMutableArray alloc] init];
	NSString *regionCode = [[[NSLocale currentLocale] objectForKey:NSLocaleCountryCode] uppercaseString];
	
	for (NSMutableDictionary *member in self.allContacts) {
		if ([member[@"selected"] boolValue] == YES) {
			NSLog(@"selected %@ regionCode %@", member, regionCode);
			[contactsToInvite addObject:@{@"phone_number":member[@"phone"], @"default_country":regionCode, @"contact_nickname":member[@"nickname"]}];
		}
	}
	
	//[contactsToInvite addObject:@{@"phone_number": @"+40700000002", @"default_country":regionCode, @"contact_nickname":@"Cristi"}];
	//[contactsToInvite addObject:@{@"phone_number": @"(070) 000-0001", @"default_country":regionCode, @"contact_nickname":@"Cristi"}];
	
	if (contactsToInvite.count > 0) {
		
		__block NSDictionary *phoneNumbers = @{@"add_members": contactsToInvite};
		NSLog(@"contactsToInvite %@", phoneNumbers);
		
		// send request
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
			NSError *error;
			AlbumContents *r = [[self.albumManager getShotVibeAPI] albumAddMembers:self.albumId phoneNumbers:contactsToInvite withError:&error];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				NSLog(@"r.members %@", r.members);
				NSLog(@"invite sent - success/error: %@", error);
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
	
	self.contactsButtons = [[NSMutableArray alloc] init];
	alphabet = @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", @"#"];
	keys = [NSArray arrayWithArray:alphabet];
	self.records = [[NSMutableDictionary alloc] init];
	stopCurrentSearch = NO;
	shouldBeginEditing = YES;
    
    CGRect segmentFrame = self.segmentControl.frame;
    segmentFrame.origin.y -= 1.5;
    self.segmentControl.frame = segmentFrame;
    
    //[self loadShotVibeContacts];
	[self loadAddressbookContacts];
	
//	[self.segmentControl setDividerImage:[UIImage imageNamed:@"SegmentSeparator.png"] forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
//	[self.segmentControl setDividerImage:[UIImage imageNamed:@"SegmentSeparator.png"] forLeftSegmentState:UIControlStateSelected rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
//	[self.segmentControl setDividerImage:[UIImage imageNamed:@"SegmentSeparator.png"] forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
	self.segmentControl.selectedSegmentIndex = 1;
	
	
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
}


#pragma mark -
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [keys count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSArray *arr = [self.records objectForKey:[keys objectAtIndex:section]];
	return [arr count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SVContactCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
    
	NSArray *sectionRecords = [self.records objectForKey:[keys objectAtIndex:indexPath.section]];
	
    cell.titleLabel.text = [sectionRecords[indexPath.row] objectForKey:kMemberNickname];
    cell.subtitleLabel.text = [sectionRecords[indexPath.row] objectForKey:kMemberPhone];
	
	UIImage *icon = [sectionRecords[indexPath.row] objectForKey:kMemberIcon];
	if (icon == nil) {
		icon = [UIImage imageNamed:@"default-avatar-0038.png"];
	}
    cell.contactIcon.image = icon;
	
	NSMutableDictionary *member = [sectionRecords objectAtIndex:indexPath.row];
	BOOL contains = [member[@"selected"] boolValue];
	cell.checkmarkImage.image = [UIImage imageNamed:contains?@"imageSelected":@"imageUnselected"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}


- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return keys;
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
	
	NSArray *arr = [self.records objectForKey:[keys objectAtIndex:section]];
	
    if ([arr count] > 0) {
        l.text = [keys objectAtIndex:section];
    }
	
	return v;
}


#pragma mark - TableviewDelegate Methods


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self.searchBar resignFirstResponder];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	SVContactCell *tappedCell = (SVContactCell*)[tableView cellForRowAtIndexPath:indexPath];
	
	NSArray *sectionRecords = [self.records objectForKey:[keys objectAtIndex:indexPath.section]];
	
	// Check if the tapped contact is already used.
	// If yes, remove it
	
	NSMutableDictionary *member = [sectionRecords objectAtIndex:indexPath.row];
	BOOL contains = [member[@"selected"] boolValue];
	tappedCell.checkmarkImage.image = [UIImage imageNamed:contains?@"imageUnselected":@"imageSelected"];
	
	if (contains) {
		NSLog(@"remove contact %@", member);
		[member setObject:[NSNumber numberWithBool:NO] forKey:@"selected"];
		[self removeContactFromTable:member];
	}
	else {
		NSLog(@"add contact %@", member);
		[member setObject:[NSNumber numberWithBool:YES] forKey:@"selected"];
        [self addToContactsList:member];
	}
}


#pragma mark -
#pragma mark Search

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
	[searchBar setShowsCancelButton:YES animated:YES];
	self.tableView.frame = CGRectMake(0, 44, 320, self.view.frame.size.height-44);
}
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
	[searchBar setShowsCancelButton:NO animated:YES];
	self.tableView.frame = CGRectMake(0, 44+75, 320, self.view.frame.size.height-44-75);
}
-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
	
	if(searchText.length == 0) {
		NSLog(@"not first responder");
        // user tapped the 'clear' button
        //shouldBeginEditing = NO;
        // do whatever I want to happen when the user clears the search...
		[searchBar resignFirstResponder];
    }
	
	stopCurrentSearch = YES;
	[self handleSearchForText: searchText.length == 0 ? nil : searchText];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	NSLog(@"cancel clicked");
	[searchBar resignFirstResponder];
	searchBar.text = @"";
	[self handleSearchForText:nil];
}
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)bar {
    // reset the shouldBeginEditing BOOL ivar to YES, but first take its value and use it to return it from the method call
    BOOL boolToReturn = shouldBeginEditing;
    shouldBeginEditing = YES;
    return boolToReturn;
}

- (void) handleSearchForText:(NSString*)str {
	
	self.records = nil;
	NSMutableArray *keys_ = [[NSMutableArray alloc] init];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		
		self.records = [[NSMutableDictionary alloc] init];
		NSLog(@"handle search string: %@", str);
		for (int i=0; i<alphabet.count-1; i++) {
			NSMutableArray *letterContacts = [NSMutableArray array];
			for (NSMutableDictionary *member in self.allContacts) {
				if (str == nil) {
					if ([[[member objectForKey:kMemberFirstName] lowercaseString] hasPrefix:[alphabet[i] lowercaseString]]) {
						[letterContacts addObject:member];
					}
				}
				else {
					if ([[[member objectForKey:kMemberFirstName] lowercaseString] hasPrefix:[alphabet[i] lowercaseString]] &&
						[[[member objectForKey:kMemberNickname] lowercaseString] rangeOfString:[str lowercaseString]].location != NSNotFound) {
						[letterContacts addObject:member];
					}
				}
			}
			//NSLog(@"%@ %i", [alphabet objectAtIndex:i], letterContacts.count);
			if (letterContacts.count > 0) {
				[keys_ addObject:[alphabet objectAtIndex:i]];
				[self.records setObject:letterContacts forKey:[alphabet objectAtIndex:i]];
			}
		}
		if (str == nil) {
			NSArray *arr2 = [self filterNonAlphabetContacts:self.allContacts];
			if (arr2.count > 0) {
				[keys_ addObject:@"#"];
				[self.records setObject:arr2 forKey:@"#"];
			}
		}
		else {
			NSMutableArray *letterContacts = [NSMutableArray array];
			for (NSMutableDictionary *member in self.allContacts) {
				if ([[[member objectForKey:kMemberNickname] lowercaseString] rangeOfString:[str lowercaseString]].location != NSNotFound) {
					[letterContacts addObject:member];
				}
			}
			if (letterContacts.count > 0) {
				[keys_ addObject:@"#"];
				[self.records setObject:letterContacts forKey:@"#"];
			}
		}
		
		keys = [NSArray arrayWithArray:keys_];
		
		if (self.records != nil) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.tableView reloadData];
			});
		}
	});
}


#pragma mark - Private Methods

-(void)addToContactsList:(NSMutableDictionary*)contact
{
	//[contact setObject:[NSNumber numberWithBool:YES] forKey:@"selected"];
	
	NSString *firstName = [contact objectForKey:kMemberFirstName];
	NSString *lastName = [contact objectForKey:kMemberLastName];
	int tag = [[contact objectForKey:@"tag"] intValue];
	
    //create a new dynamic button
	UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0];
	button.titleLabel.shadowColor = [UIColor clearColor];
	[button setTitle:([firstName isEqualToString:@""] ? lastName : firstName) forState:UIControlStateNormal];
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[button setImage:[UIImage imageNamed:@"contactsX.png"] forState:UIControlStateNormal];
	[button setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
	[button setTag:tag];
	[button sizeToFit];
	
	UIImage *baseImage = [UIImage imageNamed:@"butInvitedContacts.png"];
	UIEdgeInsets insets = UIEdgeInsetsMake(5, 20, 5, 20);
	UIImage *resizableImage = [baseImage resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
	
	[button setBackgroundImage:resizableImage forState:UIControlStateNormal];
	[button addTarget:self action:@selector(removeContactFromList:) forControlEvents:UIControlEventTouchUpInside];
	[self.addedContactsScrollView addSubview:button];
	[self.contactsButtons addObject:button];
	button.alpha = 0;
	
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
-(void)removeContactFromTable:(NSMutableDictionary*)contact
{
	NSMutableArray *arr = self.contactsButtons;
	for (UIButton *but in arr) {
		if (but.tag == [[contact objectForKey:@"tag"] intValue]) {
			[self.contactsButtons removeObject:but];
			[but removeFromSuperview];
			[self updateContacts];
			break;
		}
	}
}

-(void)removeContactFromList:(UIButton *)sender
{
	[sender removeFromSuperview];
	[self.contactsButtons removeObject:sender];
	
	for (NSMutableDictionary *member in self.allContacts) {
		if ([member[@"tag"] intValue] == sender.tag) {
			[member setObject:[NSNumber numberWithBool:NO] forKey:@"selected"];
			break;
		}
	}
	
	[self updateContacts];
	
    [self.tableView reloadData];
    
    //[self.tableView reloadData];
}
- (void)updateContacts {
	
	int i = 0;
	int x_1 = 80;
	int x_2 = 5;
	
	for (UIButton *but in self.contactsButtons) {
		
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
	self.navigationItem.rightBarButtonItem.enabled = self.contactsButtons.count > 0;
}


-(void)loadShotVibeContacts
{
	NSLog(@"loadShotVibeContacts");
    self.records = nil;
    [self.tableView reloadData];
}

-(void)loadAddressbookContacts
{
    [SVAddressBookBD searchContactsWithString:nil WithCompletion:^(NSArray *contacts, NSError *error) {
		self.allContacts = contacts;
		[self handleSearchForText:nil];
		NSLog(@"search finished %i", [contacts count]);
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
		});
	}];
}




- (NSArray *)filterNonAlphabetContacts:(NSArray *)contacts
{
    return [contacts filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary *evaluatedObject, NSDictionary *bindings) {
        
        BOOL result = YES;
        NSString * firstName = [evaluatedObject objectForKey:kMemberFirstName];
        
        for (NSString *letter in alphabet) {
            
            if ([letter isEqualToString:@"#"]) {
                break;
            }
            else if ([[firstName lowercaseString] hasPrefix:[letter lowercaseString]]) {
                result = NO;
            }
        }
        
        return result;
    }]];
}


@end
