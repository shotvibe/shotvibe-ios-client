//
//  GLFeedViewController.m
//  shotvibe
//
//  Created by Tsah Kashkash on 26/10/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import "GLPublicFeedPostViewController.h"
#import "GLFeedTableCell.h"
#import "SVAddFriendsViewController.h"
#import "SVNavigationController.h"
#import "SL/AlbumPhoto.h"
#import "NSDate+Formatting.h"
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
#import "SVDefines.h"
#import "ShotVibeAppDelegate.h"
#import "SL/AlbumPhotoComment.h"
#import "SL/AlbumPhoto.h"
#import "SDWebImageManager.h"
#import "UIImageView+WebCache.h"
#import "LNNotificationsUI.h"
#import "GLProfilePageViewController.h"
#import "YYWebImage.h"
#import "SL/MediaType.h"
#import "SL/AlbumServerVideo.h"
#import "GLSharedVideoPlayer.h"
#import "GLContainersViewController.h"

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
}

@end

@implementation GLPublicFeedPostViewController

-(void)closePressed {
    [[GLSharedVideoPlayer sharedInstance] resetPlayer];
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
    scrollToCellDisabled = NO;
    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
    glcamera.delegate = self;
    commentingNow = NO;
    membersOpened = NO;
    self.tableView.delegate = self;
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
    [self.tableView setContentInset:UIEdgeInsetsMake(60,0,0,0)];
    self.tableView.scrollEnabled = NO;
    [self setNeedsStatusBarAppearanceUpdate];
    ShotVibeAppDelegate *appDelegate = (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.pushNotificationsManager.notificationHandler_.delegate = self;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 20)];
    [headerView setBackgroundColor:[UIColor clearColor]];
    return headerView;
}
- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    
    return 20;
}

- (BOOL)screenSwiped:(UIScreenEdgePanGestureRecognizer *)gest {
    
    [self.navigationController popViewControllerAnimated:YES];
    return  YES;
    
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
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    NSLog(@"SVAlbumGridViewController %@: viewWillAppear: %d", self, animated);
    //
    
    SLAlbumContents *contents = [albumManager_ addAlbumContentsListenerWithLong:self.albumId withSLAlbumManager_AlbumContentsListener:self];
    [self setAlbumContents:contents];
    [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [albumManager_ removeAlbumContentsListenerWithLong:self.albumId withSLAlbumManager_AlbumContentsListener:self];
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
        
    }
    
    
    self.title = [albumContents getName];
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
    }
    NSString * userData = [NSString stringWithFormat:@"\"username\":\"%@\",\"website\":\"\",\"profile_picture\":\"%@\",\"full_name\":\"%@\",\"bio\":\"\",\"id\":\"%lld\"",[[[photo getServerPhoto] getAuthor] getMemberNickname],[[[photo getServerPhoto] getAuthor] getMemberAvatarUrl],[[[photo getServerPhoto] getAuthor] getMemberNickname],[[[photo getServerPhoto] getAuthor] getMemberId]];
    
    long long seconds = [[[photo getServerPhoto] getDateAdded] getTimeStamp] / 1000000LL;
    NSString *new = [[[photo getServerPhoto]getUrl] stringByReplacingOccurrencesOfString:@".jpg" withString:@"_r_fhd.jpg"];
    
    NSString * commetnsString = [NSString stringWithFormat:@"\"count\": %f,\"data\": [%@]",commentsCount,commentsFullString];
    
    NSData *objectData = [[NSString stringWithFormat:@"{\"attribution\":null,\"tags\":[],\"type\":\"image\",\"location\":null,\"comments\":{%@},\"filter\":\"Normal\",\"created_time\":\"%lld\",\"link\":\"http://instagram.com/p/xtfQ81gK0E/\",\"likes\":\"%d\",\"images\":{\"low_resolution\":{\"url\":\"http://scontent-b.cdninstagram.com/hphotos-xfa1/t51.2885-15/10932341_1042561312426099_2095600846_a.jpg\",\"width\":306,\"height\":306},\"thumbnail\":{\"url\":\"http://scontent-b.cdninstagram.com/hphotos-xfa1/t51.2885-15/10932341_1042561312426099_2095600846_s.jpg\",\"width\":150,\"height\":150},\"standard_resolution\":{\"url\":\"%@\",\"width\":480,\"height\":320}},\"users_in_photo\":[  ],\"caption\":{\"created_time\":\"%lld\"},\"user_has_liked\":false,\"id\":\"%@\",\"user\":{%@}}",commetnsString,seconds,[[photo getServerPhoto] getGlobalGlanceScore],new,seconds,[[photo getServerPhoto]getId],userData] dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableArray * arr = [[NSMutableArray alloc] init];
    NSMutableDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:objectData options:kNilOptions error:nil];
    
    
    [arr addObject:dictionary];
    [arr addObject:photo];
    
    [self.posts addObject:arr];
    
    NSArray* reversedArray = [[self.posts reverseObjectEnumerator] allObjects];
    
    self.posts = [reversedArray copy];
    
    [self.tableView reloadData];
    
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


- (void)setImageURL:(NSURL *)url cell:(GLFeedTableCell*)cell {
    cell.label.hidden = YES;
    cell.indicator.hidden = NO;
    [cell.indicator startAnimating];
    __weak typeof(cell) _self = cell;
    
    [CATransaction begin];
    [CATransaction setDisableActions: YES];
    cell.progressLayer.hidden = YES;
    cell.progressLayer.strokeEnd = 0;
    [CATransaction commit];
    
    [cell.postImage yy_setImageWithURL:url
                           placeholder:nil
                               options:YYWebImageOptionProgressiveBlur | YYWebImageOptionShowNetworkActivity | YYWebImageOptionSetImageWithFadeAnimation
                              progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                  if (expectedSize > 0 && receivedSize > 0) {
                                      CGFloat progress = (CGFloat)receivedSize / expectedSize;
                                      progress = progress < 0 ? 0 : progress > 1 ? 1 : progress;
                                      if (_self.progressLayer.hidden) _self.progressLayer.hidden = NO;
                                      _self.progressLayer.strokeEnd = progress;
                                  }
                              }
                             transform:nil
                            completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
                                if (stage == YYWebImageStageFinished) {
                                    _self.progressLayer.hidden = YES;
                                    [_self.indicator stopAnimating];
                                    _self.indicator.hidden = YES;
                                    if (!image) _self.label.hidden = NO;
                                }
                            }];
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GLFeedTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GLFeedCell" forIndexPath:indexPath];
    if(cell==nil){
        
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"GLFeedTableCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    
    
    cell.tag = indexPath.row;
    NSArray * tempDict = [self.posts objectAtIndex:indexPath.row];
    
    SLAlbumPhoto *photo = [tempDict objectAtIndex:1];
    
    long long userID = [[[[tempDict objectAtIndex:0] objectForKey:@"user"] objectForKey:@"id"] longLongValue];
    
    
    if([[photo getServerPhoto] getMediaType] == [SLMediaTypeEnum VIDEO]){
        
        SLAlbumServerVideo * video = [[photo getServerPhoto] getVideo];
        
        //        [cell.postImage yy_setImageWithURL:[NSURL URLWithString:[video getVideoThumbnailUrl]] placeholder:[UIImage imageNamed:@""]];
        
        //        [cell.postImage yy_setImageWithURL:[NSURL URLWithString:[video getVideoThumbnailUrl]]  placeholder:[UIImage imageNamed:@""] options:YYWebImageOptionProgressiveBlur | YYWebImageOptionShowNetworkActivity | YYWebImageOptionSetImageWithFadeAnimation completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
        //
        //        }];
        
        [self setImageURL:[NSURL URLWithString:[video getVideoThumbnailUrl]] cell:cell];
        
        cell.videoBadge.alpha = 1;
        
        [[GLSharedVideoPlayer sharedInstance] attachToView:cell.moviePlayer withPhotoId:[[photo getServerPhoto]getId] withVideoUrl:[video getVideoUrl] videoThumbNail:cell.postImage.image tableCell:cell];
        [cell.activityIndicator startAnimating];
        
        
        
    } else {
        
        [self setImageURL:[NSURL URLWithString:[[[[tempDict objectAtIndex:0] objectForKey:@"images"] objectForKey:@"standard_resolution"] objectForKey:@"url"]]  cell:cell];
    }
    cell.profileImageView.clipsToBounds = YES;
    [cell.profileImageView yy_setImageWithURL:[NSURL URLWithString:[[[tempDict objectAtIndex:0] objectForKey:@"user"] objectForKey:@"profile_picture"]]  placeholder:[UIImage imageNamed:@""] options:YYWebImageOptionProgressiveBlur | YYWebImageOptionShowNetworkActivity | YYWebImageOptionSetImageWithFadeAnimation completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
        
    }];
    cell.userName.text = [[[tempDict objectAtIndex:0] objectForKey:@"user"] objectForKey:@"username"];
    cell.postedTime.text = [NSString stringWithFormat:@"%@ ago",[[[NSDate alloc] initWithTimeIntervalSince1970:[[[tempDict objectAtIndex:0] objectForKey:@"created_time"] longLongValue]] distanceOfTimeInWords:[NSDate date] shortStyle:YES]];
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
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doSingleTap:)];
    singleTap.numberOfTapsRequired = 1;
    [cell.glanceUpButton addGestureRecognizer:singleTap];
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doDoubleTap:)] ;
    doubleTap.numberOfTapsRequired = 1;
    [cell.glanceDownButton addGestureRecognizer:doubleTap];
    UITapGestureRecognizer *showActionSheetGest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showActionSheets:)];
    showActionSheetGest.numberOfTapsRequired = 1;
    [cell.feed3DotsButton addGestureRecognizer:showActionSheetGest];
    UITapGestureRecognizer *showUserProfileTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showUserProfile:)];
    UITapGestureRecognizer *showUserProfileTap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showUserProfile2:)];
    cell.profileImageView.userInteractionEnabled = YES;
    cell.userName.userInteractionEnabled = YES;
    [cell.profileImageView addGestureRecognizer:showUserProfileTap];
    [cell.userName addGestureRecognizer:showUserProfileTap2];
    [cell.feed3DotsButton addGestureRecognizer:showActionSheetGest];
    cell.commentTextField.delegate = self;
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
    return cell;
}

-(void)showUserProfileWithId:(long long)userId {
    [KVNProgress showWithStatus:@"Loading Profile.." onView:[[ShotVibeAppDelegate sharedDelegate] window]];    GLProfilePageViewController * profilePage = [[GLProfilePageViewController alloc] init];
    profilePage.albumId = self.albumId;
    profilePage.userId = userId;
       profilePage.fromPublicFeed = YES;
    UINavigationController * nav = [[UINavigationController alloc] initWithRootViewController:profilePage];
    
    profilePage.title = @"User Profile";
    profilePage.navigationItem.leftBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"< Back"
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(hideProfilePage)];
    
    [self presentViewController:nav animated:YES completion:^{
        [KVNProgress dismiss];
        //
    }];
}

-(void) hideProfilePage {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)showUserProfile2:(UITapGestureRecognizer*)gest {
    [self showUserProfileWithId:gest.view.tag];
}

-(void)showUserProfile:(UITapGestureRecognizer*)gest {
    [self showUserProfileWithId:gest.view.tag];
}

-(void)showActionSheets:(UITapGestureRecognizer*)gest {

    SLAlbumPhoto * photo = [[self.posts objectAtIndex:0] objectAtIndex:1];
    NSString *destructiveTitle = @"";
    if([[photo getServerPhoto] getMediaType] == [SLMediaTypeEnum VIDEO]){
        destructiveTitle = @"Delete Video"; //Action Sheet Button Titles
    } else {
        destructiveTitle = @"Delete Photo";
    }
    NSString *other1 = @"Share";
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
                    NSMutableArray *photosToDelete = [[NSMutableArray alloc] init];
                    [photosToDelete addObject:[[photo getServerPhoto] getId]];
                    [self dismissViewControllerAnimated:YES completion:nil];
                    [[albumManager_ getShotVibeAPI] deletePhotosWithJavaLangIterable:[[SLArrayList alloc] initWithInitialArray:photosToDelete]];
                    return nil;
                } onTaskComplete:^(id dummy) {
                    [KVNProgress dismiss];
                    
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
    
    GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:gest.view.tag inSection:0]];
    [ShotVibeAPITask runTask:self withAction:^id{
        [[albumManager_ getShotVibeAPI] setPhotoMyGlanceScoreDeltaWithNSString:cell.photoId withInt:1];
        return nil;
    } onTaskComplete:^(id dummy) {
        [KVNProgress dismiss];
        [self updateData];
    }];
    
    
    [UIView animateWithDuration:0.2 animations:^{
        cell.glanceUpButton.transform = CGAffineTransformScale(cell.glanceUpButton.transform, 2.0, 2.0);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            cell.glanceUpButton.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {

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
        return nil;
    } onTaskComplete:^(id dummy) {
        [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
        [UIView animateWithDuration:0.2 animations:^{

        } completion:^(BOOL finished) {
            [KVNProgress dismiss];
            
            
        }];
        
        [self updateData];
    }];
    
    [UIView animateWithDuration:0.2 animations:^{
        cell.glanceDownButton.transform = CGAffineTransformScale(cell.glancesIcon.transform, 2.5, 2.5);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            cell.glanceDownButton.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            
        }];
    }];
    
    
    
}

-(void)updateData {
    
    [ShotVibeAPITask runTask:self withAction:^id{
        return [[albumManager_ getShotVibeAPI] getPublicAlbumContents];
    } onTaskComplete:^(SLAlbumContents *album) {
            for(SLAlbumPhoto * photo in [album getPhotos]){
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
                }
                
                NSString * userData = [NSString stringWithFormat:@"\"username\":\"%@\",\"website\":\"\",\"profile_picture\":\"%@\",\"full_name\":\"%@\",\"bio\":\"\",\"id\":\"%lld\"",[[[photo getServerPhoto] getAuthor] getMemberNickname],[[[photo getServerPhoto] getAuthor] getMemberAvatarUrl],[[[photo getServerPhoto] getAuthor] getMemberNickname],[[[photo getServerPhoto] getAuthor] getMemberId]];
                long long seconds = [[[photo getServerPhoto] getDateAdded] getTimeStamp] / 1000000LL;
                NSString *new = [[[photo getServerPhoto]getUrl] stringByReplacingOccurrencesOfString:@".jpg" withString:@"_thumb75.jpg"];
                NSString * commetnsString = [NSString stringWithFormat:@"\"count\": %f,\"data\": [%@]",commentsCount,commentsFullString];
                NSData *objectData = [[NSString stringWithFormat:@"{\"attribution\":null,\"tags\":[],\"type\":\"image\",\"location\":null,\"comments\":{%@},\"filter\":\"Normal\",\"created_time\":\"%lld\",\"link\":\"http://instagram.com/p/xtfQ81gK0E/\",\"likes\":\"%d\",\"images\":{\"low_resolution\":{\"url\":\"http://scontent-b.cdninstagram.com/hphotos-xfa1/t51.2885-15/10932341_1042561312426099_2095600846_a.jpg\",\"width\":306,\"height\":306},\"thumbnail\":{\"url\":\"http://scontent-b.cdninstagram.com/hphotos-xfa1/t51.2885-15/10932341_1042561312426099_2095600846_s.jpg\",\"width\":150,\"height\":150},\"standard_resolution\":{\"url\":\"%@\",\"width\":480,\"height\":320}},\"users_in_photo\":[  ],\"caption\":{\"created_time\":\"%lld\"},\"user_has_liked\":false,\"id\":\"%@\",\"user\":{%@}}",commetnsString,seconds,[[photo getServerPhoto] getGlobalGlanceScore],new,seconds,[[photo getServerPhoto]getId],userData] dataUsingEncoding:NSUTF8StringEncoding];
                NSMutableArray * arr = [[NSMutableArray alloc] init];
                NSMutableDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:objectData options:kNilOptions error:nil];
                [arr addObject:dictionary];
                [arr addObject:photo];
                [self.posts addObject:arr];
                NSArray* reversedArray = [[self.posts reverseObjectEnumerator] allObjects];
                self.posts = [reversedArray copy];
                [self.tableView reloadData];
                [KVNProgress dismiss];
                break;
            }
        }
    }];
}

-(void)sharePostPressed:(UIButton*)sender {
    
    GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:sender.tag inSection:0]];
    [self closePressed];
    [[GLContainersViewController sharedInstance] resetFriendsView];
    
    [[GLContainersViewController sharedInstance] goToFriendsListViewAnimatedBeforeMovingPhoto:NO photoId:cell.photoId completed:nil];
//    [[GLContainersViewController sharedInstance] goToFriendsListViewAnimatedBeforeMovingPhoto:YES photoId:[[self.singleAlbumPhoto getServerPhoto] getId] completed:^{
//        [[GLSharedCamera sharedInstance] setCameraInFeed];
//        [[GLSharedCamera sharedInstance] setInFeedMode:YES dmutNeedTransform:YES];
//    }];
}

-(void)abortCommentPressed:(UIButton*)sender {
    
    
    GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:sender.tag inSection:0]];
    commentingNow = NO;
    [cell abortCommentDidPressed];
}

-(void)keyBoardBackSpacePressed:(UIButton*)sender {
    GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:sender.tag inSection:0]];
    [[cell keyboard] backSpacePressed];
}

-(void)commentSubmitPressed:(UIButton *)sender {
    
    GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:sender.tag inSection:0]];
    if([cell.keyboard.textField.text isEqualToString:@""]){
        [KVNProgress showErrorWithStatus:@"Comment can't be empty" completion:^{
        }];
    } else {
        long long milliseconds = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
        NSString * stringForComment = cell.keyboard.textField.text;
        [cell abortCommentDidPressed];
        [ShotVibeAPITask runTask:self withAction:^id{
            [[albumManager_ getShotVibeAPI]postPhotoCommentWithNSString:cell.photoId withNSString:stringForComment withLong:milliseconds];
            return nil;
        } onTaskComplete:^(id dummy) {
            [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
            [self loadFeed];
            [self updateData];
            commentingNow = NO;
            [KVNProgress dismiss];
        } onTaskFailure:
         ^(id failure) {
             [KVNProgress showErrorWithStatus:@"Somthing went wrong"];
         }  withLoaderIndicator:NO];
    }
}

-(void)addCommentTapped:(UIButton*)sender {
    
    commentingNow = YES;
    NSLog(@"the photo id is %lld",(long long)sender.tag);
    GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:sender.tag inSection:0]];
    
    cell.commentTextField.delegate = self;
    [cell.abortCommentButton addTarget:self action:@selector(abortCommentPressed:) forControlEvents:UIControlEventTouchUpInside];
    cell.abortCommentButton.tag = 0;
    [cell.backSpaceKeyBoardButton addTarget:self action:@selector(keyBoardBackSpacePressed:) forControlEvents:UIControlEventTouchUpInside];
    cell.backSpaceKeyBoardButton.tag = 0;
    [cell.submitCommentButton addTarget:self action:@selector(commentSubmitPressed:) forControlEvents:UIControlEventTouchUpInside];
    cell.submitCommentButton.tag = 0;
    [cell showCommentAreaAndKeyBoard];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField*)textField {
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[UIScreen mainScreen] bounds].size.height*0.88;
}

@end
