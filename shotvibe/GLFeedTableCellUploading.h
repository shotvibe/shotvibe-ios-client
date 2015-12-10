//
//  GLFeedTableCell.h
//  shotvibe
//
//  Created by Tsah Kashkash on 26/10/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "SL/AlbumServerPhoto.h"
#import "PhotoFilesManager.h"
#import "PhotoView.h"
#import "CircleProgressView.h"
#import <MediaPlayer/MediaPlayer.h>
#import "AlbumPhoto.h"
//#import "AlbumVideo.h"
#import "AlbumServerPhoto.h"
#import "SL/AlbumServerVideo.h"
//#import "UIImageView+Masking.h"
#import "SDWebImageManager.h"
#import "NSDate+Formatting.h"
#import "UIImageView+WebCache.h"
#import "GLSharedVideoPlayer.h"
#import "SL/AlbumUploadingPhoto.h"
#import "SL/AlbumUploadingMedia.h"
#import "SL/AlbumPhoto.h"

@interface GLFeedTableCellUploading : UITableViewCell



- (void)updateUploadingStatus:(SLAlbumUploadingMedia*)photo;
- (void)updateProccesingStatus:(SLAlbumPhoto *)photo;

@property(nonatomic,retain) UIImageView * profileImageView;
@property(nonatomic,retain) UILabel * userName;
@property(nonatomic,retain) UILabel * postedTime;
@property(nonatomic,retain) PhotoView * postImage;
@property(nonatomic, retain) NSString * photoId;
@property(nonatomic, retain) UIImageView * videoBadge;
@property (strong, nonatomic) CircleProgressView *circleProgressView;



@end
