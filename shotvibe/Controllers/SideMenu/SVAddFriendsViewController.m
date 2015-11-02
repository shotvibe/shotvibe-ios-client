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
#import "ShotVibeAppDelegate.h"
#import "SL/AuthData.h"
#import "SL/AlbumContents.h"
#import "SL/ArrayList.h"
#import "SL/ShotVibeAPI.h"
#import "MBProgressHUD.h"
#import "UIImageView+WebCache.h"
#import "SL/ArrayList.h"
#import "SL/PhoneContactsManager.h"
#import "SL/PhoneContact.h"
#import "SL/PhoneContactDisplayData.h"

#import "GLSharedCamera.h"
#import "ShotVibeAppDelegate.h"

#import "SL/AlbumMember.h"
#import "SL/AlbumUser.h"
#import "SL/AlbumSummary.h"
#import "SL/AlbumContents.h"
#import "SL/AlbumPhoto.h"
#import "SL/AlbumServerPhoto.h"
#import "SL/ArrayList.h"
#import "SL/DateTime.h"
#import "SL/ShotVibeAPI.h"
#import "SL/APIException.h"
#import "ShotVibeAppDelegate.h"
#import "UserSettings.h"

#import "UIImageView+Masking.h"
#import "SDWebImageManager.h"
#import "ShotVibeAPITask.h"

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
    SLAlbumManager *albumManager_;
    SLPhoneContactsManager *phoneContactsManager_;
	
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
    
//    SLAlbumManager *albumManager_;
    PhotoFilesManager *photoFilesManager_;
    NSArray *allAlbums;
    BOOL showGroups;
    
    UIButton * openGroupFromMembersButton;
}



#pragma mark - View Lifecycle

-(void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    [phoneContactsManager_ unsetListener];
//    [albumManager_ removeAlbumListListenerWithSLAlbumManager_AlbumListListener:self];
    
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
//    [phoneContactsManager_ unsetListener];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"****** register");
    [phoneContactsManager_ setListenerWithSLPhoneContactsManager_Listener:self];
}



- (void)viewDidLoad
{
    showGroups = NO;
    
    [super viewDidLoad];
    
    openGroupFromMembersButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-90, 150, 70, 70)];
    [openGroupFromMembersButton setTitle:@"go" forState:UIControlStateNormal];
    openGroupFromMembersButton.alpha = 0;
    [openGroupFromMembersButton addTarget:self action:@selector(openGroupFromMembers) forControlEvents:UIControlEventTouchUpInside];
    [openGroupFromMembersButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.view addSubview:openGroupFromMembersButton];
    
    // Do any additional setup after loading the view.
    allAlbums = [[NSMutableArray alloc] init];
    albumManager_ = [ShotVibeAppDelegate sharedDelegate].albumManager;
    phoneContactsManager_ = [ShotVibeAppDelegate sharedDelegate].phoneContactsManager;
    
    [self setAlbumList:[albumManager_ getCachedAlbumContents].array];
    
//    SLAlbumManager * albumManager_ = [ShotVibeAppDelegate sharedDelegate].albumManager;
//    [self setAlbumList:[albumManager_ addAlbumListListenerWithSLAlbumManager_AlbumListListener:self].array];

    self.noContactsView.hidden = YES;
    self.butOverlay.hidden = YES;
//	[[NSUserDefaults standardUserDefaults] synchronize];
    contactsButtons = [[NSMutableArray alloc] init];

    // IOS7
    if ([self.navigationController.navigationBar respondsToSelector:@selector(barTintColor)]) {
        self.navigationController.navigationBar.translucent = NO;
        self.view.frame = CGRectMake(0, 64, self.view.frame.size.width, 568 - 64);
    }

    self.contactsSourceView.hidden = NO;
    self.contactsSourceSelector.frame = CGRectMake(5, 7, self.view.frame.size.width-10, 30);
    self.contactsSourceSelector.selectedSegmentIndex = 1;

    BOOL permissionGranted = YES;
    if (!permissionGranted) {
        self.noContactsView.hidden = NO;
    }

    // Setup back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelPressed:)];
    backButton.tintColor = UIColorFromRGB(0x3eb4b6);
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self action:@selector(donePressed:)];
    doneButton.tintColor = UIColorFromRGB(0x3eb4b6);
    

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
    
    
    

    self.searchBar.layer.borderWidth = 1;
    self.searchBar.layer.borderColor = [[UIColor groupTableViewBackgroundColor] CGColor];

    [[Mixpanel sharedInstance] track:@"Add Friends Screen Viewed"
                          properties:@{ @"album_id" : [NSString stringWithFormat:@"%lld", self.albumId] }];
}


- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

#pragma mark -
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
//    NSUInteger num;
//    if(showGroups){
//        num = [allAlbums count];
//    } else {
//        num = numSections_;
//    }
    return numSections_;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger num;
//    if(showGroups){
//        num = [allAlbums count];
//    } else {
        num = [[sectionRowCounts_ objectAtIndex:section] integerValue];
//    }
    
    return num;
}


- (SLAlbumContents *)getAlbumForIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *sectionStart = [sectionStartIndexes_ objectAtIndex:indexPath.section];
    NSInteger index = [sectionStart integerValue] + indexPath.row;
    return [searchFilteredContacts_ objectAtIndex:index];
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
    
    if(showGroups){
    
        
        
        SLAlbumContents * album = [self getAlbumForIndexPath:indexPath];//[allAlbums objectAtIndex:indexPath.row];
        
//        NSLog(@"count is : %lu",(unsigned long)[album getLatestPhotos].array.count);
        
//        if([album ]){}
        NSLog(@"album member arra %@",[album getMembers]);
        
//        NSString * groupMembers = [[NSString alloc] init];
        
//        NSArray *stringArray = [myString componentsSeparatedByString:@":"];
        NSMutableArray * membersArr = [[NSMutableArray alloc] init];
        
        for(SLAlbumMember * member in [album getMembers].array){
            
            [membersArr addObject:[[member getUser] getMemberNickname]];
            
        }
        
        NSString * result = [membersArr componentsJoinedByString:@", "];
        
//        for(SLAlbumMember * member in [album getMembers].array){
////            [groupMembers stringByAppendingFormat:@"%@, ",[[member getUser] getMemberNickname]];
//            [groupMembers stringByAppendingString:[NSString stringWithFormat:@"%@ ,",[[member getUser] getMemberNickname]]];
//        }
        
        cell.contactIcon.image = [UIImage imageNamed:@"CaptureButton"];
        if((unsigned long)[album getPhotos].array.count > 0){
            SLAlbumPhoto *latestPhoto = [[album getPhotos].array objectAtIndex:0];
            if ([latestPhoto getServerPhoto]) {
                
                cell.contactIcon.hidden = NO;
                
                NSString * st = [[[latestPhoto getServerPhoto] getUrl] stringByReplacingOccurrencesOfString:@".jpg" withString:@"_thumb75.jpg"];
                
                [cell.contactIcon setCircleImageWithURL:[NSURL URLWithString:st] placeholderImage:[UIImage imageNamed:@"CaptureButton"] borderWidth:2];
                
            }
        }
        
        
//            cell.author.text = [NSString stringWithFormat:NSLocalizedString(@"Last added by %@", nil), [[[latestPhoto getServerPhoto] getAuthor] getMemberNickname]];
//            
//            [cell.networkImageView setPhoto:[[latestPhoto getServerPhoto] getId]
//                                   photoUrl:[[latestPhoto getServerPhoto] getUrl]
            
             
        cell.titleLabel.text = [album getName];
        cell.subtitleLabel.text = result;
        
//        [album get]
//        SLAlbumContents * albumContents = [self getAlbumForIndexPath:indexPath];
//        for (SLAlbumPhoto *photo in [albumContents getPhotos].array) {
//            
//        }
        
//        cell.subtitleLabel = ;
        
//        cell.titleLabel.attributedText = attributedName;
        
//        cell.subtitleLabel.text = [[phoneContactDisplayData getPhoneContact] getPhoneNumber];
        
//        [cell.contactIcon cancelCurrentImageLoad];
        
//        if ([phoneContactDisplayData isLoading]) {
//            [cell.loadingSpinner startAnimating];
//            cell.contactIcon.hidden = YES;
//            cell.isMemberImage.hidden = YES;
//        } else {
        
        
        
//        }
        
        
    } else {
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
	
	UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 26)];
	v.backgroundColor = [UIColor colorWithRed:0.92 green:0.93 blue:0.94 alpha:1];
	
	UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.view.frame.size.width, 26)];
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

    
    
    [UIView animateWithDuration:0.2 animations:^{
        
        if([checkedContactsList_ count]>0){
            self.contactsSourceSelector.alpha = 0;
            self.contactsSourceView.alpha = 0;
            openGroupFromMembersButton.alpha = 1;
            [self.view bringSubviewToFront:openGroupFromMembersButton];
        } else {
            self.contactsSourceSelector.alpha = 1;
            self.contactsSourceView.alpha = 1;
            openGroupFromMembersButton.alpha = 0;
        }
        
    }];
    
    
    
    [self.tableView reloadData];
}


-(void)openGroupFromMembers {
    NSLog(@"%@",checkedContactsList_);
    
    
    [ShotVibeAPITask runTask:self withAction:^id{
        SLAlbumContents * newAlbum = [[albumManager_ getShotVibeAPI] createNewBlankAlbumWithNSString:@"%$#"];
        
        NSMutableArray *memberAddRequests = [[NSMutableArray alloc] init];
        
        for (SLPhoneContact *phoneContact in checkedContactsList_) {
            SLShotVibeAPI_MemberAddRequest *request = [[SLShotVibeAPI_MemberAddRequest alloc] initWithNSString:[phoneContact getFullName]
                                                                                                  withNSString:[phoneContact getPhoneNumber]];
            
            [memberAddRequests addObject:request];
        }
        
        NSString *defaultCountryCode = [[[albumManager_ getShotVibeAPI] getAuthData] getDefaultCountryCode];
        
        [[albumManager_ getShotVibeAPI] albumAddMembersWithLong:[newAlbum getId]
                                               withJavaUtilList:[[SLArrayList alloc] initWithInitialArray:memberAddRequests]
                                                   withNSString:defaultCountryCode];
//        [[albumManager_ getShotVibeAPI] :cell.photoId withInt:-1];
        //        [[albumManager_ getShotVibeAPI]postPhotoCommentWithNSString:cell.photoId withNSString:textField.text withLong:milliseconds];
        return nil;
    } onTaskComplete:^(id dummy) {
        
        [UIView animateWithDuration:0.2 animations:^{
            //                commentsDialog.alpha = 0;
            
            
            
            
        } completion:^(BOOL finished) {
//            [self.delegate goToAlbumId:2];
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
            
            
            SVAlbumListViewController *albumlistvc = [storyboard instantiateViewControllerWithIdentifier:@"SVAlbumListViewController"];
            [self.delegate goToPage:2];
            [albumlistvc goToAlbumId:1];
            
//            NSLog(@"there was a success in opening the new album the id is:",);
            
//            [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
            
        }];
    }];

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
		self.tableView.frame = CGRectMake(0, 44+44, self.view.frame.size.width, self.view.frame.size.height-44-44-216);
		self.contactsSourceView.alpha = 1;
		self.butOverlay.alpha = 0.2;
	}];
}
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
	[searchBar setShowsCancelButton:NO animated:YES];
//	self.contactsSourceView.hidden = YES;
	self.butOverlay.hidden = YES;
	[UIView animateWithDuration:0.3 animations:^{
		self.tableView.frame = CGRectMake(0, 44+75, self.view.frame.size.width, self.view.frame.size.height-44-75);
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
    
    
    if([checkedContactsList_ count] == 0){
        [UIView animateWithDuration:0.2 animations:^{
            self.contactsSourceView.alpha = 1;
            self.contactsSourceSelector.alpha = 1;
        }];
    }
    

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
//    [phoneContactsManager_ unsetListener];

    // add members to album
    //TODO if already shotvibe member just add to album else sent notification to user to join?
    RCLog(@"contacts to add >> ");
	
	[MBProgressHUD showHUDAddedTo:self.view animated:YES];
	
    NSString *defaultCountryCode = [[[albumManager_ getShotVibeAPI] getAuthData] getDefaultCountryCode];

    NSMutableArray *memberAddRequests = [[NSMutableArray alloc] init];
	
    for (SLPhoneContact *phoneContact in checkedContactsList_) {
        SLShotVibeAPI_MemberAddRequest *request = [[SLShotVibeAPI_MemberAddRequest alloc] initWithNSString:[phoneContact getFullName]
                                                                                              withNSString:[phoneContact getPhoneNumber]];

        [memberAddRequests addObject:request];
	}

    [[Mixpanel sharedInstance] track:@"Add Friends Screen Done"
                          properties:@{ @"album_id" : [NSString stringWithFormat:@"%lld", self.albumId],
                                        @"num_contacts" : [NSNumber numberWithUnsignedInteger:memberAddRequests.count] }];

	
	//[contactsToInvite addObject:@{@"phone_number": @"+40700000002", @"default_country":regionCode, @"contact_nickname":@"Cristi"}];
	//[contactsToInvite addObject:@{@"phone_number": @"(070) 000-0001", @"default_country":regionCode, @"contact_nickname":@"Cristi"}];
	
    if (memberAddRequests.count > 0) {
		// send request
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            SLAPIException *apiException = nil;
            @try {
                // TODO
                // - If any "MemberAddFailure" are returned, then show dialog to user with the details

                [[albumManager_ getShotVibeAPI] albumAddMembersWithLong:self.albumId
                                                       withJavaUtilList:[[SLArrayList alloc] initWithInitialArray:memberAddRequests]
                                                           withNSString:defaultCountryCode];
            } @catch (SLAPIException *exception) {
                apiException = exception;
            }

			dispatch_async(dispatch_get_main_queue(), ^{
                [[GLSharedCamera sharedInstance] showGlCameraView];
				[MBProgressHUD hideHUDForView:self.view animated:YES];
				[self.navigationController dismissViewControllerAnimated:YES completion:nil];
			});
		});
	}
}

- (void)cancelPressed:(id)sender {
    
    [[GLSharedCamera sharedInstance] showGlCameraView];
    
    [[Mixpanel sharedInstance] track:@"Add Friends Screen Canceled"
                          properties:@{ @"album_id" : [NSString stringWithFormat:@"%lld", self.albumId] }];

//    [phoneContactsManager_ unsetListener];

    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)contactsSourceChanged:(UISegmentedControl *)sender {
    if(sender.selectedSegmentIndex == 2){
        NSLog(@"need to show groups");
        showGroups = YES;
        [self filterContactsBySearch];
        
    } else {
        showGroups = NO;
         [self filterContactsBySearch];
    }
   
}

- (IBAction)overlayPressed:(id)sender {
	[self.searchBar resignFirstResponder];
}


// This is called from a background thread
- (void)phoneContactsUpdatedWithSLArrayList:(SLArrayList *)phoneContacts
{
    NSLog(@"phoneContacts size: %d", [phoneContacts size]);

    if (phoneContacts.array.count > 0) {
        [[Mixpanel sharedInstance] track:@"zzz phoneContactsUpdated contacts received"
                              properties:@{ @"num_contacts" : [NSString stringWithFormat:@"%d", phoneContacts.array.count] }];
    } else {
        [[Mixpanel sharedInstance] track:@"zzz phoneContactsUpdated no contacts"];
    }

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

static inline NSString * albumFirstLetter(SLAlbumSummary *album)
{
//    if ([phoneContact getLastName].length > 0) {
        return [[[album getName] substringToIndex:1] uppercaseString];
//    } else {
//        return [[[phoneContact getFirstName] substringToIndex:1] uppercaseString];
//    }
}


- (void)setAllContacts:(NSArray *)contacts
{
    allContacts_ = contacts;

    [self filterContactsBySearch];
}


- (void)setAlbumList:(NSArray *)albums {
    
    allAlbums = albums;
//    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//        // Set all the album thumbnails to download at high priority
//        for (SLAlbumSummary *a in albums) {
//            if ([a getLatestPhotos].array.count > 0) {
//                SLAlbumPhoto *p = [[a getLatestPhotos].array objectAtIndex:0];
//                if ([p getServerPhoto]) {
//                    [photoFilesManager_ queuePhotoDownload:[[p getServerPhoto] getId]
//                                                  photoUrl:[[p getServerPhoto] getUrl]
//                                                 photoSize:[PhotoSize Thumb75]
//                                              highPriority:YES];
//                }
//            }
//        }
//    });
//    
//    [self searchForAlbumWithTitle:self.searchbar.text];
}

- (void)filterContactsBySearch
{
    
//    if(segmentGroups){
//    
//        
//        
//        
//        
//        
//        
//    
//    }
    
    if(showGroups){
        searchFilteredContacts_ = allAlbums;
        [self computeSections];
        return;
    }
    
    
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
    
    
   
    
    

    int i = 0;
    int k = 0;
    
    if(showGroups){
//        numSections_ = 1;
        
        NSUInteger initialCapacity = [allAlbums count]; // Enough for the alphabet
        NSMutableArray *sectionTitles = [[NSMutableArray alloc] initWithCapacity:initialCapacity];
        
        NSMutableArray *sectionRowCounts = [[NSMutableArray alloc] initWithCapacity:initialCapacity];
        NSMutableArray *sectionStartIndexes = [[NSMutableArray alloc] initWithCapacity:initialCapacity];
        
        for (SLAlbumSummary *p in allAlbums) {
            NSString *firstLetter = [[[p getName] substringToIndex:1] uppercaseString];//albumFirstLetter([p getName]);
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
        
        
    } else {
    
        NSUInteger initialCapacity = 32; // Enough for the alphabet
        NSMutableArray *sectionTitles = [[NSMutableArray alloc] initWithCapacity:initialCapacity];
        
        NSMutableArray *sectionRowCounts = [[NSMutableArray alloc] initWithCapacity:initialCapacity];
        NSMutableArray *sectionStartIndexes = [[NSMutableArray alloc] initWithCapacity:initialCapacity];
        
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
        
    }
    
    
    

    [self.tableView reloadData];
}

- (void)computeSections2
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
