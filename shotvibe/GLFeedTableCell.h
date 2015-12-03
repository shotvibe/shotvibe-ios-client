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


@interface GLFeedTableCell : UITableViewCell<MPMediaPlayback> {
    
}


- (void)playVideo:(SLAlbumServerVideo *)video;
-(void)highLightLastCommentInPost;

- (void)notifyCellVisibleWithIsCompletelyVisible:(BOOL)completlyVisible;

- (void)loadCellWithData:(NSArray*)data photoFilesManager:(PhotoFilesManager*)photoFilesManager_;
- (void)notifyCompletelyVisible;
- (void)notifyNotCompletelyVisible;

@property(nonatomic,retain) UIImageView * profileImageView;
@property(nonatomic,retain) UILabel * userName;
@property(nonatomic,retain) UILabel * postedTime;
@property(nonatomic,retain) PhotoView * postImage;
@property(nonatomic,retain) UIScrollView * commentsScrollView;
@property(nonatomic,retain) UITextField * commentTextField;
@property(nonatomic,retain) UILabel * glancesCounter;
@property(nonatomic) BOOL loaded;
@property(nonatomic, retain) NSString * photoId;
@property(nonatomic, retain) UIImageView * glancesIcon;
@property(nonatomic, retain) UIButton * addCommentButton;
@property(nonatomic, retain) UIButton * postForwardButton;
@property(nonatomic, retain) UIView * postPannelWrapper;
@property(nonatomic, retain) UIView * commentScrollBgView;
@property(nonatomic, retain) UIButton * abortCommentButton;
@property(nonatomic, retain) UIButton * glanceUpButton;
@property(nonatomic, retain) UIButton * glanceDownButton;
@property(nonatomic, retain) UIButton * feed3DotsButton;
@property(nonatomic, retain) MPMoviePlayerController * moviePlayer;
@property(nonatomic, retain) UIImageView * videoBadge;
@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) NSTimer * playBackStartedTester;
@property (nonatomic, strong) UIActivityIndicatorView * activityIndicator;


@end
