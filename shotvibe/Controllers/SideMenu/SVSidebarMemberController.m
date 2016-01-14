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
//#import "UIImageView+WebCache.h"
#import "MFSideMenu.h"
#import "ShotVibeAppDelegate.h"
#import "SL/DateTime.h"
#import "SL/AuthData.h"
#import "SL/ShotVibeAPI.h"
#import "SL/AlbumMember.h"
#import "SL/AlbumContents.h"
#import "SL/ArrayList.h"
#import "SL/AlbumUser.h"
#import "MBProgressHUD.h"
//#import "ContainerViewController.h"
#import "ShotVibeAPITask.h"
#import "GLContainersViewController.h"
#import "YYWebImage.h"
#import "NSDate+Formatting.h"

@interface SVSidebarMemberController () {
    SLShotVibeAPI *shotvibeAPI;
    NSMutableArray *members;
    SLAlbumMember *owner;
    SVSidebarAlbumMemberCell *ownerCell;
    UINavigationController * nav;
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
    
    
    
    
    //    self addObserver:<#(nonnull NSObject *)#> forKeyPath:<#(nonnull NSString *)#> options:<#(NSKeyValueObservingOptions)#> context:<#(nullable void *)#>
    
    //    [[NSNotificationCenter defaultCenter] postNotificationName:@"kUpdateUsersStatus" object:nil];
    
    // IOS7
    //    if (IS_IOS7) {
    //        self.sidebarNav.tintColor = [UIColor blackColor];
    //        self.sidebarNav.barTintColor = BLUE;
    //
    //        UIView *background = [[UIView alloc] initWithFrame:CGRectMake(0, -20, 568, 20)];
    //        background.backgroundColor = BLUE;
    //        [self.view addSubview:background];
    //    } else {
    self.wantsFullScreenLayout = NO;
    UIImage *baseImage = [UIImage imageNamed:@"sidebarMenuNavbar.png"];
    UIEdgeInsets insets = UIEdgeInsetsMake(5, 20, 0, 20);
    UIImage *resizableImage = [baseImage resizableImageWithCapInsets:insets];
    [self.sidebarNav setBackgroundImage:resizableImage forBarMetrics:UIBarMetricsDefault];
    //    }
    
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
    
    //    self.tableView setContentOffset:<#(CGPoint)#>
    //    [self.tableView setContentInset:UIEdgeInsetsMake(38,0,0,0)];
    //    self.butAddFriends.center = CGPointMake(self.butAddFriends.frame.origin.x, self.butAddFriends.frame.origin.y+60);
    //    self.butAddFriends.frame = CGRectMake(self.butAddFriends.frame.origin.x, self.butAddFriends.frame.origin.y+150, self.butAddFriends.frame.size.width, self.butAddFriends.frame.size.height);
    //    UIImageView * but = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.butAddFriends.frame.size.height, self.butAddFriends.frame.size.height)];
    //    but.image = [UIImage imageNamed:@"addFriendsBg"];
    //    [self.butAddFriends setImage:but.image forState:UIControlStateNormal];
    //    self.butAddFriends.imageView.contentMode = UIViewContentModeScaleAspectFill;
    //    self.butAddFriends.imageEdgeInsets = UIEdgeInsetsMake(30 , 30, 30, 30);
    UIView * navBar = [[UIView alloc] initWithFrame:CGRectMake(0, -20, self.view.frame.size.width, 20)];
    navBar.backgroundColor = UIColorFromRGB(0x40b4b5);
    [self.view addSubview:navBar];
    
    
    UITapGestureRecognizer * changeNameGestTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeNameTapped:)];
    self.groupTitle.userInteractionEnabled = YES;
    [self.groupTitle addGestureRecognizer:changeNameGestTap];
    
    
    UITapGestureRecognizer * addPlusTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addPlusTapped:)];
    self.addPlusButton.userInteractionEnabled = YES;
    [self.addPlusButton addGestureRecognizer:addPlusTap];
    
    
    
    
    //    self.view.frame = CGRectMake(0,0,200,400);
    
}

-(void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    //    [[NSNotificationCenter defaultCenter] addObserver:self
    //                                             selector:@selector(registerUserList:)
    //                                                 name:@"kUpdateUsersStatus" object:nil];
    
    
    
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(registerUserList:)
                                                 name:@"kUpdateUsersStatus" object:nil];
    
}

-(void)viewDidDisappear:(BOOL)animated {
    
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"kUpdateUsersStatus" object:nil];
    //    [[NSNotificationCenter defaultCenter]removeObserver:self forKeyPath:@"kUpdateUsersStatus"];
}


#pragma mark - Actions

- (void)changeNameTapped:(UITapGestureRecognizer*)gest {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New Album Name"
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Ok", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert textFieldAtIndex:0].text = [[_albumContents getName] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    alert.tag = 35;
    [alert show];
}

- (void)addPlusTapped:(UITapGestureRecognizer*)gest {
    
    [self addFriendsButtonPressed:nil];
    
}


- (void)registerUserList:(NSNotification *)notification {
    
    [self.tableView reloadData];
}



- (void) sizeLabel: (UILabel *) label toRect: (CGRect) labelRect  {
    
    // Set the frame of the label to the targeted rectangle
    label.frame = labelRect;
    
    // Try all font sizes from largest to smallest font size
    int fontSize = 300;
    int minFontSize = 5;
    
    // Fit label width wize
    CGSize constraintSize = CGSizeMake(label.frame.size.width, MAXFLOAT);
    
    do {
        // Set current font size
        label.font = [UIFont fontWithName:label.font.fontName size:fontSize];
        
        // Find label size for current font size
        CGRect textRect = [[label text] boundingRectWithSize:constraintSize
                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                  attributes:@{NSFontAttributeName:label.font}
                                                     context:nil];
        
        CGSize labelSize = textRect.size;
        
        // Done, if created label is within target size
        if( labelSize.height <= label.frame.size.height )
            break;
        
        // Decrease the font size and try again
        fontSize -= 2;
        
    } while (fontSize > minFontSize);
}

- (void)navigateToAddFriends:(id)sender
{
    
    
    [[GLContainersViewController sharedInstance] goToFriendsListViewAnimatedBeforeAddingMembers:NO albumId:self.albumId];
    //    self.parentController
    //    __block SVSidebarMemberController * weakSelf = self;
    //    [self.parentController.menuContainerViewController setMenuState:MFSideMenuStateClosed completion:^{
    //
    //    }];
    //    [self.parentController.menuContainerViewController toggleRightSideMenuCompletion:^{
    
    //    }];
    // prepareForSegue is called in parentController SVAlbumGridViewController
    //    [self.parentController performSegueWithIdentifier:@"AddFriendsSegue" sender:sender];
    
    
    //    SVNavigationController *destinationNavigationController = (SVNavigationController *)segue.destinationViewController;
    //    SVAddFriendsViewController *destination = [[SVAddFriendsViewController alloc] init];
    //    [self presentViewController:destination animated:YES completion:nil];
    
    //    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    //  SVAddFriendsViewController *destination = [storyboard instantiateViewControllerWithIdentifier:@"AddFriendsSegue"];
    //[self.parentController performSegueWithIdentifier:@"AddFriendsSegue" sender:sender];
    
    
    
    //    UIStoryboard * sb = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    //    SVAddFriendsViewController * vc = [[SVAddFriendsViewController alloc] init];
    //    vc.albumId = self.albumId;
    //    vc.state = SVAddFriendsFromAddFriendButton;
    //    nav = [[UINavigationController alloc] initWithRootViewController:vc];
    //    [nav setNavigationBarHidden:YES];
    //    vc.navigationController = nav;
    //    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    //    self.sideself.na
    
    
    //    [self presentViewController:vc animated:YES completion:^{
    //        [[GLSharedCamera sharedInstance] hideGlCameraView];
    //    }];
    
    //    [self.navigationController pushViewController:destination animated:YES];
    //    destination.albumId = self.albumId;
    
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
    
    //	if ([self.searchBar isFirstResponder])
    //		[self.searchBar resignFirstResponder];
    
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
    
    self.groupTitle.text = [_albumContents getName];
    [self sizeLabel:self.groupTitle toRect:self.groupTitle.frame];
    
    
    
    [self searchForMemberWithName:nil];
    
    if (members.count == 0) {
        // No members
        self.noMembersView.hidden = NO;
        self.tableView.hidden = YES;
        //        self.searchBar.userInteractionEnabled = NO;
        self.butOwner.enabled = YES;
        //        self.butAddFriends.frame = CGRectMake(16, 280, 240, 40);
        
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
        //        self.searchBar.userInteractionEnabled = YES;
        
        self.butOwner.enabled = NO;
        //        self.butAddFriends.frame = CGRectMake(16, 80, 240, 40);
        
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
    if(cell==nil){
        
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SVSidebarAlbumMemberCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    SLAlbumMember *member = [members objectAtIndex:indexPath.row];
    
    
    SLDateTime * lastSeenInTime = [[member getUser] getLastOnline];
    NSString * timeInWordssAgo;
    NSDate * lastSeenDate;
    if(lastSeenInTime > 0){
        lastSeenDate = [NSDate dateWithTimeIntervalSince1970:[lastSeenInTime getTimeStamp] / 1000000.0];
        
        
        timeInWordssAgo = [NSString stringWithFormat:@"%@ ago",[lastSeenDate distanceOfTimeInWords:[NSDate date] shortStyle:YES]];
    }
    [cell.profileImageView yy_setImageWithURL:[NSURL URLWithString:[[member getUser] getMemberAvatarUrl]] options:YYWebImageOptionProgressiveBlur | YYWebImageOptionShowNetworkActivity | YYWebImageOptionSetImageWithFadeAnimation];

    [cell.memberLabel setText:[[member getUser] getMemberNickname]];
    
    
    if ([[shotvibeAPI getAuthData] getUserId] == [[member getUser] getMemberId]) {
        
        cell.statusImageView.image = [UIImage imageNamed:@"AlbumInfoLeaveIcon.png"];
        cell.statusLabel.text = NSLocalizedString(@"Leave", nil);
        cell.memberLabel.textColor = UIColorFromRGB(0x3eb4b6);
        cell.statusLabel.textColor = UIColorFromRGB(0xf07480);
        CGSize size = [cell.statusLabel.text sizeWithFont:cell.statusLabel.font];
        cell.statusImageView.frame = CGRectMake(cell.statusLabel.frame.origin.x + cell.statusLabel.frame.size.width - size.width - 4 - cell.statusImageView.frame.size.width, cell.statusImageView.frame.origin.y, 13, 13);
    }
    else {
        cell.statusLabel.textColor = UIColorFromRGB(0x3eb4b6);
        cell.memberLabel.textColor = UIColorFromRGB(0x747575);
        if (![member getInviteStatus]) {
            cell.statusImageView.image = nil;
            cell.statusLabel.text = @"";
        } else {
            switch ([member getInviteStatus].ordinal) {
                case SLAlbumMember_InviteStatus_JOINED:
                    
                    break;
                    
                case SLAlbumMember_InviteStatus_SMS_SENT:
                case SLAlbumMember_InviteStatus_INVITATION_VIEWED:
                    cell.statusImageView.image = [UIImage imageNamed:@"MemberInvited"];
                    cell.statusLabel.text = NSLocalizedString(@"Invited", nil);
                    cell.statusLabel.textColor = UIColorFromRGB(0xF07480);
                    break;
            }
            CGSize size = [cell.statusLabel.text sizeWithFont:cell.statusLabel.font];
            cell.statusImageView.frame = CGRectMake(175 + cell.statusLabel.frame.size.width - size.width - 4 - cell.statusImageView.frame.size.width, cell.statusImageView.frame.origin.y, 13, 13);
        }
    }
    //RCLog(@"%lld == %lld member.avatarUrl %@", shotvibeAPI.authData.userId, member.memberId, member.avatarUrl);
    cell.profileImageView.layer.masksToBounds = YES;
    
    if([[GLPubNubManager sharedInstance] statusForId:[NSString stringWithFormat:@"%lld",[[member getUser] getMemberId]]]){
        //Online
        cell.profileImageView.layer.borderColor = UIColorFromRGB(0x40b4b5).CGColor;
        cell.profileImageView.layer.borderWidth = 3;
        cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.size.width/2;
        
        if ([[shotvibeAPI getAuthData] getUserId] != [[member getUser] getMemberId]) {
            if(lastSeenInTime > 0){
                
                if([member getInviteStatus].ordinal == SLAlbumMember_InviteStatus_JOINED){
                    cell.statusLabel.text = @"Online";
                }
            } else {
                cell.statusLabel.text = NSLocalizedString(@"Joined", nil);
            }
        }
        
        
        
    } else {
        //Offline
        cell.profileImageView.layer.borderColor = UIColorFromRGB(0xf07480).CGColor;
        cell.profileImageView.layer.borderWidth = 3;
        cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.size.width/2;
        
        
        
        
        
        
        if ([[shotvibeAPI getAuthData] getUserId] != [[member getUser] getMemberId]) {
            if(lastSeenInTime > 0){
                
                if([member getInviteStatus].ordinal == SLAlbumMember_InviteStatus_JOINED){
                    
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateFormat:@"HH:mm"];
                    NSNumber * lastPnEvent = [[GLPubNubManager sharedInstance] disconnectTimeForId:[NSString stringWithFormat:@"%lld",[[member getUser] getMemberId]]];
                    if(lastPnEvent > 0){
                        
                        NSString * timeInWordssAgo = [NSString stringWithFormat:@"%@ ago",[[NSDate dateWithTimeIntervalSince1970:[lastPnEvent doubleValue]] distanceOfTimeInWords:[NSDate date] shortStyle:YES]];
                        
                        cell.statusLabel.text = [NSString stringWithFormat:@"Seen %@ @ %@",timeInWordssAgo,[formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[lastPnEvent doubleValue]]]];
                        
                    } else {
                        cell.statusLabel.text = [NSString stringWithFormat:@"Seen %@ @ %@",timeInWordssAgo,[formatter stringFromDate:lastSeenDate]];
                    }
                    
                    
                    
                    
                    
                    
                }
            } else {
                cell.statusLabel.text = NSLocalizedString(@"Joined", nil);
            }
        }
        
        
        
    }
    
    //        cell.contentView.backgroundColor = [UIColor purpleColor];
    return cell;
}


#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    //	if ([self.searchBar isFirstResponder])
    //		[self.searchBar resignFirstResponder];
    
    SLAlbumMember *member = [members objectAtIndex:indexPath.row];
    
    if ([[shotvibeAPI getAuthData] getUserId] == [[member getUser] getMemberId]) {
        
        [self ownerButtonPressed:nil];
    } else {
        
        GLFeedViewController * currentFeed = [[[[GLContainersViewController sharedInstance] navigationController] viewControllers] lastObject];
        
        [[[GLContainersViewController sharedInstance] membersSideMenu] toggleRightSideMenuCompletion:^{
            [currentFeed showUserProfileWithId:[[member getUser]getMemberId]];
        }];
        

        
//        [self.navigationController popViewControllerAnimated:YES];
        
    }
}


- (void)setAlbumName:(NSString *)newAlbumName {
    
    [ShotVibeAPITask runTask:self
                  withAction:^id {
                      BOOL success = [[[ShotVibeAppDelegate sharedDelegate].albumManager getShotVibeAPI] albumChangeNameWithLong:self.albumId
                                                                                                                    withNSString:newAlbumName];
                      if (success) {
                          dispatch_async(dispatch_get_main_queue(), ^{
                              [[ShotVibeAppDelegate sharedDelegate].albumManager refreshAlbumContentsWithLong:self.albumId withBoolean:YES];
                          });
                      }
                      return [NSNumber numberWithBool:success];
                  }
     
     
              onTaskComplete:^(id result) {
                  NSNumber *success = result;
                  if (![success boolValue]) {
                      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't Change Album Name"
                                                                      message:@"This album was not created by you"
                                                                     delegate:nil
                                                            cancelButtonTitle:@"Ok"
                                                            otherButtonTitles:nil];
                      [alert show];
                  }
              }];
    
}

#pragma mark UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if(buttonIndex == 0){
        
        
    } else {
        
        if(alertView.tag == 35){
            
            NSString *newAlbumName = [alertView textFieldAtIndex:0].text;
            [self setAlbumName:newAlbumName];
            
        } else if (buttonIndex == 1) {
            
            
            
            
            
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
}



#pragma mark - UISearchbarDelegate Methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    
    //	[self.searchBar setShowsCancelButton:YES animated:YES];
    CGRect f = self.tableView.frame;
    f.size.height = [UIScreen mainScreen].bounds.size.height-216-20-135;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.tableView.frame = f;
    }];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    
    //	[self.searchBar setShowsCancelButton:NO animated:YES];
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
    //	return [self.searchBar resignFirstResponder];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.superview.frame.size.height - self.view.superview.frame.origin.y);
}


@end
