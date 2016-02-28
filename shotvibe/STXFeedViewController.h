//
//  STXFeedViewController.h
//
//  Created by Jesse Armand on 20/1/14.
//  Copyright (c) 2014 2359 Media. All rights reserved.
//


#import "UIImageView+Masking.h"
#import "SDWebImageManager.h"

#import "UIImageView+WebCache.h"

#import "PhotoImageView.h"
#import "SL/AlbumPhotoComment.h"

@protocol STXFeedPhotoCellDelegate;
@protocol STXLikesCellDelegate;
@protocol STXCaptionCellDelegate;
@protocol STXCommentCellDelegate;
@protocol STXUserActionDelegate;

//@protocol STXFeedPhotoCellDelegate;
//@protocol STXLikesCellDelegate;
//@protocol STXCaptionCellDelegate;
//@protocol STXCommentCellDelegate;
//@protocol STXUserActionDelegate;

@class STXLikesCell;
@class STXCaptionCell;
@class STXCommentCell;

@interface STXFeedViewController : UIViewController

- (instancetype)initWithController:(id<STXFeedPhotoCellDelegate, STXLikesCellDelegate, STXCaptionCellDelegate, STXCommentCellDelegate, STXUserActionDelegate>)controller
                         tableView:(UITableView *)tableView;

- (STXLikesCell *)likesCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath;
- (STXCaptionCell *)captionCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath;
- (STXCommentCell *)commentCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath;

@property(nonatomic) long long int albumId;

@property (nonatomic) BOOL insertingRow;



@property (retain, nonatomic) NSMutableArray *posts;

- (instancetype)initWithController:(id<STXFeedPhotoCellDelegate, STXLikesCellDelegate, STXCaptionCellDelegate, STXCommentCellDelegate, STXUserActionDelegate>)controller;

- (void)reloadAtIndexPath:(NSIndexPath *)indexPath forTableView:(UITableView *)tableView;

@end
