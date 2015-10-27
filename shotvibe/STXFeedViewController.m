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
#import "PhotoView.h"

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



#import "STXFeedPhotoCell.h"
#import "STXLikesCell.h"
#import "STXCaptionCell.h"
#import "STXCommentCell.h"
#import "STXUserActionCell.h"

#import "STXPostItem.h"
#import "STXComment.h"

#define PHOTO_CELL_ROW 0
#define LIKES_CELL_ROW 1
#define CAPTION_CELL_ROW 2

#define NUMBER_OF_STATIC_ROWS 4
#define MAX_NUMBER_OF_COMMENTS 1




static CGFloat const UserActionCellHeight = 44;

@interface STXFeedViewController () <STXFeedPhotoCellDelegate, STXLikesCellDelegate, STXCaptionCellDelegate, STXCommentCellDelegate, STXUserActionDelegate,SLAlbumManager_AlbumContentsListener, UIAlertViewDelegate,GLSharedCameraDelegatte,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UITableViewDelegate,UITableViewDataSource,STXFeedPhotoCellDelegate, STXLikesCellDelegate, STXCaptionCellDelegate, STXCommentCellDelegate,UITextFieldDelegate,UIGestureRecognizerDelegate> {

    
    SLAlbumContents *albumContents;
    CGPoint location;
    float firstY;
    float firstX;
    
    UIView * cameraViewBackground;
    
    CGFloat cameraSlideTopLimit;
    CGFloat PhotoCellRowHeight ;
    
    
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;

//@property (strong, nonatomic) STXFeedTableViewDataSource *tableViewDataSource;
//@property (strong, nonatomic) STXFeedTableViewDelegate *tableViewDelegate;
@property (weak, nonatomic) id <STXFeedPhotoCellDelegate, STXLikesCellDelegate, STXCaptionCellDelegate, STXCommentCellDelegate, STXUserActionDelegate> controller;
@end

@implementation STXFeedViewController {

    SLAlbumManager *albumManager_;
    PhotoFilesManager *photoFilesManager_;
    
    // TODO Should use a global ImageDiskCache
    ImageDiskCache *imageDiskCache_;
    
    UIImage * uploadingImage;
    NSString * latestCommentString;
    UITextField *textField;
    UIView * commentsDialog;
    BOOL setFeedDone;

}


- (instancetype)initWithController:(id<STXFeedPhotoCellDelegate, STXLikesCellDelegate, STXCaptionCellDelegate, STXCommentCellDelegate, STXUserActionDelegate>)controller
                         tableView:(UITableView *)tableView
{
    self = [super init];
    if (self) {
        _controller = self;
        
        NSString *feedPhotoCellIdentifier = NSStringFromClass([STXFeedPhotoCell class]);
        UINib *feedPhotoCellNib = [UINib nibWithNibName:feedPhotoCellIdentifier bundle:nil];
        [tableView registerNib:feedPhotoCellNib forCellReuseIdentifier:feedPhotoCellIdentifier];
        
        NSString *userActionCellIdentifier = NSStringFromClass([STXUserActionCell class]);
        UINib *userActionCellNib = [UINib nibWithNibName:userActionCellIdentifier bundle:nil];
        [tableView registerNib:userActionCellNib forCellReuseIdentifier:userActionCellIdentifier];
    }
    
    return self;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
//    if (textField.tag == YOU_TEXT_FIELD_TAG) {
//        return NO;
//    }
    return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.posts count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    
    id<STXPostItem> postItem = self.posts[section];
    NSInteger commentsCount = MIN(MAX_NUMBER_OF_COMMENTS, [postItem totalComments]);
    return NUMBER_OF_STATIC_ROWS + commentsCount;
}

- (UIImage *)convertImageToGrayScale:(UIImage *)image {
    
    
    // Create image rectangle with current image width/height
    CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    // Grayscale color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    // Create bitmap content with current image size and grayscale colorspace
    CGContextRef context = CGBitmapContextCreate(nil, image.size.width, image.size.height, 8, 0, colorSpace, kCGImageAlphaNone);
    
    // Draw image into current context, with specified rectangle
    // using previously defined context (with grayscale colorspace)
    CGContextDrawImage(context, imageRect, [image CGImage]);
    
    // Create bitmap image info from pixel data in current context
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    
    // Create a new UIImage object
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    
    // Release colorspace, context and bitmap information
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CFRelease(imageRef);
    
    // Return the new grayscale image
    return newImage;
}

- (STXFeedPhotoCell *)photoCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = NSStringFromClass([STXFeedPhotoCell class]);
    STXFeedPhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.delegate = self;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
//    [cell sendSubviewToBack:cell.postImageView];
    
//    cell.postImageView.frame = CGRectMake(cell.postImageView.frame.origin.x, cell.postImageView.frame.origin.y, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.width*2);
    
    if (cell.indexPath != nil && cell.indexPath.section != indexPath.section) {
        [cell cancelImageLoading];
    }
    
    cell.indexPath = indexPath;
    
    if (indexPath.section < [self.posts count]) {
        id<STXPostItem> post = self.posts[indexPath.section];
        STXPost * postWithSlPhoto = self.posts[indexPath.section];
//        cell.postItem = post;
        cell.delegate = self.controller;
        cell.dateLabel.textColor = [UIColor grayColor];
        cell.dateLabel.text = [MHPrettyDate prettyDateFromDate:post.postDate withFormat:MHPrettyDateLongRelativeTime];
        
        
        
//        if([[postWithSlPhoto.slPhoto getUploadingPhoto] getPhotoId] == [postWithSlPhoto.slPhoto getServerPhoto]){
//            
//            
//            
//        }
        
//        UIView * loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 60)];
//        loadingView.backgroundColor = [UIColor redColor];
//        [cell addSubview:loadingView];
//        
//        UIImage * greyimage;
//        UIImageView * coloredImageView;
//        
//        if(uploadingImage){
//        greyimage = [self convertImageToGrayScale:uploadingImage];
//        cell.postImageView.image = greyimage;
//        
//        coloredImageView = [[UIImageView alloc] initWithFrame:cell.postImageView.frame];
//        coloredImageView.image = uploadingImage;
//        
//        [cell.postImageView addSubview:coloredImageView];
//        }
        
        
        
        if([postWithSlPhoto.slPhoto getUploadingPhoto]){
            
//            [[postWithSlPhoto.slPhoto getUploadingPhoto] ]
//            cell.justUploaded = YES;
            
//            cell.uploadedImage = uploadingImage;
//            [cell.greyImageView setFrame:cell.postImageView.frame];
            
            [cell.postImageView setImage:nil];
            [cell.greyImageView setImage:nil];
            
//            cell.postImageView.hidden = YES;
            if(uploadingImage){
            
                [cell.greyImageView setImage:[self convertImageToGrayScale:uploadingImage]];
                [cell.postImageView setImage:uploadingImage];
                [cell.postImageView setAlpha:0];
                
            }
            
            
//            PhotoView * t = [[PhotoView alloc] init];
//            t setPhoto:<#(NSString *)#> photoUrl:<#(NSString *)#> photoSize:<#(PhotoSize *)#> manager:<#(PhotoFilesManager *)#>
            
            cell.dateLabel.text = @"Now";
            
            NSLog(@"%@",[[postWithSlPhoto.slPhoto getUploadingPhoto] getState]);
            
            SLAlbumUploadingPhoto *uploadingPhoto = [postWithSlPhoto.slPhoto getUploadingPhoto];
            //
                        if ([uploadingPhoto getState] == [SLAlbumUploadingPhoto_StateEnum Saving]) {
//                            [cell.networkImageView setImage:nil];
//                            [cell.postImageView setImage:nil];
                            [cell.greyImageView setImage:nil];
                            
                        } else if ([uploadingPhoto getState] == [SLAlbumUploadingPhoto_StateEnum PreparingFiles]) {
//                            cell.postImageView.hidden =YES;
//                            cell.postImageView.frame = CGRectMake(cell.postImageView.frame.origin.x, cell.postImageView.frame.origin.y, 0, cell.postImageView.frame.size.height);
                            [cell.greyImageView setImage:[UIImage imageNamed:@"camera"]];
                        } else {
//                            UIImage *thumb = [imageDiskCache_ getImage:[uploadingPhoto getBitmapThumbPath]];
//                            greyimage = [self convertImageToGrayScale:uploadingImage];
//                            [cell.greyImageView setImage:[self convertImageToGrayScale:uploadingImage]];
                        }
            
            
                        if ([uploadingPhoto getState] == [SLAlbumUploadingPhoto_StateEnum Saving] ||
                            [uploadingPhoto getState] == [SLAlbumUploadingPhoto_StateEnum PreparingFiles]) {
//                            [cell.activityView startAnimating];
            
//                            cell.uploadProgressView.hidden = YES;
                        } else if ([uploadingPhoto getState] == [SLAlbumUploadingPhoto_StateEnum Uploading]) {
                            double progress = [uploadingPhoto getUploadProgress];
                            if (progress > 0.0) {
                                
                                [cell.postImageView setAlpha:progress];
                                if(progress == 1){
                                    
                                }
                                

                            } else {
                                
                                
                                

                            }
                        } else if ([uploadingPhoto getState] == [SLAlbumUploadingPhoto_StateEnum Uploaded]) {

                        } else if ([uploadingPhoto getState] == [SLAlbumUploadingPhoto_StateEnum AddingToAlbum]) {
                            [cell.postImageView setAlpha:1];
                        }
            
            
            
            id<STXUserItem> userItem = [post user];
            NSString *name = [postWithSlPhoto.slPhoto getAuthorNickname];
            cell.profileLabel.text = @"Uploading...";
            NSURL *profilePhotoURL = [userItem profilePictureURL];
            
            [cell.profileImageView setCircleImageWithURL:profilePhotoURL placeholderImage:[UIImage imageNamed:@"ProfilePlaceholder"] borderWidth:2];
            
            

            
            
        } else if([postWithSlPhoto.slPhoto getServerPhoto]) {
        
            
            
            if([cell.profileLabel.text isEqualToString:@"Uploading..."]){
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
            
        
        id<STXUserItem> userItem = [post user];
        NSString *name = [userItem fullname];
        cell.profileLabel.text = name;
        NSURL *profilePhotoURL = [userItem profilePictureURL];
        
        [cell.profileImageView setCircleImageWithURL:profilePhotoURL placeholderImage:[UIImage imageNamed:@"ProfilePlaceholder"] borderWidth:2];
        
        
        __block UIView * loading = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, cell.frame.size.height/7)];
        loading.backgroundColor = [UIColor greenColor];
        [cell addSubview:loading];
        
            
//            if(!cell.postImageView.image){
//            if(cell.postImageView == nil){
            
//            if(!cell.greyImageView.image){
//            if(!cell.justUploaded){
            
//            if(cell.uploadedImage){
//                cell.postImageView.image = cell.uploadedImage;
//            } else {
            
//            PhotoSize  * size = [[PhotoSize alloc] initWithExtension:@"r_fhd" width:1920 height:1080];
            
            
            if(!cell.postImageView.image){
                [cell.postImageView setPhoto:[[postWithSlPhoto.slPhoto getServerPhoto] getId]
                                    photoUrl:[[postWithSlPhoto.slPhoto getServerPhoto] getUrl]
                                   photoSize:photoFilesManager_.DeviceDisplayPhotoSize
                                     manager:photoFilesManager_];
            }
            
            
//            cell.postImageView
//        to:<#(NSString *)#> photoUrl:<#(NSString *)#> photoSize:<#(PhotoSize *)#> manager:<#(PhotoFilesManager *)#>
//                [cell.postImageView sd_setImageWithURL:post.photoURL placeholderImage:[UIImage imageNamed:@"feedPlaceHolder"] options:SDWebImageHighPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {
//                    
//                    float progress  = (float)receivedSize / (float)expectedSize;
//                    loading.frame = CGRectMake(0, 0, cell.frame.size.width*progress, cell.frame.size.height/7);
//                } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
//                    loading.hidden = YES;
//                }];
//            }
//            } else {
            
                
                
//            }
            
            
            
            NSLog(@"uploadedImage =    %@",cell.uploadedImage);
//            }
//            } else {
//                cell.postImageView.image = uploadingImage;
//            }
            
            
//            }
//            cell.justUploaded = NO;
            
//            }
        
        
        
        }
        
        
    }
    
    return cell;
}

- (STXLikesCell *)likesCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath
{
    id<STXPostItem> post = self.posts[indexPath.section];
    STXLikesCell *cell;
    
    if (cell == nil) {
        NSDictionary *likes = [post likes];
        NSInteger count = [[likes valueForKey:@"count"] integerValue];
        if (count > 2) {
            static NSString *CellIdentifier = @"STXLikesCountCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[STXLikesCell alloc] initWithStyle:STXLikesCellStyleLikesCount likes:likes reuseIdentifier:CellIdentifier];
            }
        } else {
            static NSString *CellIdentifier = @"STXLikersCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[STXLikesCell alloc] initWithStyle:STXLikesCellStyleLikers likes:likes reuseIdentifier:CellIdentifier];
            }
        }
        
        cell.delegate = self.controller;
    }
    
    cell.likes = [post likes];
    
    return cell;
}

- (STXCaptionCell *)captionCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath
{
    id<STXPostItem> post = self.posts[indexPath.section];
    
    NSString *CellIdentifier = NSStringFromClass([STXCaptionCell class]);
    STXCaptionCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[STXCaptionCell alloc] initWithCaption:[post caption] reuseIdentifier:CellIdentifier];
        cell.delegate = self.controller;
    }
    
    cell.caption = [post caption];
    
    return cell;
}

- (STXCommentCell *)commentCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath
{
    id<STXPostItem> post = self.posts[indexPath.section];
    STXCommentCell *cell;
    
    if (indexPath.row == 0 && [post totalComments] > MAX_NUMBER_OF_COMMENTS) {
        
        static NSString *AllCommentsCellIdentifier = @"STXAllCommentsCell";
        cell = [tableView dequeueReusableCellWithIdentifier:AllCommentsCellIdentifier];
        
        if (cell == nil) {
            cell = [[STXCommentCell alloc] initWithStyle:STXCommentCellStyleShowAllComments
                                           totalComments:[post totalComments]
                                         reuseIdentifier:AllCommentsCellIdentifier];
        } else {
            cell.totalComments = [post totalComments];
        }
        
    } else {
        static NSString *CellIdentifier = @"STXSingleCommentCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        NSArray *comments = [post comments];
        id<STXCommentItem> comment = comments[indexPath.row];
        
        if (indexPath.row < [comments count]) {
            if (cell == nil) {
                cell = [[STXCommentCell alloc] initWithStyle:STXCommentCellStyleSingleComment
                                                     comment:comment
                                             reuseIdentifier:CellIdentifier];
            } else {
                cell.comment = comment;
            }
        }
    }
//    cell.urlForProfilePic = [[post user] profilePictureURL];
//    cell.u
    cell.delegate = self.controller;
    
    return cell;
}

- (STXUserActionCell *)userActionCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath
{
    STXUserActionCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([STXUserActionCell class]) forIndexPath:indexPath];
    cell.indexPath = indexPath;
    cell.delegate = self;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    NSInteger captionRowOffset = 3;
    
    
    
    id<STXPostItem> postItem = self.posts[indexPath.section];
    NSInteger commentsCount = MIN(MAX_NUMBER_OF_COMMENTS, [postItem totalComments]);
    NSInteger commentsRowLimit = captionRowOffset + commentsCount;
    
    if (indexPath.row == PHOTO_CELL_ROW) {
        cell = [self photoCellForTableView:tableView atIndexPath:indexPath];
        
        
        
        
        
    } else if (indexPath.row == LIKES_CELL_ROW) {
        cell = [self likesCellForTableView:tableView atIndexPath:indexPath];
    } else if (indexPath.row == CAPTION_CELL_ROW) {
        cell = [self captionCellForTableView:tableView atIndexPath:indexPath];
//        cell.clipsToBounds = NO;
//        UIScrollView * commentsScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, -40, self.view.frame.size.width, 75)];
//        commentsScrollView.backgroundColor = [UIColor purpleColor];
//        commentsScrollView.pagingEnabled = YES;
//        commentsScrollView.contentSize = CGSizeMake(self.view.frame.size.width, 25*[[postItem comments] count]);
//        
//        int count = 0;
//        
//        for(STXComment * comment in [postItem comments]){
//            
//            
//            
//            UILabel * commentText = [[UILabel alloc] initWithFrame:CGRectMake(0, count*25, self.view.frame.size.width, 20)];
//            commentText.text = comment.text;
//            [commentsScrollView addSubview:commentText];
//            count++;
//        }
//        
//        [cell addSubview:commentsScrollView];
    } else if (indexPath.row > CAPTION_CELL_ROW && indexPath.row < commentsRowLimit) {
        NSIndexPath *commentIndexPath = [NSIndexPath indexPathForRow:indexPath.row-captionRowOffset inSection:indexPath.section];
        cell = [self commentCellForTableView:tableView atIndexPath:commentIndexPath];
        
    } else {
        cell = [self userActionCellForTableView:tableView atIndexPath:indexPath];
        
    }
    
    //    UIImageView * bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"postBg"]];
    //    bg.frame = cell.frame;
    //
    //    [cell addSubview:bg];
    
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    
    return cell;
}

- (instancetype)initWithController:(id<STXFeedPhotoCellDelegate, STXLikesCellDelegate, STXCaptionCellDelegate, STXCommentCellDelegate, STXUserActionDelegate>)controller
{
    self = [super init];
    if (self) {
        _controller = controller;
    }
    
    return self;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == PHOTO_CELL_ROW) {
        return PhotoCellRowHeight;
    }
    
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == PHOTO_CELL_ROW) {
        return PhotoCellRowHeight;
    }
    
    return UserActionCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Row Updates

- (void)reloadAtIndexPath:(NSIndexPath *)indexPath forTableView:(UITableView *)tableView
{
    self.insertingRow = YES;
    
    [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    
    
    
    //    fromImagePicker = NO;
    //
    //    //    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    //    //    [self sendImageToEdit:chosenImage];
    //    //   ;
    
    
    
    //
    //    [self updateFiltersWithSelectedImage:[self imageCroppedToFitSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.width) image:info[UIImagePickerControllerEditedImage]]];
    //    //    self.imageView.image = chosenImage;
    //
    //    //
    ShotVibeAppDelegate *appDelegate = (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    
    
    //    [appDelegate.window addSubview:picker.view];
    //    [UIView animateWithDuration:0.2 animations:^{
    //        [appDelegate.window bringSubviewToFront:[[GLSharedCamera sharedInstance] view]];
    
    //    } completion:^(BOOL done){
    [UIView animateWithDuration:0.3 animations:^{
        //        glcamera.view.alpha = 0;
        [[[GLSharedCamera sharedInstance] view] setAlpha:1];
//        [[GLSharedCamera sharedInstance] view].alpha = 1;
        [[GLSharedCamera sharedInstance] hideForPicker:NO];
        
        
    } completion:^(BOOL done){
        
    }];
    [picker dismissViewControllerAnimated:NO completion:^{
        
        
        
        [[GLSharedCamera sharedInstance] retrievePhotoFromPicker:info[UIImagePickerControllerOriginalImage]];
        //        }];
    }];
    
    
    
    
    
    
    //    imageSource = ImageSourceGallery;
    //    imageFromPicker = [self imageCroppedToFitSize:CGSizeMake(512, 512) image:info[UIImagePickerControllerEditedImage]];
    //
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


- (void)onAlbumContentsNewContentWithLong:(long long int)albumId
                      withSLAlbumContents:(SLAlbumContents *)album
{
    [self setAlbumContents:album];
//    [self loadFeed];
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


- (void)onAlbumContentsUploadsProgressedWithLong:(long long int)albumId
{
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    
    PhotoCellRowHeight = [[UIScreen mainScreen] bounds].size.width*1.333;
    
    photoFilesManager_ = [ShotVibeAppDelegate sharedDelegate].photoFilesManager;
    
    albumManager_ = [ShotVibeAppDelegate sharedDelegate].albumManager;
    
    imageDiskCache_ = [[ImageDiskCache alloc] initWithRefreshHandler:^{
        [self.tableView reloadData];
    }];
    
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor orangeColor];
    
    
    
    
    [[GLSharedCamera sharedInstance] setDelegate:self];
//    GLSharedCamera * cam = [GLSharedCamera sharedInstance];
//    cam.delegate = self;
    
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
    [self loadFeed];
    
    self.title = NSLocalizedString(@"Feed", nil);
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
//    STXFeedTableViewDataSource *dataSource = [[STXFeedTableViewDataSource alloc] initWithController:self tableView:self.tableView];
    self.tableView.dataSource = self;
//    self.tableViewDataSource = dataSource;
    
//    STXFeedTableViewDelegate *delegate = [[STXFeedTableViewDelegate alloc] initWithController:self];
    self.tableView.delegate = self;
//    self.tableViewDelegate = self;
    
    self.activityIndicatorView = [self activityIndicatorViewOnView:self.view];
    
    
    NSString *feedPhotoCellIdentifier = NSStringFromClass([STXFeedPhotoCell class]);
    UINib *feedPhotoCellNib = [UINib nibWithNibName:feedPhotoCellIdentifier bundle:nil];
    [self.tableView registerNib:feedPhotoCellNib forCellReuseIdentifier:feedPhotoCellIdentifier];
    
    NSString *userActionCellIdentifier = NSStringFromClass([STXUserActionCell class]);
    UINib *userActionCellNib = [UINib nibWithNibName:userActionCellIdentifier bundle:nil];
    [self.tableView registerNib:userActionCellNib forCellReuseIdentifier:userActionCellIdentifier];
    
    
    ((SVSidebarManagementController *)self.menuContainerViewController.leftMenuViewController).parentController = self;
    ((SVSidebarMemberController *)self.menuContainerViewController.rightMenuViewController).parentController = self;
    
    self.menuContainerViewController.panMode = MFSideMenuPanModeCenterViewController;
    
    setFeedDone = NO;
    
    UIScreenEdgePanGestureRecognizer * swipeScreen = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(screenSwiped:)];
    
    swipeScreen.minimumNumberOfTouches = 1;
    swipeScreen.maximumNumberOfTouches = 1;
    swipeScreen.edges = UIRectEdgeLeft;
    swipeScreen.delegate = self;
    
    [self.view addGestureRecognizer:swipeScreen];
    
    [self.tableView setShowsHorizontalScrollIndicator:NO];
    [self.tableView setShowsVerticalScrollIndicator:NO];
    
    
}

- (BOOL)screenSwiped:(UIScreenEdgePanGestureRecognizer *)gest {
    
    
    [self.navigationController popViewControllerAnimated:YES];
    return  YES;
    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
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
//    [self loadFeed];
    [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // This will be notified when the Dynamic Type user setting changes (from the system Settings app)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentSizeCategoryChanged:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    
    if ([self.posts count] == 0) {
//        [self.activityIndicatorView startAnimating];
    }
    
    [self.menuContainerViewController.view setFrame:[[UIScreen mainScreen] bounds]];
    [self didRotateFromInterfaceOrientation:UIInterfaceOrientationPortrait];
    
    
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
            
            NSData *objectData = [[NSString stringWithFormat:@"{\"attribution\":null,\"tags\":[],\"type\":\"image\",\"location\":null,\"comments\":{%@},\"filter\":\"Normal\",\"created_time\":\"%@\",\"link\":\"http://instagram.com/p/xtfQ81gK0E/\",\"likes\":{  },\"images\":{\"low_resolution\":{\"url\":\"http://scontent-b.cdninstagram.com/hphotos-xfa1/t51.2885-15/10932341_1042561312426099_2095600846_a.jpg\",\"width\":306,\"height\":306},\"thumbnail\":{\"url\":\"http://scontent-b.cdninstagram.com/hphotos-xfa1/t51.2885-15/10932341_1042561312426099_2095600846_s.jpg\",\"width\":150,\"height\":150},\"standard_resolution\":{\"url\":\"%@\",\"width\":480,\"height\":320}},\"users_in_photo\":[  ],\"caption\":{\"created_time\":\"%lld\"},\"user_has_liked\":false,\"id\":\"%@\",\"user\":{%@}}",commetnsString,[[photo getServerPhoto]getDateAdded],new,seconds,[[photo getServerPhoto]getId],userData] dataUsingEncoding:NSUTF8StringEncoding];
            
//            UIImageView * t = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
//            [t.networkImageView setPhoto:[[photo getServerPhoto] getId]
//                                   photoUrl:[[photo getServerPhoto] getUrl]
//                                  photoSize:[PhotoSize Thumb75]
//                                    manager:photoFilesManager_];
            
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:objectData options:kNilOptions error:nil];
            

                STXPost *post = [[STXPost alloc] initWithDictionary:dictionary];
                post.slPhoto = photo;
                [self.posts addObject:post];
            
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

#pragma mark - User Action Cell

- (void)userDidLike:(STXUserActionCell *)userActionCell
{
    
}

- (void)userDidUnlike:(STXUserActionCell *)userActionCell
{
    
}

- (void)userWillComment:(STXUserActionCell *)userActionCell
{
    
    textField.text = @"";
    
    id<STXPostItem> post = self.posts[userActionCell.indexPath.section];
    
    NSLog(@"");
    
    
    NSIndexPath *photoCellIndexPath = [NSIndexPath indexPathForRow:PHOTO_CELL_ROW inSection:userActionCell.indexPath.section];
    STXFeedPhotoCell *photoCell = (STXFeedPhotoCell *)[self.tableView cellForRowAtIndexPath:photoCellIndexPath];
    
    photoCell.postImageView.userInteractionEnabled = YES;
    
    
    // create effect
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    
    // add effect to an effect view
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc]initWithEffect:blur];
    effectView.frame = CGRectMake(0, 0, photoCell.postImageView.frame.size.width, photoCell.postImageView.frame.size.height);
    
    commentsDialog = [[UIView alloc]initWithFrame:CGRectMake(0, 0, photoCell.postImageView.frame.size.width, photoCell.postImageView.frame.size.height)];
    commentsDialog.alpha = 0;
    
    
    UIFont * customFont = [UIFont fontWithName:@"Helvetica" size:28]; //custom font

    UILabel * addCommentLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, photoCell.postImageView.frame.size.width, 50)];
    addCommentLabel.numberOfLines = 1;
    addCommentLabel.textColor = [UIColor whiteColor];
    addCommentLabel.text = @"C'mon say somthing..";
    addCommentLabel.font = customFont;
    addCommentLabel.textAlignment = NSTextAlignmentCenter;
    
    float textViewWidth = photoCell.postImageView.frame.size.width*0.8;
    float padding = (photoCell.postImageView.frame.size.width - textViewWidth)/2;
    
    textField = [[UITextField alloc] initWithFrame:CGRectMake(padding, addCommentLabel.frame.size.height*2, textViewWidth, 40)];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.font = [UIFont systemFontOfSize:15];
    textField.placeholder = @"enter text";
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.keyboardType = UIKeyboardTypeDefault;
    textField.returnKeyType = UIReturnKeyDone;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    textField.delegate = self;
    
    
    UIButton * send = [[UIButton alloc] initWithFrame:CGRectMake(0, textField.frame.origin.y*2, photoCell.postImageView.frame.size.width, 40)];
    send.tag = userActionCell.indexPath.section;
//    send. = @"test";
    [send addTarget:self
               action:@selector(postComment:) forControlEvents:UIControlEventTouchDown];
    [send setTitle:@"Send" forState:UIControlStateNormal];
    [send setFont:[UIFont fontWithName:@"Helvetica" size:20]];
    
    
    
//    [post]
    
    
    
//    commentsDialog.backgroundColor = [UIColor blackColor];
    [commentsDialog addSubview:effectView];
    [commentsDialog addSubview:addCommentLabel];
    [commentsDialog addSubview:textField];
    [commentsDialog addSubview:send];
    [photoCell.postImageView addSubview:commentsDialog];
    [UIView animateWithDuration:0.2 animations:^{
            commentsDialog.alpha = 1;
        [textField becomeFirstResponder];
        

        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:userActionCell.indexPath.section];
        [self.tableView scrollToRowAtIndexPath:indexPath
                             atScrollPosition:UITableViewScrollPositionTop
                                     animated:YES];
        
//        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:userActionCell.indexPath.section+1 inSection:0]
//                         atScrollPosition:UITableViewScrollPositionNone animated:YES];
        
    }];
    
    
}

-(void)postComment:(UIButton*)sender {
    
    id<STXPostItem> post = self.posts[sender.tag];
    long long milliseconds = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
    
    
    if([textField.text isEqualToString:@""]){
    
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Comment cannot be empty!"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        
    } else {
        
        [ShotVibeAPITask runTask:self withAction:^id{
            [[albumManager_ getShotVibeAPI]postPhotoCommentWithNSString:[post postID] withNSString:textField.text withLong:milliseconds];
            return nil;
        } onTaskComplete:^(id dummy) {
            
            [UIView animateWithDuration:0.2 animations:^{
                commentsDialog.alpha = 0;
            } completion:^(BOOL finished) {
                [commentsDialog removeFromSuperview];
                [albumManager_ refreshAlbumContentsWithLong:self.albumId withBoolean:NO];
                textField.text = @"";
            }];
        }];
        
    }
    
    
}

-(BOOL)textFieldShouldReturn:(UITextField *)textFieldd
{
    [textFieldd resignFirstResponder];
    return YES;
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
    
//    NSLog(@"view scrolled");
//    [self loadFeed];
//    [self.tableView reloadData];
    
}

@end
