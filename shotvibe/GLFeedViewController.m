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
#import "SVAddFriendsViewController.h"
#import "SVNavigationController.h"
#import "SL/AlbumPhoto.h"
#import "UIImageView+WebCache.h"
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
#import "SVSidebarManagementController.h"
#import "SVSidebarMemberController.h"
#import "MFSideMenu.h"
#import "SVDefines.h"
#import "SVSidebarMemberController.h"
#import "ShotVibeAppDelegate.h"
#import "SL/AlbumPhotoComment.h"
#import "SL/AlbumPhoto.h"
#import "SDWebImageManager.h"
#import "GLSharedCamera.h"
#import "LNNotificationsUI.h"
#import "GLProfileViewController.h"
#import "GLProfilePageViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "SL/AlbumServerVideo.h"
#import "SL/MediaType.h"
#import "GLSharedVideoPlayer.h"
#import "GLFeedTableCellUploading.h"
#import "GLContainersViewController.h"
#import "GLEmojiKeyboard.h"
#import "ALAssetsLibrary+CustomPhotoAlbum.h"

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
    
    UILabel * letsGetsStarted;
    UILabel * yet;
    UILabel * photos;
    UILabel * no;
    UIImageView * dmutArrow;
    BOOL placeHolderIsShown;
    
    NSInteger currentPostIndex;
    NSUInteger postsPrevCount;
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
            if(self.posts.count > 0){
                SLAlbumPhoto * photo = [[self.posts objectAtIndex:indexPath.row] objectAtIndex:1];
                if([[photo getServerPhoto] getMediaType] == [SLMediaTypeEnum VIDEO] && [[[photo getServerPhoto] getVideo] getStatus] != [SLAlbumServerVideo_StatusEnum PROCESSING]){
                    [self checkWhichVideoToEnable];
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [cell.activityIndicator startAnimating];
//                    });
                }
            }
        }
    }
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    currentPostIndex = 0;
    
    
    
    
    
    cameBackFromBg = NO;
    placeHolderIsShown = NO;
    
    
    
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
    
    
    
    
    tableIsScrolling = NO;
    
    self.feedScrollDirection = FeedScrollDirectionDown;
    snapIsScrolling = NO;
    
    
    
    scrollToCellDisabled = NO;
    
    
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
    
    ((SVSidebarMemberController *)self.menuContainerViewController.rightMenuViewController).parentController = self;
    ((SVSidebarMemberController *)self.menuContainerViewController.rightMenuViewController).albumId = self.albumId;
    
    
//    ShotVibeAppDelegate *appDelegate = (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];
//    appDelegate.pushNotificationsManager.notificationHandler_.delegate = self;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startUploadFromOutSide:)
                                                 name:@"ImageCapturedOnMainScreen"
                                               object:nil];
    
    lockContentsStackDepth_ = 0;
    lockContentsSavedValue_ = nil;
    
}

-(GLFeedTableCell*)ShowSpecificCell:(NSString*)photoId {
//    [KVNProgress showWithStatus:photoId];
    
    
    NSLog(@"comment retrieved");
    int c = 0;
    int position = 0;
    for(NSArray * post in self.posts){
        if([[[post objectAtIndex:0] objectForKey:@"id"] isEqualToString:photoId]){
            position = c;
            
            
            
            
            NSLog(@"i found the commented image in the table at %d",c);
            cellToHighLightIndex = c;
            
            
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:c inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
//            needCommentHl = YES;
//            [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
            
//            self.view.userInteractionEnabled = NO;
            
            GLFeedTableCell * cell = (GLFeedTableCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:c inSection:0]];
            return cell;
//                        [cell highLightLastCommentInPost];
            
            
            break;
        }
        c++;
    }
    
    
    
}

-(void)showNoPhotosPlaceHolder {
    
    
    if(placeHolderIsShown == NO){
        NSString * nos = @"No";
        float spacing = -9.0f;
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:nos];
        
        [attributedString addAttribute:NSKernAttributeName
                                 value:@(spacing)
                                 range:NSMakeRange(0, [nos length])];
        
        no = [[UILabel alloc] initWithFrame:CGRectMake(50, self.view.frame.size.height/4, self.view.frame.size.width, self.view.frame.size.height/8)];
        no.attributedText = attributedString;
        
        no.font = [UIFont fontWithName:@"GothamRounded-Bold" size:90];
        no.textColor = UIColorFromRGB(0x45B4B5);
        
        
        NSString *  photoss = @"Photos";
        NSMutableAttributedString *attributedString2 = [[NSMutableAttributedString alloc] initWithString:photoss];
        
        [attributedString2 addAttribute:NSKernAttributeName
                                  value:@(spacing)
                                  range:NSMakeRange(0, [photoss length])];
        
        photos = [[UILabel alloc] initWithFrame:CGRectMake(50, self.view.frame.size.height/4+self.view.frame.size.height/9, self.view.frame.size.width, self.view.frame.size.height/8)];
        photos.attributedText = attributedString2;
        photos.font = [UIFont fontWithName:@"GothamRounded-Bold" size:90];
        photos.textColor = UIColorFromRGB(0xFED84B);
        
        
        NSString *  yets = @"Yet";
        NSMutableAttributedString *attributedString3 = [[NSMutableAttributedString alloc] initWithString:yets];
        
        [attributedString3 addAttribute:NSKernAttributeName
                                  value:@(spacing)
                                  range:NSMakeRange(0, [yets length])];
        
        yet = [[UILabel alloc] initWithFrame:CGRectMake(50, self.view.frame.size.height/4+self.view.frame.size.height/9+self.view.frame.size.height/9, self.view.frame.size.width, self.view.frame.size.height/8)];
        yet.attributedText = attributedString3;
        yet.font = [UIFont fontWithName:@"GothamRounded-Bold" size:90];
        yet.textColor = UIColorFromRGB(0xEE7482);
        
        
        
        
        letsGetsStarted = [[UILabel alloc] initWithFrame:CGRectMake(50, self.view.frame.size.height-self.view.frame.size.height/7, 275, self.view.frame.size.height/10)];
        //            letsGetsStarted.backgroundColor = [UIColor orangeColor];
        letsGetsStarted.text = @"Pull Mr. Glance down and Let's get this party started.";
        letsGetsStarted.textColor = UIColorFromRGB(0x979494);
        letsGetsStarted.font = [UIFont fontWithName:@"GothamRounded-Bold" size:18];
        letsGetsStarted.textAlignment = NSTextAlignmentCenter;
        letsGetsStarted.lineBreakMode = NSLineBreakByWordWrapping;
        letsGetsStarted.numberOfLines=2;
        
        dmutArrow = [[UIImageView alloc] initWithFrame:CGRectMake(140, 95, 150, 175)];
        dmutArrow.image = [UIImage imageNamed:@"dmutArrow"];
        
        [self.view addSubview:dmutArrow];
        [self.tableView addSubview:no];
        [self.tableView addSubview:photos];
        [self.tableView addSubview:yet];
        [self.view addSubview:letsGetsStarted];
        [self.tableView setUserInteractionEnabled:NO];
        
        
        placeHolderIsShown = YES;
    }
    
}

-(void)hideNoPhotosPlaceHolder {
    [no removeFromSuperview];
    no = nil;
    
    [photos removeFromSuperview];
    photos = nil;
    
    [yet removeFromSuperview];
    yet = nil;
    
    [letsGetsStarted removeFromSuperview];
    letsGetsStarted = nil;
    
    [dmutArrow removeFromSuperview];
    dmutArrow = nil;
    
    [self.tableView setUserInteractionEnabled:YES];
    placeHolderIsShown = NO;
}


- (BOOL)textFieldShouldBeginEditing:(UITextField*)textField {
    
    return NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    if (sender.contentOffset.y<=0 || sender.contentOffset.y >= sender.contentSize.height) {
        //        scrollView.contentOffset = CGPointZero;
    } else {
        [self checkWhichVideoToEnable];
    }
}

- (void)checkWhichVideoToEnable
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
                cell.isVisible = YES;
                if([[photo getServerPhoto] getMediaType] == [SLMediaTypeEnum VIDEO]){
                    
                    //                    self.volumeButtonHandler = nil;
                    //                    self.volumeButtonHandler
                    cell.isVideo  = YES;
                    NSString * videoUrl = [[[photo getServerPhoto] getVideo] getVideoUrl];
                    
                    
                    
                    [[GLSharedVideoPlayer sharedInstance] attachToView:cell.moviePlayer withPhotoId:[[photo getServerPhoto] getId] withVideoUrl:videoUrl videoThumbNail:cell.postImage.image tableCell:cell postsArray:self.posts];
                    //                    cell.activityIndicator.backgroundColor = [UIColor redColor];
                    //                    cell.activityIndicator.hidesWhenStopped = NO;
                    //                    [cell bringSubviewToFront:cell.activityIndicator];
                    [cell.activityIndicator startAnimating];
                    break;
                    
                    
                    //                    [[GLSharedVideoPlayer sharedInstance] play];
                } else {
                    cell.isVideo  = NO;
                }
                //                    [[GLSharedVideoPlayer sharedInstance] pause];
                
                //                cell.backgroundColor = [UIColor redColor];
                //                currentPostIndex++;
                //                NSLog(@"down index is :%ld",(long)currentPostIndex);
            }
            else
            {
                cell.isVisible = NO;
                //                currentPostIndex++;
                //                NSLog(@"down index is :%ld",(long)currentPostIndex);
                //                [[GLSharedVideoPlayer sharedInstance] pause];
                // mute the other video cells that are not visible
                //                [((VideoMessageCell*)cell) muteVideo:YES];
                //                NSLog(@"im gone pause on this blue cell cus less then 51 is visible");
                //                [cell.activityIndicator stopAnimating];
                
                [cell abortCommentDidPressed];
                if([[[GLSharedVideoPlayer sharedInstance] photoId] isEqual:[[photo getServerPhoto] getId]]){
                    [[GLSharedVideoPlayer sharedInstance] pause];
                    break;
                    
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
    
//    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
//    dispatch_async(queue, ^(void) {
//        
        
//            //        if(error){
//            //            [KVNProgress showErrorWithStatus:[error localizedDescription]];
//            //        } else {
//            //                    [KVNProgress showSuccessWithStatus:@"Image saved succesfully to custom album"];
//            dispatch_async(dispatch_get_main_queue(), ^{
            
//            });
    
            
            //        }
        
    [[[ShotVibeAppDelegate sharedDelegate] uploadManager] addUploadVideoJob:pathToMovie withImageFilePath:filePathToThumb withAlbumId:self.albumId];
    
        
        
        
//    });
    
    
    
    
    
    //        [[ShotVibeAppDelegate sharedDelegate].uploadManager addUploadVideoJob:pathToMovie withAlbumId:self.albumId];
    //    }];
    //    long long publicFeedId = 5331;
    
}



-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    
    tableIsScrolling = NO;
//    
//    if(!scrollToCellDisabled && !commentingNow){
//        NSLog(@"im done and ready to highlight comment");
//        
//        
//        NSArray *cells = [self.tableView visibleCells];
//        
//        GLFeedTableCell *cell = nil;
//        NSIndexPath *path = [NSIndexPath indexPathForRow:cellToHighLightIndex inSection:0];
//        for (GLFeedTableCell *aCell in cells) {
//            NSIndexPath *aPath = [self.tableView indexPathForCell:aCell];
//            
//            if ([aPath isEqual:path]) {
//                cell = aCell;
//            }
//        }
//        
//        [cell highLightLastCommentInPost];
//        self.view.userInteractionEnabled = YES;
//        
//    }
    
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
        [[GLSharedVideoPlayer sharedInstance] pause];
    }
    
}

-(void)commentPushPressed:(SLNotificationMessage_PhotoComment *)msg {
    
    [[GLSharedVideoPlayer sharedInstance] pause];
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
            [self centerTable];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    //    NSLog(@"%f - %f",scrollView.contentOffset.y,scrollView.contentSize.height);
    //    if (scrollView.contentOffset.y < scrollView.contentSize.height) {
    //        scrollView.contentOffset = CGPointZero;
    //    } else {
    [self centerTable];
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
            NSData * imgData = [NSData dataWithContentsOfFile:filePath];
            NSLog(@"Size of Image(bytes):%lu",(unsigned long)[imgData length]);
            BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
            if(fileExists){
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"FINISH to write image");
                    if (self.albumId != 0) {
                        
                        RCLog(@"====================== 1. Upload selected photos to albumId %lli", self.albumId);
                        
                        [[[ShotVibeAppDelegate sharedDelegate] uploadManager] addUploadPhotoJob:filePath withAlbumId:self.albumId];
                        
                        if(self.startImidiatly){
                            self.startImidiatly = NO;
                            [[GLSharedCamera sharedInstance] setImageForOutSideUpload:nil];
                        }
                        
                    }
                    
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
    SLAlbumContents *contents = [albumManager_ addAlbumContentsListenerWithLong:self.albumId withSLAlbumManager_AlbumContentsListener:self];
    [self setAlbumContents:contents];
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
    
    if (self.feedDidAppearBlock) {
        __block GLFeedViewController *blocksafeSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            blocksafeSelf.feedDidAppearBlock(self);
        });
    }
    
    
//    GLSharedCamera * camera = [GLSharedCamera sharedInstance];
//    
//    
//    if([[ShotVibeAppDelegate sharedDelegate] appOpenedFromPush]){
//        self.photoToScrollToCommentsId = [[ShotVibeAppDelegate sharedDelegate] photoIdFromPush];
//        self.scrollToComment = YES;
//        //
//        
//        
//        int c = 0;
//        int position = 0;
//        for(NSArray * post in self.posts){
//            if([[[post objectAtIndex:0] objectForKey:@"id"] isEqualToString:self.photoToScrollToCommentsId]){
//                position = c;
//                
//                
//                
//                
//                NSLog(@"i found the commented image in the table at %d",c);
//                cellToHighLightIndex = c;
//                needCommentHl = YES;
//                [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
//                
//                self.view.userInteractionEnabled = NO;
//                
//                //            GLFeedTableCell * cell = (GLFeedTableCell*)[super tableView:self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:c inSection:0]];
//                //            [cell highLightLastCommentInPost];
//                
//                [[ShotVibeAppDelegate sharedDelegate] setAppOpenedFromPush:NO];
//                break;
//            }
//            c++;
//        }
//        
//    }
//    
//    
//    if(self.scrollToComment){
//        
//        NSLog(@"comment retrieved");
//        int c = 0;
//        int position = 0;
//        for(NSArray * post in self.posts){
//            if([[[post objectAtIndex:0] objectForKey:@"id"] isEqualToString:self.photoToScrollToCommentsId]){
//                position = c;
//                
//                
//                
//                
//                NSLog(@"i found the commented image in the table at %d",c);
//                cellToHighLightIndex = c;
//                needCommentHl = YES;
//                [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
//                
//                self.view.userInteractionEnabled = NO;
//                
//                //            GLFeedTableCell * cell = (GLFeedTableCell*)[super tableView:self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:c inSection:0]];
//                //            [cell highLightLastCommentInPost];
//                
//                
//                break;
//            }
//            c++;
//        }
//        
//    } else {
//        
//        if([self.posts count]>0){
//            
//            GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:pageNumber inSection:0]];
//            
//            NSArray * data = [self.posts objectAtIndex:[self.tableView indexPathForCell:cell].row];
//            SLAlbumPhoto *photo = [data objectAtIndex:1];
//            
//            
//            //    CGRect cellRect = [scrollView convertRect:cell.frame toView:scrollView.superview];
//            //    if (CGRectContainsRect(scrollView.frame, cellRect)){
//            //        NSLog(@"visible");
//            //    } else {
//            //        NSLog(@"unvisible");
//            //    }
//            
//            //    NSLog(@"%d",);
//            
//            //        if([[photo getServerPhoto] getMediaType] == [SLMediaTypeEnum VIDEO]){
//            //            [cell.activityIndicator startAnimating];
//            //            [[GLSharedVideoPlayer sharedInstance] play];
//            //        }
//            
//        }
//        
//        
//    }
    
    
    self.volumeButtonHandler = [JPSVolumeButtonHandler volumeButtonHandlerWithUpBlock:^{
        
        float num = self.tableView.contentOffset.y/self.tableView.frame.size.height;
        if(num > 0 && tableIsScrolling == NO){
            NSLog(@"current down %f",floorf(num+0.5));
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:floorf(num+0.5)-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
        
    } downBlock:^{
        
        float num = self.tableView.contentOffset.y/self.tableView.frame.size.height;
        if(num < self.posts.count-1 && tableIsScrolling == NO){
            NSLog(@"current down %f",floorf(num+0.5));
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:floorf(num+0.5)+1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
        
    }];
    
    
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
    
    
    
    //    NSLog(@"%lu",(unsigned long)postsPrevCount);
    
    if (lockContentsStackDepth_ > 0) {
        lockContentsSavedValue_ = album;
        return;
    }
    
    albumContents = album;
    if(albumContents != nil){
        
        
        
        if([[album getPhotos].array count] == 0){
            [self showNoPhotosPlaceHolder];
        } else {
            [self hideNoPhotosPlaceHolder];
        }
        
        GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
        if(glcamera.imageForOutSideUpload){
            
            [self imageSelected:glcamera.imageForOutSideUpload];
            glcamera.imageForOutSideUpload = nil;
        }
    }
    
    
    ((SVSidebarMemberController *)self.menuContainerViewController.rightMenuViewController).albumContents = albumContents;
    
    
    self.menuContainerViewController.panMode = MFSideMenuPanModeDefault;
    
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
            
        
//            NSArray *mutableRetrievedArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"kHiddenPosts"];
//            if(mutableRetrievedArray){
//                if([mutableRetrievedArray containsObject:[[photo getServerPhoto]getId]]){
//                    continue;
//                }
//            }
            
            
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
        //
        //        if(self.posts.count > postsPrevCount){
        //            postsPrevCount = 9999;
        //        }
        //        postsPrevCount = reversedArray.count;
        
        
        
        
    }
    
    
    
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
//short GetSharpness(char* data, unsigned int width, unsigned int height)
//{
//    // assumes that your image is already in planner yuv or 8 bit greyscale
//    IplImage* in = cvCreateImage(cvSize(width,height),IPL_DEPTH_8U,1);
//    IplImage* out = cvCreateImage(cvSize(width,height),IPL_DEPTH_16S,1);
//    memcpy(in->imageData,data,width*height);
//    
//    // aperture size of 1 corresponds to the correct matrix
//    cvLaplace(in, out, 1);
//    
//    short maxLap = -32767;
//    short* imgData = (short*)out->imageData;
//    for(int i =0;i<(out->imageSize/2);i++)
//    {
//        if(imgData[i] > maxLap) maxLap = imgData[i];
//    }
//    
//    cvReleaseImage(&in);
//    cvReleaseImage(&out);
//    return maxLap;
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
        cell.tag = indexPath.row;
        
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
                GLFeedTableCellUploading *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierUploading];
                
                if(cell==nil){
                    
                    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:CellIdentifierUploadingNibName owner:self options:nil];
                    cell = [nib objectAtIndex:0];
                }
                
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
                cell.submitCommentButton.tag = indexPath.row;
                
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
//                cell.indicator
                return  cell;
            }
            
            
            
        }
        
    }
    
}

- (void)showUserProfileWithId:(long long)userId {
    
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
        if([[member getUser] getMemberId] == userId){
            profilePage.slMemberObject = member;
        }
    }
    [self.navigationController pushViewController:profilePage animated:YES];
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
    NSString * hideOption = @"Delete Photo";
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
            [[GLSharedVideoPlayer sharedInstance] pause];
            
            SLAlbumPhoto *photo = [[self.posts objectAtIndex:popup.tag] objectAtIndex:1];
            long long int uid = [[[albumManager_ getShotVibeAPI] getAuthData] getUserId];
            long long int authorIdFromPhoto = [[[photo getServerPhoto] getAuthor] getMemberId];
            
            if(uid == authorIdFromPhoto){
                
                [KVNProgress show];
                [ShotVibeAPITask runTask:self withAction:^id{
                    
                    NSMutableArray *photosToDelete = [[NSMutableArray alloc] init];
                    [photosToDelete addObject:[[photo getServerPhoto] getId]];
                    [[albumManager_ getShotVibeAPI] deletePhotosWithJavaLangIterable:[[SLArrayList alloc] initWithInitialArray:photosToDelete]];
                    return nil;
                } onTaskComplete:^(id dummy) {
                    [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
                    [KVNProgress dismiss];
                    [[GLSharedVideoPlayer sharedInstance] pause];
                    [[GLSharedVideoPlayer sharedInstance] resetPlayer];
                } onTaskFailure:^(id success) {
                    [KVNProgress showErrorWithStatus:@"Somthing went wrong..." completion:^{
                        
                    }];
                } withLoaderIndicator:NO];
                
                
            } else {
//                NSString * photoIdToHide = [[photo getServerPhoto] getId];
                
                
//                NSDictionary *retrievedDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"DicKey"];
//                NSMutableArray *mutableRetrievedArray = [[[NSUserDefaults standardUserDefaults] objectForKey:@"kHiddenPosts"] mutableCopy];
//                if(mutableRetrievedArray == nil){
//                    mutableRetrievedArray = [[NSMutableArray alloc] init];
//                }
////                if(mutableRetrievedArray){
//                    [mutableRetrievedArray addObject:photoIdToHide];
//                    [[NSUserDefaults standardUserDefaults] setObject:mutableRetrievedArray forKey:@"kHiddenPosts"];
//                    [[NSUserDefaults standardUserDefaults] synchronize];
//                    [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
////                }
//
//                
                
                [KVNProgress showErrorWithStatus:@"Hi! That's not your's to delete!" onView:self.view completion:^{
                    NSLog(@"");
                }];
                
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
    
    GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:gest.view.tag inSection:0]];
    SLAlbumPhoto * photo = [[self.posts objectAtIndex:gest.view.tag] objectAtIndex:1];
    int glanceScoreDelta = [[photo getServerPhoto]  getMyGlanceScoreDelta];
    int globalGlanceScore = [[photo getServerPhoto] getGlobalGlanceScore];
    
    int newPredictedPhotoGlanceScore = globalGlanceScore - glanceScoreDelta + 1;
    
    cell.glancesCounter.text = [NSString stringWithFormat:@"%d", newPredictedPhotoGlanceScore];
    if (glanceScoreDelta == 1) {
        return;
    }
//    if(glanceScoreDelta <= 0){
//    
//        if([cell.glancesCounter.text intValue] >= -1){
//            cell.glancesCounter.text = [NSString stringWithFormat:@"%d",[cell.glancesCounter.text intValue]+2];
//        } else {
//            cell.glancesCounter.text = [NSString stringWithFormat:@"%d",[cell.glancesCounter.text intValue]+1];
//        }
    
        [ShotVibeAPITask runTask:self withAction:^id{
            [[albumManager_ getShotVibeAPI] setPhotoMyGlanceScoreDeltaWithNSString:cell.photoId withInt:1];
            return nil;
        } onTaskComplete:^(id dummy) {
            [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
            [UIView animateWithDuration:0.2 animations:^{
                
            } completion:^(BOOL finished) {
                
                
            }];
        } onTaskFailure:^(id success) {
            
            [KVNProgress showErrorWithStatus:@"Somthing went wrong.."];
            
        } withLoaderIndicator:NO];
//    }
    
    
    
    
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
    
    SLAlbumPhoto * photo = [[self.posts objectAtIndex:gest.view.tag] objectAtIndex:1];
    int glanceScoreDelta = [[photo getServerPhoto]  getMyGlanceScoreDelta];
    int globalGlanceScore = [[photo getServerPhoto] getGlobalGlanceScore];
    
    int newPredictedPhotoGlanceScore = globalGlanceScore - glanceScoreDelta - 1;
    
    if (glanceScoreDelta == -1) {
        return;
    }
    
    cell.glancesCounter.text = [NSString stringWithFormat:@"%d", newPredictedPhotoGlanceScore];
//    if(glanceScoreDelta >= 0){
    
//        if([cell.glancesCounter.text intValue] >= 1){
//            cell.glancesCounter.text = [NSString stringWithFormat:@"%d",[cell.glancesCounter.text intValue]-2];
//        } else {
//            cell.glancesCounter.text = [NSString stringWithFormat:@"%d",[cell.glancesCounter.text intValue]-1];
//        }
    
        [ShotVibeAPITask runTask:self withAction:^id{
            [[albumManager_ getShotVibeAPI] setPhotoMyGlanceScoreDeltaWithNSString:cell.photoId withInt:-1];
            
            return nil;
        } onTaskComplete:^(id dummy) {
            [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
            [UIView animateWithDuration:0.2 animations:^{
                
            } completion:^(BOOL finished) {
                
            }];
        } onTaskFailure:^(id success) {
            
            [KVNProgress showErrorWithStatus:@"Somthing went wrong..."];
            
        } withLoaderIndicator:NO];
        
//    }
    
    
    [UIView animateWithDuration:0.2 animations:^{
        cell.glanceDownButton.transform = CGAffineTransformScale(cell.glancesIcon.transform, 2.5, 2.5);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            cell.glanceDownButton.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            
        }];
    }];
    
    
    
}

-(void)sharePostPressed:(UIButton*)sender {
    GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:sender.tag inSection:0]];
    [[GLContainersViewController sharedInstance] goToFriendsListViewAnimatedBeforeMovingPhoto:NO photoId:cell.photoId completed:^{
        [[GLContainersViewController sharedInstance] resetFriendsView];
    } fromPublic:NO];
}

-(void)backPressed {
    [[GLContainersViewController sharedInstance] unlockScrollingPages];
    if(![[[self.navigationController viewControllers]lastObject] isKindOfClass:[GLProfilePageViewController class]]){
        
//        [[GLContainersViewController sharedInstance] resetFriendsView];
        [[GLSharedCamera sharedInstance] setCameraInMain];
        self.volumeButtonHandler = nil;
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
        [UIView animateWithDuration:0.2 animations:^{
            [[[GLSharedCamera sharedInstance]membersButton]setAlpha:1];
            [[[GLSharedCamera sharedInstance] dmut] setUserInteractionEnabled:YES];
        }];
    }
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
    commentingNow = NO;
    [cell abortCommentDidPressed];
    [[GLContainersViewController sharedInstance] enableSideMembers];
    
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
    
    [[GLContainersViewController sharedInstance] disableSideMembers];
    
    commentingNow = YES;
    NSLog(@"the photo id is %lld",(long long)sender.tag);
    GLFeedTableCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:sender.tag inSection:0]];
    
    cell.commentTextField.delegate = self;
    //    [cell bringSubviewToFront:cell.commentTextField];
    [cell.abortCommentButton addTarget:self action:@selector(abortCommentPressed:) forControlEvents:UIControlEventTouchUpInside];
    cell.abortCommentButton.tag = sender.tag;
    
    [cell.backSpaceKeyBoardButton addTarget:self action:@selector(keyBoardBackSpacePressed:) forControlEvents:UIControlEventTouchUpInside];
    cell.backSpaceKeyBoardButton.tag = sender.tag;
    
    [cell.submitCommentButton addTarget:self action:@selector(commentSubmitPressed:) forControlEvents:UIControlEventTouchUpInside];
    cell.submitCommentButton.tag = sender.tag;
    
    
    [cell showCommentAreaAndKeyBoard];
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
            
            commentingNow = NO;
            [[GLContainersViewController sharedInstance] enableSideMembers];
            
        } onTaskFailure:
         ^(id failure) {
             
             [KVNProgress showErrorWithStatus:@"Somthing went wrong"];
             
         }  withLoaderIndicator:NO];
        
    }
    
    
    
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    RCLog(@"%@ did receive memory warning", NSStringFromClass([self class]));
    //    [thumbnailCache removeAllObjects];
    
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[UIScreen mainScreen] bounds].size.height*0.883;
}


@end
