//
//  GLFeedViewController.m
//  shotvibe
//
//  Created by Tsah Kashkash on 26/10/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//
#import "TmpFilePhotoUploadRequest.h"
#import "GLPublicFeedPostViewController.h"
#import "GLFeedTableCell.h"
#import "MBProgressHUD.h"
//#import "SVCameraPickerController.h"
#import "SVImagePickerListViewController.h"
#import "SVAlbumGridViewCell.h"
#import "SVAddFriendsViewController.h"
#import "SVNavigationController.h"
#import "SL/AlbumPhoto.h"
#import "UIImageView+WebCache.h"
#import "SVAlbumGridSection.h"
#import "NSDate+Formatting.h"
#import "SVNonRotatingNavigationControllerViewController.h"
#import "SL/AlbumServerPhoto.h"
#import "SL/AlbumMember.h"
#import "SL/AlbumUser.h"
#import "SL/ArrayList.h"
#import "AlbumUploadingPhoto.h"
#import "SL/DateTime.h"
#import "SL/AuthData.h"
#import "SL/ShotVibeAPI.h"
#import "SVInitialization.h"
#import "ShotVibeAPITask.h"
#import "ImageDiskCache.h"
#import "SVSidebarManagementController.h"
#import "SVSidebarMemberController.h"

#import "MFSideMenu.h"
#import "SVDefines.h"
#import "SVPhotoViewerController.h"
#import "SVSidebarMemberController.h"
#import "SVSidebarManagementController.h"
#import "SVSettingsViewController.h"

#import "ShotVibeAppDelegate.h"
#import "SL/AlbumPhotoComment.h"
#import "SL/AlbumPhoto.h"

#import "UIImageView+Masking.h"
#import "SDWebImageManager.h"

#import "UIImageView+WebCache.h"

#import "PhotoImageView.h"
#import "GLSharedCamera.h"

#import "YALSunnyRefreshControl.h"
#import "LNNotificationsUI.h"

//#import "ParallaxHeaderView.h"
#import "GLProfileViewController.h"
#import "ContainerViewController.h"
#import "GLProfilePageViewController.h"

@interface GLPublicFeedPostViewController () <SLAlbumManager_AlbumContentsListener,SLAlbumManager_AlbumContentsListener, UIAlertViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate,UIGestureRecognizerDelegate, GLSharedCameraDelegatte> {
    
    SLAlbumManager *albumManager_;
    PhotoFilesManager *photoFilesManager_;
    ImageDiskCache *imageDiskCache_;
    SLAlbumContents *albumContents;
    UIImage * uploadingImage;
    BOOL membersOpened;
    NSMutableArray * postsAsSLPhotos;
    int cellToHighLightIndex;
    BOOL needCommentHl;
    BOOL commentingNow;
    NSMutableArray * allEmojis;
    BOOL scrollToCellDisabled;
//    YALSunnyRefreshControl *sunnyRefreshControl;
}

@end

@implementation GLPublicFeedPostViewController

-(void)closePressed {

    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    UIImage * glanceLogo = [UIImage imageNamed:@"welcomeGlanceLogo"];
    UIImageView * glanceLogoView = [[UIImageView alloc] initWithImage:glanceLogo];
    glanceLogoView.frame = CGRectMake(268 ,-33 ,94 ,40);
    [self.view addSubview:glanceLogoView];
    
    UIImage * backButtonImage = [UIImage imageNamed:@"backToCameraIcon"];
    UIButton * closeButton = [[UIButton alloc] initWithFrame:CGRectMake(13, -27, 25, 25)];
    [closeButton addTarget:self action:@selector(closePressed) forControlEvents:UIControlEventTouchUpInside];
    [closeButton setImage:backButtonImage forState:UIControlStateNormal];
    [self.view addSubview:closeButton];
    self.tableView.clipsToBounds = NO;
    
    
//    backToCameraIcon
    
        
        
    
    
    scrollToCellDisabled = NO;
    
    allEmojis = [[NSMutableArray alloc] initWithObjects:@"😄", @"😃", @"😀", @"😊", @"☺️", @"😉", @"😍", @"😘", @"😚", @"😗", @"😙", @"😜", @"😝", @"😛", @"😳", @"😁", @"😔", @"😌", @"😒", @"😞", @"😣", @"😢", @"😂", @"😭", @"😪", @"😥", @"😰", @"😅", @"😓", @"😩", @"😫", @"😨", @"😱", @"😠", @"😡", @"😤", @"😖", @"😆", @"😋", @"😷", @"😎", @"😴", @"😵", @"😲", @"😟", @"😦", @"😧", @"😈", @"👿", @"😮", @"😬", @"😐", @"😕", @"😯", @"😶", @"😇", @"😏", @"😑", @"👲", @"👳", @"👮", @"👷", @"💂", @"👶", @"👦", @"👧", @"👨", @"👩", @"👴", @"👵", @"👱", @"👼", @"👸", @"😺", @"😸", @"😻", @"😽", @"😼", @"🙀", @"😿", @"😹", @"😾", @"👹", @"👺", @"🙈", @"🙉", @"🙊", @"💀", @"👽", @"💩", @"🔥", @"✨", @"🌟", @"💫", @"💥", @"💢", @"💦", @"💧", @"💤", @"💨", @"👂", @"👀", @"👃", @"👅", @"👄", @"👍", @"👎", @"👌", @"👊", @"✊", @"✌️", @"👋", @"✋", @"👐", @"👆", @"👇", @"👉", @"👈", @"🙌", @"🙏", @"☝️", @"👏", @"💪", @"🚶", @"🏃", @"💃", @"👫", @"👪", @"👬", @"👭", @"💏", @"💑", @"👯", @"🙆", @"🙅", @"💁", @"🙋", @"💆", @"💇", @"💅", @"👰", @"🙎", @"🙍", @"🙇", @"🎩", @"👑", @"👒", @"👟", @"👞", @"👡", @"👠", @"👢", @"👕", @"👔", @"👚", @"👗", @"🎽", @"👖", @"👘", @"👙", @"💼", @"👜", @"👝", @"👛", @"👓", @"🎀", @"🌂", @"💄", @"💛", @"💙", @"💜", @"💚", @"❤️", @"💔", @"💗", @"💓", @"💕", @"💖", @"💞", @"💘", @"💌", @"💋", @"💍", @"💎", @"👤", @"👥", @"💬", @"👣", @"💭", @"🐶", @"🐺", @"🐱", @"🐭", @"🐹", @"🐰", @"🐸", @"🐯", @"🐨", @"🐻", @"🐷", @"🐽", @"🐮", @"🐗", @"🐵", @"🐒", @"🐴", @"🐑", @"🐘", @"🐼", @"🐧", @"🐦", @"🐤", @"🐥", @"🐣", @"🐔", @"🐍", @"🐢", @"🐛", @"🐝", @"🐜", @"🐞", @"🐌", @"🐙", @"🐚", @"🐠", @"🐟", @"🐬", @"🐳", @"🐋", @"🐄", @"🐏", @"🐀", @"🐃", @"🐅", @"🐇", @"🐉", @"🐎", @"🐐", @"🐓", @"🐕", @"🐖", @"🐁", @"🐂", @"🐲", @"🐡", @"🐊", @"🐫", @"🐪", @"🐆", @"🐈", @"🐩", @"🐾", @"💐", @"🌸", @"🌷", @"🍀", @"🌹", @"🌻", @"🌺", @"🍁", @"🍃", @"🍂", @"🌿", @"🌾", @"🍄", @"🌵", @"🌴", @"🌲", @"🌳", @"🌰", @"🌱", @"🌼", @"🌐", @"🌞", @"🌝", @"🌚", @"🌑", @"🌒", @"🌓", @"🌔", @"🌕", @"🌖", @"🌗", @"🌘", @"🌜", @"🌛", @"🌙", @"🌍", @"🌎", @"🌏", @"🌋", @"🌌", @"🌠", @"⭐️", @"☀️", @"⛅️", @"☁️", @"⚡️", @"☔️", @"❄️", @"⛄️", @"🌀", @"🌁", @"🌈", @"🌊", @"🎍", @"💝", @"🎎", @"🎒", @"🎓", @"🎏", @"🎆", @"🎇", @"🎐", @"🎑", @"🎃", @"👻", @"🎅", @"🎄", @"🎁", @"🎋", @"🎉", @"🎊", @"🎈", @"🎌", @"🔮", @"🎥", @"📷", @"📹", @"📼", @"💿", @"📀", @"💽", @"💾", @"💻", @"📱", @"☎️", @"📞", @"📟", @"📠", @"📡", @"📺", @"📻", @"🔊", @"🔉", @"🔈", @"🔇", @"🔔", @"🔕", @"📢", @"📣", @"⏳", @"⌛️", @"⏰", @"⌚️", @"🔓", @"🔒", @"🔏", @"🔐", @"🔑", @"🔎", @"💡", @"🔦", @"🔆", @"🔅", @"🔌", @"🔋", @"🔍", @"🛁", @"🛀", @"🚿", @"🚽", @"🔧", @"🔩", @"🔨", @"🚪", @"🚬", @"💣", @"🔫", @"🔪", @"💊", @"💉", @"💰", @"💴", @"💵", @"💷", @"💶", @"💳", @"💸", @"📲", @"📧", @"📥", @"📤", @"✉️", @"📩", @"📨", @"📯", @"📫", @"📪", @"📬", @"📭", @"📮", @"📦", @"📝", @"📄", @"📃", @"📑", @"📊", @"📈", @"📉", @"📜", @"📋", @"📅", @"📆", @"📇", @"📁", @"📂", @"✂️", @"📌", @"📎", @"✒️", @"✏️", @"📏", @"📐", @"📕", @"📗", @"📘", @"📙", @"📓", @"📔", @"📒", @"📚", @"📖", @"🔖", @"📛", @"🔬", @"🔭", @"📰", @"🎨", @"🎬", @"🎤", @"🎧", @"🎼", @"🎵", @"🎶", @"🎹", @"🎻", @"🎺", @"🎷", @"🎸", @"👾", @"🎮", @"🃏", @"🎴", @"🀄️", @"🎲", @"🎯", @"🏈", @"🏀", @"⚽️", @"⚾️", @"🎾", @"🎱", @"🏉", @"🎳", @"⛳️", @"🚵", @"🚴", @"🏁", @"🏇", @"🏆", @"🎿", @"🏂", @"🏊", @"🏄", @"🎣", @"☕️", @"🍵", @"🍶", @"🍼", @"🍺", @"🍻", @"🍸", @"🍹", @"🍷", @"🍴", @"🍕", @"🍔", @"🍟", @"🍗", @"🍖", @"🍝", @"🍛", @"🍤", @"🍱", @"🍣", @"🍥", @"🍙", @"🍘", @"🍚", @"🍜", @"🍲", @"🍢", @"🍡", @"🍳", @"🍞", @"🍩", @"🍮", @"🍦", @"🍨", @"🍧", @"🎂", @"🍰", @"🍪", @"🍫", @"🍬", @"🍭", @"🍯", @"🍎", @"🍏", @"🍊", @"🍋", @"🍒", @"🍇", @"🍉", @"🍓", @"🍑", @"🍈", @"🍌", @"🍐", @"🍍", @"🍠", @"🍆", @"🍅", @"🌽", @"🏠", @"🏡", @"🏫", @"🏢", @"🏣", @"🏥", @"🏦", @"🏪", @"🏩", @"🏨", @"💒", @"⛪️", @"🏬", @"🏤", @"🌇", @"🌆", @"🏯", @"🏰", @"⛺️", @"🏭", @"🗼", @"🗾", @"🗻", @"🌄", @"🌅", @"🌃", @"🗽", @"🌉", @"🎠", @"🎡", @"⛲️", @"🎢", @"🚢", @"⛵️", @"🚤", @"🚣", @"⚓️", @"🚀", @"✈️", @"💺", @"🚁", @"🚂", @"🚊", @"🚉", @"🚞", @"🚆", @"🚄", @"🚅", @"🚈", @"🚇", @"🚝", @"🚋", @"🚃", @"🚎", @"🚌", @"🚍", @"🚙", @"🚘", @"🚗", @"🚕", @"🚖", @"🚛", @"🚚", @"🚨", @"🚓", @"🚔", @"🚒", @"🚑", @"🚐", @"🚲", @"🚡", @"🚟", @"🚠", @"🚜", @"💈", @"🚏", @"🎫", @"🚦", @"🚥", @"⚠️", @"🚧", @"🔰", @"⛽️", @"🏮", @"🎰", @"♨️", @"🗿", @"🎪", @"🎭", @"📍", @"🚩", @"🇯🇵", @"🇰🇷", @"🇩🇪", @"🇨🇳", @"🇺🇸", @"🇫🇷", @"🇪🇸", @"🇮🇹", @"🇷🇺", @"🇬🇧", @"1⃣", @"2⃣", @"3⃣", @"4⃣", @"5⃣", @"6⃣", @"7⃣", @"8⃣", @"9⃣", @"0⃣", @"1️⃣", @"2️⃣", @"3️⃣", @"4️⃣", @"5️⃣", @"6️⃣", @"7️⃣", @"8️⃣", @"9️⃣", @"0️⃣", @"🔟", @"🔢", @"#️⃣", @"🔣", @"⬆️", @"⬇️", @"⬅️", @"➡️", @"🔠", @"🔡", @"🔤", @"↗️", @"↖️", @"↘️", @"↙️", @"↔️", @"↕️", @"🔄", @"◀️", @"▶️", @"🔼", @"🔽", @"↩️", @"↪️", @"ℹ️", @"⏪", @"⏩", @"⏫", @"⏬", @"⤵️", @"⤴️", @"🆗", @"🔀", @"🔁", @"🔂", @"🆕", @"🆙", @"🆒", @"🆓", @"🆖", @"📶", @"🎦", @"🈁", @"🈯️", @"🈳", @"🈵", @"🈴", @"🈲", @"🉐", @"🈹", @"🈺", @"🈶", @"🈚️", @"🚻", @"🚹", @"🚺", @"🚼", @"🚾", @"🚰", @"🚮", @"🅿️", @"♿️", @"🚭", @"🈷", @"🈸", @"🈂", @"Ⓜ️", @"🛂", @"🛄", @"🛅", @"🛃", @"🉑", @"㊙️", @"㊗️", @"🆑", @"🆘", @"🆔", @"🚫", @"🔞", @"📵", @"🚯", @"🚱", @"🚳", @"🚷", @"🚸", @"⛔️", @"✳️", @"❇️", @"❎", @"✅", @"✴️", @"💟", @"🆚", @"📳", @"📴", @"🅰", @"🅱", @"🆎", @"🅾", @"💠", @"➿", @"♻️", @"♈️", @"♉️", @"♊️", @"♋️", @"♌️", @"♍️", @"♎️", @"♏️", @"♐️", @"♑️", @"♒️", @"♓️", @"⛎", @"🔯", @"🏧", @"💹", @"💲", @"💱", @"©", @"®", @"™", @"❌", @"‼️", @"⁉️", @"❗️", @"❓", @"❕", @"❔", @"⭕️", @"🔝", @"🔚", @"🔙", @"🔛", @"🔜", @"🔃", @"🕛", @"🕧", @"🕐", @"🕜", @"🕑", @"🕝", @"🕒", @"🕞", @"🕓", @"🕟", @"🕔", @"🕠", @"🕕", @"🕖", @"🕗", @"🕘", @"🕙", @"🕚", @"🕡", @"🕢", @"🕣", @"🕤", @"🕥", @"🕦", @"✖️", @"➕", @"➖", @"➗", @"♠️", @"♥️", @"♣️", @"♦️", @"💮", @"💯", @"✔️", @"☑️", @"🔘", @"🔗", @"➰", @"〰", @"〽️", @"🔱", @"◼️", @"◻️", @"◾️", @"◽️", @"▪️", @"▫️", @"🔺", @"🔲", @"🔳", @"⚫️", @"⚪", @"🔴", @"🔵", @"🔻", @"⬜️", @"⬛️", @"🔶", @"🔷", @"🔸", @"🔹", nil];
    
    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
    //    glcamera.delegate = nil;
    glcamera.delegate = self;
    
    commentingNow = NO;
//    goToHighlitedCell = NO;
    membersOpened = NO;
    self.tableView.delegate = self;
    needCommentHl = NO;
    postsAsSLPhotos = [[NSMutableArray alloc] init];
    self.tableView.scrollsToTop = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
//    [self.tableView setContentInset:UIEdgeInsetsMake(60,0,0,0)];
//
    
    photoFilesManager_ = [ShotVibeAppDelegate sharedDelegate].photoFilesManager;
    
    albumManager_ = [ShotVibeAppDelegate sharedDelegate].albumManager;
    
    imageDiskCache_ = [[ImageDiskCache alloc] initWithRefreshHandler:^{
        [self.tableView reloadData];
    }];
    
    
    
    
    
    UINib *feedPhotoCellNib = [UINib nibWithNibName:@"GLFeedTableCell" bundle:nil];
    [self.tableView registerNib:feedPhotoCellNib forCellReuseIdentifier:@"GLFeedCell"];
    
    [self loadFeed];
    
//    UIScreenEdgePanGestureRecognizer * swipeScreen = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(screenSwiped:)];
    
//    swipeScreen.minimumNumberOfTouches = 1;
//    swipeScreen.maximumNumberOfTouches = 1;
//    swipeScreen.edges = UIRectEdgeLeft;
//    swipeScreen.delegate = self;
//    
//    [self.view addGestureRecognizer:swipeScreen];
    
    ((SVSidebarManagementController *)self.menuContainerViewController.leftMenuViewController).parentController = self;
    ((SVSidebarMemberController *)self.menuContainerViewController.rightMenuViewController).parentController = self;
    ((SVSidebarMemberController *)self.menuContainerViewController.rightMenuViewController).albumId = self.albumId;
    
//    self.menuContainerViewController.panMode = MFSideMenuPanModeCenterViewController;
    
    
//
    
//    sunnyRefreshControl = [YALSunnyRefreshControl attachToScrollView:self.tableView
//                                                              target:self
//                                                       refreshAction:@selector(sunnyControlDidStartAnimation)];
//    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
//    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self.tableView setContentInset:UIEdgeInsetsMake(60,0,0,0)];
//    self.tableView.backgroundColor = [UIColor redColor];
//    CGRect frame = self.tableView.frame;
//    frame.origin.y += 20;
//    self.tableView.frame = frame;
    
    self.tableView.scrollEnabled = NO;
    [self setNeedsStatusBarAppearanceUpdate];
//    [self.tableView sendSubviewToBack:sunnyRefreshControl];
    
//    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 60.0f, self.tableView.bounds.size.width, 60.01f)];
    
//    [sunnyRefreshControl startRefreshing];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    ShotVibeAppDelegate *appDelegate = (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.pushNotificationsManager.notificationHandler_.delegate = self;
//    
//    // Create ParallaxHeaderView with specified size, and set it as uitableView Header, that's it
//    ParallaxHeaderView *headerView = [ParallaxHeaderView parallaxHeaderViewWithCGSize:CGSizeMake(self.tableView.frame.size.width, 300)];
//    headerView.headerTitleLabel.text = self.story[@"story"];
//    headerView.headerImage = [UIImage imageNamed:@"HeaderImage"];
//    
//    [self.mainTableView setTableHeaderView:headerView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startUploadFromOutSide:)
                                                 name:@"ImageCapturedOnMainScreen"
                                               object:nil];

}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 20)];
//    if (section == integerRepresentingYourSectionOfInterest)
//        [headerView setBackgroundColor:[UIColor redColor]];
//    else
    [headerView setBackgroundColor:[UIColor clearColor]];
    return headerView;
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {


    if(scrollToCellDisabled){
        
    } else {
    if(!commentingNow){
            NSLog(@"im done and ready to highlight comment");
    
    
            NSArray *cells = [self.tableView visibleCells];
    
            GLFeedTableCell *cell = nil;
            NSIndexPath *path = [NSIndexPath indexPathForRow:cellToHighLightIndex inSection:0];
            for (GLFeedTableCell *aCell in cells) {
                NSIndexPath *aPath = [self.tableView indexPathForCell:aCell];
        
                if ([aPath isEqual:path]) {
                    cell = aCell;
                }
            }
    
//    GLFeedTableCell * cell = (GLFeedTableCell*)[super tableView:self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:cellToHighLightIndex inSection:0]];
            [cell highLightLastCommentInPost];
            self.view.userInteractionEnabled = YES;
        }
    }
    
    
    

}

//
//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
//{
//    if (!decelerate) {
//        [self scrollingFinish];
//    }
//}
//- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
//{
//    [self scrollingFinish];
//}
//- (void)scrollingFinish {
//    //enter code here
//}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

-(void)startUploadFromOutSide:(NSNotification*)not {


    NSLog(@"im gone start upload");


}

-(void)addPhotoPushPressed:(SLNotificationMessage_PhotosAdded*)msg {

//    msg get
    if(self.albumId != [msg getAlbumId]){
        GLPublicFeedPostViewController * feedView = [[GLPublicFeedPostViewController alloc] init];
        feedView.albumId = [msg getAlbumId];
        feedView.scrollToComment = YES;
        //    feedView.photoToScrollToCommentsId = [msg getPhotoId];
        feedView.prevAlbumId = self.albumId;
        feedView.startImidiatly = NO;
        GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
        glcamera.imageForOutSideUpload = nil;
        //    [msg getAlbumId];
        //        [self.navigationController popToRootViewControllerAnimated:NO];
        [self.navigationController pushViewController:feedView animated:YES];
        //        [self dismissViewControllerAnimated:NO completion:nil];
        [self removeFromParentViewController];
    } else {
        
    }
    
    
    
}

-(void)commentPushPressed:(SLNotificationMessage_PhotoComment *)msg {

    
    if(self.albumId != [msg getAlbumId]){
    
        GLPublicFeedPostViewController * feedView = [[GLPublicFeedPostViewController alloc] init];
        feedView.albumId = [msg getAlbumId];
        feedView.scrollToComment = YES;
        feedView.photoToScrollToCommentsId = [msg getPhotoId];
        feedView.prevAlbumId = self.albumId;
        feedView.startImidiatly = NO;
        GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
        glcamera.imageForOutSideUpload = nil;
        //    [msg getAlbumId];
//        [self.navigationController popToRootViewControllerAnimated:NO];
        [self.navigationController pushViewController:feedView animated:YES];
//        [self dismissViewControllerAnimated:NO completion:nil];
        [self removeFromParentViewController];
        
    } else {
        
            NSLog(@"comment retrieved");
            int c = 0;
            int position = 0;
            for(NSArray * post in self.posts){
                if([[[post objectAtIndex:0] objectForKey:@"id"] isEqualToString:[msg getPhotoId]]){
                    position = c;
        
        
        
        
                    NSLog(@"i found the commented image in the table at %d",c);
                    cellToHighLightIndex = c;
                    needCommentHl = YES;
                    [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
        
                    self.view.userInteractionEnabled = NO;
        
        //            GLFeedTableCell * cell = (GLFeedTableCell*)[super tableView:self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:c inSection:0]];
        //            [cell highLightLastCommentInPost];
                    
                    
                    break;
                }
                c++;
            }
        
    }
    

    

    
    


}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    
    return 20;
}

- (BOOL)screenSwiped:(UIScreenEdgePanGestureRecognizer *)gest {
    
    
    [self.navigationController popViewControllerAnimated:YES];
    return  YES;
    
}

//- (void)openAppleImagePicker {
//    
//    
//    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
//    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
//    //    glcamera.delegate = self;
//    
//    //    glcamera.delegate
//    //     glcamera.imagePickerDelegate = picker.delegate;
//    picker.delegate = self;
//    
//    
//    //    fromImagePicker = YES;
//    picker.allowsEditing = NO;
//    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
//    
//    [self presentViewController:picker animated:YES completion:^{
//        
//        //        [appDelegate.window sendSubviewToBack:glcamera.view];
//        
//        [UIView animateWithDuration:0.3 animations:^{
//            glcamera.view.alpha = 0;
//            [glcamera hideForPicker:YES];
//        }];
//    }];
//    
//    
//    
//    
//    
//}

-(void)openAppleImagePicker {
    
    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    //    glcamera.delegate = self;
    
    //    glcamera.delegate
    //     glcamera.imagePickerDelegate = picker.delegate;
    picker.delegate = self;
    
    
    //    fromImagePicker = YES;
    //    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:^{
        
        //        [appDelegate.window sendSubviewToBack:glcamera.view];
        
        [UIView animateWithDuration:0.3 animations:^{
            //            glcamera.view.alpha = 0;
            //            [glcamera hideForPicker:YES];
        }];
    }];
    
}

-(void)imageSelected:(UIImage*)image {
    
    if(image != nil){
    if([self.posts count] > 0){
        scrollToCellDisabled = YES;
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    
    uploadingImage = image;
    // Take as many pictures as you want. Save the path and the thumb and the picture
    __block NSString *filePath = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/Library/Caches/Photo%i.jpg", 0]];
    __block NSString *thumbPath = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/Library/Caches/Photo%i_thumb.jpg", 0]];
    
    // Save large image
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    dispatch_async(queue, ^(void) {
        
        
        [UIImageJPEGRepresentation(image, 1.0) writeToFile:filePath atomically:YES];
        CGSize newSize = CGSizeMake(200, 200);
        float oldWidth = image.size.width;
        float scaleFactor = newSize.width / oldWidth;
        float newHeight = image.size.height * scaleFactor;
        float newWidth = oldWidth * scaleFactor;
        
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
        [image drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
        UIImage * thumbImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        // Save thumb image
        [UIImageJPEGRepresentation(thumbImage, 0.5) writeToFile:thumbPath atomically:YES];
        
        
        NSLog(@"FINISH to SAVE NO MAIN QUE with path %@",filePath);
        
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
        
        if(fileExists){
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"FINISH to write image");
                //                [self dismissViewControllerAnimated:YES completion:^{
                
                if (self.albumId != 0) {
                    
//                    RCLog(@"====================== 1. Upload selected photos to albumId %lli", self.albumId);
                    
                    // Upload the taken photos
                    
                    TmpFilePhotoUploadRequest *photoUploadRequest = [[TmpFilePhotoUploadRequest alloc] initWithTmpFile:filePath];
                    //            [photoUploadRequests addObject:photoUploadRequest];
                    
                    [albumManager_ uploadPhotosWithLong:self.albumId
                                       withJavaUtilList:[[SLArrayList alloc]
                                                         initWithInitialArray:[NSMutableArray arrayWithObject:photoUploadRequest]]];
                    
                    if(self.startImidiatly){
                        self.startImidiatly = NO;
                        [[GLSharedCamera sharedInstance] setImageForOutSideUpload:nil];
                    }
                    
                }
                
                //                }];
                
            });
            
            
        } else {
            
            NSLog(@"file wasnt saved correctly !!! isnt found on path!");
            
        }
        
        
        
        
    });
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.onClose) {
        __block GLPublicFeedPostViewController *blocksafeSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            blocksafeSelf.onClose(nil);
        });
    }
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSLog(@"SVAlbumGridViewController %@: viewWillAppear: %d", self, animated);
    //
    
    SLAlbumContents *contents = [albumManager_ addAlbumContentsListenerWithLong:self.albumId withSLAlbumManager_AlbumContentsListener:self];
    [self setAlbumContents:contents];
    //    [self loadFeed];
    [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
    GLSharedCamera * camera = [GLSharedCamera sharedInstance];
//    camera.picYourGroup.alpha = 1;
//    camera.cameraViewBackground.userInteractionEnabled = YES;
    camera.delegate = [ContainerViewController sharedInstance];
    
    
    if([[ShotVibeAppDelegate sharedDelegate] appOpenedFromPush]){
        self.photoToScrollToCommentsId = [[ShotVibeAppDelegate sharedDelegate] photoIdFromPush];
        self.scrollToComment = YES;
//
        
        
        int c = 0;
        int position = 0;
        for(NSArray * post in self.posts){
            if([[[post objectAtIndex:0] objectForKey:@"id"] isEqualToString:self.photoToScrollToCommentsId]){
                position = c;
                
                
                
                
                NSLog(@"i found the commented image in the table at %d",c);
                cellToHighLightIndex = c;
                needCommentHl = YES;
                [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
                
                self.view.userInteractionEnabled = NO;
                
                //            GLFeedTableCell * cell = (GLFeedTableCell*)[super tableView:self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:c inSection:0]];
                //            [cell highLightLastCommentInPost];
                
                [[ShotVibeAppDelegate sharedDelegate] setAppOpenedFromPush:NO];
                break;
            }
            c++;
        }
        
    }
    
    
    if(self.scrollToComment){
        
        NSLog(@"comment retrieved");
            int c = 0;
            int position = 0;
            for(NSArray * post in self.posts){
                if([[[post objectAtIndex:0] objectForKey:@"id"] isEqualToString:self.photoToScrollToCommentsId]){
                    position = c;
        
        
        
        
                    NSLog(@"i found the commented image in the table at %d",c);
                    cellToHighLightIndex = c;
                    needCommentHl = YES;
                    [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
        
                    self.view.userInteractionEnabled = NO;
        
        //            GLFeedTableCell * cell = (GLFeedTableCell*)[super tableView:self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:c inSection:0]];
        //            [cell highLightLastCommentInPost];
                    
                    
                    break;
                }
                c++;
            }
        
    }
//    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
//    glcamera.delegate = self;
    
    
    
    // This will be notified when the Dynamic Type user setting changes (from the system Settings app)
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentSizeCategoryChanged:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    
//    if ([self.posts count] == 0) {
//        //        [self.activityIndicatorView startAnimating];
//    }
    
//    [self.menuContainerViewController.view setFrame:[[UIScreen mainScreen] bounds]];
//    [self didRotateFromInterfaceOrientation:UIInterfaceOrientationPortrait];
//    self.menuContainerViewController.panMode = MFSideMenuPanModeCenterViewController;
    
    
}

- (void)clearNewPhotoBadges:(SLAlbumContents *)album
{
    SLDateTime *mostRecentPhotoDate = nil;
    
    for (SLAlbumPhoto *photo in [album getPhotos]) {
        if ([photo getServerPhoto]) {
            if (!mostRecentPhotoDate) {
                mostRecentPhotoDate = [[photo getServerPhoto] getDateAdded];
            } else {
                long long photoTimestamp = [[[photo getServerPhoto] getDateAdded] getTimeStamp];
                if ([mostRecentPhotoDate getTimeStamp] < photoTimestamp) {
                    mostRecentPhotoDate = [[photo getServerPhoto] getDateAdded];
                }
            }
        }
    }
    
    SLDateTime *lastAccess = mostRecentPhotoDate;
    [albumManager_ updateLastAccessWithLong:self.albumId withSLDateTime:lastAccess];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
//    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
//    glcamera.delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
    
    [self clearNewPhotoBadges:albumContents];
    
    [albumManager_ removeAlbumContentsListenerWithLong:self.albumId withSLAlbumManager_AlbumContentsListener:self];
    
    
}
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [[[GLSharedCamera sharedInstance] videoCamera] stopCameraCapture];
    [self dismissViewControllerAnimated:YES completion:^{
        [[GLSharedCamera sharedInstance] retrievePhotoFromPicker:info[UIImagePickerControllerOriginalImage]];
    }];
}

- (void)onAlbumContentsNewContentWithLong:(long long int)albumId
                      withSLAlbumContents:(SLAlbumContents *)album
{
    if(needCommentHl){
        [self.tableView scrollToRowAtIndexPath:
                      [NSIndexPath indexPathForRow:cellToHighLightIndex inSection:0]
                                           atScrollPosition:UITableViewScrollPositionTop
                                                   animated:YES];
        needCommentHl = NO;
    }
    [self setAlbumContents:album];
    //    [self loadFeed];
}

- (void)onAlbumContentsUploadsProgressedWithLong:(long long int)albumId
{
    [self.tableView reloadData];
}

- (void)setAlbumContents:(SLAlbumContents *)album
{
    albumContents = album;
    if(albumContents != nil){
        GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
        if(glcamera.imageForOutSideUpload){
            
            [self imageSelected:glcamera.imageForOutSideUpload];
            glcamera.imageForOutSideUpload = nil;
        }
    }
    
    //    albumContents
    //    SLArrayList * membersList = [albumContents getMembers];
    
    
    ((SVSidebarManagementController *)self.menuContainerViewController.leftMenuViewController).albumContents = albumContents;
    ((SVSidebarMemberController *)self.menuContainerViewController.rightMenuViewController).albumContents = albumContents;
    
    self.title = [albumContents getName];
    //    [albumContents];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // First set all the fullscreen photos to download at high priority
        for (SLAlbumPhoto *p in [albumContents getPhotos].array) {
            if ([p getServerPhoto]) {
                [photoFilesManager_ queuePhotoDownload:[[p getServerPhoto] getId]
                                              photoUrl:[[p getServerPhoto] getUrl]
                                             photoSize:photoFilesManager_.DeviceDisplayPhotoSize
                                          highPriority:YES];
            }
        }
        
        // Now set all the thumbnails to download at high priority, these will now be pushed to download before all of the previously queued fullscreen photos
        //        for (SLAlbumPhoto *p in [albumContents getPhotos].array) {
        //            if ([p getServerPhoto]) {
        //                [photoFilesManager_ queuePhotoDownload:[[p getServerPhoto] getId]
        //                                              photoUrl:[[p getServerPhoto] getUrl]
        //                                             photoSize:[PhotoSize Thumb75]
        //                                          highPriority:YES];
        //            }
        //        }
    }
                   
                   
                   );
    
    //    [self sortThumbsBy:sort];
    //    [self.tableView reloadData];
    //    [self updateEmptyState];
    [self loadFeed];
}

- (void)onAlbumContentsBeginUserRefreshWithLong:(long long int)albumId
{
    //    [self showRefreshSpinner];
}


- (void)onAlbumContentsEndUserRefreshWithSLAPIException:(SLAPIException *)error
{
    //    [self hideRefreshSpinner];
    
    if (error) {
        // TODO Show "Toast" message
    }
}

- (void)loadFeed
{
    
    int counter = 0;
    
    self.posts = [[NSMutableArray alloc] init];
    
    
    
    
    
    
    SLAlbumPhoto * photo = self.singleAlbumPhoto;
//    for (SLAlbumPhoto *photo in [albumContents getPhotos].array) {
    
        
//        [postsAsSLPhotos addObject:photo];
        
        NSArray * photoComments = [[photo getServerPhoto]getComments].array;
        float commentsCount = [photoComments count];
        
        NSMutableString * commentsFullString = [[NSMutableString alloc] init];
        
        for(SLAlbumPhotoComment * comment in photoComments){
            
            NSMutableString * commentItem = [NSMutableString stringWithFormat:@"{\"created_time\": \"%@\",\"text\": \"%@\",\"from\": {\"username\": \"%@\",\"profile_picture\": \"%@\",\"id\": \"%lld\",\"full_name\": \"%@\"},\"id\": \"%lld\"}",[comment getDateCreated],[comment getCommentText],[[comment getAuthor] getMemberNickname],[[comment getAuthor]getMemberAvatarUrl],[[comment getAuthor]getMemberId],[[comment getAuthor]getMemberNickname],[comment getClientMsgId]];
            
            [commentsFullString appendString:commentItem];
            if(comment != [photoComments lastObject]){
                [commentsFullString appendString:@","];
            }
            
            
            //            commentItem appendString:<#(nonnull NSString *)#>
            
        }
        
        
        //        if ([photo getServerPhoto]) {
        
        
        NSString * userData = [NSString stringWithFormat:@"\"username\":\"%@\",\"website\":\"\",\"profile_picture\":\"%@\",\"full_name\":\"%@\",\"bio\":\"\",\"id\":\"%lld\"",[[[photo getServerPhoto] getAuthor] getMemberNickname],[[[photo getServerPhoto] getAuthor] getMemberAvatarUrl],[[[photo getServerPhoto] getAuthor] getMemberNickname],[[[photo getServerPhoto] getAuthor] getMemberId]];
        
        long long seconds = [[[photo getServerPhoto] getDateAdded] getTimeStamp] / 1000000LL;
        //            NSDate *photoDateAdded = [[NSDate alloc] initWithTimeIntervalSince1970:seconds];
        
        //            [album]
        
        NSString *new = [[[photo getServerPhoto]getUrl] stringByReplacingOccurrencesOfString:@".jpg" withString:@"_thumb75.jpg"];
        
        
        //        NSString * commentsDataString = [NSString stringWithFormat:<#(nonnull NSString *), ...#>];
        NSString * commetnsString = [NSString stringWithFormat:@"\"count\": %f,\"data\": [%@]",commentsCount,commentsFullString];
        
        NSData *objectData = [[NSString stringWithFormat:@"{\"attribution\":null,\"tags\":[],\"type\":\"image\",\"location\":null,\"comments\":{%@},\"filter\":\"Normal\",\"created_time\":\"%lld\",\"link\":\"http://instagram.com/p/xtfQ81gK0E/\",\"likes\":\"%d\",\"images\":{\"low_resolution\":{\"url\":\"http://scontent-b.cdninstagram.com/hphotos-xfa1/t51.2885-15/10932341_1042561312426099_2095600846_a.jpg\",\"width\":306,\"height\":306},\"thumbnail\":{\"url\":\"http://scontent-b.cdninstagram.com/hphotos-xfa1/t51.2885-15/10932341_1042561312426099_2095600846_s.jpg\",\"width\":150,\"height\":150},\"standard_resolution\":{\"url\":\"%@\",\"width\":480,\"height\":320}},\"users_in_photo\":[  ],\"caption\":{\"created_time\":\"%lld\"},\"user_has_liked\":false,\"id\":\"%@\",\"user\":{%@}}",commetnsString,seconds,[[photo getServerPhoto] getGlobalGlanceScore],new,seconds,[[photo getServerPhoto]getId],userData] dataUsingEncoding:NSUTF8StringEncoding];
        
        //            UIImageView * t = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        //            [t.networkImageView setPhoto:[[photo getServerPhoto] getId]
        //                                   photoUrl:[[photo getServerPhoto] getUrl]
        //                                  photoSize:[PhotoSize Thumb75]
        //                                    manager:photoFilesManager_];
        
        NSMutableArray * arr = [[NSMutableArray alloc] init];
        NSMutableDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:objectData options:kNilOptions error:nil];
        
        
        [arr addObject:dictionary];
        [arr addObject:photo];
        
//        NSMutableArray * arr = [[NSMutableArray alloc] initwith];
        
//        [dictionary setValue:photo forKey:@"slPhoto"];
//        [dictionary]
        
//        STXPost *post = [[STXPost alloc] initWithDictionary:dictionary];
//        post.slPhoto = photo;
        [self.posts addObject:arr];
        
        //            if(counter == 20){
        //                break;
        //            }
        
        //        }
        
        
        //        }
    
    //
    //    NSArray * photosArray = [NSArray arrayWithArray:[albumContents getPhotos].array];
    //    int limit = 20;
    //
    //    if([photosArray count] < 20){
    //        limit = [photosArray count];
    //    }
    
    //    NSArray *smallArray = [posts subarrayWithRange:NSMakeRange(0, limit)];
    NSArray* reversedArray = [[self.posts reverseObjectEnumerator] allObjects];
    
    self.posts = [reversedArray copy];

    [self.tableView reloadData];
    
    
//            [sunnyRefreshControl endRefreshing];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Incomplete implementation, return the number of sections
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete implementation, return the number of rows
    return [self.posts count];
}




- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GLFeedTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GLFeedCell" forIndexPath:indexPath];
    cell.tag = indexPath.row;
    NSArray * tempDict = [self.posts objectAtIndex:indexPath.row];
    
    SLAlbumPhoto *photo = [tempDict objectAtIndex:1];
    
    long long userID = [[[[tempDict objectAtIndex:0] objectForKey:@"user"] objectForKey:@"id"] longLongValue];
    
    if ([photo getUploadingPhoto]) {
        
        
        
        NSLog(@"aaa");
        [cell.profileImageView setImage:[UIImage imageNamed:@"CaptureButton"]];
        
        cell.userName.text = [NSString stringWithFormat:@"Uploading - %.f%% ",[[photo getUploadingPhoto] getUploadProgress] * 100];//@"Uploading";
        
        if([[photo getUploadingPhoto] getUploadProgress] * 100 == 100){
            scrollToCellDisabled = NO;
            NSString *path = [NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] resourcePath], @"/dropsound.wav"];
            //
            SystemSoundID soundID;
            //
            NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
            //
            //        //Use audio sevices to create the sound
            //
            AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &soundID);
            
            //Use audio services to play the sound
            
            AudioServicesPlaySystemSound(soundID);
        }
        
        cell.postedTime.text = @"now";

        [cell.postImage setImage:uploadingImage];
//        [UIView animateWithDuration:0.5 animations:^{
//            cell.postImage.alpha = [[photo getUploadingPhoto] getUploadProgress];
//        }];
        
        
        
        cell.glancesCounter.text = [[tempDict objectAtIndex:0] objectForKey:@"likes"];
        
        
        cell.photoId = [[tempDict objectAtIndex:0] objectForKey:@"id"];
        
        
        cell.addCommentButton.tag = indexPath.row;//[[tempDict objectForKey:@"id"] longLongValue];
        cell.abortCommentButton.tag = indexPath.row;
        cell.glanceDownButton.tag = indexPath.row;
        cell.glanceUpButton.tag = indexPath.row;
        
        cell.feed3DotsButton.tag = indexPath.row;
        
        long long userID = [[[[tempDict objectAtIndex:0] objectForKey:@"user"] objectForKey:@"id"] longLongValue];
        
        cell.profileImageView.tag = userID;
        cell.userName.tag = userID;

        
//        cell.glancesIcon.tag = indexPath.row;
        
        [cell.postForwardButton addTarget:self action:@selector(sharePostPressed:) forControlEvents:UIControlEventTouchUpInside];
        cell.postForwardButton.tag = indexPath.row;
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doSingleTap:)];
        singleTap.numberOfTapsRequired = 1;
        //    singleTap
        [cell.glanceUpButton addGestureRecognizer:singleTap];
        
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doDoubleTap:)] ;
        doubleTap.numberOfTapsRequired = 1;
        [cell.glanceDownButton addGestureRecognizer:doubleTap];
        
        
        
        UITapGestureRecognizer *showActionSheetGest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showActionSheets:)];
//        showActionSheetGest.view.tag = indexPath.row;
//        showActionSheetGest
        showActionSheetGest.numberOfTapsRequired = 1;
        
        
        UITapGestureRecognizer *showUserProfileTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showUserProfile:)];
        UITapGestureRecognizer *showUserProfileTap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showUserProfile2:)];
        
        cell.profileImageView.tag =
        
        cell.profileImageView.userInteractionEnabled = YES;
        cell.userName.userInteractionEnabled = YES;
        [cell.profileImageView addGestureRecognizer:showUserProfileTap];
        [cell.userName addGestureRecognizer:showUserProfileTap2];
        //    singleTap
        [cell.feed3DotsButton addGestureRecognizer:showActionSheetGest];
        
//        [singleTap requireGestureRecognizerToFail:doubleTap];
        
        //    [cell.glancesIcon addGestureRecognizer:<#(nonnull UIGestureRecognizer *)#>];
        
        
        cell.commentTextField.delegate = self;
        //    cell.commentTextField
        cell.commentTextField.tag = indexPath.row;
        
//        [cell.addCommentButton addTarget:self action:@selector(addCommentTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        
        cell.commentsScrollView.alpha = 0;
        
        
        
        cell.profileImageView.tag = userID;

    } else {

    [cell.profileImageView setCircleImageWithURL:[NSURL URLWithString:[[[tempDict objectAtIndex:0] objectForKey:@"user"] objectForKey:@"profile_picture"]] placeholderImage:[UIImage imageNamed:@"ProfilePlaceholder"] borderWidth:2];

    cell.userName.text = [[[tempDict objectAtIndex:0] objectForKey:@"user"] objectForKey:@"username"];
    cell.postedTime.text = [NSString stringWithFormat:@"%@ ago",[[[NSDate alloc] initWithTimeIntervalSince1970:[[[tempDict objectAtIndex:0] objectForKey:@"created_time"] longLongValue]] distanceOfTimeInWords:[NSDate date] shortStyle:YES]];
        
       

//        if(!cell.loaded){
//        if(indexPath.row > 0 && uploadingImage == nil){
        
        
//        UIImage * tempImage;
//        if(indexPath.row ==0){
//            if(!uploadingImage){
//                tempImage = [UIImage imageNamed:@"postIsUploadingPh"];
//            } else {
//                tempImage = [uploadingImage copy];
////                uploadingImage = nil;
//            }
//            
//            
//        } else{
//            tempImage = [UIImage imageNamed:@"postIsUploadingPh"];
//        }
        
//        
//            [cell.postImage sd_setImageWithURL:[NSURL URLWithString:[[[[tempDict objectAtIndex:0] objectForKey:@"images"] objectForKey:@"standard_resolution"] objectForKey:@"url"]]
//                              placeholderImage:uploadingImage options:SDWebImageHighPriority completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
//                                  [UIView animateWithDuration:0.2 animations:^{
//                                      cell.postImage.alpha = 1;
//                                  }];
//                              }];
        
        
//        }
        
        SLAlbumPhoto * photo = [tempDict objectAtIndex:1];
//        cell.postImage
//        if(cell.postImage.image != uploadingImage){
        
        
//        [cell.postImage setPhoto:[[photo getServerPhoto] getId] photoUrl:[[photo getServerPhoto] getUrl] photoSize:[PhotoSize FeedSize] manager:photoFilesManager_];
        
//        cell.postImage
        
//        __block UIActivityIndicatorView *activityIndicator;
//        __weak UIImageView *weakImageView = cell.postImage;
//        [cell.postImage sd_setImageWithURL:[NSURL URLWithString:[[photo getServerPhoto] getUrl]]
//                          placeholderImage:nil
//                                   options:SDWebImageProgressiveDownload
//                                  progress:^(NSInteger receivedSize, NSInteger expectedSize) {
//                                      if (!activityIndicator) {
//                                          [weakImageView addSubview:activityIndicator = [UIActivityIndicatorView.alloc initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]];
//                                          activityIndicator.center = weakImageView.center;
//                                          [activityIndicator startAnimating];
//                                      }
//                                  }
//                                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
//                                     [activityIndicator removeFromSuperview];
//                                     activityIndicator = nil;
//                                 }];
        
//        }
            //
        
        
        
//        int score = [[photo getServerPhoto] getMyGlanceScoreDelta];
//        if(score < 0){
//            cell.glancesIcon.image = [UIImage imageNamed:@"glancesIconUnGlanced"];
//        } else if(score == 0){
//            cell.glancesIcon.image = [UIImage imageNamed:@"glancesIconRegular"];
//        } else {
//            cell.glancesIcon.image = [UIImage imageNamed:@"glancesIconGlanced"];
//        }
//        [cell.postImage setPhoto:<#(NSString *)#> photoUrl: objectForKey:@"url"]] photoSize:[PhotoSize FeedSize] manager:albumManager_]
    
//        }
    
        
    cell.glancesCounter.text = [[tempDict objectAtIndex:0] objectForKey:@"likes"];
    
    
    
    
    
        NSMutableArray * commentsArray = [[NSMutableArray alloc] init];
        commentsArray = [[[tempDict objectAtIndex:0] objectForKey:@"comments"] objectForKey:@"data"];
    
    
    cell.photoId = [[tempDict objectAtIndex:0] objectForKey:@"id"];
    
    
    cell.addCommentButton.tag = indexPath.row;//[[tempDict objectForKey:@"id"] longLongValue];
    cell.abortCommentButton.tag = indexPath.row;
        cell.glanceDownButton.tag = indexPath.row;
        cell.glanceUpButton.tag = indexPath.row;
        
        cell.feed3DotsButton.tag = indexPath.row;
        
    [cell.postForwardButton addTarget:self action:@selector(sharePostPressed:) forControlEvents:UIControlEventTouchUpInside];
    cell.postForwardButton.tag = indexPath.row;
        
        
        
        cell.profileImageView.tag = userID;
        cell.userName.tag = userID;
        
    
//    cell.glancesIcon.tag = indexPath.row;
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doSingleTap:)];
    singleTap.numberOfTapsRequired = 1;
//    singleTap
    [cell.glanceUpButton addGestureRecognizer:singleTap];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doDoubleTap:)] ;
    doubleTap.numberOfTapsRequired = 1;
    [cell.glanceDownButton addGestureRecognizer:doubleTap];
        
        UITapGestureRecognizer *showActionSheetGest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showActionSheets:)];
        showActionSheetGest.numberOfTapsRequired = 1;
//        showActionSheetGest.view.tag = indexPath.row;
        //    singleTap
        [cell.feed3DotsButton addGestureRecognizer:showActionSheetGest];
        
        UITapGestureRecognizer *showUserProfileTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showUserProfile:)];
        UITapGestureRecognizer *showUserProfileTap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showUserProfile2:)];
        
        cell.profileImageView.userInteractionEnabled = YES;
        cell.userName.userInteractionEnabled = YES;
        [cell.profileImageView addGestureRecognizer:showUserProfileTap];
        [cell.userName addGestureRecognizer:showUserProfileTap2];
        //    singleTap
        [cell.feed3DotsButton addGestureRecognizer:showActionSheetGest];
    
//    [singleTap requireGestureRecognizerToFail:doubleTap];
        
        
    
//    [cell.glancesIcon addGestureRecognizer:<#(nonnull UIGestureRecognizer *)#>];
    
    
    cell.commentTextField.delegate = self;
    //    cell.commentTextField
    cell.commentTextField.tag = indexPath.row;
    
    [cell.addCommentButton addTarget:self action:@selector(addCommentTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [cell.postPannelWrapper bringSubviewToFront:cell.abortCommentButton];

    
    [cell.commentsScrollView removeFromSuperview];
    
    cell.commentsScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 65, [[UIScreen mainScreen] bounds].size.width, 69)];
        cell.commentsScrollView.alpha = 1;
    cell.commentsScrollView.pagingEnabled = YES;
    cell.commentsScrollView.backgroundColor = [UIColor clearColor];
    cell.commentsScrollView.contentSize = CGSizeMake(self.view.frame.size.width, [commentsArray count]*23);
    
    
        
    
    
    
        
        int c = 0;
        
        for(NSDictionary * comment in commentsArray){
//            NSLog(@"%@",[comment objectForKey:@"text"]);
            
            
            
            UILabel * commentAuthor = [[UILabel alloc] initWithFrame:CGRectMake(20, c*23, self.view.frame.size.width/3, 20)];
            commentAuthor.numberOfLines = 1;
            commentAuthor.textColor = [UIColor whiteColor];
            
            
            NSArray *tagschemes = [NSArray arrayWithObjects:NSLinguisticTagSchemeLanguage, nil];
            NSLinguisticTagger *tagger = [[NSLinguisticTagger alloc] initWithTagSchemes:tagschemes options:0];
            [tagger setString:[[comment objectForKey:@"from"] objectForKey:@"full_name"]];
            NSString *language = [tagger tagAtIndex:0 scheme:NSLinguisticTagSchemeLanguage tokenRange:NULL sentenceRange:NULL];
            if ([language rangeOfString:@"he"].location != NSNotFound || [language rangeOfString:@"ar"].location != NSNotFound) {
                commentAuthor.text = [@": " stringByAppendingString:[[comment objectForKey:@"from"] objectForKey:@"full_name"]];
            } else {
                commentAuthor.text = [[[comment objectForKey:@"from"] objectForKey:@"full_name"] stringByAppendingString:@":"];
            }
            
            
            commentAuthor.font = [UIFont fontWithName:@"GothamRounded-Book" size:14];
            
            float widthIs =
            [commentAuthor.text
             boundingRectWithSize:commentAuthor.frame.size
             options:NSStringDrawingUsesLineFragmentOrigin
             attributes:@{ NSFontAttributeName:commentAuthor.font }
             context:nil]
            .size.width;
            commentAuthor.frame = CGRectMake(20, c*23, widthIs, 20);
            
            UILabel * t = [[UILabel alloc] initWithFrame:CGRectMake(commentAuthor.frame.size.width+25, c*23, self.view.frame.size.width*0.6, 20)];
            t.textColor = [UIColor whiteColor];
            t.font = [UIFont fontWithName:@"GothamRounded-Book" size:14];
            t.numberOfLines = 1;
            t.lineBreakMode = NSLineBreakByWordWrapping;
            t.text = [comment objectForKey:@"text"];
            [cell.commentsScrollView addSubview:commentAuthor];
            [cell.commentsScrollView addSubview:t];
            c++;
        }
    
    [cell.postPannelWrapper addSubview:cell.commentsScrollView];
    
        if([commentsArray count] > 3){
        
            CGPoint bottomOffset = CGPointMake(0, cell.commentsScrollView.contentSize.height - cell.commentsScrollView.bounds.size.height);
            [cell.commentsScrollView setContentOffset:bottomOffset animated:NO];
        
        } else {
        
            cell.commentsScrollView.scrollEnabled = NO;
        
        }
    
    
        
        cell.loaded = YES;
    
    
    
    if (indexPath.row == 4) {
        NSLog(@"need to reload more now");
    }
    }
    
    return cell;
}

-(void)showUserProfileWithId:(long long)userId {

//    GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:cellRow inSection:0]];
    
//    [ShotVibeAPITask runTask:self withAction:^id{
    
        //                [MBProgressHUD showHUDAddedTo:self.view animated:YES];

        
        
        //                });
        //                [[albumManager_ getShotVibeAPI] get];
//        return nil;
//    } onTaskComplete:^(id dummy) {
    
    if([[[albumManager_ getShotVibeAPI] getUserProfileWithLong:[[[albumManager_ getShotVibeAPI] getAuthData] getUserId]] getMemberId] != userId){
        
        
        [MBProgressHUD showHUDAddedTo:[[ShotVibeAppDelegate sharedDelegate] window] animated:YES];
        
        [[[GLSharedCamera sharedInstance] membersButton] setAlpha:0];
        [[[GLSharedCamera sharedInstance] dmut] setUserInteractionEnabled:NO];
        
        GLProfilePageViewController * profilePage = [[GLProfilePageViewController alloc] init];
        profilePage.albumId = self.albumId;
        profilePage.userId = userId;
        
        
        for(SLAlbumMember * member in [albumContents getMembers].array){
            
            if([[member getUser] getMemberId] == [[[albumManager_ getShotVibeAPI] getAuthData] getUserId]){
                
                if([member getAlbumAdmin]){
                    
                    profilePage.imAdmin = YES;
                    
                }
                
            }
            
        }
        
        
        [self.navigationController pushViewController:profilePage animated:YES];
        
    } else {
        
    }
    
    
    
}

-(void)showUserProfile2:(UITapGestureRecognizer*)gest {
    
    [self showUserProfileWithId:gest.view.tag];
    
    
}

-(void)showUserProfile:(UITapGestureRecognizer*)gest {
    
    [self showUserProfileWithId:gest.view.tag];
    
    
}

-(void)showActionSheets:(UITapGestureRecognizer*)gest {


//    GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:gest.view.tag inSection:0]];
//    NSString *actionSheetTitle = @"Action Sheet Demo"; //Action Sheet Title
    NSString *destructiveTitle = @"Delete Photo"; //Action Sheet Button Titles
    NSString *other1 = @"Share";
//    NSString *other2 = @"Other Button 2";
//    NSString *other3 = @"Other Button 3";
    NSString *cancelTitle = @"Close";
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:nil
                                  delegate:self
                                  cancelButtonTitle:cancelTitle
                                  destructiveButtonTitle:destructiveTitle
                                  otherButtonTitles:other1, nil];
    actionSheet.tag = gest.view.tag;
    [actionSheet showInView:self.view];

}

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {

    
    
    switch (buttonIndex) {
        case 0://Delete Photo
        {
            SLAlbumPhoto *photo = [[self.posts objectAtIndex:popup.tag] objectAtIndex:1];
            long long int uid = [[[albumManager_ getShotVibeAPI] getAuthData] getUserId];
            long long int authorIdFromPhoto = [[[photo getServerPhoto] getAuthor] getMemberId];
            
            if(uid == authorIdFromPhoto){
                
                
                
                [ShotVibeAPITask runTask:self withAction:^id{
//                    [MBProgressHUD showHUDAddedTo:[[ShotVibeAppDelegate sharedDelegate] window] animated:YES];
                    //                [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    NSMutableArray *photosToDelete = [[NSMutableArray alloc] init];
                    [photosToDelete addObject:[[photo getServerPhoto] getId]];
                    
                    [self dismissViewControllerAnimated:YES completion:nil];
                    
                    
                    [[albumManager_ getShotVibeAPI] deletePhotosWithJavaLangIterable:[[SLArrayList alloc] initWithInitialArray:photosToDelete]];
                    
                    
                    //                });
                    //                [[albumManager_ getShotVibeAPI] get];
                    return nil;
                } onTaskComplete:^(id dummy) {
                    
                    
                    
                    //                dispatch_async(dispatch_get_main_queue(), ^{
//                    [MBProgressHUD hideHUDForView:[[ShotVibeAppDelegate sharedDelegate] window] animated:YES];
                    //                });
//                    [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
//                    [self updateData];
                    
//                    [self removeFromParentViewController];
                    
                }];

                
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete failed"
                                                                message:@"You can't delete a photo that dosn't belong to you.."
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
                [alert show];
                
            }
            
            
        }
            
            break;
        case 1://Share
        {
        
            GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:popup.tag inSection:0]];
            
            UIImage *image = cell.postImage.image;
            
//            UIActivity * activiti
            
            NSArray *activityItems = @[image,@"Check this awesome photo from Glance App"];
            
            UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                                                                                 applicationActivities:nil];
            [self.navigationController presentViewController:activityViewController animated:YES completion:nil];
        
        }
            break;
            
        default:
            break;
    }
    

}

-(void)doSingleTap:(UITapGestureRecognizer*)gest {

//    GLProfileViewController * st = [[GLProfileViewController alloc] init];
//    [self.navigationController pushViewController:st animated:YES];
    
    GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:gest.view.tag inSection:0]];
    
    
    [ShotVibeAPITask runTask:self withAction:^id{
        [[albumManager_ getShotVibeAPI] setPhotoMyGlanceScoreDeltaWithNSString:cell.photoId withInt:1];
//        [[albumManager_ getShotVibeAPI]postPhotoCommentWithNSString:cell.photoId withNSString:textField.text withLong:milliseconds];
        return nil;
    } onTaskComplete:^(id dummy) {
//        [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
        
        [self updateData];
        
//        [];
//        [UIView animateWithDuration:0.2 animations:^{
//            //                commentsDialog.alpha = 0;
//            
//        
//            
//            
//        } completion:^(BOOL finished) {
//            
//            
//    
//        }];
    }];

    
    [UIView animateWithDuration:0.2 animations:^{
        cell.glanceUpButton.transform = CGAffineTransformScale(cell.glanceUpButton.transform, 2.0, 2.0);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            cell.glanceUpButton.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
//            cell.glancesIcon.image = [UIImage imageNamed:@"glancesIconGlanced"];
//            CATransition *transition = [CATransition animation];
//            transition.duration = 0.3f;
//            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
//            transition.type = kCATransitionFromRight;
//            [cell.glancesIcon.layer addAnimation:transition forKey:nil];
        }];
    }];
    
    
}

- (BOOL)shouldAutorotate
{
    return NO;
}

-(void)doDoubleTap:(UITapGestureRecognizer*)gest {
    
    
    

    GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:gest.view.tag inSection:0]];
    
    [ShotVibeAPITask runTask:self withAction:^id{
        [[albumManager_ getShotVibeAPI] setPhotoMyGlanceScoreDeltaWithNSString:cell.photoId withInt:-1];
        //        [[albumManager_ getShotVibeAPI]postPhotoCommentWithNSString:cell.photoId withNSString:textField.text withLong:milliseconds];
        return nil;
    } onTaskComplete:^(id dummy) {
        [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
        [UIView animateWithDuration:0.2 animations:^{
            //                commentsDialog.alpha = 0;
            
            
            
            
        } completion:^(BOOL finished) {
            
            
            
        }];
        
        [self updateData];
    }];
    
    [UIView animateWithDuration:0.2 animations:^{
        cell.glanceDownButton.transform = CGAffineTransformScale(cell.glancesIcon.transform, 2.5, 2.5);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            cell.glanceDownButton.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
//            cell.glancesIcon.image = [UIImage imageNamed:@"glancesIconUnGlanced"];
//            CATransition *transition = [CATransition animation];
//            transition.duration = 0.3f;
//            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
//            transition.type = kCATransitionFromLeft;
//            [cell.glancesIcon.layer addAnimation:transition forKey:nil];
        }];
    }];
    
    

}

-(void)updateData {

    [ShotVibeAPITask runTask:self withAction:^id{
        //        [[al getShotVibeAPI] getPublic];
        return [[albumManager_ getShotVibeAPI] getPublicAlbumContents];
    } onTaskComplete:^(SLAlbumContents *album) {
        //        NSLog(@"Public feed name: %@", [album getName]);
        
//        self.publicFeed = [[GLPublicFeedViewController alloc] init];
//        self.publicFeed.photosArray = [[NSMutableArray alloc] init];
        
//        self.posts = [[NSArray alloc] initWithObjects:<#(nonnull id), ...#>, nil];
        
        for(SLAlbumPhoto * photo in [album getPhotos]){
            
//            NSLog(@"found the photo");
            
            if([[[self.singleAlbumPhoto getServerPhoto] getId] isEqualToString:[[photo getServerPhoto]getId]]){
            
                NSLog(@"found the photo");
                self.posts = [[NSMutableArray alloc] init];
                
                
                NSArray * photoComments = [[photo getServerPhoto]getComments].array;
                float commentsCount = [photoComments count];
                
                NSMutableString * commentsFullString = [[NSMutableString alloc] init];
                
                for(SLAlbumPhotoComment * comment in photoComments){
                    
                    NSMutableString * commentItem = [NSMutableString stringWithFormat:@"{\"created_time\": \"%@\",\"text\": \"%@\",\"from\": {\"username\": \"%@\",\"profile_picture\": \"%@\",\"id\": \"%lld\",\"full_name\": \"%@\"},\"id\": \"%lld\"}",[comment getDateCreated],[comment getCommentText],[[comment getAuthor] getMemberNickname],[[comment getAuthor]getMemberAvatarUrl],[[comment getAuthor]getMemberId],[[comment getAuthor]getMemberNickname],[comment getClientMsgId]];
                    
                    [commentsFullString appendString:commentItem];
                    if(comment != [photoComments lastObject]){
                        [commentsFullString appendString:@","];
                    }
                    
                    
                    //            commentItem appendString:<#(nonnull NSString *)#>
                    
                }
                
                
                //        if ([photo getServerPhoto]) {
                
                
                NSString * userData = [NSString stringWithFormat:@"\"username\":\"%@\",\"website\":\"\",\"profile_picture\":\"%@\",\"full_name\":\"%@\",\"bio\":\"\",\"id\":\"%lld\"",[[[photo getServerPhoto] getAuthor] getMemberNickname],[[[photo getServerPhoto] getAuthor] getMemberAvatarUrl],[[[photo getServerPhoto] getAuthor] getMemberNickname],[[[photo getServerPhoto] getAuthor] getMemberId]];
                
                long long seconds = [[[photo getServerPhoto] getDateAdded] getTimeStamp] / 1000000LL;
                //            NSDate *photoDateAdded = [[NSDate alloc] initWithTimeIntervalSince1970:seconds];
                
                //            [album]
                
                NSString *new = [[[photo getServerPhoto]getUrl] stringByReplacingOccurrencesOfString:@".jpg" withString:@"_thumb75.jpg"];
                
                
                //        NSString * commentsDataString = [NSString stringWithFormat:<#(nonnull NSString *), ...#>];
                NSString * commetnsString = [NSString stringWithFormat:@"\"count\": %f,\"data\": [%@]",commentsCount,commentsFullString];
                
                NSData *objectData = [[NSString stringWithFormat:@"{\"attribution\":null,\"tags\":[],\"type\":\"image\",\"location\":null,\"comments\":{%@},\"filter\":\"Normal\",\"created_time\":\"%lld\",\"link\":\"http://instagram.com/p/xtfQ81gK0E/\",\"likes\":\"%d\",\"images\":{\"low_resolution\":{\"url\":\"http://scontent-b.cdninstagram.com/hphotos-xfa1/t51.2885-15/10932341_1042561312426099_2095600846_a.jpg\",\"width\":306,\"height\":306},\"thumbnail\":{\"url\":\"http://scontent-b.cdninstagram.com/hphotos-xfa1/t51.2885-15/10932341_1042561312426099_2095600846_s.jpg\",\"width\":150,\"height\":150},\"standard_resolution\":{\"url\":\"%@\",\"width\":480,\"height\":320}},\"users_in_photo\":[  ],\"caption\":{\"created_time\":\"%lld\"},\"user_has_liked\":false,\"id\":\"%@\",\"user\":{%@}}",commetnsString,seconds,[[photo getServerPhoto] getGlobalGlanceScore],new,seconds,[[photo getServerPhoto]getId],userData] dataUsingEncoding:NSUTF8StringEncoding];
                
                //            UIImageView * t = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
                //            [t.networkImageView setPhoto:[[photo getServerPhoto] getId]
                //                                   photoUrl:[[photo getServerPhoto] getUrl]
                //                                  photoSize:[PhotoSize Thumb75]
                //                                    manager:photoFilesManager_];
                
                NSMutableArray * arr = [[NSMutableArray alloc] init];
                NSMutableDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:objectData options:kNilOptions error:nil];
                
                
                [arr addObject:dictionary];
                [arr addObject:photo];
                
                //        NSMutableArray * arr = [[NSMutableArray alloc] initwith];
                
                //        [dictionary setValue:photo forKey:@"slPhoto"];
                //        [dictionary]
                
                //        STXPost *post = [[STXPost alloc] initWithDictionary:dictionary];
                //        post.slPhoto = photo;
                [self.posts addObject:arr];
                
                //            if(counter == 20){
                //                break;
                //            }
                
                //        }
                
                
                //        }
                
                //
                //    NSArray * photosArray = [NSArray arrayWithArray:[albumContents getPhotos].array];
                //    int limit = 20;
                //
                //    if([photosArray count] < 20){
                //        limit = [photosArray count];
                //    }
                
                //    NSArray *smallArray = [posts subarrayWithRange:NSMakeRange(0, limit)];
                NSArray* reversedArray = [[self.posts reverseObjectEnumerator] allObjects];
                
                self.posts = [reversedArray copy];
                
                [self.tableView reloadData];
//                self.singleAlbumPhoto = photo;
//                [self loadFeed];
                break;
                
                
            }
            
//            if([[[[self.posts objectAtIndex:0] objectAtIndex:0] objectForKey:@"id"] isEqualToString:[[photo getServerPhoto]getId]]){
            
//                NSLog(@"found the photo")
            
//            }
            
//            [[self.posts objectAtIndex:0] getph]
            
//            [self.publicFeed.photosArray addObject:photo];
        }
        
//        NSArray* reversedArray = [[self.publicFeed.photosArray reverseObjectEnumerator] allObjects];
        
//        self.publicFeed.photosArray = [reversedArray copy];
        
        //        self.publicFeed.albumId = [[al getShotVibeAPI] getPublicAlbumId];
        // TODO ...
    }];

}

-(void)sharePostPressed:(UIButton*)sender {
    

    
//    [self backPressed];
    GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:sender.tag inSection:0]];

//    [self.navigationController popViewControllerAnimated:YES];
    
//    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:cell.photoId forKey:@"photoToMoveId"];
//    [[NSNotificationCenter defaultCenter] postNotificationName: @"ImageJustMoved" object:nil userInfo:userInfo];

//
    
    [[ContainerViewController sharedInstance] setFriendsForMove:cell.photoId];
    [[ContainerViewController sharedInstance] transitToFriendsList:NO direction:UIPageViewControllerNavigationDirectionForward completion:^{
        
    }];
    
//    SVAddFriendsViewController * addFriendsVc =  [[SVAddFriendsViewController alloc] init];
//    addFriendsVc.fromCameraMainScreen = NO;
//    [self presentViewController:addFriendsVc animated:YES completion:^{
//        
//    }];
    
    
//    addFriendsVc.show
    
//    [ShotVibeAPITask runTask:self withAction:^id{
//        
//        NSMutableArray * arr = [[NSMutableArray alloc] initWithCapacity:1];
//        [arr addObject:cell.photoId];
//        
//        
//        
//        [[albumManager_ getShotVibeAPI] albumCopyPhotosWithLong:(long long int)5130 withJavaLangIterable:(id<JavaLangIterable>)arr];
//        
////        [[albumManager_ getShotVibeAPI]postPhotoCommentWithNSString:cell.photoId withNSString:textField.text withLong:milliseconds];
//        return nil;
//    } onTaskComplete:^(id dummy) {
//        
//        [UIView animateWithDuration:0.2 animations:^{
//            //                commentsDialog.alpha = 0;
//            
//            cell.glancesIcon.alpha = 1;
//            cell.commentTextField.text = @"";
//            cell.commentTextField.frame = CGRectMake(cell.addCommentButton.frame.origin.x+cell.addCommentButton.frame.size.width+10,cell.glancesCounter.frame.origin.y+2, 0,35);
//            
//            cell.glancesCounter.frame = CGRectMake(cell.addCommentButton.frame.origin.x+cell.addCommentButton.frame.size.width, 26, 45, 35);
//            
//            
//        } completion:^(BOOL finished) {
//            
//            [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
//            [self.tableView setUserInteractionEnabled:YES];
//            //                textField.text = @"";
//        }];
//    }];
    
    
    
//    GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:sender.tag inSection:0]];
//    
//    NSMutableArray *activityItems = [NSMutableArray array];
//    //    if (image)
//            [activityItems addObject:cell.postImage.image];
//    //    if (text)
////    [activityItems addObject:@"test"];
//    //    if (url)
//    //        [activityItems addObject:url];
//    
//    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
//    [self presentViewController:activityViewController animated:YES completion:nil];
//    //    [self.de]
//    
}

- (void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated {
    
}

-(void)backPressed {
    
//    self.de
//    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"NO" forKey:@"lockScroll"];
//    [[NSNotificationCenter defaultCenter] postNotificationName: @"LockScrollingInContainerPages" object:nil userInfo:userInfo];

    [[ContainerViewController sharedInstance] lockScrolling:NO];
    
    if(membersOpened){
        
        
         membersOpened = !membersOpened;
        
        [self.menuContainerViewController toggleRightSideMenuCompletion:^{
           
        }];
    
    }

    [[GLSharedCamera sharedInstance] setCameraInMain];
//    [UIView animateWithDuration:0.2 animations:^{
//        [[[GLSharedCamera sharedInstance]backButton]setAlpha:0];
//        [[[GLSharedCamera sharedInstance]membersButton]setAlpha:0];
//    }];
    [self.navigationController popToRootViewControllerAnimated:YES];
    
    
}

-(void)membersPressed {

    membersOpened = !membersOpened;
    
    [self.menuContainerViewController toggleRightSideMenuCompletion:^{
        
    }];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    
    if([textField.text isEqualToString:@""]){
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Comment cannot be empty!"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        
        
    } else {
        long long milliseconds = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
        GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:textField.tag inSection:0]];
        [cell.commentTextField resignFirstResponder];
//        [self.tableView reloadData];
        [ShotVibeAPITask runTask:self withAction:^id{
            [[albumManager_ getShotVibeAPI]postPhotoCommentWithNSString:cell.photoId withNSString:textField.text withLong:milliseconds];
            return nil;
        } onTaskComplete:^(id dummy) {
            
            
            [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
            [self.tableView setUserInteractionEnabled:YES];
            
            
            [UIView animateWithDuration:0.2 animations:^{
//                commentsDialog.alpha = 0;
                cell.abortCommentButton.alpha = 0;
                cell.addCommentButton.alpha = 1;
//                cell.glancesIcon.alpha = 1;
                cell.commentTextField.text = @"";
                cell.commentTextField.frame = CGRectMake(cell.addCommentButton.frame.origin.x+cell.addCommentButton.frame.size.width+10,cell.glancesCounter.frame.origin.y+2, 0,35);
                
                cell.glancesCounter.frame = CGRectMake(cell.addCommentButton.frame.origin.x+cell.addCommentButton.frame.size.width+32, 26, 45, 35);
                
                
            } completion:^(BOOL finished) {
                commentingNow = NO;
                [self updateData];
//                textField.text = @"";
            }];
        }];
        
    }
    
    
//    [self setEditing:NO];
    
    return YES;
}

-(void)abortCommentPressed:(UIButton*)sender {
    
    
    GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:sender.tag inSection:0]];
//    [cell.abortCommentButton addTarget:self action:@selector(abortCommentPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [cell.commentTextField resignFirstResponder];
    [UIView animateWithDuration:0.2 animations:^{
        //                commentsDialog.alpha = 0;
        cell.abortCommentButton.alpha = 0;
        cell.addCommentButton.alpha = 1;
//        cell.glancesIcon.alpha = 1;
        cell.commentTextField.text = @"";
        cell.commentTextField.frame = CGRectMake(cell.addCommentButton.frame.origin.x+cell.addCommentButton.frame.size.width+10,cell.glancesCounter.frame.origin.y+2, 0,35);
        
        cell.glancesCounter.frame = CGRectMake(cell.addCommentButton.frame.origin.x+cell.addCommentButton.frame.size.width+32, 26, 45, 35);
        
        
    } completion:^(BOOL finished) {
        commentingNow = NO;
        
        //                textField.text = @"";
    }];
    
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
//    NSLog(@"%lu",(unsigned long)[string length]);
    if (!(([string isEqualToString:@""]))) {//not a backspace, else `characterAtIndex` will crash.
        unichar unicodevalue = [string characterAtIndex:0];
        if (unicodevalue == 55357 || [allEmojis containsObject:string]) {
            if([textField.text length] < 11){
                return YES;
            } else {
                return NO;
            }

        } else {
            return NO;
        }
    }
}

-(void)addCommentTapped:(UIButton*)sender {

//    [NSString stringWithFormat:@"%@ commented on a photo @ %@",[msg getCommentAuthorNickname],[msg getAlbumName]]
//    LNNotification* notification = [LNNotification notificationWithMessage:@"Omer has commented @ The best friends"];
//    notification.title = @"Omer has just Cmmented";
//    notification.soundName = @"demo.aiff";
//    notification.defaultAction = [LNNotificationAction actionWithTitle:@"Default Action" handler:^(LNNotificationAction *action) {
//        //Handle default action
//        NSLog(@"test");
//        
//    }];
//    
//    [[LNNotificationCenter defaultCenter] presentNotification:notification forApplicationIdentifier:@"glance_app"];
    
    
//    [self.tableView setUserInteractionEnabled:NO];
    commentingNow = YES;
    NSLog(@"the photo id is %lld",(long long)sender.tag);
    GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:sender.tag inSection:0]];
    
    cell.commentTextField.delegate = self;
//    [cell bringSubviewToFront:cell.commentTextField];
    [cell.abortCommentButton addTarget:self action:@selector(abortCommentPressed:) forControlEvents:UIControlEventTouchUpInside];
//    [cell.abortCommentButton addTarget:self action:@selector(abortCommentPressed:) forControlEvents:UIControlEventTouchUpInside];
    
//    [cell.postPannelWrapper addSubview:abortCommentButton];
    
    [UIView animateWithDuration:0.3 animations:^{
        
        cell.addCommentButton.alpha = 0;
        cell.abortCommentButton.alpha = 1;
//        cell.glancesIcon.alpha = 0;
        
        cell.commentTextField.frame = CGRectMake(cell.commentTextField.frame.origin.x, cell.commentTextField.frame.origin.y, self.view.frame.size.width*0.60, cell.commentTextField.frame.size.height);
        
        cell.glancesCounter.frame = CGRectMake(cell.commentTextField.frame.origin.x+cell.commentTextField.frame.size.width, cell.glancesCounter.frame.origin.y, cell.glancesCounter.frame.size.width, cell.glancesCounter.frame.size.height);
    } completion:^(BOOL finished) {
        [cell.commentTextField becomeFirstResponder];
    }];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[UIScreen mainScreen] bounds].size.height*0.88;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here, for example:
    // Create the next view controller.
    DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"Nib name" bundle:nil];
    
    // Pass the selected object to the new view controller.
    
    // Push the view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
