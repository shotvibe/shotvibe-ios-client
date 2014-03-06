//
//  SVAddFriendsViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 4/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVAddFriendsViewController.h"
#import "SVDefines.h"
#import "SVContactCell.h"
#import "SL/AlbumContents.h"
#import "SL/ArrayList.h"
#import "SL/ShotVibeAPI.h"
#import "MBProgressHUD.h"
#import "UIImageView+WebCache.h"
#import "SL/ArrayList.h"
#import "SL/PhoneContactsManager.h"
#import "SL/PhoneContact.h"
#import "SL/PhoneContactDisplayData.h"


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
	
	NSMutableArray *contactsButtons;// list of selected contacts buttons

    NSArray *allContacts_;
    NSArray *searchFilteredContacts_;

    NSString *searchString_;

    NSInteger numSections_;
    NSArray *sectionRowCounts_;
    NSArray *sectionIndexTitles_;
    NSArray *sectionStartIndexes_;

    NSMutableArray *checkedContactsList_;
    NSHashTable *checkedContactsSet_;
}


#pragma mark - View Lifecycle

- (void)viewDidLoad {
	
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	self.noContactsView.hidden = YES;
	self.butOverlay.hidden = YES;
//	[[NSUserDefaults standardUserDefaults] synchronize];
	contactsButtons = [[NSMutableArray alloc] init];
	
	// IOS7
	if ([self.navigationController.navigationBar respondsToSelector:@selector(barTintColor)]) {
		self.navigationController.navigationBar.translucent = NO;
		self.view.frame = CGRectMake(0, 64, 320, 568-64);
	}
	
	self.contactsSourceView.hidden = YES;
	self.contactsSourceSelector.frame = IS_IOS7 ? CGRectMake(8, 7, 239, 30) : CGRectMake(5, 7, 233, 30);
    self.contactsSourceSelector.selectedSegmentIndex = 1;
	
    BOOL permissionGranted = YES;
    if (!permissionGranted) {
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

    checkedContactsList_ = [[NSMutableArray alloc] init];
    NSUInteger defaultCapacity = 16;
    checkedContactsSet_ = [[NSHashTable alloc] initWithOptions:NSHashTableStrongMemory capacity:defaultCapacity];

    searchString_ = @"";

    [self setAllContacts:[[NSArray alloc] init]];

    [self.albumManager.phoneContactsManager setListenerWithSLPhoneContactsManager_Listener:self];
}


- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

#pragma mark -
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return numSections_;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[sectionRowCounts_ objectAtIndex:section] integerValue];
}


- (SLPhoneContactDisplayData *)getContactForIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *sectionStart = [sectionStartIndexes_ objectAtIndex:indexPath.section];
    NSInteger index = [sectionStart integerValue] + indexPath.row;
    return [searchFilteredContacts_ objectAtIndex:index];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SVContactCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];

    SLPhoneContactDisplayData *phoneContactDisplayData = [self getContactForIndexPath:indexPath];

    NSString *firstName = [[phoneContactDisplayData getPhoneContact] getFirstName];
    NSString *lastName = [[phoneContactDisplayData getPhoneContact] getLastName];

    NSString *fullName;
    NSRange boldRange;
    if (firstName.length == 0) {
        fullName = lastName;
        boldRange = NSMakeRange(0, lastName.length);
    } else if (lastName.length == 0) {
        fullName = firstName;
        boldRange = NSMakeRange(0, firstName.length);
    } else {
        fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
        boldRange = NSMakeRange(firstName.length + 1, lastName.length);
    }
    NSMutableAttributedString *attributedName = [[NSMutableAttributedString alloc] initWithString:fullName];
    UIFont *boldFont = [UIFont boldSystemFontOfSize:cell.titleLabel.font.pointSize];
    [attributedName setAttributes:[[NSDictionary alloc] initWithObjectsAndKeys:boldFont, NSFontAttributeName, nil]
                            range:boldRange];
    cell.titleLabel.attributedText = attributedName;

    cell.subtitleLabel.text = [[phoneContactDisplayData getPhoneContact] getPhoneNumber];

    [cell.contactIcon cancelCurrentImageLoad];

    if ([phoneContactDisplayData isLoading]) {
        [cell.loadingSpinner startAnimating];
        cell.contactIcon.hidden = YES;
        cell.isMemberImage.hidden = YES;
    } else {
        [cell.loadingSpinner stopAnimating];
        cell.contactIcon.hidden = NO;
        [cell.contactIcon setImageWithURL:[[NSURL alloc] initWithString:[phoneContactDisplayData getAvatarUrl]]];
        cell.isMemberImage.hidden = [phoneContactDisplayData getUserId] == nil;
    }

    if ([checkedContactsSet_ containsObject:[phoneContactDisplayData getPhoneContact]]) {
        cell.checkmarkImage.image = [UIImage imageNamed:@"imageSelected"];
    } else {
        cell.checkmarkImage.image = [UIImage imageNamed:@"imageUnselected"];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return sectionIndexTitles_;
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
	
    l.text = [sectionIndexTitles_ objectAtIndex:section];

	return v;
}


#pragma mark - TableviewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self.searchBar resignFirstResponder];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

    SLPhoneContactDisplayData *phoneContactDisplayData = [self getContactForIndexPath:indexPath];

    SLPhoneContact *phoneContact = [phoneContactDisplayData getPhoneContact];

    if ([checkedContactsSet_ containsObject:phoneContact]) {
        NSInteger index = [checkedContactsList_ indexOfObject:phoneContact];
        [self removeButtonFromContactListWithIndex:index];

        [checkedContactsList_ removeObjectAtIndex:index];
        [checkedContactsSet_ removeObject:phoneContact];
    } else {
        [checkedContactsSet_ addObject:phoneContact];
        [checkedContactsList_ addObject:phoneContact];

        [self addButtonToContactsList:phoneContact withIndex:checkedContactsList_.count - 1];
    }

    [self.tableView reloadData];
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
    searchString_ = searchText;
    [self filterContactsBySearch];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	[searchBar resignFirstResponder];
	searchBar.text = @"";
    searchString_ = @"";
    self.contactsSourceSelector.selectedSegmentIndex = 1;
    [self filterContactsBySearch];
}
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)bar {
    return YES;
}


- (BOOL)displayOnlyShotVibeUsers
{
    return self.contactsSourceSelector.selectedSegmentIndex == 0;
}


#pragma mark - Private Methods

- (void)addButtonToContactsList:(SLPhoneContact *)phoneContact withIndex:(NSInteger)index
{
    NSString *shortName = [phoneContact getFirstName];
    if (shortName.length == 0) {
        shortName = [phoneContact getLastName];
    }

    //create a new dynamic button
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.frame = CGRectMake(0, 0, 100, 20);
	button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0];
	button.titleLabel.shadowColor = [UIColor clearColor];
	[button setTitle:shortName forState:UIControlStateNormal];
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[button setImage:[UIImage imageNamed:@"contactsX.png"] forState:UIControlStateNormal];
	[button setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
	
	CGRect f = button.frame;
	f.size = button.intrinsicContentSize;
	f.size.width += 20;
	button.frame = f;
	
	UIImage *baseImage = [UIImage imageNamed:@"butInvitedContacts.png"];
	UIEdgeInsets insets = UIEdgeInsetsMake(5, 20, 5, 20);
	UIImage *resizableImage = [baseImage resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
	
	[button setBackgroundImage:resizableImage forState:UIControlStateNormal];
    [button addTarget:self action:@selector(contactButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.addedContactsScrollView addSubview:button];
	[contactsButtons addObject:button];
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

- (void)removeButtonFromContactListWithIndex:(NSInteger)index
{
    UIButton *but = [contactsButtons objectAtIndex:index];

    [but removeFromSuperview];

    [contactsButtons removeObjectAtIndex:index];

    [self updateContacts];
}

- (void)contactButtonPressed:(UIButton *)sender
{
    // Find the index of the sender
    NSInteger index = 0;
    for (UIButton *button in contactsButtons) {
        if (button == sender) {
            break;
        }
        index++;
    }
    NSAssert(index != contactsButtons.count, @"sender not found");

    [self removeButtonFromContactListWithIndex:index];

    SLPhoneContact *phoneContact = [checkedContactsList_ objectAtIndex:index];

    [checkedContactsList_ removeObjectAtIndex:index];
    [checkedContactsSet_ removeObject:phoneContact];

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
    [self.albumManager.phoneContactsManager unsetListener];

    // add members to album
    //TODO if already shotvibe member just add to album else sent notification to user to join?
    RCLog(@"contacts to add >> ");
	
	[MBProgressHUD showHUDAddedTo:self.view animated:YES];
	
    NSString *defaultCountryCode = [self.albumManager getShotVibeAPI].authData.defaultCountryCode;

    NSMutableArray *memberAddRequests = [[NSMutableArray alloc] init];
	
    for (SLPhoneContact *phoneContact in checkedContactsList_) {
        SLShotVibeAPI_MemberAddRequest *request = [[SLShotVibeAPI_MemberAddRequest alloc] initWithNSString:[phoneContact getFullName]
                                                                                              withNSString:[phoneContact getPhoneNumber]];

        [memberAddRequests addObject:request];
	}
	
	//[contactsToInvite addObject:@{@"phone_number": @"+40700000002", @"default_country":regionCode, @"contact_nickname":@"Cristi"}];
	//[contactsToInvite addObject:@{@"phone_number": @"(070) 000-0001", @"default_country":regionCode, @"contact_nickname":@"Cristi"}];
	
    if (memberAddRequests.count > 0) {
		// send request
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            SLAPIException *apiException = nil;
            @try {
                // TODO
                // - If any "MemberAddFailure" are returned, then show dialog to user with the details

                [[self.albumManager getShotVibeAPI] albumAddMembers:self.albumId
                                              withMemberAddRequests:[[SLArrayList alloc] initWithInitialArray:memberAddRequests]
                                                 withDefaultCountry:defaultCountryCode];
            } @catch (SLAPIException *exception) {
                apiException = exception;
            }

			dispatch_async(dispatch_get_main_queue(), ^{
				[MBProgressHUD hideHUDForView:self.view animated:YES];
				[self.navigationController dismissViewControllerAnimated:YES completion:nil];
			});
		});
	}
}

- (void)cancelPressed:(id)sender {
    [self.albumManager.phoneContactsManager unsetListener];

    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)contactsSourceChanged:(UISegmentedControl *)sender {
    [self filterContactsBySearch];
}

- (IBAction)overlayPressed:(id)sender {
	[self.searchBar resignFirstResponder];
}


// This is called from a background thread
- (void)phoneContactsUpdatedWithSLArrayList:(SLArrayList *)phoneContacts
{
    NSLog(@"phoneContacts size: %d", [phoneContacts size]);

    [phoneContacts.array sortUsingComparator:^NSComparisonResult (id obj1, id obj2) {
        SLPhoneContact *c1 = [(SLPhoneContactDisplayData *)obj1 getPhoneContact];
        SLPhoneContact *c2 = [(SLPhoneContactDisplayData *)obj2 getPhoneContact];

        NSComparisonResult r;
        if ([c1 getLastName].length == 0 && [c2 getLastName].length > 0) {
            r = [[c1 getFirstName] compare:[c2 getLastName] options:NSCaseInsensitiveSearch];
        } else if ([c1 getLastName].length > 0 && [c2 getLastName].length == 0) {
            r = [[c1 getLastName] compare:[c2 getFirstName] options:NSCaseInsensitiveSearch];
        } else {
            r = [[c1 getLastName] compare:[c2 getLastName] options:NSCaseInsensitiveSearch];
        }

        if (r != NSOrderedSame) {
            return r;
        }

        r = [[c1 getFirstName] compare:[c2 getFirstName] options:NSCaseInsensitiveSearch];

        if (r != NSOrderedSame) {
            return r;
        }

        return [[c1 getPhoneNumber] compare:[c2 getPhoneNumber]];
    }];

    NSLog(@"sort complete");

    dispatch_async(dispatch_get_main_queue(), ^{
        [self setAllContacts:phoneContacts.array];
    });
}


static inline NSString * contactFirstLetter(SLPhoneContact *phoneContact)
{
    if ([phoneContact getLastName].length > 0) {
        return [[[phoneContact getLastName] substringToIndex:1] uppercaseString];
    } else {
        return [[[phoneContact getFirstName] substringToIndex:1] uppercaseString];
    }
}


- (void)setAllContacts:(NSArray *)contacts
{
    allContacts_ = contacts;

    [self filterContactsBySearch];
}


- (void)filterContactsBySearch
{
    if (searchString_.length == 0 && ![self displayOnlyShotVibeUsers]) {
        searchFilteredContacts_ = allContacts_;

        [self computeSections];
        return;
    }

    NSMutableArray *searchFilteredContacts = [[NSMutableArray alloc] init];
    for (SLPhoneContactDisplayData *phoneContactDisplayData in allContacts_) {
        SLPhoneContact *phoneContact = [phoneContactDisplayData getPhoneContact];

        BOOL contactContainsSearchString;
        if (searchString_.length == 0) {
            contactContainsSearchString = YES;
        } else {
            if ([[phoneContact getFullName] rangeOfString:searchString_ options:NSCaseInsensitiveSearch].location != NSNotFound) {
                contactContainsSearchString = YES;
            } else if ([[phoneContact getPhoneNumber] rangeOfString:searchString_ options:NSCaseInsensitiveSearch].location != NSNotFound) {
                contactContainsSearchString = YES;
            } else {
                contactContainsSearchString = NO;
            }
        }

        if (contactContainsSearchString) {
            if ([self displayOnlyShotVibeUsers]) {
                if (![phoneContactDisplayData isLoading] && [phoneContactDisplayData getUserId] != nil) {
                    [searchFilteredContacts addObject:phoneContactDisplayData];
                }
            } else {
                [searchFilteredContacts addObject:phoneContactDisplayData];
            }
        }
    }

    searchFilteredContacts_ = searchFilteredContacts;

    [self computeSections];
}


- (void)computeSections
{
    NSUInteger initialCapacity = 32; // Enough for the alphabet
    NSMutableArray *sectionTitles = [[NSMutableArray alloc] initWithCapacity:initialCapacity];

    NSMutableArray *sectionRowCounts = [[NSMutableArray alloc] initWithCapacity:initialCapacity];
    NSMutableArray *sectionStartIndexes = [[NSMutableArray alloc] initWithCapacity:initialCapacity];

    int i = 0;
    int k = 0;
    for (SLPhoneContactDisplayData *p in searchFilteredContacts_) {
        NSString *firstLetter = contactFirstLetter([p getPhoneContact]);
        if (i == 0 || ![firstLetter isEqualToString:[sectionTitles objectAtIndex:sectionTitles.count - 1]]) {
            [sectionStartIndexes addObject:[[NSNumber alloc] initWithInteger:i]];
            [sectionTitles addObject:firstLetter];

            if (i != 0) {
                [sectionRowCounts addObject:[[NSNumber alloc] initWithInteger:k]];
                k = 0;
            }
        }

        k++;
        i++;
    }
    [sectionRowCounts addObject:[[NSNumber alloc] initWithInteger:k]];

    sectionRowCounts_ = sectionRowCounts;

    sectionIndexTitles_ = sectionTitles;

    numSections_ = sectionIndexTitles_.count;

    sectionStartIndexes_ = sectionStartIndexes;

    [self.tableView reloadData];
}


@end
