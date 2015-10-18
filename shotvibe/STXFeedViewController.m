//
//  STXFeedViewController.m
//
//  Created by Jesse Armand on 20/1/14.
//  Copyright (c) 2014 2359 Media. All rights reserved.
//

#import "STXFeedViewController.h"

#import "STXPost.h"
#import "STXLikesCell.h"
#import "STXUserActionCell.h"

#import "MFSideMenu.h"
#import "SVDefines.h"
#import "SVPhotoViewerController.h"
#import "SVSidebarMemberController.h"
#import "SVSidebarManagementController.h"
#import "SVSettingsViewController.h"

#import "ShotVibeAppDelegate.h"

#import "SVCameraNavController.h"
#import "SVPickerController.h"
#import "SVAlbumListViewController.h"

#import "SVCameraPickerController.h"
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

#import "TmpFilePhotoUploadRequest.h"

#define PHOTO_CELL_ROW 0

@interface STXFeedViewController () <STXFeedPhotoCellDelegate, STXLikesCellDelegate, STXCaptionCellDelegate, STXCommentCellDelegate, STXUserActionDelegate,SLAlbumManager_AlbumContentsListener, UIAlertViewDelegate,GLSharedCameraDelegatte,UIImagePickerControllerDelegate,UINavigationControllerDelegate> {

    
    SLAlbumContents *albumContents;
    
    
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) STXFeedTableViewDataSource *tableViewDataSource;
@property (strong, nonatomic) STXFeedTableViewDelegate *tableViewDelegate;

@end

@implementation STXFeedViewController {

    SLAlbumManager *albumManager_;
    PhotoFilesManager *photoFilesManager_;
    
    // TODO Should use a global ImageDiskCache
    ImageDiskCache *imageDiskCache_;

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

- (void)openAppleImagePicker {
    
    
    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    //    glcamera.delegate = self;
    
    //    glcamera.delegate
    //     glcamera.imagePickerDelegate = picker.delegate;
    picker.delegate = self;
    
    
    //    fromImagePicker = YES;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:^{
        ShotVibeAppDelegate *appDelegate = (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        
        
        
        //    [appDelegate.window addSubview:picker.view];
        
        //        [appDelegate.window bringSubviewToFront:picker.view];
        //        [appDelegate.window sendSubviewToBack:glcamera.view];
        
        [UIView animateWithDuration:0.3 animations:^{
            glcamera.view.alpha = 0;
        }];
    }];
    
    
    
    
    
}

-(void)imageSelected:(UIImage*)image {
    //
    //    [self dismissViewControllerAnimated:YES completion:nil];
    //
    //
    //    NSString *filePath = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/Library/Caches/Photo%i.jpg", 0]];
    //
    //    @autoreleasepool {
    //        CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:filePath];
    //        CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    //
    //        NSDictionary *properties = @{
    //                                     (__bridge NSString *)kCGImageDestinationLossyCompressionQuality: @(1.0)
    //                                     };
    //
    //        CGImageDestinationAddImage(destination, image.CGImage,(__bridge CFDictionaryRef)properties);
    //
    //        if (!CGImageDestinationFinalize(destination)){
    //            NSLog(@"ERROR saving: %@", url);
    //        } else {
    //            NSLog(@"SUCCESS saving: %@", url);
    //        }
    //
    //        CFRelease(destination);
    ////        CGImageRelease(image.CGImage);
    //    }
    
    
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


- (void)onAlbumContentsNewContentWithLong:(long long int)albumId
                      withSLAlbumContents:(SLAlbumContents *)album
{
    [self setAlbumContents:album];
    [self loadFeed];
}

- (void)setAlbumContents:(SLAlbumContents *)album
{
    albumContents = album;
    
    ((SVSidebarManagementController *)self.menuContainerViewController.leftMenuViewController).albumContents = albumContents;
    ((SVSidebarMemberController *)self.menuContainerViewController.rightMenuViewController).albumContents = albumContents;
    
    self.title = [albumContents getName];
//    [albumContents];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // First set all the fullscreen photos to download at high priority
        for (SLAlbumPhoto *p in [albumContents getPhotos]) {
            if ([p getServerPhoto]) {
                [photoFilesManager_ queuePhotoDownload:[[p getServerPhoto] getId]
                                              photoUrl:[[p getServerPhoto] getUrl]
                                             photoSize:photoFilesManager_.DeviceDisplayPhotoSize
                                          highPriority:YES];
            }
        }
        
        // Now set all the thumbnails to download at high priority, these will now be pushed to download before all of the previously queued fullscreen photos
        for (SLAlbumPhoto *p in [albumContents getPhotos].array) {
            if ([p getServerPhoto]) {
                [photoFilesManager_ queuePhotoDownload:[[p getServerPhoto] getId]
                                              photoUrl:[[p getServerPhoto] getUrl]
                                             photoSize:[PhotoSize Thumb75]
                                          highPriority:YES];
            }
        }
    }
                   
                   
                   );
    
//    [self sortThumbsBy:sort];
    [self.tableView reloadData];
//    [self updateEmptyState];
}


- (void)onAlbumContentsUploadsProgressedWithLong:(long long int)albumId
{
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    
    photoFilesManager_ = [ShotVibeAppDelegate sharedDelegate].photoFilesManager;
    
    albumManager_ = [ShotVibeAppDelegate sharedDelegate].albumManager;
    
    imageDiskCache_ = [[ImageDiskCache alloc] initWithRefreshHandler:^{
        [self.tableView reloadData];
    }];
    
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor orangeColor];
    
    
    [[GLSharedCamera sharedInstance] setDelegate:self];
    
//    NSMutableArray * ar = [NSMutableArray arrayWithArray:[albumContents getPhotos].array];
//    __block NSArray *arr = [sections objectForKey:sectionsKeys[indexPath.section]];
//    
//    [cell.networkImageView setImage:nil];
//    
//    SLAlbumPhoto *photo = [arr objectAtIndex:indexPath.row];
//
//    self.tableView = [[UITableView alloc]initWithFrame:self.view.frame];
//    self.tableView.backgroundColor = [UIColor purpleColor];
//    
    self.title = NSLocalizedString(@"Feed", nil);
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    STXFeedTableViewDataSource *dataSource = [[STXFeedTableViewDataSource alloc] initWithController:self tableView:self.tableView];
    self.tableView.dataSource = dataSource;
    self.tableViewDataSource = dataSource;
    
    STXFeedTableViewDelegate *delegate = [[STXFeedTableViewDelegate alloc] initWithController:self];
    self.tableView.delegate = delegate;
    self.tableViewDelegate = delegate;
    
    self.activityIndicatorView = [self activityIndicatorViewOnView:self.view];
    
    [self loadFeed];
}

- (void)dealloc
{
    // To prevent crash when popping this from navigation controller
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSLog(@"SVAlbumGridViewController %@: viewWillAppear: %d", self, animated);
    //
    SLAlbumContents *contents = [albumManager_ addAlbumContentsListenerWithLong:self.albumId withSLAlbumManager_AlbumContentsListener:self];
    [self setAlbumContents:contents];
    [self loadFeed];
    [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // This will be notified when the Dynamic Type user setting changes (from the system Settings app)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentSizeCategoryChanged:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    
    if ([self.tableViewDataSource.posts count] == 0) {
//        [self.activityIndicatorView startAnimating];
    }
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
    
    [self clearNewPhotoBadges:albumContents];
    
    [albumManager_ removeAlbumContentsListenerWithLong:self.albumId withSLAlbumManager_AlbumContentsListener:self];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)contentSizeCategoryChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
}

#pragma mark - Feed

- (void)loadFeed
{
    
    int counter = 0;
    
    NSMutableArray *posts = [NSMutableArray array];
    
    
    
    
    for (SLAlbumPhoto *photo in [albumContents getPhotos].array) {
        if ([photo getServerPhoto]) {
            counter++;
            
            NSString * userData = [NSString stringWithFormat:@"\"username\":\"%@\",\"website\":\"\",\"profile_picture\":\"%@\",\"full_name\":\"%@\",\"bio\":\"\",\"id\":\"%lld\"",[[[photo getServerPhoto] getAuthor] getMemberNickname],[[[photo getServerPhoto] getAuthor] getMemberAvatarUrl],[[[photo getServerPhoto] getAuthor] getMemberNickname],[[[photo getServerPhoto] getAuthor] getMemberId]];
            
            long long seconds = [[[photo getServerPhoto] getDateAdded] getTimeStamp] / 1000000LL;
//            NSDate *photoDateAdded = [[NSDate alloc] initWithTimeIntervalSince1970:seconds];
            
//            [album]
            
            NSString *new = [[[photo getServerPhoto]getUrl] stringByReplacingOccurrencesOfString:@".jpg" withString:@"_r_wvga.jpg"];
            
            NSData *objectData = [[NSString stringWithFormat:@"{\"attribution\":null,\"tags\":[],\"type\":\"image\",\"location\":null,\"comments\":{},\"filter\":\"Normal\",\"created_time\":\"%@\",\"link\":\"http://instagram.com/p/xtfQ81gK0E/\",\"likes\":{  },\"images\":{\"low_resolution\":{\"url\":\"http://scontent-b.cdninstagram.com/hphotos-xfa1/t51.2885-15/10932341_1042561312426099_2095600846_a.jpg\",\"width\":306,\"height\":306},\"thumbnail\":{\"url\":\"http://scontent-b.cdninstagram.com/hphotos-xfa1/t51.2885-15/10932341_1042561312426099_2095600846_s.jpg\",\"width\":150,\"height\":150},\"standard_resolution\":{\"url\":\"%@\",\"width\":480,\"height\":320}},\"users_in_photo\":[  ],\"caption\":{\"created_time\":\"%lld\"},\"user_has_liked\":false,\"id\":\"%@\",\"user\":{%@}}",[[photo getServerPhoto]getDateAdded],new,seconds,[[photo getServerPhoto]getId],userData] dataUsingEncoding:NSUTF8StringEncoding];
            
//            UIImageView * t = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
//            [t.networkImageView setPhoto:[[photo getServerPhoto] getId]
//                                   photoUrl:[[photo getServerPhoto] getUrl]
//                                  photoSize:[PhotoSize Thumb75]
//                                    manager:photoFilesManager_];
            
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:objectData options:kNilOptions error:nil];
            

                STXPost *post = [[STXPost alloc] initWithDictionary:dictionary];
                [posts addObject:post];
            
            if(counter == 20){
                break;
            }

        }
        
        
    }
//    [posts reverseObjectEnumerator]
//    
//    NSArray * photosArray = [NSArray arrayWithArray:[albumContents getPhotos].array];
//    int limit = 20;
//    
//    if([photosArray count] < 20){
//        limit = [photosArray count];
//    }
    
//    NSArray *smallArray = [posts subarrayWithRange:NSMakeRange(0, limit)];
    NSArray* reversedArray = [[posts reverseObjectEnumerator] allObjects];
    
    self.tableViewDataSource.posts = [reversedArray copy];
    
    [self.tableView reloadData];
    
    
    
//    NSString *feedPath = [[NSBundle mainBundle] pathForResource:@"instagram_media_popular" ofType:@"json"];
//    
//    NSError *error;
//    NSData *jsonData = [NSData dataWithContentsOfFile:feedPath options:NSDataReadingMappedIfSafe error:&error];
//    if (jsonData) {
//        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
//        if (error) {
//            UALog(@"%@", error);
//        }
//        
//        NSDictionary *instagramPopularMediaDictionary = jsonObject;
//        if (instagramPopularMediaDictionary) {
//            NSArray *mediaDataArray = [instagramPopularMediaDictionary valueForKey:@"data"];
//            
//            NSMutableArray *posts = [NSMutableArray array];
//            for (NSDictionary *mediaDictionary in mediaDataArray) {
//                STXPost *post = [[STXPost alloc] initWithDictionary:mediaDictionary];
//                [posts addObject:post];
//            }
//            
//            self.tableViewDataSource.posts = [posts copy];
//            
//            [self.tableView reloadData];
//            
//        } else {
//            if (error) {
//                UALog(@"%@", error);
//            }
//        }
//    } else {
//        if (error) {
//            UALog(@"%@", error);
//        }
//    }
    
}

#pragma mark - User Action Cell

- (void)userDidLike:(STXUserActionCell *)userActionCell
{
    
}

- (void)userDidUnlike:(STXUserActionCell *)userActionCell
{
    
}

- (void)userWillComment:(STXUserActionCell *)userActionCell
{
    
}

- (void)userWillShare:(STXUserActionCell *)userActionCell
{
    id<STXPostItem> postItem = userActionCell.postItem;
    
    NSIndexPath *photoCellIndexPath = [NSIndexPath indexPathForRow:PHOTO_CELL_ROW inSection:userActionCell.indexPath.section];
    STXFeedPhotoCell *photoCell = (STXFeedPhotoCell *)[self.tableView cellForRowAtIndexPath:photoCellIndexPath];
    UIImage *photoImage = photoCell.photoImage;
    
    [self shareImage:photoImage text:postItem.captionText url:postItem.sharedURL];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    NSLog(@"view scrolled");
//    [self loadFeed];
//    [self.tableView reloadData];
    
}

@end
