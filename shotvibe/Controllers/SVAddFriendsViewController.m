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
#import "SVHttpClient.h"


@interface SVAddFriendsViewController ()<UISearchBarDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIScrollView *addedContactsScrollView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;

@property (nonatomic, strong) NSArray *allContacts;
@property (nonatomic, strong) NSMutableDictionary *records;// dictionary of arrays
@property (nonatomic, strong) NSMutableArray *selectedIndexPaths;
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
    NSLog(@"contacts to add >> %@", self.selectedIndexPaths);
	
	//NSMutableArray *contactsToInvite = [[NSMutableArray alloc] init];
	
	for (UIButton *but in self.contactsButtons) {
		int tag = but.tag;
		NSDictionary *dict = [self.allContacts objectAtIndex:tag];
		NSLog(@"%i %@ %@", tag, dict, self.selectedAlbum.albumId);
	}
	
	NSArray *members = @[@{@"phone_number": @"40722905582", @"default_country":@"ro", @"contact_nickname":@"Cristi"}];
	NSDictionary *phoneNumbers = @{@"add_members": members};
	
	// send request
	
	[[SVEntityStore sharedStore] invitePhoneNumbers:phoneNumbers toAlbumId:self.selectedAlbum.albumId WithCompletion:^(BOOL success, NSError *error) {
		
		NSLog(@"invite sent - success/error:  %i %@", success, error);
		[self.navigationController dismissViewControllerAnimated:YES completion:nil];
	}];
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


- (id) init {
	self = [super init];
	if (self) {
		
	}
	return self;
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	self.selectedIndexPaths = [[NSMutableArray alloc] init];
	self.contactsButtons = [[NSMutableArray alloc] init];
	alphabet = @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", @"#"];
	keys = [NSArray arrayWithArray:alphabet];
	self.records = [[NSMutableDictionary alloc] init];
	stopCurrentSearch = NO;
    
    CGRect segmentFrame = self.segmentControl.frame;
    segmentFrame.origin.y -= 1.5;
    self.segmentControl.frame = segmentFrame;
    
    //[self loadShotVibeContacts];
	[self loadAddressbookContacts];
	
//	[self.segmentControl setDividerImage:[UIImage imageNamed:@"SegmentSeparator.png"] forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
//	[self.segmentControl setDividerImage:[UIImage imageNamed:@"SegmentSeparator.png"] forLeftSegmentState:UIControlStateSelected rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
//	[self.segmentControl setDividerImage:[UIImage imageNamed:@"SegmentSeparator.png"] forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
	self.segmentControl.selectedSegmentIndex = 1;
	
	self.searchBar.backgroundImage = [UIImage imageNamed:@"searchFieldBg.png"];
	[self.searchBar setSearchFieldBackgroundImage:[UIImage imageNamed:@"butTransparent.png"] forState:UIControlStateNormal];
	[self.searchBar setImage:[UIImage imageNamed:@"searchFieldIcon.png"] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
	
	// Setup back button
	UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(backButtonPressed:)];
    NSDictionary *att = @{UITextAttributeFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:16.0], UITextAttributeTextShadowColor:[UIColor clearColor]};
	[backButton setTitleTextAttributes:att forState:UIControlStateNormal];
	[backButton setTitlePositionAdjustment:UIOffsetMake(15,0) forBarMetrics:UIBarMetricsDefault];
	//self.navigationItem.backBarButtonItem = backButton;
	
    //UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelPressed:)];
	//UIImage *baseImage = [UIImage imageNamed:@"navbarBackButton.png"];
	//UIEdgeInsets insets = UIEdgeInsetsMake(5, 35, 5, 5);
	//UIImage *resizableImage = [baseImage resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
	
	self.navigationItem.leftBarButtonItem = backButton;
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
    
	NSArray *filteredRecords = [self.records objectForKey:[keys objectAtIndex:indexPath.section]];
	
    cell.textLabel.text = [[filteredRecords objectAtIndex:indexPath.row] objectForKey:kMemberNickname];
    cell.detailTextLabel.text = [[filteredRecords objectAtIndex:indexPath.row] objectForKey:kMemberPhone];
	
	BOOL contains = NO;
	for (NSIndexPath *idx in self.selectedIndexPaths) {
		if (idx.row == indexPath.row && idx.section == indexPath.section) {
			contains = YES;
			break;
		}
	}
	
	cell.imageView.image = [UIImage imageNamed:contains?@"imageSelected":@"imageUnselected"];
    
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
	UITableViewCell *tappedCell = [tableView cellForRowAtIndexPath:indexPath];
	
	// Check if the tapped contact is already used
	BOOL contains = NO;
	int i = 0;
	for (NSIndexPath *idx in self.selectedIndexPaths) {
		if (idx.row == indexPath.row && idx.section == indexPath.section) {
			contains = YES;
			break;
		}
		i++;
	}
	
	if (contains) {
		[tappedCell.imageView setImage:[UIImage imageNamed:@"imageUnselected"]];
        [self.selectedIndexPaths removeObjectAtIndex:i];
        //[self removeContact:[self.contactsButtons objectAtIndex:i]];
	}
	else {
        [tappedCell.imageView setImage:[UIImage imageNamed:@"imageSelected"]];
        [self.selectedIndexPaths addObject:[indexPath copy]];
        NSLog(@"self.contactsToAdd %i %@", indexPath.row, self.selectedIndexPaths);
		
		NSArray *arr = [self.records objectForKey:[keys objectAtIndex:indexPath.section]];
		NSDictionary *contact = [arr objectAtIndex:indexPath.row];
		NSLog(@"contact %@", contact);
        [self addToContactsList:contact];
	}
}


#pragma mark -
#pragma mark Search

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
	
	stopCurrentSearch = YES;
	[self handleSearchForText: searchText.length == 0 ? nil : searchText];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	searchBar.text = @"";
	[self handleSearchForText:nil];
	[searchBar resignFirstResponder];
}
- (void) handleSearchForText:(NSString*)str {
	
	self.records = nil;
	NSMutableArray *keys_ = [[NSMutableArray alloc] init];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		
		self.records = [[NSMutableDictionary alloc] init];
		for (int i=0; i<alphabet.count-1; i++) {
			NSPredicate *predicate;
			if (str == nil) {
				predicate = [NSPredicate predicateWithFormat:@"%K BEGINSWITH[cd] %@", kMemberFirstName, [alphabet objectAtIndex:i]];
			}
			else {
				predicate = [NSPredicate predicateWithFormat:@"%K BEGINSWITH[cd] %@ && %K CONTAINS[cd] %@", kMemberFirstName, [alphabet objectAtIndex:i], kMemberFirstName, str];
			}
			NSArray *arr = [self.allContacts filteredArrayUsingPredicate:predicate];
			
			if (arr.count > 0) {
				[keys_ addObject:[alphabet objectAtIndex:i]];
				[self.records setObject:arr forKey:[alphabet objectAtIndex:i]];
			}
		}
		
		// Non alphabetic names
		NSArray *arr2 = [self filterNonAlphabetContacts:self.allContacts];
		if (arr2.count > 0) {
			[keys_ addObject:@"#"];
			[self.records setObject:arr2 forKey:@"#"];
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

-(void)addToContactsList:(NSDictionary*)contact
{
	NSString *firstName = [contact objectForKey:kMemberFirstName];
	NSString *lastName = [contact objectForKey:kMemberLastName];
	int tag = [[contact objectForKey:@"tag"] intValue];
	
    //create a new dynamic button
	UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12.0];
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
-(void)removeContact:(NSDictionary*)contact
{
//	[self.addedContactsScrollView addSubview:button];
//	
//	CGRect frame = CGRectMake(x, 10, button.frame.size.width, 30);
//	button.frame = frame;
//	
//	x = x + button.frame.size.width + 5;
//	
//	[self.addedContactsScrollView setContentSize:(CGSizeMake(x, self.addedContactsScrollView.frame.size.height))];
}

-(void)removeContactFromList:(UIButton *)sender
{
	[sender removeFromSuperview];
	[self.contactsButtons removeObject:sender];
	[self updateContacts];
	
    //[self.selectedIndexPaths removeObjectAtIndex:sender.tag];
    
    //[self.tableView reloadData];
}
- (void)updateContacts {
	
	int i = 0;
	int x_1 = 5;
	int x_2 = 5;
	
	for (UIButton *but in self.contactsButtons) {
		
		CGRect frame;
		
		if (i % 2 == 0) {
			frame = CGRectMake (x_1, 3, but.frame.size.width, 22);
			x_1 = x_1 + but.frame.size.width + 5;
		}
		else {
			frame = CGRectMake (x_2, 28, but.frame.size.width, 22);
			x_2 = x_2 + but.frame.size.width + 5;
		}
		i++;
		
		[UIView animateWithDuration:0.3 animations:^{
			but.frame = frame;
		}];
	}
	
	[self.addedContactsScrollView setContentSize:(CGSizeMake(x_1 > x_2 ? x_1 : x_2, self.addedContactsScrollView.frame.size.height))];
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
