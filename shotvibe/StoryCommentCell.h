//
//  StoryCommentCell.h
//  ParallaxTableViewHeader
//
//  Created by Vinodh  on 26/10/14.
//  Copyright (c) 2014 Daston~Rhadnojnainva. All rights reserved.

//

#import <UIKit/UIKit.h>

static NSString *kCommentsKey   = @"Comments";
static NSString *kCommentKey    = @"Comment";
static NSString *kTimeKey       = @"Time";
static NSString *kLikesCountKey = @"LikesCount";

static NSString *kCellIdentifier = @"storyCellId";

@interface StoryCommentCell : UITableViewCell
+ (void)setTableViewWidth:(CGFloat)tableWidth;
+ (id)storyCommentCellForTableWidth:(CGFloat)width;
+ (CGFloat)cellHeightForComment:(NSString *)comment;
- (void)configureCommentCellForComment:(NSDictionary *)comment;
@end

// Copyright belongs to original author
// http://code4app.net (en) http://code4app.com (cn)
// From the most professional code share website: Code4App.net 
