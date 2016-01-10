//
//  GLFeedTableCell.m
//  shotvibe
//
//  Created by Tsah Kashkash on 26/10/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import "GLFeedTableCell.h"
#import <MediaPlayer/MediaPlayer.h>
#import "AlbumPhoto.h"
#import "AlbumServerPhoto.h"
#import "SL/AlbumServerVideo.h"
#import "SL/MediaType.h"
#import "SL/AlbumUser.h"
//#import "UIImageView+Masking.h"
#import "SDWebImageManager.h"
#import "NSDate+Formatting.h"
#import "UIImageView+WebCache.h"
#import "GLSharedVideoPlayer.h"
#import "GLPubNubManager.h"
//#import "UIView+YYAdd.h"
//#import "CALayer+YYAdd.h"
//#import "UIGestureRecognizer+YYAdd.h"


@implementation GLFeedTableCell



//-(void)
- (void)awakeFromNib {

    
    self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.indicator.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    self.indicator.hidden = YES;
    self.contentView.clipsToBounds = YES;
    
    self.profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 15, 60, 60)];
    [self.contentView addSubview:self.profileImageView];
    self.profileImageView.layer.masksToBounds = YES;
    self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width/2;
    
    self.userName = [[UILabel alloc] initWithFrame:CGRectMake(80, 15, [[UIScreen mainScreen] bounds].size.width*0.5, 60)];
    self.userName.backgroundColor = [UIColor whiteColor];
    self.userName.textColor = UIColorFromRGB(0x626262);
    self.userName.font = [UIFont fontWithName:@"GothamRounded-Book" size:16];
    [self.contentView addSubview:self.userName];
    
    self.postedTime = [[UILabel alloc] initWithFrame:CGRectMake(self.userName.frame.size.width+self.userName.frame.origin.x+10, 15, [[UIScreen mainScreen] bounds].size.width*0.22, 60)];
    
    self.postedTime.backgroundColor = [UIColor whiteColor];
    self.postedTime.textAlignment = NSTextAlignmentRight;
    self.postedTime.font = [UIFont fontWithName:@"GothamRounded-Book" size:16];
    self.postedTime.textColor = UIColorFromRGB(0x626262);
    
    [self.contentView addSubview:self.postedTime];
    
    self.postImage = [[YYAnimatedImageView alloc] initWithFrame:CGRectMake(0, 89, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height*0.75)];
    
    self.postImage.contentMode = UIViewContentModeScaleAspectFill;
    self.postImage.clipsToBounds = YES;
    
    self.moviePlayer = [[UIView alloc] initWithFrame:self.postImage.frame];
    
    
//    [self.moviePlayer.view setFrame:self.postImage.frame];
    
    
    
    self.postedTime.contentMode = UIViewContentModeScaleAspectFit;
    self.postImage.backgroundColor = [UIColor whiteColor];
    [self.contentView addSubview:self.postImage];
    
    [self.contentView addSubview:self.moviePlayer];
    
    
    self.postPannelWrapper = [[UIView alloc] initWithFrame:CGRectMake(0, (self.postImage.frame.origin.y+self.postImage.frame.size.height)-self.postImage.frame.size.height*0.3, [[UIScreen mainScreen] bounds].size.width, self.postImage.frame.size.height*0.3)];
    
    self.commentScrollBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, self.postImage.frame.size.height*0.3)];
    self.commentScrollBgView.backgroundColor = [UIColor blackColor];
    self.commentScrollBgView.alpha = 0.5;
    
    
    
    
    self.commentsScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 65, [[UIScreen mainScreen] bounds].size.width, 69)];
    self.commentsScrollView.pagingEnabled = YES;
    self.commentsScrollView.backgroundColor = [UIColor clearColor];
    
    
    self.addCommentButton = [[UIButton alloc] initWithFrame:CGRectMake(26, 28, 24, 32)];
    [self.addCommentButton setBackgroundImage:[UIImage imageNamed:@"feedCommentIcon"] forState:UIControlStateNormal];
    
    
    self.abortCommentButton = [[UIButton alloc] initWithFrame:CGRectMake(26, 32.5, 24, 26)];
    [self.abortCommentButton setBackgroundImage:[UIImage imageNamed:@"backToCameraIcon"] forState:UIControlStateNormal];
//    [self.abortCommentButton addTarget:self action:@selector(abortCommentPressed) forControlEvents:UIControlEventTouchUpInside];
    self.abortCommentButton.alpha = 0;
    
    self.glanceDownButton = [[UIButton alloc] initWithFrame:CGRectMake(self.addCommentButton.frame.origin.x+self.addCommentButton.frame.size.width+8, 27, 35, 30)];
//    self.glanceDownButton.backgroundColor = [UIColor purpleColor];
    [self.glanceDownButton setImage:[UIImage imageNamed:@"glanceDownIcon"] forState:UIControlStateNormal];
//    self.glanceDownButton.imageView.frame = CGRectMake(0, 0, 14, 8);
    [self.glanceDownButton setImageEdgeInsets:UIEdgeInsetsMake(11, 10.5, 11, 10.5)];
    
    
    self.glancesCounter = [[UILabel alloc] initWithFrame:CGRectMake(self.addCommentButton.frame.origin.x+self.addCommentButton.frame.size.width+32, 26, 45, 35)];
    self.glancesCounter.backgroundColor = [UIColor clearColor];
    self.glancesCounter.text = @"5";
    self.glancesCounter.textAlignment = NSTextAlignmentCenter;
    self.glancesCounter.textColor = [UIColor whiteColor];
    self.glancesCounter.font = [UIFont fontWithName:@"GothamRounded-Book" size:42];
    
    self.glanceUpButton = [[UIButton alloc] initWithFrame:CGRectMake(self.addCommentButton.frame.origin.x+self.addCommentButton.frame.size.width+20+45, 25, 35, 30)];
//    self.glanceUpButton.backgroundColor = [UIColor redColor];
    [self.glanceUpButton setImage:[UIImage imageNamed:@"glanceUpIcon"] forState:UIControlStateNormal];
    [self.glanceUpButton setImageEdgeInsets:UIEdgeInsetsMake(11, 10.5, 11, 10.5)];
    
//    self.glancesIcon = [[UIImageView alloc] initWithFrame:CGRectMake(self.glancesCounter.frame.size.width+self.glancesCounter.frame.origin.x, self.glancesCounter.frame.origin.y+3.5, self.frame.size.width/7, 27)];
//    self.glancesIcon.userInteractionEnabled = YES;
//    self.glancesIcon.image = [UIImage imageNamed:@"glancesIconRegular"];
    
    
    self.postForwardButton = [[UIButton alloc] initWithFrame:CGRectMake((self.frame.size.width/2)-30, 28, 25, 25)];
    [self.postForwardButton setBackgroundImage:[UIImage imageNamed:@"feedMoveImageIcon"] forState:UIControlStateNormal];
    
    
    self.feed3DotsButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width-40, 25, 25, 25)];
    [self.feed3DotsButton setBackgroundImage:[UIImage imageNamed:@"feed3Dots"] forState:UIControlStateNormal];
    

    
    self.submitCommentButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width-40, 32.5, 30, 25)];
    [self.submitCommentButton setBackgroundImage:[UIImage imageNamed:@"approveTextIcon"] forState:UIControlStateNormal];
    self.submitCommentButton.alpha = 0;
    
    self.backSpaceKeyBoardButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width-80, 32, 30, 30)];
    [self.backSpaceKeyBoardButton setBackgroundImage:[UIImage imageNamed:@"backSpaceIcon"] forState:UIControlStateNormal];
    self.backSpaceKeyBoardButton.alpha = 0;
    

    
    
    
    
    
    
    
    
    self.commentTextField = [[UITextField alloc] initWithFrame:CGRectMake(self.addCommentButton.frame.origin.x+self.addCommentButton.frame.size.width+10,self.glancesCounter.frame.origin.y+2, 0,35)];
//    self.commentTextField.delegate = self;
    self.commentTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.commentTextField.font = [UIFont systemFontOfSize:15];
    self.commentTextField.placeholder = @"C'mon say somthing";
    //    cell.commentTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.commentTextField.keyboardType = UIKeyboardTypeDefault;
    self.commentTextField.returnKeyType = UIReturnKeyDone;
    //    cell.commentTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    //    cell.commentTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    
    self.commentTextField.keyboardAppearance = UIKeyboardAppearanceDark;
    
    self.postImage.alpha = 1;
    
    
//    self.postImage.image = image;
    
    self.videoBadge = [[UIImageView alloc]initWithFrame:CGRectMake(13, 13, 30, 30)];
    self.videoBadge.alpha = 0;
    self.videoBadge.image = [UIImage imageNamed:@"glanceVideoIcon"];
    [self.postImage addSubview:self.videoBadge];
    
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    CGRect viewBounds = self.postImage.bounds;
    viewBounds.size.height = viewBounds.size.height/1.5;
    self.activityIndicator.center = CGPointMake(CGRectGetMidX(viewBounds), CGRectGetMidY(viewBounds));
    
    [self.postImage addSubview:self.activityIndicator];

    
    [self.contentView addSubview:self.postPannelWrapper];
    [self.postPannelWrapper addSubview:self.commentScrollBgView];
    [self.postPannelWrapper addSubview:self.commentsScrollView];
    [self.postPannelWrapper addSubview:self.glancesCounter];
    [self.postPannelWrapper addSubview:self.postForwardButton];
    [self.postPannelWrapper addSubview:self.addCommentButton];
    [self.postPannelWrapper addSubview:self.abortCommentButton];
    [self.postPannelWrapper addSubview:self.glanceDownButton];
    [self.postPannelWrapper addSubview:self.glanceUpButton];
    [self.postPannelWrapper addSubview:self.feed3DotsButton];
    [self.postPannelWrapper addSubview:self.commentTextField];
    [self.postPannelWrapper addSubview:self.backSpaceKeyBoardButton];
    [self.postPannelWrapper addSubview:self.submitCommentButton];
    
   
    
    
//    [self.contentView bringSubviewToFront:self.moviePlayer.view];
//    self.moviePlayer.view.backgroundColor = [UIColor redColor];
    
    
    CGFloat lineHeight = 4;
    _progressLayer = [CAShapeLayer layer];
    _progressLayer.size = CGSizeMake(self.postImage.width, lineHeight);
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, _progressLayer.height / 2)];
    [path addLineToPoint:CGPointMake(self.postImage.width, _progressLayer.height / 2)];
    _progressLayer.lineWidth = lineHeight;
    _progressLayer.path = path.CGPath;
    _progressLayer.strokeColor = UIColorFromRGB(0x36A7A6).CGColor;
    _progressLayer.lineCap = kCALineCapButt;
    _progressLayer.strokeStart = 0;
    _progressLayer.strokeEnd = 0;
    [self.postImage.layer addSublayer:_progressLayer];

}

-(void)abortCommentDidPressed {
    
    [UIView animateWithDuration:0.2 animations:^{
        //                commentsDialog.alpha = 0;
        self.abortCommentButton.alpha = 0;
        self.addCommentButton.alpha = 1;
        self.feed3DotsButton.alpha = 1;
        //        cell.glancesIcon.alpha = 1;
        self.commentTextField.text = @"";
        self.commentTextField.frame = CGRectMake(self.addCommentButton.frame.origin.x+self.addCommentButton.frame.size.width+10,self.glancesCounter.frame.origin.y+2, 0,35);
        
        self.glancesCounter.alpha = 1;
        
        self.submitCommentButton.alpha = 0;
        self.backSpaceKeyBoardButton.alpha = 0;
        
//        self.glancesCounter.frame = CGRectMake(cell.addCommentButton.frame.origin.x+cell.addCommentButton.frame.size.width+32, 26, 45, 35);
        
        
    } completion:^(BOOL finished) {
        [self hideKeyBoard];
    }];
    
}

-(void)showCommentAreaAndKeyBoard {

    [self showKeyBoard];
    [UIView animateWithDuration:0.3 animations:^{
        
        self.addCommentButton.alpha = 0;
        self.abortCommentButton.alpha = 1;
        self.backSpaceKeyBoardButton.alpha = 1;
        self.submitCommentButton.alpha = 1;
        //        cell.glancesIcon.alpha = 0;
        
        self.commentTextField.frame = CGRectMake(self.commentTextField.frame.origin.x, self.commentTextField.frame.origin.y, self.frame.size.width*0.60, self.commentTextField.frame.size.height);
        self.glancesCounter.alpha = 0;
//        cell.glancesCounter.frame = CGRectMake(cell.commentTextField.frame.origin.x+cell.commentTextField.frame.size.width, cell.glancesCounter.frame.origin.y, cell.glancesCounter.frame.size.width, cell.glancesCounter.frame.size.height);
        
        self.feed3DotsButton.alpha = 0;
        
    } completion:^(BOOL finished) {
//        PMCustomKeyboard *customKeyboard = [[PMCustomKeyboard alloc] init];
        
        
//        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:sender.tag inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        
        
//        [customKeyboard setTextView:cell.commentTextField];
        //        [cell.commentTextField becomeFirstResponder];
        
        //        GLEmojiKeyboard * key = [[GLEmojiKeyboard alloc] init];
        //        [key slideKeyBoardIn];
    }];
    
}

-(void)hideKeyBoard {
    [self.keyboard slideKeyBoardOut];
}

-(void)showKeyBoard {

    self.keyboard = [[GLEmojiKeyboard alloc] initWithView:self.contentView frame:self.postImage.frame];
    self.keyboard.textField = self.commentTextField;
//        [self.contentView bringSubviewToFront:self.postedTime];
//    [self.contentView bringSubviewToFront:self.keyboard.view];

}


- (void)setImageURL:(NSURL *)url {
    _label.hidden = YES;
    _indicator.hidden = NO;
    [_indicator startAnimating];
    __weak typeof(self) _self = self;
    
    [CATransaction begin];
    [CATransaction setDisableActions: YES];
    self.progressLayer.hidden = YES;
    self.progressLayer.strokeEnd = 0;
    [CATransaction commit];
    
    [self.postImage yy_setImageWithURL:url
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

/*
-(void)videoDidStartedPlaying {
    
    [self.activityIndicator startAnimating];
    
    if([self.moviePlayer currentPlaybackTime] > 0.0){
        
        [self.moviePlayer.view setHidden:NO];
        [UIView animateWithDuration:0.2 animations:^{
            [self.activityIndicator stopAnimating];
            self.postImage.alpha = 0;
            //            [self.contentView bringSubviewToFront:self.moviePlayer.view];
        } completion:^(BOOL finished) {
            [self.playBackStartedTester invalidate];
        }];
        
    }
    
}
 */

//- (void)willMoveToSuperview:(UIView *)newSuperview {
//    [super willMoveToSuperview:newSuperview];
//    if(!newSuperview) {
//        
//        [self.moviePlayer stop];
//        self.moviePlayer= nil;
//        
//    }
//}

/*
- (void)playVideo:(SLAlbumServerVideo *)video {

    if(self.moviePlayer.playbackState != MPMoviePlaybackStatePlaying)
    {
        // is not Playing
        self.playBackStartedTester = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                                      target:self
                                                                    selector:@selector(videoDidStartedPlaying)
                                                                    userInfo:nil
                                                                     repeats:YES];
        
        NSURL * videoUrl = [NSURL URLWithString:[video getVideoUrl]];
        [self.moviePlayer setContentURL:videoUrl];
        [self.moviePlayer prepareToPlay];
        [self.moviePlayer play];
    }

    
//
//    }


}
 */

- (void)notifyCellVisibleWithIsCompletelyVisible:(BOOL)completlyVisible {

    
    if(completlyVisible){
        NSLog(@"completlyVisible - %d",completlyVisible);
    }
}


- (void)notifyCompletelyVisible {
    
    NSLog(@"completlyVisible");

    [self.activityIndicator startAnimating];
    [[GLSharedVideoPlayer sharedInstance] play];
}
- (void)notifyNotCompletelyVisible {
//    NSLog(@"unvisible");
}

/*
-(void)playbackStateChanged:(MPMoviePlaybackState)state {
    NSLog(@"playback state %ld",(long)self.moviePlayer.playbackState);
    
    if(self.moviePlayer.playbackState == 1){
        
        
        
//        [self.moviePlayer.view setHidden:NO];
//        [UIView animateWithDuration:0.2 animations:^{
//            self.postImage.alpha = 0;
////            [self.contentView bringSubviewToFront:self.moviePlayer.view];
//        }];
    } else {
        [self.moviePlayer.view setHidden:YES];
        [UIView animateWithDuration:0.2 animations:^{
            self.postImage.alpha = 1;
        }];
    }
}
 */

- (void)loadCellWithData:(NSArray*)data photoFilesManager:(PhotoFilesManager*)photoFilesManager_ {


    SLAlbumPhoto *photo = [data objectAtIndex:1];
    
    long long userID = [[[[data objectAtIndex:0] objectForKey:@"user"] objectForKey:@"id"] longLongValue];
    
//    [self.profileImageView setCircleImageWithURL:[NSURL URLWithString:[[[data objectAtIndex:0] objectForKey:@"user"] objectForKey:@"profile_picture"]] placeholderImage:[UIImage imageNamed:@"ProfilePlaceholder"] borderWidth:2];
    
//    [self.profileImageView yy_setImageWithURL:[NSURL URLWithString:[[[data objectAtIndex:0] objectForKey:@"user"] objectForKey:@"profile_picture"]] placeholder:[UIImage imageNamed:@"ProfilePlaceholder"]];
    
    
    
    [self.profileImageView yy_setImageWithURL:[NSURL URLWithString:[[[data objectAtIndex:0] objectForKey:@"user"] objectForKey:@"profile_picture"]] placeholder:[UIImage imageNamed:@"ProfilePlaceholder"] options:YYWebImageOptionProgressiveBlur | YYWebImageOptionShowNetworkActivity | YYWebImageOptionSetImageWithFadeAnimation completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
        
    }];
    
        self.userName.text = [[[data objectAtIndex:0] objectForKey:@"user"] objectForKey:@"username"];
        self.postedTime.text = [NSString stringWithFormat:@"%@ ago",[[[NSDate alloc] initWithTimeIntervalSince1970:[[[data objectAtIndex:0] objectForKey:@"created_time"] longLongValue]] distanceOfTimeInWords:[NSDate date] shortStyle:YES]];
    
    
    self.glancesCounter.text = [[data objectAtIndex:0] objectForKey:@"likes"];
    
    if([[photo getServerPhoto] getMediaType] == [SLMediaTypeEnum VIDEO]){
        
        self.videoBadge.alpha = 1;
        
        self.moviePlayer.hidden = NO;

//        NSString * videoUrl = [[[photo getServerPhoto] getVideo] getVideoUrl];
//        [[GLSharedVideoPlayer sharedInstance] attachToView:self.moviePlayer withPhotoId:[[photo getServerPhoto] getId] withVideoUrl:videoUrl videoThumbNail:self.postImage.image];
//        [self.activityIndicator startAnimating];
//        SLAlbumServerVideo * video = [[photo getServerPhoto] getVideo];

        
        
        
//                        [cell bringSubviewToFront:self.moviePlayer.view];
//                            [self.moviePlayerController play];
        
        
//        SDWebImageManager *manager = [SDWebImageManager sharedManager];
//        [manager downloadImageWithURL:[NSURL URLWithString:[[[photo getServerPhoto] getVideo] getVideoThumbnailUrl]] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {} completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL)
//        {
//            
//            if (image) {
//                self.postImage.image = image;
//                
////                [self.contentView bringSubviewToFront:self.moviePlayer.view];
////                [self.moviePlayer.view setAlpha:1];
//            }
//            
//         }];
        
//        [self.postImage yy_setImageWithURL:[NSURL URLWithString:[[[photo getServerPhoto] getVideo] getVideoThumbnailUrl]] placeholder:[UIImage imageNamed:@""]];
        
//        [self.postImage yy_setImageWithURL:[NSURL URLWithString:[[[photo getServerPhoto] getVideo] getVideoThumbnailUrl]] placeholder:[UIImage imageNamed:@""] options:YYWebImageOptionProgressiveBlur | YYWebImageOptionShowNetworkActivity | YYWebImageOptionSetImageWithFadeAnimation completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
//            
//        }];
        
        if([[GLPubNubManager sharedInstance] statusForId:[NSString stringWithFormat:@"%lld",[[[photo getServerPhoto] getAuthor]getMemberId]]]){
            
            self.profileImageView.layer.borderColor = UIColorFromRGB(0x40b4b5).CGColor;
            self.profileImageView.layer.borderWidth = 3;
            self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width/2;
            
            
        } else {
            
            self.profileImageView.layer.borderColor = UIColorFromRGB(0xf07480).CGColor;
            self.profileImageView.layer.borderWidth = 3;
            self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width/2;
            
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
             [self setImageURL:[NSURL URLWithString:[[[photo getServerPhoto] getVideo] getVideoThumbnailUrl]]];
        });
        
//        };
        
//        [[MPMusicPlayerController applicationMusicPlayer] setVolume:0];
//        [self.moviePlayer setUseApplicationAudioSession:NO];
//        if ([self.tableView.visibleCells containsObject:self])
//        {
//            [self.moviePlayer setContentURL:videoUrl];
//            [self.moviePlayer prepareToPlay];
//            [self.moviePlayer play];
//        }
//        [self.moviePlayer.view setHidden:NO];
        
        

        
    } else {
        
        self.videoBadge.alpha = 0;
        
        self.moviePlayer.hidden = YES;
        
//        [self.moviePlayer stop];
//        [self.moviePlayer.view removeFromSuperview];
//        [self.moviePlayer.view setHidden:YES];
//        self.moviePlayer = nil;
        
//        [self.postImage setPhoto:[[photo getServerPhoto] getId] photoUrl:[[photo getServerPhoto] getUrl] photoSize:[PhotoSize FeedSize] manager:photoFilesManager_];
        

        if([[GLPubNubManager sharedInstance] statusForId:[NSString stringWithFormat:@"%lld",[[[photo getServerPhoto] getAuthor]getMemberId]]]){
        
            self.profileImageView.layer.borderColor = UIColorFromRGB(0x40b4b5).CGColor;
            self.profileImageView.layer.borderWidth = 3;
            self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width/2;
            
        
        } else {
            
            self.profileImageView.layer.borderColor = UIColorFromRGB(0xf07480).CGColor;
            self.profileImageView.layer.borderWidth = 3;
            self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width/2;
            
        }
        
        
        NSString * thumUrl = [[photo getServerPhoto] getUrl];
        
        NSString *new = [thumUrl stringByReplacingOccurrencesOfString:@".jpg" withString:@"_r_fhd.jpg"];
        
        [self setImageURL:[NSURL URLWithString:new]];
        
        

        
        
//        if([[SDImageCache sharedImageCache] imageFromDiskCacheForKey:[[[photo getServerPhoto]getUrl] stringByReplacingOccurrencesOfString:@".jpg" withString:@"_r_wvga.jpg"]]){
//        
//            self.postImage.image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:[[[photo getServerPhoto]getUrl] stringByReplacingOccurrencesOfString:@".jpg" withString:@"_r_wvga.jpg"]];
//            
//        } else {
//            
//            [self.postImage sd_setImageWithURL:[NSURL URLWithString:[[[photo getServerPhoto]getUrl] stringByReplacingOccurrencesOfString:@".jpg" withString:@"_r_wvga.jpg"]] placeholderImage:[UIImage imageNamed:@""] options:SDWebImageHighPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {
//                
//                NSLog(@"%ld/%ld",(long)receivedSize,(long)expectedSize);
//                
//            } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
//                [[SDImageCache sharedImageCache] storeImage:image forKey:[[[photo getServerPhoto]getUrl] stringByReplacingOccurrencesOfString:@".jpg" withString:@"_r_wvga.jpg"]];
//                [self.tableView reloadData];
//            }];
//        
//
//        }
        
        
    }
    
    



}

-(void)highLightLastCommentInPost {

//    [self.commentsScrollView.subviews objectAtIndex:]
    
    NSMutableArray * arr = [[NSMutableArray alloc] init];
    
    int count = 0;
    
    for(int r=0;r < self.commentsScrollView.subviews.count;r++){
    
        if([[self.commentsScrollView.subviews objectAtIndex:r] isKindOfClass:[UILabel class]]){
            [arr addObject:[self.commentsScrollView.subviews objectAtIndex:r]];
        }
//        count = r;
    }
    UILabel * lastAuthor = [arr objectAtIndex:arr.count-2];
    UILabel * lstCommentText = [arr lastObject];

    [self shakeAnimation:lastAuthor];
    [self shakeAnimation:lstCommentText];
//    [self shakeAnimation:lastAuthor];
//    [self shakeAnimation:lstCommentText];
//    [self shakeAnimation:lastAuthor];
//    [self shakeAnimation:lstCommentText];
    
//    } completion:nil];
//    [self performSelector:@selector(YourFunctionName)
//               withObject:(can be Self or Object from other Classes)
//               afterDelay:(Time Of Delay)];
    
    
//    [UIView animateWithDuration:0.5 delay:1.0 options:UIViewAnimationOptionCurveLinear animations:^{
//        
//        lastAuthor.transform = CGAffineTransformScale(lastAuthor.transform, 2, 2);
//        lstCommentText.transform = CGAffineTransformScale(lstCommentText.transform, 2, 2);
//        
//    } completion:^(BOOL finished) {
//        [UIView animateWithDuration:0.5 animations:^{
//            
//            lastAuthor.transform = CGAffineTransformIdentity;
//            lstCommentText.transform = CGAffineTransformIdentity;
//            
//        } completion:^(BOOL finished) {
//            
//            
//            
//            [UIView animateWithDuration:0.5 animations:^{
//            
//                lastAuthor.transform = CGAffineTransformScale(lastAuthor.transform, 1.5, 1.5);
//                lstCommentText.transform = CGAffineTransformScale(lstCommentText.transform, 1.5, 1.5);
//                
//            } completion:^(BOOL finished) {
//                
//                [UIView animateWithDuration:0.5 animations:^{
//                    lastAuthor.transform = CGAffineTransformIdentity;
//                    lstCommentText.transform = CGAffineTransformIdentity;
//                } completion:^(BOOL finished) {
//                    [UIView animateWithDuration:0.5 delay:1.0 options:UIViewAnimationOptionCurveLinear animations:^{
//                        
//                        lastAuthor.transform = CGAffineTransformScale(lastAuthor.transform, 1.5, 1.5);
//                        lstCommentText.transform = CGAffineTransformScale(lstCommentText.transform, 1.5, 1.5);
//                        
//                    } completion:^(BOOL finished) {
//                        [UIView animateWithDuration:0.5 animations:^{
//                            
//                            lastAuthor.transform = CGAffineTransformIdentity;
//                            lstCommentText.transform = CGAffineTransformIdentity;
//                            
//                        } completion:^(BOOL finished) {
//                            
//                            
//                            
//                            [UIView animateWithDuration:0.5 animations:^{
//                                
//                                lastAuthor.transform = CGAffineTransformScale(lastAuthor.transform, 1.5, 1.5);
//                                lstCommentText.transform = CGAffineTransformScale(lstCommentText.transform, 1.5, 1.5);
//                                
//                            } completion:^(BOOL finished) {
//                                
//                                [UIView animateWithDuration:0.5 animations:^{
//                                    lastAuthor.transform = CGAffineTransformIdentity;
//                                    lstCommentText.transform = CGAffineTransformIdentity;
//                                } completion:^(BOOL finished) {
//                                    
//                                }];
//                                
//                            }];
//                            
//                            
//                        }];
//                    }];
//                }];
//                
//            }];
//            
//            
//        }];
//    }];
    NSLog(@"last comment  is :%@ %@",lastAuthor.text, lstCommentText.text);
    
//    UILabel * lastComment = [self.commentsScrollView.subviews lastObject];
//    NSLog(@"lastComment : %@",lastComment.text);


}
-(void)shakeAnimation:(UILabel*) label
{
    CABasicAnimation *shake = [CABasicAnimation animationWithKeyPath:@"position"];
    [shake setDuration:0.1];
    [shake setRepeatCount:5];
    [shake setAutoreverses:YES];
    [shake setFromValue:[NSValue valueWithCGPoint:
                         CGPointMake(label.center.x - 5,label.center.y)]];
    [shake setToValue:[NSValue valueWithCGPoint:
                       CGPointMake(label.center.x + 5, label.center.y)]];
    [label.layer addAnimation:shake forKey:@"position"];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        
        
        
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
