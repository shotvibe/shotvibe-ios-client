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
#import "SL/ArrayList.h"
#import "SL/PhoneContactsManager.h"
#import "SL/PhoneContact.h"
#import "SL/PhoneContactDisplayData.h"
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
#import "SDWebImageManager.h"
#import "ShotVibeAPITask.h"
#import "GLContainersViewController.h"
#import "YYWebImage.h"

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
    UIView * contactTypeSelectedLine;
    UIButton * openGroupFromMembersButton;
    
    UILabel * no;
    UILabel * photos;
    UILabel * yet;
    UILabel * letsGetsStarted;
    UIImageView * dmutArrow;
    UIImageView * friendsArrow;
}



#pragma mark - View Lifecycle

-(void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    [phoneContactsManager_ unsetListener];
    
    [no removeFromSuperview];
    [photos removeFromSuperview];
    [yet removeFromSuperview];
    
    
    
    //    [albumManager_ removeAlbumListListenerWithSLAlbumManager_AlbumListListener:self];
    
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    //    [phoneContactsManager_ unsetListener];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"****** register");
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [phoneContactsManager_ setListenerWithSLPhoneContactsManager_Listener:self];
    
    
    if(self.state == SVAddFriendsFromAddFriendButton){
        self.pageTitle.text = @"Pick friends to group:";
        self.contactsSourceSelector.selectedSegmentIndex = 0;
        self.backBut.alpha = 1;
        
        self.groupsSourceButton.alpha = 0;
        //            [self.groupsSourceButton removeFromSuperview];
        
        
        
        self.friendsSourceButton.frame = CGRectMake(self.friendsSourceButton.frame.origin.x, self.friendsSourceButton.frame.origin.y, self.view.frame.size.width/2, self.friendsSourceButton.frame.size.height);
        //            self.friendsSourceButton.backgroundColor = [UIColor redColor];
        
        self.contactsSourceButton.frame = CGRectMake(self.view.frame.size.width/2, self.contactsSourceButton.frame.origin.y, self.view.frame.size.width/2, self.contactsSourceButton.frame.size.height);
        //            self.contactsSourceButton.backgroundColor = [UIColor greenColor];
        //        });
        
        //
        //
        
        contactTypeSelectedLine.frame = CGRectMake(0, contactTypeSelectedLine.frame.origin.y, self.view.frame.size.width/2, contactTypeSelectedLine.frame.size.height);
        
        
    } else if(self.state == SVAddFriendsMainWithImage){
        self.pageTitle.text = @"Choose some friends to share with or create a new group:";
        self.backBut.alpha = 1;
        self.contactsSourceSelector.selectedSegmentIndex = 2;
    } else if(self.state == SVAddFriendsFromMove){
        self.pageTitle.text = @"Choose group to share image with:";
        //            self.pageTitle
        self.backBut.alpha = 1;
        
        self.friendsSourceButton.alpha = 0;
        self.contactsSourceButton.alpha = 0;
        
        
        self.groupsSourceButton.frame = CGRectMake(0, self.groupsSourceButton.frame.origin.y, self.view.frame.size.width, self.groupsSourceButton.frame.size.height);
        
        contactTypeSelectedLine.frame = CGRectMake(0, contactTypeSelectedLine.frame.origin.y, self.view.frame.size.width, contactTypeSelectedLine.frame.size.height);
        
        self.contactsSourceSelector.selectedSegmentIndex = 2;
        //        [UIView animateWithDuration:0.3 animations:^{
        //            contactTypeSelectedLine.frame = CGRectMake((self.view.frame.size.width/3)*2, self.contactSourceButtonsView.frame.size.height-1, self.view.frame.size.width/3, 8);
        //        }];
        [self contactsSourceChanged:self.contactsSourceSelector];
        self.tableView.frame = CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y, self.tableView.frame.size.width, self.tableView.frame.size.height+self.proceedButton.frame.size.height);
        
        
    }
    
    //    else if(self.state == SVAddFriendsMainWithoutIamge) {
    //
    ////        self.state = SVAddFriendsMainWithoutIamge;
    //        self.backBut.alpha = 0;
    //        self.pageTitle.text = @"llalala";
    //
    //    }
    //
    //    if(self.showGroupsSegment){
    //        [self.contactsSourceSelector setWidth:100 forSegmentAtIndex:2];
    //        [self.contactsSourceSelector setEnabled:YES forSegmentAtIndex:2];
    //    } else {
    //        [self.contactsSourceSelector setWidth:0.1 forSegmentAtIndex:2];
    //        [self.contactsSourceSelector setEnabled:NO forSegmentAtIndex:2];
    //    }
    
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //    [self.tableView reloadInputViews];
    //    [self.tableView reloadSectionIndexTitles];
    //
    //    [self viewDidLoad];
    
    
    //    [self.tableView deselectRowAtIndexPath:0 animated:YES];
    
    
    
}

//-(void)viewWillDisappear:(BOOL)animated {
//    [super viewWillDisappear:animated];
//
//}

//- (void)viewWillAppear:(BOOL)animated {
//    [super viewWillAppear:animated];
//
//
//
//
//}

- (void)viewDidLoad
{
    showGroups = NO;
    self.fromCameraMainScreen = NO;
    self.friendsFromMainWithPicture = NO;
    self.showGroupsSegment = NO;
    self.fromMove = NO;
    //    self.indexNumber = 1;
    
    
    [super viewDidLoad];
    self.proceedButton.enabled = YES;
    self.proceedButton.frame = CGRectMake(self.proceedButton.frame.origin.x, self.proceedButton.frame.origin.y+self.proceedButton.frame.size.height, self.proceedButton.frame.size.width, self.proceedButton.frame.size.height);
    
    //    openGroupFromMembersButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-90, 150, 70, 70)];
    //    [openGroupFromMembersButton setTitle:@"go" forState:UIControlStateNormal];
    //    openGroupFromMembersButton.alpha = 0;
    //    [openGroupFromMembersButton addTarget:self action:@selector(openGroupFromMembers) forControlEvents:UIControlEventTouchUpInside];
    //    [openGroupFromMembersButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    //    [self.view addSubview:openGroupFromMembersButton];
    
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
    self.contactsSourceSelector.selectedSegmentIndex = 0;
    
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
    
    self.searchBar.translucent = NO;
    self.searchBar.opaque = NO;
    self.searchBar.showsCancelButton = NO;
    //    self.searchBar.subviews obje
    [self.searchBar setBackgroundImage:[[UIImage alloc] init]];
    
    UIView * searchBorder = [[UIView alloc] initWithFrame:CGRectMake(self.searchBar.frame.origin.x,self.searchBar.frame.size.height-1, self.searchBar.frame.size.width, 1)];
    searchBorder.backgroundColor = UIColorFromRGB(0x747575);
    [self.searchBar addSubview:searchBorder];
    
    
    //    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.layer.borderWidth = 0;
    self.searchBar.barTintColor = [UIColor whiteColor];
    self.searchBar.layer.borderColor = [[UIColor whiteColor] CGColor];
    
    [[Mixpanel sharedInstance] track:@"Add Friends Screen Viewed"
                          properties:@{ @"album_id" : [NSString stringWithFormat:@"%lld", self.albumId] }];
    
    //    self.searchBar.tin
    self.searchBar.placeholder = @"search";
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"GothamRounded-Book" size:20]}];
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:UIColorFromRGB(0x747575)];
    
    
    
    contactTypeSelectedLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.contactSourceButtonsView.frame.size.height-1, self.view.frame.size.width/3, 8)];
    contactTypeSelectedLine.backgroundColor = UIColorFromRGB(0x3eb4b6);
    
    [self.contactSourceButtonsView addSubview:contactTypeSelectedLine];
    
    self.backBut.alpha = 0;
    
    
//    self.groupsSourceButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width/3, self.contactSourceButtonsView.frame.size.height)];
//    
//    [self.contactSourceButtonsView addSubview:self.groupsSourceButton];
    
    
    
//    self.friendsSourceButton.frame = CGRectMake(self.friendsSourceButton.frame.origin.x, self.friendsSourceButton.frame.origin.y, self.view.frame.size.width/2, self.friendsSourceButton.frame.size.height);
    //            self.friendsSourceButton.backgroundColor = [UIColor redColor];
    
//    self.contactsSourceButto
    
    
//    dispatch_async(dispatch_get_main_queue(), ^{
    
//        [self.friendsSourceButton removeFromSuperview];
//        self.contactSourceButtonsView.alpha = 0;
    
//        [self.contactSourceButtonsView addSubview:self.friendsSourceButton];
        
//        self.friendsSourceButton.backgroundColor = [UIColor redColor];
//        self.friendsSourceButton.frame = CGRectMake(0, 0, 100, 10);
        
//    });
    
    
}

- (IBAction)nvBackTapped:(id)sender {
    
    //    [[[ContainerViewController sharedInstance] navigationController] popViewControllerAnimated:YES];
    
    if(self.state == SVAddFriendsFromAddFriendButton){
        [[GLContainersViewController sharedInstance] resetFriendsView];
        [[GLContainersViewController sharedInstance] goToAlbumListViewController:NO];
    } else
    
    if(self.state == SVAddFriendsFromMove){
        
        
        [[GLContainersViewController sharedInstance] resetFriendsView];
        [[GLContainersViewController sharedInstance] goToAlbumListViewController:NO];
        //        [[ContainerViewController sharedInstance] transitToAlbumList:NO direction:UIPageViewControllerNavigationDirectionForward withAlbumId:0 completion:^{
        //            [[ContainerViewController sharedInstance] resetFriendsView];
        //            self.fromCameraMainScreen = NO;
        
        //        }];
        
    } else if(self.state == SVAddFriendsMainWithImage){
        
        [[GLContainersViewController sharedInstance] resetFriendsView];
        [[GLContainersViewController sharedInstance] goToAlbumListViewController:NO];
        

        
        //        [[ContainerViewController sharedInstance] transitToAlbumList:NO direction:UIPageViewControllerNavigationDirectionForward withAlbumId:0 completion:^{
        //            [[ContainerViewController sharedInstance] resetFriendsView];
        //            //            self.fromCameraMainScreen = NO;
        //
        //        }];
        
    } else {
        [[GLContainersViewController sharedInstance] resetFriendsView];
        [[GLContainersViewController sharedInstance] goToAlbumListViewController:YES];
    }
    
}

- (IBAction)contactsButtonTapped:(id)sender {
    
    self.contactsSourceSelector.selectedSegmentIndex = 1;
    [UIView animateWithDuration:0.3 animations:^{
        
        if(self.state == SVAddFriendsFromAddFriendButton){
            contactTypeSelectedLine.frame = CGRectMake(self.view.frame.size.width/2, self.contactSourceButtonsView.frame.size.height-1, self.view.frame.size.width/2, 8);
        } else {
            contactTypeSelectedLine.frame = CGRectMake(self.view.frame.size.width/3, self.contactSourceButtonsView.frame.size.height-1, self.view.frame.size.width/3, 8);
        }
    }];
    [self contactsSourceChanged:self.contactsSourceSelector];
    
}

- (IBAction)groupsButtonTapped:(id)sender {
    
    
    //    if(self.state != SVAddFriendsMainWithoutIamge){
    
    self.contactsSourceSelector.selectedSegmentIndex = 2;
    [UIView animateWithDuration:0.3 animations:^{
        contactTypeSelectedLine.frame = CGRectMake((self.view.frame.size.width/3)*2, self.contactSourceButtonsView.frame.size.height-1, self.view.frame.size.width/3, 8);
    }];
    [self contactsSourceChanged:self.contactsSourceSelector];
    
    //    } else if (self.state == SVAddFriendsFromMove){
    
    //    } else {
    
    //        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oopsi"
    //                                                                                          message:@"Create a group with a group? try to select friends to group with instead to create group with the friends you have just selected."
    //                                                                                         delegate:nil
    //                                                                                cancelButtonTitle:@"Ohh i got it"
    //                                                                                otherButtonTitles:nil];
    //                                          [alert show];
    //
    //
    
    //    }
    
    
}

- (IBAction)proceedTapped:(id)sender {
    if(self.state == SVAddFriendsFromAddFriendButton){
        [self donePressed:nil];
    }
    if(self.state == SVAddFriendsMainWithImage || self.state == SVAddFriendsMainWithoutIamge){
        [self openGroupFromMembers];
    }
    
    
}

- (IBAction)friendsButtonTapped:(id)sender {
    
    self.contactsSourceSelector.selectedSegmentIndex = 0;
    [UIView animateWithDuration:0.2 animations:^{
        
        if(self.state == SVAddFriendsFromAddFriendButton){
            contactTypeSelectedLine.frame = CGRectMake(0, self.contactSourceButtonsView.frame.size.height-1, self.view.frame.size.width/2, 8);
        } else {
            contactTypeSelectedLine.frame = CGRectMake(0, self.contactSourceButtonsView.frame.size.height-1, self.view.frame.size.width/3, 8);
        }
        
    }];
    [self contactsSourceChanged:self.contactsSourceSelector];
    
    
}


//- (UIStatusBarStyle)preferredStatusBarStyle
//{
//    return UIStatusBarStyleDefault;
//}

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
    if(cell==nil){
        
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SVContactCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    cell.contactIcon.layer.cornerRadius = cell.contactIcon.frame.size.width/2;
    if(showGroups){
        
        
        
        SLAlbumContents * album = [self getAlbumForIndexPath:indexPath];//[allAlbums objectAtIndex:indexPath.row];
        cell.albumId = [album getId];
        
        //        NSLog(@"count is : %lu",(unsigned long)[album getLatestPhotos].array.count);
        
        //        if([album ]){}
        NSLog(@"album member arra %@",[album getMembers]);
        
//        if([album getMembers].array.count  > 0){
        
            
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
            //        cell.checkmarkImage = nil;
            cell.isMemberImage = nil;
            cell.contactIcon.image = [UIImage imageNamed:@"CaptureButton"];
            if((unsigned long)[album getPhotos].array.count > 0){
                SLAlbumPhoto *latestPhoto = [[album getPhotos].array objectAtIndex:0];
                if ([latestPhoto getServerPhoto]) {
                    
                    cell.contactIcon.hidden = NO;
                    
                    NSString * st = [[[latestPhoto getServerPhoto] getUrl] stringByReplacingOccurrencesOfString:@".jpg" withString:@"_thumb75.jpg"];
                    
                    //                [cell.contactIcon setCircleImageWithURL:[NSURL URLWithString:st] placeholderImage:[UIImage imageNamed:@"CaptureButton"] borderWidth:2];
                    
                }
            }
            
            
            //            cell.author.text = [NSString stringWithFormat:NSLocalizedString(@"Last added by %@", nil), [[[latestPhoto getServerPhoto] getAuthor] getMemberNickname]];
            //
            //            [cell.networkImageView setPhoto:[[latestPhoto getServerPhoto] getId]
            //                                   photoUrl:[[latestPhoto getServerPhoto] getUrl]
            
            
            cell.titleLabel.text = [album getName];
            cell.subtitleLabel.text = result;
//        } else {
//            
//            
//            [KVNProgress showErrorWithStatus:@"no groups yet"];
//            
//            
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
        
        [cell.contactIcon yy_cancelCurrentImageRequest];
        
        if ([phoneContactDisplayData isLoading]) {
            [cell.loadingSpinner startAnimating];
            cell.contactIcon.hidden = YES;
            cell.isMemberImage.hidden = YES;
        } else {
            [cell.loadingSpinner stopAnimating];
            cell.contactIcon.hidden = NO;
            [cell.contactIcon yy_setImageWithURL:[NSURL URLWithString:[phoneContactDisplayData getAvatarUrl]] options:YYWebImageOptionProgressiveBlur | YYWebImageOptionShowNetworkActivity | YYWebImageOptionSetImageWithFadeAnimation];
//            [cell.contactIcon setImageWithURL:[[NSURL alloc] initWithString:[phoneContactDisplayData getAvatarUrl]]];
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
    return 28;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 26)];
    //	v.backgroundColor = [UIColor colorWithRed:0.92 green:0.93 blue:0.94 alpha:1];
    
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.view.frame.size.width, 26)];
    [v addSubview:l];
    l.font = [UIFont fontWithName:@"GothamRounded-Bold" size:18.0];
    l.textColor = [UIColor grayColor];
    l.backgroundColor = [UIColor clearColor];
    
    l.text = [sectionIndexTitles_ objectAtIndex:section];
    
    return v;
}

-(void)setProceedButtonActive {
    //    self.proceedButton.enabled = YES;
    [UIView animateWithDuration:0.2 animations:^{
        
        self.proceedButton.frame = CGRectMake(self.proceedButton.frame.origin.x, self.view.frame.size.height-self.proceedButton.frame.size.height, self.proceedButton.frame.size.width, self.proceedButton.frame.size.height);
    }];
}
-(void)setProceedButtonUnActive {
    //    self.proceedButton.enabled = YES;
    [UIView animateWithDuration:0.2 animations:^{
        
        self.proceedButton.frame = CGRectMake(self.proceedButton.frame.origin.x, self.proceedButton.frame.origin.y+self.proceedButton.frame.size.height, self.proceedButton.frame.size.width, self.proceedButton.frame.size.height);
    }];
}


#pragma mark - TableviewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        if(!showGroups){
    
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
                    //            self.contactsSourceSelector.alpha = 0;
                    self.contactSourceButtonsView.alpha = 0;
                    //            self.contactsSourceView.alpha = 0;
                    //            openGroupFromMembersButton.alpha = 1;
                    //            [self.view bringSubviewToFront:openGroupFromMembersButton];
    
                    [self setProceedButtonActive];
                } else {
                    self.contactSourceButtonsView.alpha = 1;
                    //            self.contactsSourceSelector.alpha = 1;
                    //            self.contactsSourceView.alpha = 1;
                    openGroupFromMembersButton.alpha = 0;
                    [self setProceedButtonUnActive];
                }
    
            }];
    
    
    
            [self.tableView reloadData];
    
        } else {
    
    
            if(self.state == SVAddFriendsMainWithImage){
    
                //            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"1"
                //                                                            message:@"1"
                //                                                           delegate:nil
                //                                                  cancelButtonTitle:@"1"
                //                                                  otherButtonTitles:nil];
                //            [alert show];
    
    
                
                
//                [[GLSharedCamera sharedInstance] resetCameraAfterUploadingFromMain];
                
                
                
                SLAlbumContents * album = [self getAlbumForIndexPath:indexPath];
                [[GLContainersViewController sharedInstance] goToFeedViewAnimated:YES withAlbumId:[album getId] completed:^{
                    self.friendsDoneBlock();
                }];

//                [[ContainerViewController sharedInstance] startUploadAfterSourceSelect:[album getId] withAlbumContents:nil];
//                [[ContainerViewController sharedInstance] transitToAlbumList:YES direction:UIPageViewControllerNavigationDirectionForward withAlbumId:0 completion:^{
//                    [[ContainerViewController sharedInstance] resetFriendsView];
//                    self.fromCameraMainScreen = NO;
//    
//                }];
                //            [self.delegate goToPage:2 andTransitToFeedAt:[al getId] startUploadImidiatly:YES afterMove:NO];
    
    
    
    
    
            } else {
    
    
                SLAlbumContents * album = [self getAlbumForIndexPath:indexPath];
    
                if(self.state == SVAddFriendsFromMove){
    
                    [ShotVibeAPITask runTask:self withAction:^id{
                        //
                        NSMutableArray * arr = [[NSMutableArray alloc] initWithCapacity:1];
                        [arr addObject:self.photoToMoveId];
    
    
    
                        [[albumManager_ getShotVibeAPI] albumCopyPhotosWithLong:[album getId] withJavaLangIterable:(id<JavaLangIterable>)arr];
    
    
                        return nil;
                    } onTaskComplete:^(id dummy) {
    
    
                        //                        for(UIViewController * vc in [[[ContainerViewController sharedInstance] navigationController] childViewControllers]){
                        [[GLContainersViewController sharedInstance] resetFriendsView];
//                        [[GLSharedCamera sharedInstance] setCameraInMain];
                        [[GLContainersViewController sharedInstance] goToFeedViewAnimated:YES withAlbumId:[album getId] completed:^{
                            [KVNProgress dismiss];
                            [[GLSharedCamera sharedInstance] setCameraInFeed];
                            
                            [[GLSharedCamera sharedInstance] setInFeedMode:YES dmutNeedTransform:self.fromPublicFeed ? YES : NO];
                            
                        }];
                        
//                        [[[ContainerViewController sharedInstance] navigationController] popViewControllerAnimated:NO];

    
                        //                            NSLog(@"%@",[[[ContainerViewController sharedInstance] navigationController] childViewControllers]);
    
                        //                        }
    
//                        [[ContainerViewController sharedInstance] transitToAlbumList:YES direction:UIPageViewControllerNavigationDirectionForward withAlbumId:[album getId] completion:^{
    
//                            [[ContainerViewController sharedInstance] resetFriendsView];
                            //                            [[ContainerViewController sharedInstance] startUploadAfterSourceSelect:[album getId] withAlbumContents:nil];
    
//                        }];
    
                    }];
                } else if(self.state == SVAddFriendsMainWithoutIamge){
//                    [[GLSharedCamera sharedInstance] setCameraInFeed];
//                    [[GLSharedCamera sharedInstance] setInFeedMode:YES dmutNeedTransform:YES];
//                    [[GLContainersViewController sharedInstance] goToFeedViewAnimated:YES withAlbumId:[album getId]];
                }
//                } else {
//    
//    
//                    if(self.state == SVAddFriendsMainWithoutIamge){
//    
//                        [[ContainerViewController sharedInstance] transitToAlbumList:YES direction:UIPageViewControllerNavigationDirectionForward withAlbumId:[album getId] completion:^{
//    
//                            [[ContainerViewController sharedInstance] resetFriendsView];
//                            //                            [[ContainerViewController sharedInstance] startUploadAfterSourceSelect:[album getId] withAlbumContents:nil];
//    
//                        }];
//    
//                    }
//    
//                }
    
            }
    
    
    
        }
}

//-(void)moveImage


-(void)openGroupFromMembers {
    
        BOOL allowProceed = NO;
    
        if(self.state == SVAddFriendsFromAddFriendButton || self.state ==
           SVAddFriendsFromMove){
            allowProceed = YES;
        } else {
            if([contactsButtons count] >= 3){
                allowProceed = YES;
            } else {
                allowProceed = NO;
            }
        }
    
        if(allowProceed){
            NSLog(@"%@",checkedContactsList_);
    
            __block long long int albumId;
            __block SLAlbumContents * album;
    
            [ShotVibeAPITask runTask:self withAction:^id{
                SLAlbumContents * newAlbum = [albumManager_ createNewBlankAlbumWithNSString:@""];
    
                NSMutableArray *memberAddRequests = [[NSMutableArray alloc] init];
    
                for (SLPhoneContact *phoneContact in checkedContactsList_) {
                    SLShotVibeAPI_MemberAddRequest *request = [[SLShotVibeAPI_MemberAddRequest alloc] initWithNSString:[phoneContact getFullName]
                                                                                                          withNSString:[phoneContact getPhoneNumber]];
    
                    [memberAddRequests addObject:request];
                }
    
                NSString *defaultCountryCode = [[[albumManager_ getShotVibeAPI] getAuthData] getDefaultCountryCode];
    
                albumId = [newAlbum getId];
                [[albumManager_ getShotVibeAPI] albumAddMembersWithLong:[newAlbum getId]
                                                       withJavaUtilList:[[SLArrayList alloc] initWithInitialArray:memberAddRequests]
                                                           withNSString:defaultCountryCode];
                album = newAlbum;
                return nil;
            } onTaskComplete:^(id dummy) {
    
                [KVNProgress dismiss];
    
                if(self.friendsFromMainWithPicture || self.friendsFromMainWithVideo){
                    albumId = 0;
                }
                
                
                
//                [KVNProgress showSuccessWithStatus:@"group is opened and now we need to transit to it"];
    
                
                [[GLContainersViewController sharedInstance] goToFeedViewAnimated:YES withAlbumId:[album getId]  completed:^{
                    [[GLContainersViewController sharedInstance] resetFriendsView];
                    if(self.friendsDoneBlock){
                        self.friendsDoneBlock();
                    } else {
                        [[GLSharedCamera sharedInstance] setCameraInFeedAfterGroupOpenedWithoutImage];
//                        [[GLSharedCamera sharedInstance] setCameraInFeed];
                    }
                    
                }];
                
//                [[ContainerViewController sharedInstance] transitToAlbumList:YES direction:UIPageViewControllerNavigationDirectionForward withAlbumId:albumId completion:^{
//                    [[ContainerViewController sharedInstance] resetFriendsView];
//                    if(self.friendsFromMainWithPicture){
//    
//                        [[ContainerViewController sharedInstance] startUploadAfterSourceSelect:[album getId] withAlbumContents:nil];
//    
//                        self.friendsFromMainWithPicture = NO;
//                    } else if (self.friendsFromMainWithVideo){
//    
//                        [[ContainerViewController sharedInstance] startUploadAfterSourceSelect:[album getId] withAlbumContents:nil];
//                        self.friendsFromMainWithVideo = NO;
//    
//                    }
//                }];
            }];
        } else {
            [KVNProgress showErrorWithStatus:@"Group is a minimum of 4"];
        }
    
}

#pragma mark -
#pragma mark Search

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    //	[searchBar setShowsCancelButton:YES animated:YES];
    //	self.contactsSourceView.alpha = 0;
    //	self.contactsSourceView.hidden = YES;
    //    self.contactSourceButtonsView.alpha = 0;
    
    self.butOverlay.alpha = 0;
    self.butOverlay.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^{
        //		self.tableView.frame = CGRectMake(0, 44+44, self.view.frame.size.width, self.view.frame.size.height-44-44-216);
        //		self.contactsSourceView.alpha = 0;
        //        contactTypeSelectedLine.alpha = 1;
        //        self.contactSourceButtonsView.alpha = 0;
        self.butOverlay.alpha = 0.2;
    }];
}
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    //	[searchBar setShowsCancelButton:NO animated:YES];
    //	self.contactsSourceView.hidden = YES;
    self.butOverlay.hidden = YES;
    [UIView animateWithDuration:0.3 animations:^{
        
        //        self.contactSourceButtonsView.alpha = 1;
        //        contactTypeSelectedLine.alpha = 0;
        //		self.tableView.frame = CGRectMake(0, 44+75, self.view.frame.size.width, self.view.frame.size.height-44-75);
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
    [self contactsButtonTapped:nil];
    //    self.contactsSourceSelector.selectedSegmentIndex = 1;
    [self filterContactsBySearch];
}
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)bar {
    return YES;
}

- (BOOL)shouldAutorotate
{
    return NO;
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
    button.titleLabel.font = [UIFont fontWithName:@"GothamRounded-Book" size:15.0];
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
            //            self.contactsSourceView.alpha = 1;
            self.contactSourceButtonsView.alpha = 1;
            [self setProceedButtonUnActive];
            //            self.contactsSourceSelector.alpha = 1;
        }];
    }
    
    
    [self.tableView reloadData];
}

- (void)updateContacts {
    
    int i = 0;
    int x_1 = 5;
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
    
    [KVNProgress show];
//    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
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
                [KVNProgress showErrorWithStatus:@"Error adding members try again later"];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[GLSharedCamera sharedInstance] showGlCameraView];
                [KVNProgress showSuccessWithStatus:[NSString stringWithFormat:@"%lu Friends Added",(unsigned long)memberAddRequests.count]];
                [[GLContainersViewController sharedInstance] goBackToFeedAfterAddingMembersAnimated:NO];
                
                
//                [MBProgressHUD hideHUDForView:self.view animated:YES];
                //				[self.navigationController dismissViewControllerAnimated:YES completion:nil];
                [self dismissViewControllerAnimated:YES
                                         completion:nil];
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
                              properties:@{ @"num_contacts" : [NSString stringWithFormat:@"%lu", (unsigned long)phoneContacts.array.count] }];
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
        [no removeFromSuperview];
        [photos removeFromSuperview];
        [yet removeFromSuperview];
        
        if(allAlbums.count < 1){
//            [KVNProgress showErrorWithStatus:@"no groups yet blah blah"];
            
            NSString * nos = @"No";
            float spacing = -9.0f;
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:nos];
            
            [attributedString addAttribute:NSKernAttributeName
                                     value:@(spacing)
                                     range:NSMakeRange(0, [nos length])];
            
            no = [[UILabel alloc] initWithFrame:CGRectMake(50, 60, self.view.frame.size.width, self.view.frame.size.height/8)];
            no.attributedText = attributedString;
            
            no.font = [UIFont fontWithName:@"GothamRounded-Bold" size:90];
            no.textColor = UIColorFromRGB(0x45B4B5);
            
            
            NSString *  photoss = @"Groups";
            NSMutableAttributedString *attributedString2 = [[NSMutableAttributedString alloc] initWithString:photoss];
            
            [attributedString2 addAttribute:NSKernAttributeName
                                      value:@(spacing)
                                      range:NSMakeRange(0, [photoss length])];
            
            photos = [[UILabel alloc] initWithFrame:CGRectMake(50, 60+self.view.frame.size.height/9, self.view.frame.size.width, self.view.frame.size.height/8)];
            photos.attributedText = attributedString2;
            photos.font = [UIFont fontWithName:@"GothamRounded-Bold" size:90];
            photos.textColor = UIColorFromRGB(0xFED84B);
            
            
            NSString *  yets = @"Yet.";
            NSMutableAttributedString *attributedString3 = [[NSMutableAttributedString alloc] initWithString:yets];
            
            [attributedString3 addAttribute:NSKernAttributeName
                                      value:@(spacing)
                                      range:NSMakeRange(0, [yets length])];
            
            yet = [[UILabel alloc] initWithFrame:CGRectMake(50, 60+self.view.frame.size.height/9+self.view.frame.size.height/9, self.view.frame.size.width, self.view.frame.size.height/8)];
            yet.attributedText = attributedString3;
            yet.font = [UIFont fontWithName:@"GothamRounded-Bold" size:90];
            yet.textColor = UIColorFromRGB(0xEE7482);
            
            
            
            
            letsGetsStarted = [[UILabel alloc] initWithFrame:CGRectMake(50, self.view.frame.size.height-self.view.frame.size.height/10, self.view.frame.size.width-100, self.view.frame.size.height/10)];
            //    letsGetsStarted.backgroundColor = [UIColor orangeColor];
            letsGetsStarted.text = @"Pull Mr. Glance down or swipe Right and Let's get this party started.";
            letsGetsStarted.lineBreakMode = NSLineBreakByTruncatingMiddle;
            letsGetsStarted.numberOfLines = 2;
            letsGetsStarted.textColor = UIColorFromRGB(0x979494);
            letsGetsStarted.font = [UIFont fontWithName:@"GothamRounded-Bold" size:18];
            letsGetsStarted.textAlignment = NSTextAlignmentCenter;
            
            dmutArrow = [[UIImageView alloc] initWithFrame:CGRectMake(170, 215, 150, 175)];
            dmutArrow.image = [UIImage imageNamed:@"dmutArrow"];
            
            
            
            float degrees = -20; //the value in degrees
            dmutArrow.transform = CGAffineTransformMakeRotation(degrees * M_PI/180);
            
            
            
            
//            [self.tableView setUserInteractionEnabled:NO];
            [no removeFromSuperview];
            [photos removeFromSuperview];
            [yet removeFromSuperview];
            
            [self.tableView addSubview:no];
            [self.tableView addSubview:photos];
            [self.tableView addSubview:yet];
//            [self.tableView addSubview:letsGetsStarted];
            
            
        } else {
            [no removeFromSuperview];
            [photos removeFromSuperview];
            [yet removeFromSuperview];
            
        }
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
        
        [no removeFromSuperview];
        [photos removeFromSuperview];
        [yet removeFromSuperview];
        
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    RCLog(@"%@ did receive memory warning", NSStringFromClass([self class]));
    //    [thumbnailCache removeAllObjects];
    
}

@end
