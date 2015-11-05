//
//  GLFeedTableCell.h
//  shotvibe
//
//  Created by Tsah Kashkash on 26/10/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GLFeedTableCell : UITableViewCell

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

@end
