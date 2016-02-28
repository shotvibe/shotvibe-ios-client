//
//  STXFeedPhotoCell.h
//  STXDynamicTableView
//
//  Created by Triệu Khang on 24/3/14.
//  Copyright (c) 2014 2359 Media. All rights reserved.
//

//@import UIKit;

#import "PhotoView.h"

#import "ShotVibeAppDelegate.h"
#import "PhotoSize.h"

@protocol STXFeedPhotoCellDelegate <NSObject>

@optional

- (void)feedCellWillShowPoster:(id <STXUserItem>)poster;

@end

@interface STXFeedPhotoCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *greyImageView;
@property (weak, nonatomic) IBOutlet UILabel *profileLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet PhotoView *postImageView;

@property (strong, nonatomic) NSIndexPath *indexPath;

@property (strong, nonatomic) id <STXPostItem> postItem;
@property (strong, nonatomic) UIImage *photoImage;

@property (weak, nonatomic) id <STXFeedPhotoCellDelegate> delegate;

@property(nonatomic,retain) UIImage * uploadedImage;

@property (nonatomic) BOOL justUploaded;

- (void)cancelImageLoading;

@end
