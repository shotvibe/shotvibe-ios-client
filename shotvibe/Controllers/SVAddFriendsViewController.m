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
#import "SVJSONAPIClient.h"


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
}

#pragma mark - Actions

- (IBAction)donePressed:(id)sender {
    // add members to album
    //TODO if already shotvibe member just add to album else sent notification to user to join?
    NSLog(@"contacts to add >> %@", self.selectedIndexPaths);
	
	NSMutableArray *contactsToInvite = [[NSMutableArray alloc] init];
	
	for (UIButton *but in self.contactsButtons) {
		int tag = but.tag;
		NSDictionary *dict = [self.allContacts objectAtIndex:tag];
		NSLog(@"%i %@", tag, dict);
	}
	
	NSString *path = [NSString stringWithFormat:@"/albums/%@/", @"My Instagrams"];
	NSArray *members = @[@{@"phone_number": @"0722905582", @"default_country":@"ro", @"contact_nickname":@"Cristi"}];
	NSDictionary *params = @{@"add_members": members};
	NSDictionary *headers = [[NSDictionary alloc] init];
	NSMutableURLRequest *req = [[SVJSONAPIClient sharedClient] GETRequestForAllRecordsAtPath:path withParameters:params andHeaders:headers];
    
	//get response
	NSHTTPURLResponse* urlResponse = nil;
	NSError *error = [[NSError alloc] init];
	NSData *responseData = [NSURLConnection sendSynchronousRequest:req returningResponse:&urlResponse error:&error];
	NSString *result = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
	NSLog(@"Response Code: %d", [urlResponse statusCode]);
	
	if ([urlResponse statusCode] >= 200 && [urlResponse statusCode] < 300)
	{
		NSLog(@"Response: %@", result);
	}
	
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
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
	self.records = [[NSMutableDictionary alloc] init];
    
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
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelPressed:)];
	UIImage *baseImage = [UIImage imageNamed:@"navbarBackButton.png"];
	UIEdgeInsets insets = UIEdgeInsetsMake(5, 35, 5, 5);
	UIImage *resizableImage = [baseImage resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
	
    //NSDictionary *att = @{UITextAttributeFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:16.0], UITextAttributeTextShadowColor:[UIColor clearColor]};
	//[backButton setTitleTextAttributes:att forState:UIControlStateNormal];
	[backButton setTitlePositionAdjustment:UIOffsetMake(-10,0) forBarMetrics:UIBarMetricsDefault];
	[backButton setBackgroundImage:resizableImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
	
	self.navigationItem.leftBarButtonItem = backButton;
}


#pragma mark -
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return alphabet.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSArray *arr = [self.records objectForKey:[alphabet objectAtIndex:section]];
	return [arr count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
    
	NSArray *filteredRecords = [self.records objectForKey:[alphabet objectAtIndex:indexPath.section]];
	
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


- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return alphabet;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSArray *arr = [self.records objectForKey:[alphabet objectAtIndex:section]];
	
    if ([arr count] > 0) {
        return [alphabet objectAtIndex:section];
    }
	
    return nil;
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
		
		NSArray *arr = [self.records objectForKey:[alphabet objectAtIndex:indexPath.section]];
		NSDictionary *contact = [arr objectAtIndex:indexPath.row];
		NSLog(@"contact %@", contact);
        [self addToContactsList:contact];
	}
}


#pragma mark -
#pragma mark Search

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
	
	if ([searchText length] == 0) {
        //[self resetSearch];
        [self.tableView reloadData];
    }
//	else if ([searchTerm length] > 1) {
//		isSearching = YES;
		[self handleSearchForText:searchText];
//	}
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = @"";
//    [self resetSearch];
    [self.tableView reloadData];
//    [self dismissKeyboard:nil];
}


#pragma mark - Private Methods

-(void)addToContactsList:(NSDictionary*)contact
{
	NSString *firstName = [contact objectForKey:kMemberFirstName];
	NSString *lastName = [contact objectForKey:kMemberLastName];
	int tag = [[contact objectForKey:@"tag"] intValue];
	
    //create a new dynamic button
	UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[button setTitle:([firstName isEqualToString:@""] ? lastName : firstName) forState:UIControlStateNormal];
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	//button setImage:<#(UIImage *)#> forState:<#(UIControlState)#>
	[button setTag:tag];
	[button sizeToFit];
	
	UIImage *baseImage = [UIImage imageNamed:@"contactsStreachableButton_normal"];
	UIEdgeInsets insets = UIEdgeInsetsMake(5, 20, 5, 20);
	
	UIImage *resizableImage = [baseImage resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
	
	[button setBackgroundImage:resizableImage forState:UIControlStateNormal];
	[button addTarget:self action:@selector(removeContactFromList:) forControlEvents:UIControlEventTouchUpInside];
	[self.addedContactsScrollView addSubview:button];
	[self.contactsButtons insertObject:button atIndex:0];
	button.alpha = 0;
	
    [self updateContacts];
	
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
	
	int x = 5;
	for (UIButton *but in self.contactsButtons) {
		
		CGRect frame = CGRectMake(x, 10, but.frame.size.width, 30);
		
		[UIView animateWithDuration:0.3 animations:^{
			but.frame = frame;
		}];
		
		x = x + but.frame.size.width + 5;
	}
	
	[self.addedContactsScrollView setContentSize:(CGSizeMake(x, self.addedContactsScrollView.frame.size.height))];
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


- (void) handleSearchForText:(NSString*)str {
	
	self.records = nil;
	
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
			NSLog(@"arr count %@ %i", [alphabet objectAtIndex:i], [arr count]);
			[self.records setObject:arr forKey:[alphabet objectAtIndex:i]];
		}
		[self.records setObject:[self filterNonAlphabetContacts:self.allContacts] forKey:@"#"];
		
		if (self.records != nil) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.tableView reloadData];
			});
		}
	});
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



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
