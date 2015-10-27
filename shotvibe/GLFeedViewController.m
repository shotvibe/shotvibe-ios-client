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

#import "UIImageView+Masking.h"
#import "SDWebImageManager.h"

#import "UIImageView+WebCache.h"

#import "PhotoImageView.h"
#import "GLSharedCamera.h"



@interface GLFeedViewController () <SLAlbumManager_AlbumContentsListener,SLAlbumManager_AlbumContentsListener, UIAlertViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate,UIGestureRecognizerDelegate, GLSharedCameraDelegatte> {
    
    SLAlbumManager *albumManager_;
    PhotoFilesManager *photoFilesManager_;
    ImageDiskCache *imageDiskCache_;
    SLAlbumContents *albumContents;
    UIImage * uploadingImage;
    
}

@end

@implementation GLFeedViewController  {

    
    

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.tableView.scrollsToTop = YES;
    [self.tableView setContentInset:UIEdgeInsetsMake(60,0,0,0)];
    
    photoFilesManager_ = [ShotVibeAppDelegate sharedDelegate].photoFilesManager;
    
    albumManager_ = [ShotVibeAppDelegate sharedDelegate].albumManager;
    
    imageDiskCache_ = [[ImageDiskCache alloc] initWithRefreshHandler:^{
        [self.tableView reloadData];
    }];
    
    
    
    UINib *feedPhotoCellNib = [UINib nibWithNibName:@"GLFeedTableCell" bundle:nil];
    [self.tableView registerNib:feedPhotoCellNib forCellReuseIdentifier:@"GLFeedCell"];
    
    [self loadFeed];
    
    UIScreenEdgePanGestureRecognizer * swipeScreen = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(screenSwiped:)];
    
    swipeScreen.minimumNumberOfTouches = 1;
    swipeScreen.maximumNumberOfTouches = 1;
    swipeScreen.edges = UIRectEdgeLeft;
    swipeScreen.delegate = self;
    
    [self.view addGestureRecognizer:swipeScreen];
    
    ((SVSidebarManagementController *)self.menuContainerViewController.leftMenuViewController).parentController = self;
    ((SVSidebarMemberController *)self.menuContainerViewController.rightMenuViewController).parentController = self;
    
    self.menuContainerViewController.panMode = MFSideMenuPanModeCenterViewController;
    
    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
    glcamera.delegate = self;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
- (BOOL)screenSwiped:(UIScreenEdgePanGestureRecognizer *)gest {
    
    
    [self.navigationController popViewControllerAnimated:YES];
    return  YES;
    
}

- (void)openAppleImagePicker {
    
    
    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    //    glcamera.delegate = self;
    
    //    glcamera.delegate
    //     glcamera.imagePickerDelegate = picker.delegate;
    picker.delegate = self;
    
    
    //    fromImagePicker = YES;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:^{
        
        //        [appDelegate.window sendSubviewToBack:glcamera.view];
        
        [UIView animateWithDuration:0.3 animations:^{
            glcamera.view.alpha = 0;
            [glcamera hideForPicker:YES];
        }];
    }];
    
    
    
    
    
}

-(void)imageSelected:(UIImage*)image {
    
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
                    
                    RCLog(@"====================== 1. Upload selected photos to albumId %lli", self.albumId);
                    
                    // Upload the taken photos
                    
                    TmpFilePhotoUploadRequest *photoUploadRequest = [[TmpFilePhotoUploadRequest alloc] initWithTmpFile:filePath];
                    //            [photoUploadRequests addObject:photoUploadRequest];
                    
                    [albumManager_ uploadPhotosWithLong:self.albumId
                                       withJavaUtilList:[[SLArrayList alloc]
                                                         initWithInitialArray:[NSMutableArray arrayWithObject:photoUploadRequest]]];
                    
                }
                
                //                }];
                
            });
            
            
        } else {
            
            NSLog(@"file wasnt saved correctly !!! isnt found on path!");
            
        }
        
        
        
        
    });
    
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
    
    // This will be notified when the Dynamic Type user setting changes (from the system Settings app)
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentSizeCategoryChanged:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    
//    if ([self.posts count] == 0) {
//        //        [self.activityIndicatorView startAnimating];
//    }
    
    [self.menuContainerViewController.view setFrame:[[UIScreen mainScreen] bounds]];
//    [self didRotateFromInterfaceOrientation:UIInterfaceOrientationPortrait];
    
    
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
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
    
    [self clearNewPhotoBadges:albumContents];
    
    [albumManager_ removeAlbumContentsListenerWithLong:self.albumId withSLAlbumManager_AlbumContentsListener:self];
}

- (void)onAlbumContentsNewContentWithLong:(long long int)albumId
                      withSLAlbumContents:(SLAlbumContents *)album
{
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
    
    
    
    
    
    
    
    for (SLAlbumPhoto *photo in [albumContents getPhotos].array) {
        
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
        
        NSString *new = [[[photo getServerPhoto]getUrl] stringByReplacingOccurrencesOfString:@".jpg" withString:@"_r_wvga.jpg"];
        
        
        //        NSString * commentsDataString = [NSString stringWithFormat:<#(nonnull NSString *), ...#>];
        NSString * commetnsString = [NSString stringWithFormat:@"\"count\": %f,\"data\": [%@]",commentsCount,commentsFullString];
        
        NSData *objectData = [[NSString stringWithFormat:@"{\"attribution\":null,\"tags\":[],\"type\":\"image\",\"location\":null,\"comments\":{%@},\"filter\":\"Normal\",\"created_time\":\"%lld\",\"link\":\"http://instagram.com/p/xtfQ81gK0E/\",\"likes\":{  },\"images\":{\"low_resolution\":{\"url\":\"http://scontent-b.cdninstagram.com/hphotos-xfa1/t51.2885-15/10932341_1042561312426099_2095600846_a.jpg\",\"width\":306,\"height\":306},\"thumbnail\":{\"url\":\"http://scontent-b.cdninstagram.com/hphotos-xfa1/t51.2885-15/10932341_1042561312426099_2095600846_s.jpg\",\"width\":150,\"height\":150},\"standard_resolution\":{\"url\":\"%@\",\"width\":480,\"height\":320}},\"users_in_photo\":[  ],\"caption\":{\"created_time\":\"%lld\"},\"user_has_liked\":false,\"id\":\"%@\",\"user\":{%@}}",commetnsString,seconds,new,seconds,[[photo getServerPhoto]getId],userData] dataUsingEncoding:NSUTF8StringEncoding];
        
        //            UIImageView * t = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        //            [t.networkImageView setPhoto:[[photo getServerPhoto] getId]
        //                                   photoUrl:[[photo getServerPhoto] getUrl]
        //                                  photoSize:[PhotoSize Thumb75]
        //                                    manager:photoFilesManager_];
        
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:objectData options:kNilOptions error:nil];
        
//        [dictionary setValue:photo forKey:@"slPhoto"];
//        [dictionary]
        
//        STXPost *post = [[STXPost alloc] initWithDictionary:dictionary];
//        post.slPhoto = photo;
        [self.posts addObject:dictionary];
        
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
    
    NSDictionary * tempDict = [self.posts objectAtIndex:indexPath.row];
    
//    SLAlbumPhoto * slPhoto = [tempDict objectForKey:@"slPhoto"];
//    cell
//    if(!cell.loaded){
        cell.profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 60, 60)];
        cell.profileImageView.backgroundColor = [UIColor redColor];
        //    profileImageView.layer.cornerRadius = 30;
        
        
        [cell.profileImageView setCircleImageWithURL:[NSURL URLWithString:[[tempDict objectForKey:@"user"] objectForKey:@"profile_picture"]] placeholderImage:[UIImage imageNamed:@"ProfilePlaceholder"] borderWidth:2];
        //    profileImageView setp
        [cell addSubview:cell.profileImageView];
    
//    for (NSString* family in [UIFont familyNames])
//    {
//        NSLog(@"%@", family);
//        
//        for (NSString* name in [UIFont fontNamesForFamilyName: family])
//        {
//            NSLog(@"  %@", name);
//        }
//    }
    
    
        cell.userName = [[UILabel alloc] initWithFrame:CGRectMake(80, 10, [[UIScreen mainScreen] bounds].size.width*0.5, 60)];
        cell.userName.text = [[tempDict objectForKey:@"user"] objectForKey:@"username"];
        cell.userName.backgroundColor = [UIColor whiteColor];
        cell.userName.textColor = UIColorFromRGB(0x626262);
        cell.userName.font = [UIFont fontWithName:@"GothamRounded-Book" size:16];
        [cell addSubview:cell.userName];
        
        cell.postedTime = [[UILabel alloc] initWithFrame:CGRectMake(cell.userName.frame.size.width+cell.userName.frame.origin.x+10, 10, [[UIScreen mainScreen] bounds].size.width*0.22, 60)];
        cell.postedTime.backgroundColor = [UIColor whiteColor];
        cell.postedTime.text = [NSString stringWithFormat:@"%@ ago",[[[NSDate alloc] initWithTimeIntervalSince1970:[[tempDict objectForKey:@"created_time"] longLongValue]] distanceOfTimeInWords:[NSDate date] shortStyle:YES]];
        cell.postedTime.textAlignment = NSTextAlignmentRight;
    cell.postedTime.font = [UIFont fontWithName:@"GothamRounded-Book" size:16];
    cell.postedTime.textColor = UIColorFromRGB(0x626262);
        
        [cell addSubview:cell.postedTime];
        
        cell.postImage = [[PhotoView alloc] initWithFrame:CGRectMake(0, 80, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height*0.75)];
    cell.postedTime.contentMode = UIViewContentModeScaleAspectFill;
        cell.postImage.backgroundColor = [UIColor blueColor];
        
        [cell.postImage setPhoto:[tempDict objectForKey:@"id"]
                        photoUrl:[[tempDict objectForKey:@"user"] objectForKey:@"username"]
                       photoSize:photoFilesManager_.DeviceDisplayPhotoSize
                         manager:photoFilesManager_];
        
        
        [cell addSubview:cell.postImage];
    
    
        NSMutableArray * commentsArray = [[NSMutableArray alloc] init];
        commentsArray = [[tempDict objectForKey:@"comments"] objectForKey:@"data"];
    
    
    cell.photoId = [tempDict objectForKey:@"id"];
    
    UIView * postPannelWrapper = [[UIView alloc] initWithFrame:CGRectMake(0, (cell.postImage.frame.origin.y+cell.postImage.frame.size.height)-cell.postImage.frame.size.height*0.3, [[UIScreen mainScreen] bounds].size.width, cell.postImage.frame.size.height*0.3)];
    
    UIView * commentScrollBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, cell.postImage.frame.size.height*0.3)];
    commentScrollBgView.backgroundColor = [UIColor blackColor];
    commentScrollBgView.alpha = 0.5;
    
    
    
    
    cell.commentsScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 65, [[UIScreen mainScreen] bounds].size.width, 69)];
    cell.commentsScrollView.pagingEnabled = YES;
    cell.commentsScrollView.backgroundColor = [UIColor clearColor];
    cell.commentsScrollView.contentSize = CGSizeMake(self.view.frame.size.width, [commentsArray count]*23);
    
    UIButton * addCommentButton = [[UIButton alloc] initWithFrame:CGRectMake(23, 33, 25, 25)];
    [addCommentButton setBackgroundImage:[UIImage imageNamed:@"PostAddCommentIcon"] forState:UIControlStateNormal];
    [addCommentButton addTarget:self action:@selector(addCommentTapped:) forControlEvents:UIControlEventTouchUpInside];
    addCommentButton.tag = indexPath.row;//[[tempDict objectForKey:@"id"] longLongValue];

    
    cell.glancesCounter = [[UILabel alloc] initWithFrame:CGRectMake(addCommentButton.frame.origin.x+addCommentButton.frame.size.width, 26, 45, 35)];
    cell.glancesCounter.backgroundColor = [UIColor clearColor];
    cell.glancesCounter.text = @"5";
    cell.glancesCounter.textAlignment = NSTextAlignmentCenter;
    cell.glancesCounter.textColor = [UIColor whiteColor];
    cell.glancesCounter.font = [UIFont fontWithName:@"GothamRounded-Book" size:42];
    
    UIButton * postForwardButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-40, 28, 25, 25)];
    [postForwardButton setBackgroundImage:[UIImage imageNamed:@"PostForwardIcon"] forState:UIControlStateNormal];
    
    
    cell.commentTextField = [[UITextField alloc] initWithFrame:CGRectMake(addCommentButton.frame.origin.x+addCommentButton.frame.size.width+10,cell.glancesCounter.frame.origin.y+2, 0,35)];
    cell.commentTextField.borderStyle = UITextBorderStyleRoundedRect;
    cell.commentTextField.font = [UIFont systemFontOfSize:15];
    cell.commentTextField.placeholder = @"C'mon say somthing";
//    cell.commentTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    cell.commentTextField.keyboardType = UIKeyboardTypeDefault;
    cell.commentTextField.returnKeyType = UIReturnKeyDone;
//    cell.commentTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
//    cell.commentTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    cell.commentTextField.delegate = self;
//    cell.commentTextField
    cell.commentTextField.tag = indexPath.row;
    cell.commentTextField.keyboardAppearance = UIKeyboardAppearanceDark;
    
    
    [postPannelWrapper addSubview:commentScrollBgView];
    [cell addSubview:postPannelWrapper];
    [postPannelWrapper addSubview:cell.commentsScrollView];
    [postPannelWrapper addSubview:cell.commentTextField];
    [postPannelWrapper addSubview:cell.glancesCounter];
    [postPannelWrapper addSubview:postForwardButton];
    [postPannelWrapper addSubview:addCommentButton];
    
        
    
    
    
        
        int c = 0;
        
        for(NSDictionary * comment in commentsArray){
            NSLog(@"%@",[comment objectForKey:@"text"]);
            
            
            
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
            
            
//            commentAuthor.textAlignment = NSTextAlignmentRight;
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
    
        if([commentsArray count] > 3){
        
            CGPoint bottomOffset = CGPointMake(0, cell.commentsScrollView.contentSize.height - cell.commentsScrollView.bounds.size.height);
            [cell.commentsScrollView setContentOffset:bottomOffset animated:NO];
        
        } else {
        
            cell.commentsScrollView.scrollEnabled = NO;
        
        }
    
    
        
        cell.loaded = YES;
//    }
    
    
    // Configure the cell...
    
    return cell;
}
- (void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated {
    
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
//        [self.tableView reloadData];
        [ShotVibeAPITask runTask:self withAction:^id{
            [[albumManager_ getShotVibeAPI]postPhotoCommentWithNSString:cell.photoId withNSString:textField.text withLong:milliseconds];
            return nil;
        } onTaskComplete:^(id dummy) {
            
            [UIView animateWithDuration:0.2 animations:^{
//                commentsDialog.alpha = 0;
            } completion:^(BOOL finished) {
//                [commentsDialog removeFromSuperview];
                [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
//                textField.text = @"";
            }];
        }];
        
    }
    
    
//    [self setEditing:NO];
    [self resignFirstResponder];
    return YES;
}

-(void)addCommentTapped:(UIButton*)sender {
    
    NSLog(@"the photo id is %lld",(long long)sender.tag);
    GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:sender.tag inSection:0]];
    
    [UIView animateWithDuration:0.2 animations:^{
        
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
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:<#@"Nib name"#> bundle:nil];
    
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
