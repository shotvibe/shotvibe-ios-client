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

#import "YALSunnyRefreshControl.h"
#import "LNNotificationsUI.h"

//#import "ParallaxHeaderView.h"
#import "GLProfileViewController.h"
#import "ContainerViewController.h"

@interface GLFeedViewController () <SLAlbumManager_AlbumContentsListener,SLAlbumManager_AlbumContentsListener, UIAlertViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate,UIGestureRecognizerDelegate, GLSharedCameraDelegatte> {
    
    SLAlbumManager *albumManager_;
    PhotoFilesManager *photoFilesManager_;
    ImageDiskCache *imageDiskCache_;
    SLAlbumContents *albumContents;
    UIImage * uploadingImage;
    BOOL membersOpened;
    NSMutableArray * postsAsSLPhotos;
    
//    YALSunnyRefreshControl *sunnyRefreshControl;
}

@end

@implementation GLFeedViewController  {

    
    

}

-(void)sunnyControlDidStartAnimation{
    
    // start loading something
//    [self loadFeed];
    
}
//-(void)en{

//}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    membersOpened = NO;
    
    
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
    
    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
//    glcamera.delegate = self;
//
    
//    sunnyRefreshControl = [YALSunnyRefreshControl attachToScrollView:self.tableView
//                                                              target:self
//                                                       refreshAction:@selector(sunnyControlDidStartAnimation)];
    
    [self.tableView setContentInset:UIEdgeInsetsMake(60,0,0,0)];
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

-(void)startUploadFromOutSide:(NSNotification*)not {


    NSLog(@"im gone start upload");


}

-(void)commentPushPressed:(SLNotificationMessage_PhotoComment *)msg {

    
    
    
    NSLog(@"comment retrieved");
    int c = 0;
    int position = 0;
    for(NSDictionary * post in self.posts){
        if([[post objectForKey:@"id"] isEqualToString:[msg getPhotoId]]){
            position = c;
            NSLog(@"i found the commented image in the table at %d",c);
            [self.tableView scrollToRowAtIndexPath:
             [NSIndexPath indexPathForRow:c inSection:0]
                                  atScrollPosition:UITableViewScrollPositionTop
                                          animated:YES];
            break;
        }
        c++;
    }
    
    
//    for(GLFeedTableCell * cell in self.tableView.c){
//        if([cell isKindOfClass:[GLFeedTableCell class]]){
//            if([cell.photoId isEqualToString:[msg getPhotoId]]){
////                NSLog(@"i found the commented image in the table");
//            }
//        }
//    }
    
//    [msg getPhotoId];

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
    
    
    if([self.posts count] > 0){
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
                    
                    RCLog(@"====================== 1. Upload selected photos to albumId %lli", self.albumId);
                    
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
    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
    glcamera.delegate = self;
    
    
    
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
    
    
    
    
    
    
    
    for (SLAlbumPhoto *photo in [albumContents getPhotos].array) {
        
        
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
        
        NSString *new = [[[photo getServerPhoto]getUrl] stringByReplacingOccurrencesOfString:@".jpg" withString:@"_r_wvga.jpg"];
        
        
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
    NSArray * tempDict = [self.posts objectAtIndex:indexPath.row];
    
    SLAlbumPhoto *photo = [tempDict objectAtIndex:1];
    
    
    
    if ([photo getUploadingPhoto]) {
        NSLog(@"aaa");
        [cell.profileImageView setImage:[UIImage imageNamed:@"CaptureButton"]];
        
        cell.userName.text = [NSString stringWithFormat:@"Uploading - %.f%% ",[[photo getUploadingPhoto] getUploadProgress] * 100];//@"Uploading";
        cell.postedTime.text = @"now";

        [cell.postImage setImage:uploadingImage];
//        [UIView animateWithDuration:0.5 animations:^{
//            cell.postImage.alpha = [[photo getUploadingPhoto] getUploadProgress];
//        }];
        
        
        
        cell.glancesCounter.text = [[tempDict objectAtIndex:0] objectForKey:@"likes"];
        
        
        cell.photoId = [[tempDict objectAtIndex:0] objectForKey:@"id"];
        
        
        cell.addCommentButton.tag = indexPath.row;//[[tempDict objectForKey:@"id"] longLongValue];
        
        
        
        cell.glancesIcon.tag = indexPath.row;
        
        [cell.postForwardButton addTarget:self action:@selector(sharePostPressed:) forControlEvents:UIControlEventTouchUpInside];
        cell.postForwardButton.tag = indexPath.row;
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doSingleTap:)];
        singleTap.numberOfTapsRequired = 1;
        //    singleTap
        [cell.glancesIcon addGestureRecognizer:singleTap];
        
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doDoubleTap:)] ;
        doubleTap.numberOfTapsRequired = 2;
        [cell.glancesIcon addGestureRecognizer:doubleTap];
        
        [singleTap requireGestureRecognizerToFail:doubleTap];
        
        //    [cell.glancesIcon addGestureRecognizer:<#(nonnull UIGestureRecognizer *)#>];
        
        
        cell.commentTextField.delegate = self;
        //    cell.commentTextField
        cell.commentTextField.tag = indexPath.row;
        
//        [cell.addCommentButton addTarget:self action:@selector(addCommentTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        
        
        
        

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
//            [cell.postImage sd_setImageWithURL:[NSURL URLWithString:[[[[tempDict objectAtIndex:0] objectForKey:@"images"] objectForKey:@"standard_resolution"] objectForKey:@"url"]]
//                              placeholderImage:uploadingImage completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
//                                  [UIView animateWithDuration:0.2 animations:^{
//                                      cell.postImage.alpha = 1;
//                                  }];
//                              }];
        
        
//        }
        
        SLAlbumPhoto * photo = [tempDict objectAtIndex:1];
        [cell.postImage setPhoto:[[photo getServerPhoto] getId] photoUrl:[[photo getServerPhoto] getUrl] photoSize:[PhotoSize FeedSize] manager:photoFilesManager_];
        
//        [cell.postImage setPhoto:<#(NSString *)#> photoUrl: objectForKey:@"url"]] photoSize:[PhotoSize FeedSize] manager:albumManager_]
    
//        }
    
        
    cell.glancesCounter.text = [[tempDict objectAtIndex:0] objectForKey:@"likes"];
    
    
    
    
    
        NSMutableArray * commentsArray = [[NSMutableArray alloc] init];
        commentsArray = [[[tempDict objectAtIndex:0] objectForKey:@"comments"] objectForKey:@"data"];
    
    
    cell.photoId = [[tempDict objectAtIndex:0] objectForKey:@"id"];
    
    
    cell.addCommentButton.tag = indexPath.row;//[[tempDict objectForKey:@"id"] longLongValue];

    [cell.postForwardButton addTarget:self action:@selector(sharePostPressed:) forControlEvents:UIControlEventTouchUpInside];
    cell.postForwardButton.tag = indexPath.row;
    
    cell.glancesIcon.tag = indexPath.row;
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doSingleTap:)];
    singleTap.numberOfTapsRequired = 1;
//    singleTap
    [cell.glancesIcon addGestureRecognizer:singleTap];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doDoubleTap:)] ;
    doubleTap.numberOfTapsRequired = 2;
    [cell.glancesIcon addGestureRecognizer:doubleTap];
    
    [singleTap requireGestureRecognizerToFail:doubleTap];
    
//    [cell.glancesIcon addGestureRecognizer:<#(nonnull UIGestureRecognizer *)#>];
    
    
    cell.commentTextField.delegate = self;
    //    cell.commentTextField
    cell.commentTextField.tag = indexPath.row;
    
    [cell.addCommentButton addTarget:self action:@selector(addCommentTapped:) forControlEvents:UIControlEventTouchUpInside];

    
    [cell.commentsScrollView removeFromSuperview];
    
    cell.commentsScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 65, [[UIScreen mainScreen] bounds].size.width, 69)];
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

-(void)doSingleTap:(UITapGestureRecognizer*)gest {

//    GLProfileViewController * st = [[GLProfileViewController alloc] init];
//    [self.navigationController pushViewController:st animated:YES];
    
    GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:gest.view.tag inSection:0]];
    
    
    [ShotVibeAPITask runTask:self withAction:^id{
        [[albumManager_ getShotVibeAPI] setPhotoMyGlanceScoreDeltaWithNSString:cell.photoId withInt:1];
//        [[albumManager_ getShotVibeAPI]postPhotoCommentWithNSString:cell.photoId withNSString:textField.text withLong:milliseconds];
        return nil;
    } onTaskComplete:^(id dummy) {
        
        [UIView animateWithDuration:0.2 animations:^{
            //                commentsDialog.alpha = 0;
            
        
            
            
        } completion:^(BOOL finished) {
            
            [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
    
        }];
    }];

    
    [UIView animateWithDuration:0.2 animations:^{
        cell.glancesIcon.transform = CGAffineTransformScale(cell.glancesIcon.transform, 1.5, 1.5);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            cell.glancesIcon.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            cell.glancesIcon.image = [UIImage imageNamed:@"glancesIconGlanced"];
            CATransition *transition = [CATransition animation];
            transition.duration = 0.3f;
            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            transition.type = kCATransitionFromRight;
            [cell.glancesIcon.layer addAnimation:transition forKey:nil];
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
        
        [UIView animateWithDuration:0.2 animations:^{
            //                commentsDialog.alpha = 0;
            
            
            
            
        } completion:^(BOOL finished) {
            
            [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
            
        }];
    }];
    
    [UIView animateWithDuration:0.2 animations:^{
        cell.glancesIcon.transform = CGAffineTransformScale(cell.glancesIcon.transform, 1.5, 1.5);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            cell.glancesIcon.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            cell.glancesIcon.image = [UIImage imageNamed:@"glancesIconUnGlanced"];
            CATransition *transition = [CATransition animation];
            transition.duration = 0.3f;
            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            transition.type = kCATransitionFromLeft;
            [cell.glancesIcon.layer addAnimation:transition forKey:nil];
        }];
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
    [self.navigationController popViewControllerAnimated:YES];
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
            
            [UIView animateWithDuration:0.2 animations:^{
//                commentsDialog.alpha = 0;
                
                cell.glancesIcon.alpha = 1;
                cell.commentTextField.text = @"";
                cell.commentTextField.frame = CGRectMake(cell.addCommentButton.frame.origin.x+cell.addCommentButton.frame.size.width+10,cell.glancesCounter.frame.origin.y+2, 0,35);
                
                cell.glancesCounter.frame = CGRectMake(cell.addCommentButton.frame.origin.x+cell.addCommentButton.frame.size.width, 26, 45, 35);
                
                
            } completion:^(BOOL finished) {
                
                [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
                [self.tableView setUserInteractionEnabled:YES];
//                textField.text = @"";
            }];
        }];
        
    }
    
    
//    [self setEditing:NO];
    
    return YES;
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
    
    
    [self.tableView setUserInteractionEnabled:NO];
    
    NSLog(@"the photo id is %lld",(long long)sender.tag);
    GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:sender.tag inSection:0]];
    
    [UIView animateWithDuration:0.2 animations:^{
        
        cell.glancesIcon.alpha = 0;
        
        cell.commentTextField.frame = CGRectMake(cell.commentTextField.frame.origin.x, cell.commentTextField.frame.origin.y, self.view.frame.size.width*0.60, cell.commentTextField.frame.size.height);
        
        cell.glancesCounter.frame = CGRectMake(cell.commentTextField.frame.origin.x+cell.commentTextField.frame.size.width, cell.glancesCounter.frame.origin.y, cell.glancesCounter.frame.size.width, cell.glancesCounter.frame.size.height);
    } completion:^(BOOL finished) {
        [cell.commentTextField becomeFirstResponder];
    }];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[UIScreen mainScreen] bounds].size.height*0.90;
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
