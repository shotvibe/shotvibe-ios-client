//
//  GLFeedViewController.m
//  shotvibe
//
//  Created by Tsah Kashkash on 26/10/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//
#import "TmpFilePhotoUploadRequest.h"
#import "GLFeedViewController.h"
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

//#import "UIImageView+Masking.h"
#import "SDWebImageManager.h"

#import "UIImageView+WebCache.h"

#import "PhotoImageView.h"
#import "GLSharedCamera.h"

#import "LNNotificationsUI.h"

//#import "ParallaxHeaderView.h"
#import "GLProfileViewController.h"
//#import "ContainerViewController.h"
#import "GLProfilePageViewController.h"

#import "PMCustomKeyboard.h"
#import <MediaPlayer/MediaPlayer.h>
#import "SL/AlbumServerVideo.h"
#import "SL/MediaType.h"
#import "GLSharedVideoPlayer.h"
#import "GLFeedTableCellUploading.h"
#import "GLContainersViewController.h"



@interface GLFeedViewController () <SLAlbumManager_AlbumContentsListener,SLAlbumManager_AlbumContentsListener, UIAlertViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate,UIGestureRecognizerDelegate, GLSharedCameraDelegatte> {
    
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
    BOOL snapIsScrolling;
    BOOL scrollToCellDisabled;
    BOOL tableIsScrolling;
    BOOL viewDidInitialed;
    CGFloat pageNumber;
    BOOL feedLoadedOnce;
    BOOL cameBackFromBg;
    int lockContentsStackDepth_;
    SLAlbumContents *lockContentsSavedValue_;
}
@end

@implementation GLFeedViewController

-(void)pubNubRefreshTableView {
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(GLFeedTableCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    
    
    NSLog(@"TEST %ld",indexPath.row);
    
    if(indexPath.row == 0){
        
        if([cell class] == [GLFeedTableCell class]){
            SLAlbumPhoto * photo = [[self.posts objectAtIndex:indexPath.row] objectAtIndex:1];
            if([[photo getServerPhoto] getMediaType] == [SLMediaTypeEnum VIDEO] && [[[photo getServerPhoto] getVideo] getStatus] != [SLAlbumServerVideo_StatusEnum PROCESSING]){
                [self checkWhichVideoToEnable];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [cell.activityIndicator startAnimating];
                });
            }
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    cameBackFromBg = NO;
    
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(menuStateEventOccurred:)
//                                                 name:MFSideMenuStateNotificationEvent
//                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appActive:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appBg:)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    
//    [[GLPubNubManager sharedInstance]setTableViewToRefresh:self.tableView];
    
    feedLoadedOnce = YES;
    
    self.feedItems = [[NSMutableArray alloc] init];
    
    __block NSString *filePath = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/Library/Caches/Photo%i.jpg", 0]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    //        NSString *filePath = [documentsPath stringByAppendingPathComponent:fileName];
    NSError *error;
    BOOL success = [fileManager removeItemAtPath:filePath error:&error];
    
    viewDidInitialed = NO;
    pageNumber = 0;
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    
    
    tableIsScrolling = NO;
    
    self.feedScrollDirection = FeedScrollDirectionDown;
    snapIsScrolling = NO;
    
    
    
    scrollToCellDisabled = NO;
    
    allEmojis = [[NSMutableArray alloc] initWithObjects:@"😄", @"😃", @"😀", @"😊", @"☺️", @"😉", @"😍", @"😘", @"😚", @"😗", @"😙", @"😜", @"😝", @"😛", @"😳", @"😁", @"😔", @"😌", @"😒", @"😞", @"😣", @"😢", @"😂", @"😭", @"😪", @"😥", @"😰", @"😅", @"😓", @"😩", @"😫", @"😨", @"😱", @"😠", @"😡", @"😤", @"😖", @"😆", @"😋", @"😷", @"😎", @"😴", @"😵", @"😲", @"😟", @"😦", @"😧", @"😈", @"👿", @"😮", @"😬", @"😐", @"😕", @"😯", @"😶", @"😇", @"😏", @"😑", @"👲", @"👳", @"👮", @"👷", @"💂", @"👶", @"👦", @"👧", @"👨", @"👩", @"👴", @"👵", @"👱", @"👼", @"👸", @"😺", @"😸", @"😻", @"😽", @"😼", @"🙀", @"😿", @"😹", @"😾", @"👹", @"👺", @"🙈", @"🙉", @"🙊", @"💀", @"👽", @"💩", @"🔥", @"✨", @"🌟", @"💫", @"💥", @"💢", @"💦", @"💧", @"💤", @"💨", @"👂", @"👀", @"👃", @"👅", @"👄", @"👍", @"👎", @"👌", @"👊", @"✊", @"✌️", @"👋", @"✋", @"👐", @"👆", @"👇", @"👉", @"👈", @"🙌", @"🙏", @"☝️", @"👏", @"💪", @"🚶", @"🏃", @"💃", @"👫", @"👪", @"👬", @"👭", @"💏", @"💑", @"👯", @"🙆", @"🙅", @"💁", @"🙋", @"💆", @"💇", @"💅", @"👰", @"🙎", @"🙍", @"🙇", @"🎩", @"👑", @"👒", @"👟", @"👞", @"👡", @"👠", @"👢", @"👕", @"👔", @"👚", @"👗", @"🎽", @"👖", @"👘", @"👙", @"💼", @"👜", @"👝", @"👛", @"👓", @"🎀", @"🌂", @"💄", @"💛", @"💙", @"💜", @"💚", @"❤️", @"💔", @"💗", @"💓", @"💕", @"💖", @"💞", @"💘", @"💌", @"💋", @"💍", @"💎", @"👤", @"👥", @"💬", @"👣", @"💭", @"🐶", @"🐺", @"🐱", @"🐭", @"🐹", @"🐰", @"🐸", @"🐯", @"🐨", @"🐻", @"🐷", @"🐽", @"🐮", @"🐗", @"🐵", @"🐒", @"🐴", @"🐑", @"🐘", @"🐼", @"🐧", @"🐦", @"🐤", @"🐥", @"🐣", @"🐔", @"🐍", @"🐢", @"🐛", @"🐝", @"🐜", @"🐞", @"🐌", @"🐙", @"🐚", @"🐠", @"🐟", @"🐬", @"🐳", @"🐋", @"🐄", @"🐏", @"🐀", @"🐃", @"🐅", @"🐇", @"🐉", @"🐎", @"🐐", @"🐓", @"🐕", @"🐖", @"🐁", @"🐂", @"🐲", @"🐡", @"🐊", @"🐫", @"🐪", @"🐆", @"🐈", @"🐩", @"🐾", @"💐", @"🌸", @"🌷", @"🍀", @"🌹", @"🌻", @"🌺", @"🍁", @"🍃", @"🍂", @"🌿", @"🌾", @"🍄", @"🌵", @"🌴", @"🌲", @"🌳", @"🌰", @"🌱", @"🌼", @"🌐", @"🌞", @"🌝", @"🌚", @"🌑", @"🌒", @"🌓", @"🌔", @"🌕", @"🌖", @"🌗", @"🌘", @"🌜", @"🌛", @"🌙", @"🌍", @"🌎", @"🌏", @"🌋", @"🌌", @"🌠", @"⭐️", @"☀️", @"⛅️", @"☁️", @"⚡️", @"☔️", @"❄️", @"⛄️", @"🌀", @"🌁", @"🌈", @"🌊", @"🎍", @"💝", @"🎎", @"🎒", @"🎓", @"🎏", @"🎆", @"🎇", @"🎐", @"🎑", @"🎃", @"👻", @"🎅", @"🎄", @"🎁", @"🎋", @"🎉", @"🎊", @"🎈", @"🎌", @"🔮", @"🎥", @"📷", @"📹", @"📼", @"💿", @"📀", @"💽", @"💾", @"💻", @"📱", @"☎️", @"📞", @"📟", @"📠", @"📡", @"📺", @"📻", @"🔊", @"🔉", @"🔈", @"🔇", @"🔔", @"🔕", @"📢", @"📣", @"⏳", @"⌛️", @"⏰", @"⌚️", @"🔓", @"🔒", @"🔏", @"🔐", @"🔑", @"🔎", @"💡", @"🔦", @"🔆", @"🔅", @"🔌", @"🔋", @"🔍", @"🛁", @"🛀", @"🚿", @"🚽", @"🔧", @"🔩", @"🔨", @"🚪", @"🚬", @"💣", @"🔫", @"🔪", @"💊", @"💉", @"💰", @"💴", @"💵", @"💷", @"💶", @"💳", @"💸", @"📲", @"📧", @"📥", @"📤", @"✉️", @"📩", @"📨", @"📯", @"📫", @"📪", @"📬", @"📭", @"📮", @"📦", @"📝", @"📄", @"📃", @"📑", @"📊", @"📈", @"📉", @"📜", @"📋", @"📅", @"📆", @"📇", @"📁", @"📂", @"✂️", @"📌", @"📎", @"✒️", @"✏️", @"📏", @"📐", @"📕", @"📗", @"📘", @"📙", @"📓", @"📔", @"📒", @"📚", @"📖", @"🔖", @"📛", @"🔬", @"🔭", @"📰", @"🎨", @"🎬", @"🎤", @"🎧", @"🎼", @"🎵", @"🎶", @"🎹", @"🎻", @"🎺", @"🎷", @"🎸", @"👾", @"🎮", @"🃏", @"🎴", @"🀄️", @"🎲", @"🎯", @"🏈", @"🏀", @"⚽️", @"⚾️", @"🎾", @"🎱", @"🏉", @"🎳", @"⛳️", @"🚵", @"🚴", @"🏁", @"🏇", @"🏆", @"🎿", @"🏂", @"🏊", @"🏄", @"🎣", @"☕️", @"🍵", @"🍶", @"🍼", @"🍺", @"🍻", @"🍸", @"🍹", @"🍷", @"🍴", @"🍕", @"🍔", @"🍟", @"🍗", @"🍖", @"🍝", @"🍛", @"🍤", @"🍱", @"🍣", @"🍥", @"🍙", @"🍘", @"🍚", @"🍜", @"🍲", @"🍢", @"🍡", @"🍳", @"🍞", @"🍩", @"🍮", @"🍦", @"🍨", @"🍧", @"🎂", @"🍰", @"🍪", @"🍫", @"🍬", @"🍭", @"🍯", @"🍎", @"🍏", @"🍊", @"🍋", @"🍒", @"🍇", @"🍉", @"🍓", @"🍑", @"🍈", @"🍌", @"🍐", @"🍍", @"🍠", @"🍆", @"🍅", @"🌽", nil];
    
    
    
    
    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
    glcamera.delegate = self;
    self.automaticallyAdjustsScrollViewInsets = NO;
    commentingNow = NO;
    membersOpened = NO;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 80, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height*0.883)];
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    GLPubNubManager * pubManager = [GLPubNubManager sharedInstance];
    pubManager.tableViewToRefresh = self.tableView;
    
    
    needCommentHl = NO;
    postsAsSLPhotos = [[NSMutableArray alloc] init];
    self.tableView.scrollsToTop = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    photoFilesManager_ = [ShotVibeAppDelegate sharedDelegate].photoFilesManager;
    
    albumManager_ = [ShotVibeAppDelegate sharedDelegate].albumManager;
    
    imageDiskCache_ = [[ImageDiskCache alloc] initWithRefreshHandler:^{
        [self.tableView reloadData];
    }];
    
    
    
    
    
    UINib *feedPhotoCellNib = [UINib nibWithNibName:@"GLFeedTableCell" bundle:nil];
    [self.tableView registerNib:feedPhotoCellNib forCellReuseIdentifier:@"GLFeedCell"];
    
    [self loadFeed];
    
    
//    ((SVSidebarManagementController *)self.menuContainerViewController.leftMenuViewController).parentController = self;
    ((SVSidebarMemberController *)self.menuContainerViewController.rightMenuViewController).parentController = self;
    ((SVSidebarMemberController *)self.menuContainerViewController.rightMenuViewController).albumId = self.albumId;
    
    
    ShotVibeAppDelegate *appDelegate = (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.pushNotificationsManager.notificationHandler_.delegate = self;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startUploadFromOutSide:)
                                                 name:@"ImageCapturedOnMainScreen"
                                               object:nil];
    
    lockContentsStackDepth_ = 0;
    lockContentsSavedValue_ = nil;
    
    
    
    
    if(self.posts.count == 0){
    
        
        NSString * nos = @"No";
        float spacing = -9.0f;
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:nos];
        
        [attributedString addAttribute:NSKernAttributeName
                                 value:@(spacing)
                                 range:NSMakeRange(0, [nos length])];
        
        UILabel * no = [[UILabel alloc] initWithFrame:CGRectMake(50, self.view.frame.size.height/4, self.view.frame.size.width, self.view.frame.size.height/8)];
        no.attributedText = attributedString;
        
        no.font = [UIFont fontWithName:@"GothamRounded-Bold" size:90];
        no.textColor = UIColorFromRGB(0x45B4B5);
        
        
        NSString *  photoss = @"Photos";
        NSMutableAttributedString *attributedString2 = [[NSMutableAttributedString alloc] initWithString:photoss];
        
        [attributedString2 addAttribute:NSKernAttributeName
                                  value:@(spacing)
                                  range:NSMakeRange(0, [photoss length])];
        
        UILabel * photos = [[UILabel alloc] initWithFrame:CGRectMake(50, self.view.frame.size.height/4+self.view.frame.size.height/9, self.view.frame.size.width, self.view.frame.size.height/8)];
        photos.attributedText = attributedString2;
        photos.font = [UIFont fontWithName:@"GothamRounded-Bold" size:90];
        photos.textColor = UIColorFromRGB(0xFED84B);
        
        
        NSString *  yets = @"Yet";
        NSMutableAttributedString *attributedString3 = [[NSMutableAttributedString alloc] initWithString:yets];
        
        [attributedString3 addAttribute:NSKernAttributeName
                                  value:@(spacing)
                                  range:NSMakeRange(0, [yets length])];
        
        UILabel * yet = [[UILabel alloc] initWithFrame:CGRectMake(50, self.view.frame.size.height/4+self.view.frame.size.height/9+self.view.frame.size.height/9, self.view.frame.size.width, self.view.frame.size.height/8)];
        yet.attributedText = attributedString3;
        yet.font = [UIFont fontWithName:@"GothamRounded-Bold" size:90];
        yet.textColor = UIColorFromRGB(0xEE7482);
        
        
        
        
        UILabel * letsGetsStarted = [[UILabel alloc] initWithFrame:CGRectMake(50, self.view.frame.size.height-self.view.frame.size.height/7, 275, self.view.frame.size.height/10)];
//            letsGetsStarted.backgroundColor = [UIColor orangeColor];
        letsGetsStarted.text = @"Pull Mr. Glance down and Let's get this party started.";
        letsGetsStarted.textColor = UIColorFromRGB(0x979494);
        letsGetsStarted.font = [UIFont fontWithName:@"GothamRounded-Bold" size:18];
        letsGetsStarted.textAlignment = NSTextAlignmentCenter;
    letsGetsStarted.lineBreakMode = NSLineBreakByWordWrapping;
    letsGetsStarted.numberOfLines=2;
    
        
        [self.tableView setUserInteractionEnabled:NO];
        
        [self.tableView addSubview:no];
        [self.tableView addSubview:photos];
        [self.tableView addSubview:yet];
        [self.tableView addSubview:letsGetsStarted];
    
    
    
    UIImageView * dmutArrow = [[UIImageView alloc] initWithFrame:CGRectMake(140, 95, 150, 175)];
    dmutArrow.image = [UIImage imageNamed:@"dmutArrow"];
    [self.view addSubview:dmutArrow];
        
        
    }
}

//- (void)menuStateEventOccurred:(NSNotification *)notification {
//    MFSideMenuStateEvent event = [[[notification userInfo] objectForKey:@"eventType"] intValue];
//    if(event == MFSideMenuStateEventMenuDidOpen){
//        NSLog(@"menu opened");
//        [[GLSharedVideoPlayer sharedInstance] pause];
//    } else if(event == MFSideMenuStateEventMenuDidClose){
//        NSLog(@"menu closed");
//        [[GLSharedVideoPlayer sharedInstance] play];
//    }
//    MFSideMenuContainerViewController *containerViewController = notification.object;
//    // ...
//}

-(void)appActive:(NSNotification*)not {
    
//    cameBackFromBg = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];

}

-(void)appBg:(NSNotification*)not {
    
    cameBackFromBg = YES;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    
}


//- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
//    
//    if(!cameBackFromBg){
//        return NO;
//    }
//    return YES;
//    cameBackFromBg = NO;
//    
//}

//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (indexPath.row == [self.feedItems count] - 3 ) {
//        [self loadPhotos:++self.currentPage];
//    }
//}

//- (void)loadPhotos:(NSInteger)page {
//
//    NSLog(@"need to load page %ld",(long)page);
//    [self.feedItems addObject:[self.posts objectAtIndex:5]];
//        [self.feedItems addObject:[self.posts objectAtIndex:6]];
//        [self.feedItems addObject:[self.posts objectAtIndex:7]];
//        [self.feedItems addObject:[self.posts objectAtIndex:8]];
//        [self.feedItems addObject:[self.posts objectAtIndex:9]];
//    [self.tableView setNeedsDisplay];
//    [self.tableView reloadData];
////        [self.feedItems addObject:[self.posts objectAtIndex:5]];
////    [self loadFeed];
////    for(int x = 0;x < ){}
//}



-(void)scrollViewDidScroll:(UIScrollView *)sender
{
    if (sender.contentOffset.y<=0 || sender.contentOffset.y >= sender.contentSize.height) {
        //        scrollView.contentOffset = CGPointZero;
    } else {
        [self checkWhichVideoToEnable];
    }
}

-(void)checkWhichVideoToEnable
{
    for(GLFeedTableCell *cell in [self.tableView visibleCells])
    {
        if([cell isKindOfClass:[GLFeedTableCell class]])
        {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            CGRect cellRect = [self.tableView rectForRowAtIndexPath:indexPath];
            UIView *superview = self.tableView.superview;
            
            CGRect convertedRect=[self.tableView convertRect:cellRect toView:superview];
            CGRect intersect = CGRectIntersection(self.tableView.frame, convertedRect);
            float visibleHeight = CGRectGetHeight(intersect);
            
            NSArray * data = [self.posts objectAtIndex:indexPath.row];
            SLAlbumPhoto *photo = [data objectAtIndex:1];
            
            if(visibleHeight>cell.frame.size.height*0.51) // only if 51% of the cell is visible
            {
                // unmute the video if we can see at least half of the cell
                //                [((VideoMessageCell*)cell) muteVideo:!btnMuteVideos.selected];
                //                NSLog(@"im gone play on this red cell cus more then 51 is visible");
                
                if([[photo getServerPhoto] getMediaType] == [SLMediaTypeEnum VIDEO]){
                    
                    NSString * videoUrl = [[[photo getServerPhoto] getVideo] getVideoUrl];
                    [[GLSharedVideoPlayer sharedInstance] attachToView:cell.moviePlayer withPhotoId:[[photo getServerPhoto] getId] withVideoUrl:videoUrl videoThumbNail:cell.postImage.image];
                    //                    cell.activityIndicator.backgroundColor = [UIColor redColor];
                    //                    cell.activityIndicator.hidesWhenStopped = NO;
                    //                    [cell bringSubviewToFront:cell.activityIndicator];
                    [cell.activityIndicator startAnimating];
                    
                    
                    
                    //                    [[GLSharedVideoPlayer sharedInstance] play];
                }
                //                    [[GLSharedVideoPlayer sharedInstance] pause];
                
                //                cell.backgroundColor = [UIColor redColor];
            }
            else
            {
                //                [[GLSharedVideoPlayer sharedInstance] pause];
                // mute the other video cells that are not visible
                //                [((VideoMessageCell*)cell) muteVideo:YES];
                //                NSLog(@"im gone pause on this blue cell cus less then 51 is visible");
                //                [cell.activityIndicator stopAnimating];
                
                if([[[GLSharedVideoPlayer sharedInstance] photoId] isEqual:[[photo getServerPhoto] getId]]){
                    [[GLSharedVideoPlayer sharedInstance] pause];
                    
                    //                    cell.backgroundColor = [UIColor blueColor];
                }
                
            }
        }
    }
}

-(void)videoSelected {
    
    [[[GLSharedCamera sharedInstance] videoCamera] stopCameraCapture];
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mp4"];
    
    __block NSString *filePathToThumb = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/Library/Caches/Video_Photo%i.jpg", 0]];
    
//    [KVNProgress showSuccessWithStatus:@"Yhaa !im ready!" completion:^{
    
//        -(void)addUploadVideoJob:(NSString *)videoFilePath withImageFilePath:(NSString *)imageFile withAlbumId:(long long)albumId
        
        [[[ShotVibeAppDelegate sharedDelegate] uploadManager] addUploadVideoJob:pathToMovie withImageFilePath:filePathToThumb withAlbumId:self.albumId];
        
        //        [[ShotVibeAppDelegate sharedDelegate].uploadManager addUploadVideoJob:pathToMovie withAlbumId:self.albumId];
//    }];
    //    long long publicFeedId = 5331;
    
}



-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    
    tableIsScrolling = NO;
    
    if(!scrollToCellDisabled && !commentingNow){
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
        
        [cell highLightLastCommentInPost];
        self.view.userInteractionEnabled = YES;
        
    }
    
}

-(void)startUploadFromOutSide:(NSNotification*)not {
    
    
    //    NSLog(@"im gone start upload");
    
    
}

-(void)addPhotoPushPressed:(SLNotificationMessage_PhotosAdded*)msg {
    
    if(self.albumId != [msg getAlbumId]){
        GLFeedViewController * feedView = [[GLFeedViewController alloc] init];
        feedView.albumId = [msg getAlbumId];
        feedView.scrollToComment = YES;
        feedView.prevAlbumId = self.albumId;
        feedView.startImidiatly = NO;
        GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
        glcamera.imageForOutSideUpload = nil;
        [self.navigationController pushViewController:feedView animated:YES];
        [self removeFromParentViewController];
    }
    
}

-(void)commentPushPressed:(SLNotificationMessage_PhotoComment *)msg {
    
    
    if(self.albumId != [msg getAlbumId]){
        
        GLFeedViewController * feedView = [[GLFeedViewController alloc] init];
        feedView.albumId = [msg getAlbumId];
        feedView.scrollToComment = YES;
        feedView.photoToScrollToCommentsId = [msg getPhotoId];
        feedView.prevAlbumId = self.albumId;
        feedView.startImidiatly = NO;
        GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
        glcamera.imageForOutSideUpload = nil;
        [self.navigationController pushViewController:feedView animated:YES];
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



- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    tableIsScrolling = YES;
    
    
}
//
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    // if decelerating, let scrollViewDidEndDecelerating: handle it
    if (scrollView.contentOffset.y<=0 || scrollView.contentOffset.y >= scrollView.contentSize.height) {
        //        scrollView.contentOffset = CGPointZero;
    } else {
        if (decelerate == NO) {
            //        [self centerTable];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    //    NSLog(@"%f - %f",scrollView.contentOffset.y,scrollView.contentSize.height);
    //    if (scrollView.contentOffset.y < scrollView.contentSize.height) {
    //        scrollView.contentOffset = CGPointZero;
    //    } else {
    //    [self centerTable];
    //    }
}

- (void)centerTable {
    NSIndexPath *pathForCenterCell = [self.tableView indexPathForRowAtPoint:CGPointMake(CGRectGetMidX(self.tableView.bounds), CGRectGetMidY(self.tableView.bounds))];
    
    snapIsScrolling = YES;
    [self.tableView scrollToRowAtIndexPath:pathForCenterCell atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    //    commentingNow = NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    
    return 0;
}

- (BOOL)screenSwiped:(UIScreenEdgePanGestureRecognizer *)gest {
    
    
    [self.navigationController popViewControllerAnimated:YES];
    return  YES;
    
}


- (void)openAppleImagePicker {
    
    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:^{
        
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
            
            CFURLRef url = CFURLCreateWithString(NULL, (CFStringRef)[NSString stringWithFormat:@"file://%@", filePath], NULL);
            CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypeJPEG, 1, NULL);
            CFRelease(url);
            
            NSDictionary *jfifProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                            (__bridge id)kCFBooleanTrue, kCGImagePropertyJFIFIsProgressive,
                                            nil];
            
            NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithFloat:.7], kCGImageDestinationLossyCompressionQuality,
                                        jfifProperties, kCGImagePropertyJFIFDictionary,
                                        nil];
            
            CGImageDestinationAddImage(destination, ((UIImage*)image).CGImage, (__bridge CFDictionaryRef)properties);
            CGImageDestinationFinalize(destination);
            CFRelease(destination);
            
            
            
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
            
            UIImage * reallyFinalImageBeforeUpload = [UIImage imageWithContentsOfFile:filePath];
//            NSData *imgData = UIImageJPEGRepresentation(image, 1); //1 it represents the quality of the image.
            NSData * imgData = [NSData dataWithContentsOfFile:filePath];
            NSLog(@"Size of Image(bytes):%lu",(unsigned long)[imgData length]);
            
            BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
            
            if(fileExists){
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"FINISH to write image");
                    //                [self dismissViewControllerAnimated:YES completion:^{
                    
                    if (self.albumId != 0) {
                        
                        RCLog(@"====================== 1. Upload selected photos to albumId %lli", self.albumId);
                        
                        // Upload the taken photos
                        
                        //                    TmpFilePhotoUploadRequest *photoUploadRequest = [[TmpFilePhotoUploadRequest alloc] initWithTmpFile:filePath];
                        //                    //            [photoUploadRequests addObject:photoUploadRequest];
                        //
                        //                    [albumManager_ uploadPhotosWithLong:self.albumId
                        //                                       withJavaUtilList:[[SLArrayList alloc]
                        //                                                         initWithInitialArray:[NSMutableArray arrayWithObject:photoUploadRequest]]];
                        
                        [[[ShotVibeAppDelegate sharedDelegate] uploadManager] addUploadPhotoJob:filePath withAlbumId:self.albumId];
                        
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSLog(@"SVAlbumGridViewController %@: viewWillAppear: %d", self, animated);
    //
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    
    SLAlbumContents *contents = [albumManager_ addAlbumContentsListenerWithLong:self.albumId withSLAlbumManager_AlbumContentsListener:self];
    [self setAlbumContents:contents];
    //    [self loadFeed];
    [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
    
    
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[GLContainersViewController sharedInstance] lockScrollingPages];

    
    
    
    [self.tableView.delegate scrollViewDidScroll:self.tableView];
    
    if(viewDidInitialed == NO){
        viewDidInitialed = YES;
        
    }
    
    
    //    [self.tableView scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionTop animated:YES];
    
    GLSharedCamera * camera = [GLSharedCamera sharedInstance];
    //    camera.picYourGroup.alpha = 1;
    //    camera.cameraViewBackground.userInteractionEnabled = YES;
//    camera.delegate = [ContainerViewController sharedInstance];
    
    
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
        
    } else {
        
        if([self.posts count]>0){
            
            GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:pageNumber inSection:0]];
            
            NSArray * data = [self.posts objectAtIndex:[self.tableView indexPathForCell:cell].row];
            SLAlbumPhoto *photo = [data objectAtIndex:1];
            
            
            //    CGRect cellRect = [scrollView convertRect:cell.frame toView:scrollView.superview];
            //    if (CGRectContainsRect(scrollView.frame, cellRect)){
            //        NSLog(@"visible");
            //    } else {
            //        NSLog(@"unvisible");
            //    }
            
            //    NSLog(@"%d",);
            
            //        if([[photo getServerPhoto] getMediaType] == [SLMediaTypeEnum VIDEO]){
            //            [cell.activityIndicator startAnimating];
            //            [[GLSharedVideoPlayer sharedInstance] play];
            //        }
            
        }
        
        
    }
    
    
    
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

-(void)viewWillDisappear:(BOOL)animated {
    
    [[GLPubNubManager sharedInstance]setTableViewToRefresh:nil];
    
    
//    GLFeedTableCell * cell = [self.tableView.visibleCells objectAtIndex:0];
    
    
    [[GLSharedVideoPlayer sharedInstance] resetPlayer];
    
    
    
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    
}



- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    //    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
    //    glcamera.delegate = nil;
    
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
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

- (void)lockAlbumContents
{
    lockContentsStackDepth_++;
}

- (void)unlockAlbumContents
{
    NSAssert(lockContentsStackDepth_ > 0, @"unlockAlbumContents matches lockAlbumContents call");
    lockContentsStackDepth_--;
    if (lockContentsStackDepth_ == 0) {
        if (lockContentsSavedValue_) {
            SLAlbumContents *savedValue = lockContentsSavedValue_;
            lockContentsSavedValue_ = nil;
            [self setAlbumContents:savedValue];
            
            [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows]
                             withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

- (void)setAlbumContents:(SLAlbumContents *)album
{
    if (lockContentsStackDepth_ > 0) {
        lockContentsSavedValue_ = album;
        return;
    }

    albumContents = album;
    if(albumContents != nil){
        GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
        if(glcamera.imageForOutSideUpload){
            
            [self imageSelected:glcamera.imageForOutSideUpload];
            glcamera.imageForOutSideUpload = nil;
        }
        
        //        if(glcamera.goneUploadAmovie) {
        //            [self videoSelected];
        //            glcamera.goneUploadAmovie = NO;
        //        }
    }
    
    //    albumContents
    //    SLArrayList * membersList = [albumContents getMembers];
    
    
//    ((SVSidebarManagementController *)self.menuContainerViewController.leftMenuViewController).albumContents = albumContents;
    ((SVSidebarMemberController *)self.menuContainerViewController.rightMenuViewController).albumContents = albumContents;
    
    
    self.menuContainerViewController.panMode = MFSideMenuPanModeDefault;
    
    self.title = [albumContents getName];
    //    [albumContents];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // First set all the fullscreen photos to download at high priority
//        for (SLAlbumPhoto *p in [albumContents getPhotos].array) {
//            if ([p getServerPhoto]) {
//                [photoFilesManager_ queuePhotoDownload:[[p getServerPhoto] getId]
//                                              photoUrl:[[p getServerPhoto] getUrl]
//                                             photoSize:[PhotoSize FeedSize]
//                  /                        highPriority:YES];
//            }
//        }
        
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
    
    self.feedItems = [[NSMutableArray alloc] init];
    if(albumContents != nil){
        int pagingCount = 5;
        self.currentPage = 0;
        self.totalItems = [[albumContents getPhotos].array count];
        self.totalPages = ceil(self.totalItems/pagingCount);
        
        if((self.totalPages * pagingCount) <= self.totalItems){
            self.totalPages++;
        }
    
        self.posts = [[NSMutableArray alloc] init];
        for (SLAlbumPhoto *photo in [albumContents getPhotos].array) {
            
//            counter++;
//            
//            
//            
//            NSString * thumUrl2 = [[photo getServerPhoto] getUrl];
//            
//            NSString *new2 = [thumUrl2 stringByReplacingOccurrencesOfString:@".jpg" withString:@"_r_fhd.jpg"];
//            
//            [[YYWebImageManager sharedManager] requestImageWithURL:[NSURL URLWithString:new2] options:YYWebImageOptionAllowBackgroundTask progress:^(NSInteger receivedSize, NSInteger expectedSize) {
//                
//            } transform:^UIImage *(UIImage *image, NSURL *url) {
//
//                
//                return image;
//                
//                
//            } completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
//                
//            }];
            
            
            //        SDWebImageManager *manager = [SDWebImageManager sharedManager];
            //        [manager downloadImageWithURL:[NSURL URLWithString:[[photo getServerPhoto] getUrl]]
            //                              options:SDWebImageHighPriority
            //                             progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            //                                 // progression tracking code
            //                             }
            //                            completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            //                                if (image) {
            //                                    // do something with image
            //                                    [[SDImageCache sharedImageCache] storeImage:image forKey:[[photo getServerPhoto] getUrl]];
            //
            //                                }
            //                            }];
            
            
            
            
            
            //        (SLAlbumServerPhoto_MediaTypeEnum *)VIDEO;
            
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
            
                
            }
            

            NSString * userData = [NSString stringWithFormat:@"\"username\":\"%@\",\"website\":\"\",\"profile_picture\":\"%@\",\"full_name\":\"%@\",\"bio\":\"\",\"id\":\"%lld\"",[[[photo getServerPhoto] getAuthor] getMemberNickname],[[[photo getServerPhoto] getAuthor] getMemberAvatarUrl],[[[photo getServerPhoto] getAuthor] getMemberNickname],[[[photo getServerPhoto] getAuthor] getMemberId]];
            
            long long seconds = [[[photo getServerPhoto] getDateAdded] getTimeStamp] / 1000000LL;
            NSString *new = [[[photo getServerPhoto]getUrl] stringByReplacingOccurrencesOfString:@".jpg" withString:@"_thumb75.jpg"];
            
            NSString * commetnsString = [NSString stringWithFormat:@"\"count\": %f,\"data\": [%@]",commentsCount,commentsFullString];
            
            NSData *objectData = [[NSString stringWithFormat:@"{\"type\":\"image\",\"location\":null,\"comments\":{%@},\"created_time\":\"%lld\",\"likes\":\"%d\",\"images\":{\"standard_resolution\":{\"url\":\"%@\"}},\"caption\":{\"created_time\":\"%lld\"},\"id\":\"%@\",\"user\":{%@}}",commetnsString,seconds,[[photo getServerPhoto] getGlobalGlanceScore],new,seconds,[[photo getServerPhoto]getId],userData] dataUsingEncoding:NSUTF8StringEncoding];
            
            NSMutableArray * arr = [[NSMutableArray alloc] init];
            NSMutableDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:objectData options:kNilOptions error:nil];
            
            if(dictionary){
                [arr addObject:dictionary];
                [arr addObject:photo];
                [self.posts addObject:arr];
            }
            
            
            //        if(counter < pagingCount){
            //            [self.feedItems addObject:arr];
            //        }
            //
            //        feedLoadedOnce = YES;
            //        counter++;
            
            //            if(counter == 20){
            //                break;
            //            }
            
            //        }
            
            
            //        }
        }
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
        
    }
    
    
    
}

//- (void)didReceiveMemoryWarning {
//    [super didReceiveMemoryWarning];
//    // Dispose of any resources that can be recreated.
//}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    //#warning Incomplete implementation, return the number of sections
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //#warning Incomplete implementation, return the number of rows
    return [self.posts count];
}


//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    GLFeedTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GLFeedCell" forIndexPath:indexPath];
//    cell.tag = indexPath.row;
//    NSArray * tempDict = [self.posts objectAtIndex:indexPath.row];
//
//    SLAlbumPhoto *photo = [tempDict objectAtIndex:1];
//
//
//
//    if ([photo getUploadingPhoto]) {
//
//
//
//        NSLog(@"aaa");
//        [cell.profileImageView setImage:[UIImage imageNamed:@"CaptureButton"]];
//
//        cell.userName.text = [NSString stringWithFormat:@"Uploading - %.f%% ",[[photo getUploadingPhoto] getUploadProgress] * 100];//@"Uploading";
//
//        if([[photo getUploadingPhoto] getUploadProgress] * 100 == 100){
//            scrollToCellDisabled = NO;
//            NSString *path = [NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] resourcePath], @"/dropsound.wav"];
//            //
//            SystemSoundID soundID;
//            //
//            NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
//            //
//            //        //Use audio sevices to create the sound
//            //
//            AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &soundID);
//
//            //Use audio services to play the sound
//
//            AudioServicesPlaySystemSound(soundID);
//        }
//
//        cell.postedTime.text = @"now";
//
//        [cell.postImage setImage:uploadingImage];
//        //        [UIView animateWithDuration:0.5 animations:^{
//        //            cell.postImage.alpha = [[photo getUploadingPhoto] getUploadProgress];
//        //        }];
//
//
//
//        cell.glancesCounter.text = [[tempDict objectAtIndex:0] objectForKey:@"likes"];
//
//
//        cell.photoId = [[tempDict objectAtIndex:0] objectForKey:@"id"];
//
//
//        cell.addCommentButton.tag = indexPath.row;//[[tempDict objectForKey:@"id"] longLongValue];
//        cell.abortCommentButton.tag = indexPath.row;
//        cell.glanceDownButton.tag = indexPath.row;
//        cell.glanceUpButton.tag = indexPath.row;
//
//
//        //        cell.glancesIcon.tag = indexPath.row;
//
//        [cell.postForwardButton addTarget:self action:@selector(sharePostPressed:) forControlEvents:UIControlEventTouchUpInside];
//        cell.postForwardButton.tag = indexPath.row;
//
//        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doSingleTap:)];
//        singleTap.numberOfTapsRequired = 1;
//        //    singleTap
//        [cell.glanceUpButton addGestureRecognizer:singleTap];
//
//        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doDoubleTap:)] ;
//        doubleTap.numberOfTapsRequired = 1;
//        [cell.glanceDownButton addGestureRecognizer:doubleTap];
//
//        //        [singleTap requireGestureRecognizerToFail:doubleTap];
//
//        //    [cell.glancesIcon addGestureRecognizer:<#(nonnull UIGestureRecognizer *)#>];
//
//
//        cell.commentTextField.delegate = self;
//        //    cell.commentTextField
//        cell.commentTextField.tag = indexPath.row;
//
//        //        [cell.addCommentButton addTarget:self action:@selector(addCommentTapped:) forControlEvents:UIControlEventTouchUpInside];
//
//
//        cell.commentsScrollView.alpha = 0;
//
//
//
//    } else {
//
//        [cell.profileImageView setCircleImageWithURL:[NSURL URLWithString:[[[tempDict objectAtIndex:0] objectForKey:@"user"] objectForKey:@"profile_picture"]] placeholderImage:[UIImage imageNamed:@"ProfilePlaceholder"] borderWidth:2];
//
//        cell.userName.text = [[[tempDict objectAtIndex:0] objectForKey:@"user"] objectForKey:@"username"];
//        cell.postedTime.text = [NSString stringWithFormat:@"%@ ago",[[[NSDate alloc] initWithTimeIntervalSince1970:[[[tempDict objectAtIndex:0] objectForKey:@"created_time"] longLongValue]] distanceOfTimeInWords:[NSDate date] shortStyle:YES]];
//
//        //        if(!cell.loaded){
//        //        if(indexPath.row > 0 && uploadingImage == nil){
//
//
//        //        UIImage * tempImage;
//        //        if(indexPath.row ==0){
//        //            if(!uploadingImage){
//        //                tempImage = [UIImage imageNamed:@"postIsUploadingPh"];
//        //            } else {
//        //                tempImage = [uploadingImage copy];
//        ////                uploadingImage = nil;
//        //            }
//        //
//        //
//        //        } else{
//        //            tempImage = [UIImage imageNamed:@"postIsUploadingPh"];
//        //        }
//
//        //
//        //            [cell.postImage sd_setImageWithURL:[NSURL URLWithString:[[[[tempDict objectAtIndex:0] objectForKey:@"images"] objectForKey:@"standard_resolution"] objectForKey:@"url"]]
//        //                              placeholderImage:uploadingImage options:SDWebImageHighPriority completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
//        //                                  [UIView animateWithDuration:0.2 animations:^{
//        //                                      cell.postImage.alpha = 1;
//        //                                  }];
//        //                              }];
//
//
//        //        }
//
//        SLAlbumPhoto * photo = [tempDict objectAtIndex:1];
//        //        cell.postImage
//        //        if(cell.postImage.image != uploadingImage){
//        [cell.postImage setPhoto:[[photo getServerPhoto] getId] photoUrl:[[photo getServerPhoto] getUrl] photoSize:[PhotoSize FeedSize] manager:photoFilesManager_];
//        //        }
//        //
//
//
//
//        //        int score = [[photo getServerPhoto] getMyGlanceScoreDelta];
//        //        if(score < 0){
//        //            cell.glancesIcon.image = [UIImage imageNamed:@"glancesIconUnGlanced"];
//        //        } else if(score == 0){
//        //            cell.glancesIcon.image = [UIImage imageNamed:@"glancesIconRegular"];
//        //        } else {
//        //            cell.glancesIcon.image = [UIImage imageNamed:@"glancesIconGlanced"];
//        //        }
//        //        [cell.postImage setPhoto:<#(NSString *)#> photoUrl: objectForKey:@"url"]] photoSize:[PhotoSize FeedSize] manager:albumManager_]
//
//        //        }
//
//
//        cell.glancesCounter.text = [[tempDict objectAtIndex:0] objectForKey:@"likes"];
//
//
//
//
//
//        NSMutableArray * commentsArray = [[NSMutableArray alloc] init];
//        commentsArray = [[[tempDict objectAtIndex:0] objectForKey:@"comments"] objectForKey:@"data"];
//
//
//        cell.photoId = [[tempDict objectAtIndex:0] objectForKey:@"id"];
//
//
//        cell.addCommentButton.tag = indexPath.row;//[[tempDict objectForKey:@"id"] longLongValue];
//        cell.abortCommentButton.tag = indexPath.row;
//        cell.glanceDownButton.tag = indexPath.row;
//        cell.glanceUpButton.tag = indexPath.row;
//
//        [cell.postForwardButton addTarget:self action:@selector(sharePostPressed:) forControlEvents:UIControlEventTouchUpInside];
//        cell.postForwardButton.tag = indexPath.row;
//
//        //    cell.glancesIcon.tag = indexPath.row;
//
//        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doSingleTap:)];
//        singleTap.numberOfTapsRequired = 1;
//        //    singleTap
//        [cell.glanceUpButton addGestureRecognizer:singleTap];
//
//        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doDoubleTap:)] ;
//        doubleTap.numberOfTapsRequired = 1;
//        [cell.glanceDownButton addGestureRecognizer:doubleTap];
//
//        //    [singleTap requireGestureRecognizerToFail:doubleTap];
//
//
//
//        //    [cell.glancesIcon addGestureRecognizer:<#(nonnull UIGestureRecognizer *)#>];
//
//
//        cell.commentTextField.delegate = self;
//        //    cell.commentTextField
//        cell.commentTextField.tag = indexPath.row;
//
//        [cell.addCommentButton addTarget:self action:@selector(addCommentTapped:) forControlEvents:UIControlEventTouchUpInside];
//
//        [cell.postPannelWrapper bringSubviewToFront:cell.abortCommentButton];
//
//
//        [cell.commentsScrollView removeFromSuperview];
//
//        cell.commentsScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 65, [[UIScreen mainScreen] bounds].size.width, 69)];
//        cell.commentsScrollView.alpha = 1;
//        cell.commentsScrollView.pagingEnabled = YES;
//        cell.commentsScrollView.backgroundColor = [UIColor clearColor];
//        cell.commentsScrollView.contentSize = CGSizeMake(self.view.frame.size.width, [commentsArray count]*23);
//
//
//
//
//
//
//
//        int c = 0;
//
//        for(NSDictionary * comment in commentsArray){
//            //            NSLog(@"%@",[comment objectForKey:@"text"]);
//
//
//
//            UILabel * commentAuthor = [[UILabel alloc] initWithFrame:CGRectMake(20, c*23, self.view.frame.size.width/3, 20)];
//            commentAuthor.numberOfLines = 1;
//            commentAuthor.textColor = [UIColor whiteColor];
//
//
//            NSArray *tagschemes = [NSArray arrayWithObjects:NSLinguisticTagSchemeLanguage, nil];
//            NSLinguisticTagger *tagger = [[NSLinguisticTagger alloc] initWithTagSchemes:tagschemes options:0];
//            [tagger setString:[[comment objectForKey:@"from"] objectForKey:@"full_name"]];
//            NSString *language = [tagger tagAtIndex:0 scheme:NSLinguisticTagSchemeLanguage tokenRange:NULL sentenceRange:NULL];
//            if ([language rangeOfString:@"he"].location != NSNotFound || [language rangeOfString:@"ar"].location != NSNotFound) {
//                commentAuthor.text = [@": " stringByAppendingString:[[comment objectForKey:@"from"] objectForKey:@"full_name"]];
//            } else {
//                commentAuthor.text = [[[comment objectForKey:@"from"] objectForKey:@"full_name"] stringByAppendingString:@":"];
//            }
//
//
//            commentAuthor.font = [UIFont fontWithName:@"GothamRounded-Book" size:14];
//
//            float widthIs =
//            [commentAuthor.text
//             boundingRectWithSize:commentAuthor.frame.size
//             options:NSStringDrawingUsesLineFragmentOrigin
//             attributes:@{ NSFontAttributeName:commentAuthor.font }
//             context:nil]
//            .size.width;
//            commentAuthor.frame = CGRectMake(20, c*23, widthIs, 20);
//
//            UILabel * t = [[UILabel alloc] initWithFrame:CGRectMake(commentAuthor.frame.size.width+25, c*23, self.view.frame.size.width*0.6, 20)];
//            t.textColor = [UIColor whiteColor];
//            t.font = [UIFont fontWithName:@"GothamRounded-Book" size:14];
//            t.numberOfLines = 1;
//            t.lineBreakMode = NSLineBreakByWordWrapping;
//            t.text = [comment objectForKey:@"text"];
//            [cell.commentsScrollView addSubview:commentAuthor];
//            [cell.commentsScrollView addSubview:t];
//            c++;
//        }
//
//        [cell.postPannelWrapper addSubview:cell.commentsScrollView];
//
//        if([commentsArray count] > 3){
//
//            CGPoint bottomOffset = CGPointMake(0, cell.commentsScrollView.contentSize.height - cell.commentsScrollView.bounds.size.height);
//            [cell.commentsScrollView setContentOffset:bottomOffset animated:NO];
//
//        } else {
//
//            cell.commentsScrollView.scrollEnabled = NO;
//
//        }
//
//
//
//        cell.loaded = YES;
//
//
//
//        if (indexPath.row == 4) {
//            NSLog(@"need to reload more now");
//        }
//    }
//
//    return cell;
//}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    NSArray * tempDict = [self.posts objectAtIndex:indexPath.row];
    
    SLAlbumPhoto * photo = [tempDict objectAtIndex:1];
    
    static NSString * CellIdentifier = @"GLFeedCell";
    static NSString * CellIdentifierNibName = @"GLFeedTableCell";
    static NSString * CellIdentifierUploading = @"GLFeedCellUploading";
    static NSString * CellIdentifierUploadingNibName = @"GLFeedTableCellUploading";
    
    if (indexPath.row == 99999999999) {
        
        GLFeedTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierUploading];
        
        if(cell==nil){
            
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:CellIdentifierUploadingNibName owner:self options:nil];
            cell = [nib objectAtIndex:0];
        }
        
        cell.backgroundColor = [UIColor greenColor];
        CGRect frame = cell.frame;
        frame.size.height = 60;
        cell.frame = frame;
        
        
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityIndicator.center = cell.center;
        [cell.contentView addSubview:activityIndicator];
        [activityIndicator startAnimating];
        
        return cell;
        
    } else {
        
        if ([photo getUploadingMedia]) {
            
            //        NSArray *deleteIndexPaths = [[NSArray alloc] initWithObjects:
            //                                     [NSIndexPath indexPathForRow:10 inSection:0],
            //                                     nil];
            //        NSArray *insertIndexPaths = [[NSArray alloc] initWithObjects:
            //                                     [NSIndexPath indexPathForRow:0 inSection:0],
            //                                     nil];
            //
            //
            //        [self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationFade];
            //        [self.tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
            //        [self.tableView endUpdates];
            
            
            GLFeedTableCellUploading *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierUploading];
            
            if(cell==nil){
                
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:CellIdentifierUploadingNibName owner:self options:nil];
                cell = [nib objectAtIndex:0];
            }
            
            [cell updateUploadingStatus:[photo getUploadingMedia]];
            
            
            return  cell;

        } else {
            
            if([[photo getServerPhoto] getMediaType] == [SLMediaTypeEnum VIDEO] && [[[photo getServerPhoto] getVideo] getStatus] == [SLAlbumServerVideo_StatusEnum PROCESSING] ){
                
                NSLog(@"proccing now");
                
                //            [self.tableView beginUpdates];
                
                //            NSArray *insertIndexPaths = [[NSArray alloc] initWithObjects:
                //                                         [NSIndexPath indexPathForRow:0 inSection:0],
                //                                         nil];
                
                
                //            NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                //            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                //
                ////            [self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationFade];
                //
                //
                //            [self.tableView endUpdates];
                
                GLFeedTableCellUploading *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierUploading];
                
                
                
                if(cell==nil){
                    
                    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:CellIdentifierUploadingNibName owner:self options:nil];
                    cell = [nib objectAtIndex:0];
                }
                
                //            [cell updateUploadingStatus:[photo getUploadingMedia]];
                [cell updateProccesingStatus:photo];
                
                
                return  cell;
                
                
                
                
            } else {
                
                GLFeedTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                
                if(cell==nil){
                    
                    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:CellIdentifierNibName owner:self options:nil];
                    cell = [nib objectAtIndex:0];
                }
                
                [cell loadCellWithData:tempDict photoFilesManager:photoFilesManager_];
                cell.tableView = self.tableView;
                
                long long userID = [[[[tempDict objectAtIndex:0] objectForKey:@"user"] objectForKey:@"id"] longLongValue];
                
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
                return  cell;
            }
            
            
        }
        
        
        
        
        
        
        //
        //    if ([photo getUploadingPhoto]) {
        //        [];
        //    } else {
        //
        //    }
        //
        //        cell.videoBadge.alpha = 0;
        //
        //                NSLog(@"aaa");
        //                [cell.profileImageView setImage:[UIImage imageNamed:@"CaptureButton"]];
        //
        //                cell.userName.text = [NSString stringWithFormat:@"Uploading - %.f%% ",[[photo getUploadingPhoto] getUploadProgress] * 100];//@"Uploading";
        //
        //                if([[photo getUploadingPhoto] getUploadProgress] * 100.f == 99.9f){
        //                    scrollToCellDisabled = NO;
        //                    NSString *path = [NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] resourcePath], @"/dropsound.wav"];
        //                    //
        //                    SystemSoundID soundID;
        //                    //
        //                    NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
        //                    //
        //                    //        //Use audio sevices to create the sound
        //                    //
        //                    AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &soundID);
        //
        //                    //Use audio services to play the sound
        //
        //                    AudioServicesPlaySystemSound(soundID);
        //                }
        //
        //                cell.postedTime.text = @"now";
        //
        //                [cell.postImage setImage:uploadingImage];
        //                //        [UIView animateWithDuration:0.5 animations:^{
        //                //            cell.postImage.alpha = [[photo getUploadingPhoto] getUploadProgress];
        //                //        }];
        //
        //
        //
        //                cell.glancesCounter.text = [[tempDict objectAtIndex:0] objectForKey:@"likes"];
        //
        //
        //                cell.photoId = [[tempDict objectAtIndex:0] objectForKey:@"id"];
        //
        //
        //                cell.addCommentButton.tag = indexPath.row;//[[tempDict objectForKey:@"id"] longLongValue];
        //                cell.abortCommentButton.tag = indexPath.row;
        //                cell.glanceDownButton.tag = indexPath.row;
        //                cell.glanceUpButton.tag = indexPath.row;
        //
        //
        //                //        cell.glancesIcon.tag = indexPath.row;
        //
        //                [cell.postForwardButton addTarget:self action:@selector(sharePostPressed:) forControlEvents:UIControlEventTouchUpInside];
        //                cell.postForwardButton.tag = indexPath.row;
        //
        //                UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doSingleTap:)];
        //                singleTap.numberOfTapsRequired = 1;
        //                //    singleTap
        //                [cell.glanceUpButton addGestureRecognizer:singleTap];
        //
        //                UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doDoubleTap:)] ;
        //                doubleTap.numberOfTapsRequired = 1;
        //                [cell.glanceDownButton addGestureRecognizer:doubleTap];
        //
        //                //        [singleTap requireGestureRecognizerToFail:doubleTap];
        //
        //                //    [cell.glancesIcon addGestureRecognizer:<#(nonnull UIGestureRecognizer *)#>];
        //
        //
        //                cell.commentTextField.delegate = self;
        //                //    cell.commentTextField
        //                cell.commentTextField.tag = indexPath.row;
        //
        //                //        [cell.addCommentButton addTarget:self action:@selector(addCommentTapped:) forControlEvents:UIControlEventTouchUpInside];
        //
        //
        //                cell.commentsScrollView.alpha = 0;
        //
        //
        //
        //            } else {
        //
        //
        //
        //    [cell loadCellWithData:tempDict photoFilesManager:photoFilesManager_];
        //    cell.tableView = self.tableView;
        //
        //    long long userID = [[[[tempDict objectAtIndex:0] objectForKey:@"user"] objectForKey:@"id"] longLongValue];
        //
        //        NSMutableArray * commentsArray = [[NSMutableArray alloc] init];
        //        commentsArray = [[[tempDict objectAtIndex:0] objectForKey:@"comments"] objectForKey:@"data"];
        //
        //
        //    cell.photoId = [[tempDict objectAtIndex:0] objectForKey:@"id"];
        //
        //
        //    cell.addCommentButton.tag = indexPath.row;//[[tempDict objectForKey:@"id"] longLongValue];
        //    cell.abortCommentButton.tag = indexPath.row;
        //        cell.glanceDownButton.tag = indexPath.row;
        //        cell.glanceUpButton.tag = indexPath.row;
        //
        //        cell.feed3DotsButton.tag = indexPath.row;
        //
        //    [cell.postForwardButton addTarget:self action:@selector(sharePostPressed:) forControlEvents:UIControlEventTouchUpInside];
        //    cell.postForwardButton.tag = indexPath.row;
        //
        //
        //
        //    cell.profileImageView.tag = userID;
        //    cell.userName.tag = userID;
        //
        //    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doSingleTap:)];
        //    singleTap.numberOfTapsRequired = 1;
        ////    singleTap
        //    [cell.glanceUpButton addGestureRecognizer:singleTap];
        //
        //    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doDoubleTap:)] ;
        //    doubleTap.numberOfTapsRequired = 1;
        //    [cell.glanceDownButton addGestureRecognizer:doubleTap];
        //
        //        UITapGestureRecognizer *showActionSheetGest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showActionSheets:)];
        //        showActionSheetGest.numberOfTapsRequired = 1;
        ////        showActionSheetGest.view.tag = indexPath.row;
        //        //    singleTap
        //        [cell.feed3DotsButton addGestureRecognizer:showActionSheetGest];
        //
        //        UITapGestureRecognizer *showUserProfileTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showUserProfile:)];
        //        UITapGestureRecognizer *showUserProfileTap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showUserProfile2:)];
        //
        //        cell.profileImageView.userInteractionEnabled = YES;
        //        cell.userName.userInteractionEnabled = YES;
        //        [cell.profileImageView addGestureRecognizer:showUserProfileTap];
        //        [cell.userName addGestureRecognizer:showUserProfileTap2];
        //        //    singleTap
        //        [cell.feed3DotsButton addGestureRecognizer:showActionSheetGest];
        //
        //
        //
        //    cell.commentTextField.delegate = self;
        //    //    cell.commentTextField
        //    cell.commentTextField.tag = indexPath.row;
        //
        //    [cell.addCommentButton addTarget:self action:@selector(addCommentTapped:) forControlEvents:UIControlEventTouchUpInside];
        //
        //    [cell.postPannelWrapper bringSubviewToFront:cell.abortCommentButton];
        //
        //
        //    [cell.commentsScrollView removeFromSuperview];
        //
        //    cell.commentsScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 65, [[UIScreen mainScreen] bounds].size.width, 69)];
        //        cell.commentsScrollView.alpha = 1;
        //    cell.commentsScrollView.pagingEnabled = YES;
        //    cell.commentsScrollView.backgroundColor = [UIColor clearColor];
        //    cell.commentsScrollView.contentSize = CGSizeMake(self.view.frame.size.width, [commentsArray count]*23);
        //
        //
        //
        //
        //
        //
        //
        //        int c = 0;
        //
        //        for(NSDictionary * comment in commentsArray){
        ////            NSLog(@"%@",[comment objectForKey:@"text"]);
        //
        //
        //
        //            UILabel * commentAuthor = [[UILabel alloc] initWithFrame:CGRectMake(20, c*23, self.view.frame.size.width/3, 20)];
        //            commentAuthor.numberOfLines = 1;
        //            commentAuthor.textColor = [UIColor whiteColor];
        //
        //
        //            NSArray *tagschemes = [NSArray arrayWithObjects:NSLinguisticTagSchemeLanguage, nil];
        //            NSLinguisticTagger *tagger = [[NSLinguisticTagger alloc] initWithTagSchemes:tagschemes options:0];
        //            [tagger setString:[[comment objectForKey:@"from"] objectForKey:@"full_name"]];
        //            NSString *language = [tagger tagAtIndex:0 scheme:NSLinguisticTagSchemeLanguage tokenRange:NULL sentenceRange:NULL];
        //            if ([language rangeOfString:@"he"].location != NSNotFound || [language rangeOfString:@"ar"].location != NSNotFound) {
        //                commentAuthor.text = [@": " stringByAppendingString:[[comment objectForKey:@"from"] objectForKey:@"full_name"]];
        //            } else {
        //                commentAuthor.text = [[[comment objectForKey:@"from"] objectForKey:@"full_name"] stringByAppendingString:@":"];
        //            }
        //
        //
        //            commentAuthor.font = [UIFont fontWithName:@"GothamRounded-Book" size:14];
        //
        //            float widthIs =
        //            [commentAuthor.text
        //             boundingRectWithSize:commentAuthor.frame.size
        //             options:NSStringDrawingUsesLineFragmentOrigin
        //             attributes:@{ NSFontAttributeName:commentAuthor.font }
        //             context:nil]
        //            .size.width;
        //            commentAuthor.frame = CGRectMake(20, c*23, widthIs, 20);
        //
        //            UILabel * t = [[UILabel alloc] initWithFrame:CGRectMake(commentAuthor.frame.size.width+25, c*23, self.view.frame.size.width*0.6, 20)];
        //            t.textColor = [UIColor whiteColor];
        //            t.font = [UIFont fontWithName:@"GothamRounded-Book" size:14];
        //            t.numberOfLines = 1;
        //            t.lineBreakMode = NSLineBreakByWordWrapping;
        //            t.text = [comment objectForKey:@"text"];
        //            [cell.commentsScrollView addSubview:commentAuthor];
        //            [cell.commentsScrollView addSubview:t];
        //            c++;
        //        }
        //
        //    [cell.postPannelWrapper addSubview:cell.commentsScrollView];
        //
        //        if([commentsArray count] > 3){
        //
        //            CGPoint bottomOffset = CGPointMake(0, cell.commentsScrollView.contentSize.height - cell.commentsScrollView.bounds.size.height);
        //            [cell.commentsScrollView setContentOffset:bottomOffset animated:NO];
        //
        //        } else {
        //
        //            cell.commentsScrollView.scrollEnabled = NO;
        //
        //        }
        //
        //
        //
        //        cell.loaded = YES;
        //    }
        
        
    }
    
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
                
                
                //                [ShotVibeAPITask runTask:self withAction:^id{
                //
                //                } onTaskComplete:^(id dummy) {
                //
                //                } withSuccess:YES withFailure:YES successText:@"" failureText:@"" showLoadingText:YES loadingText:@""];
                
                
                //                [KVNProgress showWithStatus:@"Deleting.."];
                [ShotVibeAPITask runTask:self withAction:^id{
                    //                    [MBProgressHUD showHUDAddedTo:[[ShotVibeAppDelegate sharedDelegate] window] animated:YES];
                    //                [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    NSMutableArray *photosToDelete = [[NSMutableArray alloc] init];
                    [photosToDelete addObject:[[photo getServerPhoto] getId]];
                    
                    
                    [[albumManager_ getShotVibeAPI] deletePhotosWithJavaLangIterable:[[SLArrayList alloc] initWithInitialArray:photosToDelete]];
                    
                    
                    //                });
                    //                [[albumManager_ getShotVibeAPI] get];
                    return nil;
                } onTaskComplete:^(id dummy) {
                    //                dispatch_async(dispatch_get_main_queue(), ^{
                    //                    [MBProgressHUD hideHUDForView:[[ShotVibeAppDelegate sharedDelegate] window] animated:YES];
                    //                });
                    //                    [KVNProgress showSuccessWithStatus:@"Deleted"];
                    [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
                    
                    
                } onTaskFailure:^(id success) {
                    [KVNProgress showErrorWithStatus:@"Somthing wenet wrong..." completion:^{
                        
                    }];
                } withLoaderIndicator:NO];
                
                
            } else {
                
                [KVNProgress showErrorWithStatus:@"Hi! That's not your's to delete!" onView:self.view completion:^{
                    NSLog(@"");
                }];
                //                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete failed"
                //                                                                message:@"You can't delete a photo that dosn't belong to you.."
                //                                                               delegate:nil
                //                                                      cancelButtonTitle:@"Ok"
                //                                                      otherButtonTitles:nil];
                //                [alert show];
                
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
    
    //    [KVNProgress showWithStatus:@"Glancing Up"];
    GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:gest.view.tag inSection:0]];
    
    
    
    
    SLAlbumPhoto * photo = [[self.posts objectAtIndex:gest.view.tag] objectAtIndex:1];
    int glanceScoreDelta = [[photo getServerPhoto]  getMyGlanceScoreDelta];
    if(glanceScoreDelta <= 0){
        
        if([cell.glancesCounter.text intValue] >= -1){
            cell.glancesCounter.text = [NSString stringWithFormat:@"%d",[cell.glancesCounter.text intValue]+2];
        } else {
            cell.glancesCounter.text = [NSString stringWithFormat:@"%d",[cell.glancesCounter.text intValue]+1];
        }
        
        
        
        
        [ShotVibeAPITask runTask:self withAction:^id{
            [[albumManager_ getShotVibeAPI] setPhotoMyGlanceScoreDeltaWithNSString:cell.photoId withInt:1];
            
            //        [[albumManager_ getShotVibeAPI]postPhotoCommentWithNSString:cell.photoId withNSString:textField.text withLong:milliseconds];
            return nil;
        } onTaskComplete:^(id dummy) {
            [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
            [UIView animateWithDuration:0.2 animations:^{
                //                commentsDialog.alpha = 0;
                
                
                
                
            } completion:^(BOOL finished) {
                
                //            [KVNProgress showSuccessWithStatus:@"Glanced!"];
                
            }];
        } onTaskFailure:^(id success) {
            
            [KVNProgress showErrorWithStatus:@"Somthing went wrong.."];
            
        } withLoaderIndicator:NO];
    }
    
    
    
    
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
    
    
    
    //    [KVNProgress showWithStatus:@"Glancing Down"];
    GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:gest.view.tag inSection:0]];
    
    SLAlbumPhoto * photo = [[self.posts objectAtIndex:gest.view.tag] objectAtIndex:1];
    int glanceScoreDelta = [[photo getServerPhoto]  getMyGlanceScoreDelta];
    if(glanceScoreDelta >= 0){
        
        if([cell.glancesCounter.text intValue] >= 1){
            cell.glancesCounter.text = [NSString stringWithFormat:@"%d",[cell.glancesCounter.text intValue]-2];
        } else {
            cell.glancesCounter.text = [NSString stringWithFormat:@"%d",[cell.glancesCounter.text intValue]-1];
        }
        
        [ShotVibeAPITask runTask:self withAction:^id{
            [[albumManager_ getShotVibeAPI] setPhotoMyGlanceScoreDeltaWithNSString:cell.photoId withInt:-1];
            
            //        [[albumManager_ getShotVibeAPI]postPhotoCommentWithNSString:cell.photoId withNSString:textField.text withLong:milliseconds];
            return nil;
        } onTaskComplete:^(id dummy) {
            [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
            [UIView animateWithDuration:0.2 animations:^{
                //                commentsDialog.alpha = 0;
                
                
                
                
            } completion:^(BOOL finished) {
                
                //            [KVNProgress showSuccessWithStatus:@"UnGlanced!"];
                
            }];
        } onTaskFailure:^(id success) {
            
            [KVNProgress showErrorWithStatus:@"Somthing went wrong..."];
            
        } withLoaderIndicator:NO];
        
    }
    
    
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



-(void)sharePostPressed:(UIButton*)sender {
    
    
    GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:sender.tag inSection:0]];
    [[GLContainersViewController sharedInstance] goToFriendsListViewAnimatedBeforeMovingPhoto:NO photoId:cell.photoId];
    
    //    [self backPressed];
//
    
    //    [self.navigationController popViewControllerAnimated:YES];
    
    //    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:cell.photoId forKey:@"photoToMoveId"];
    //    [[NSNotificationCenter defaultCenter] postNotificationName: @"ImageJustMoved" object:nil userInfo:userInfo];
    
    //
    
//    [[ContainerViewController sharedInstance] setFriendsForMove:cell.photoId];
//    [[ContainerViewController sharedInstance] transitToFriendsList:NO direction:UIPageViewControllerNavigationDirectionForward completion:^{
//        
//    }];
    
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
    
//    [[ContainerViewController sharedInstance] lockScrolling:NO];
    
//    if(membersOpened){
//        
//        
//        membersOpened = !membersOpened;
//        
//        [self.menuContainerViewController toggleRightSideMenuCompletion:nil];
//        
//    }
    
    [[GLContainersViewController sharedInstance] unlockScrollingPages];
    
    [[GLSharedCamera sharedInstance] setCameraInMain];
    //    [UIView animateWithDuration:0.2 animations:^{
    //        [[[GLSharedCamera sharedInstance]backButton]setAlpha:0];
    //        [[[GLSharedCamera sharedInstance]membersButton]setAlpha:0];
    //    }];
    [self.navigationController popToRootViewControllerAnimated:YES];
    
    
}

-(void)membersPressed {
    
    membersOpened = !membersOpened;
    
    [self.menuContainerViewController toggleRightSideMenuCompletion:nil];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    
    if([textField.text isEqualToString:@""]){
        
        
        [KVNProgress showErrorWithStatus:@"Comment can't be empty" completion:^{
            
        }];
        
        
    } else {
        
        //        [KVNProgress showWithStatus:@"Posting your comment"];
        
        long long milliseconds = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
        GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:textField.tag inSection:0]];
        
        
        [cell.commentTextField resignFirstResponder];
        //        [self.tableView reloadData];
        [ShotVibeAPITask runTask:self withAction:^id{
            
            [[albumManager_ getShotVibeAPI]postPhotoCommentWithNSString:cell.photoId withNSString:textField.text withLong:milliseconds];
            return nil;
        } onTaskComplete:^(id dummy) {
            
            
            [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
            //            [self.tableView setUserInteractionEnabled:YES];
            
            
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
                
                //                [KVNProgress showSuccessWithStatus:@"Comment Posted"];
                
                //                textField.text = @"";
            }];
        } onTaskFailure:
         ^(id failure) {
             
             [KVNProgress showErrorWithStatus:@"Somthing went wrong"];
             
         }  withLoaderIndicator:NO];
        
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
        cell.feed3DotsButton.alpha = 1;
        //        cell.glancesIcon.alpha = 1;
        cell.commentTextField.text = @"";
        cell.commentTextField.frame = CGRectMake(cell.addCommentButton.frame.origin.x+cell.addCommentButton.frame.size.width+10,cell.glancesCounter.frame.origin.y+2, 0,35);
        
        cell.glancesCounter.frame = CGRectMake(cell.addCommentButton.frame.origin.x+cell.addCommentButton.frame.size.width+32, 26, 45, 35);
        
        
    } completion:^(BOOL finished) {
        commentingNow = NO;
    }];
    
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSLog(@"%lu",textField.text.length);
    if(textField.text.length > 10){
        
    }
    
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
        
        cell.feed3DotsButton.alpha = 0;
        
    } completion:^(BOOL finished) {
        PMCustomKeyboard *customKeyboard = [[PMCustomKeyboard alloc] init];
        
        
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:sender.tag inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        
        
        [customKeyboard setTextView:cell.commentTextField];
        [cell.commentTextField becomeFirstResponder];
    }];
    
}



-(void)keyboardDidShow:(NSNotification *)notification {
    
    
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
//    if (state == UIApplicationStateActive)
//    {
        //Do checking here.
//        if(![[GLSharedCamera sharedInstance] cameraIsShown] && ![[ContainerViewController sharedInstance] membersOpen]){
//            [self lockAlbumContents];
//        }
    
        
//    }
    
    
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    

    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
//    if (state == UIApplicationStateActive)
//    {
//    if(![[GLSharedCamera sharedInstance] cameraIsShown] && ![[ContainerViewController sharedInstance] membersOpen]){
//        
//        
////        [self lockAlbumContents];
//        
//        self.tableView.scrollEnabled = NO;
//        
//        CGRect frame = self.tableView.frame;
//        CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
//        frame.origin.y -= keyboardRect.size.height;
//        
//        [UIView animateWithDuration:0.2
//                         animations:^{
//                             self.tableView.frame = frame;
//                         }];
//    }
//    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    RCLog(@"%@ did receive memory warning", NSStringFromClass([self class]));
//    [thumbnailCache removeAllObjects];
    
}

-(void)keyboardDidHide:(NSNotification *)note {
    
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
//    if (state == UIApplicationStateActive)
//    {
//    if(![[GLSharedCamera sharedInstance] cameraIsShown] && ![[ContainerViewController sharedInstance] membersOpen]){
//        [self unlockAlbumContents];
//    }
//    }
    
    
}

- (void)keyboardWillHide:(NSNotification *)notification
{
//    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
//    if (state == UIApplicationStateActive)
//    {
//        if(![[GLSharedCamera sharedInstance] cameraIsShown] && ![[ContainerViewController sharedInstance] membersOpen]){
//            
//            //        [self unlockAlbumContents];
//            
//            self.tableView.scrollEnabled = YES;
//            CGRect frame = self.tableView.frame;
//            CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
//            frame.origin.y += keyboardRect.size.height;
//            
//            [UIView animateWithDuration:0.2
//                             animations:^{
//                                 self.tableView.frame = frame;
//                             }];
//            
//            
//        }
//    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[UIScreen mainScreen] bounds].size.height*0.883;
}


@end
