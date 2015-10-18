//
//  STXFeedPhotoCell.m
//  STXDynamicTableView
//
//  Created by Triệu Khang on 24/3/14.
//  Copyright (c) 2014 2359 Media. All rights reserved.
//

#import "STXFeedPhotoCell.h"

#import "UIImageView+Masking.h"
#import "SDWebImageManager.h"

#import "UIImageView+WebCache.h"

#import "PhotoImageView.h"



@interface STXFeedPhotoCell ()

@property (weak, nonatomic) IBOutlet UILabel *profileLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UIImageView *postImageView;

@end

@implementation STXFeedPhotoCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.profileImageView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *imageGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(profileTapped:)];
    [self.profileImageView addGestureRecognizer:imageGestureRecognizer];
    
    self.profileLabel.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *labelGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(profileTapped:)];
    [self.profileLabel addGestureRecognizer:labelGestureRecognizer];
    
    self.dateLabel.backgroundColor = [self.dateLabel superview].backgroundColor;
    
    self.profileImageView.clipsToBounds = YES;

    self.postImageView.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)setPostItem:(id<STXPostItem>)postItem
{
    if (_postItem != postItem) {
        _postItem = postItem;
        
        self.dateLabel.textColor = [UIColor grayColor];
        self.dateLabel.text = [MHPrettyDate prettyDateFromDate:postItem.postDate withFormat:MHPrettyDateLongRelativeTime];
        
        id<STXUserItem> userItem = [postItem user];
        NSString *name = [userItem fullname];
        self.profileLabel.text = name;
        NSURL *profilePhotoURL = [userItem profilePictureURL];
        
        [self.profileImageView setCircleImageWithURL:profilePhotoURL placeholderImage:[UIImage imageNamed:@"ProfilePlaceholder"] borderWidth:2];
        
//        SDWebImageManager *manager = [SDWebImageManager sharedManager];
//        [manager ]
//        SDWebImageOptions.CacheMemoryOnly
        
         __block UIView * loading = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, self.frame.size.height/7)];
        loading.backgroundColor = [UIColor greenColor];
        [self addSubview:loading];
        
        

        
//        [self.postImageView setPhoto:postItem.postID photoUrl:[postItem.photoURL absoluteString] photoSize:[PhotoSize Thumb75] manager:[ShotVibeAppDelegate sharedDelegate].photoFilesManager];
        
        self.postImageView.alpha = 0 ;
        
        [self.postImageView sd_setImageWithURL:postItem.photoURL placeholderImage:[UIImage imageNamed:@"feedPlaceHolder"] options:SDWebImageHighPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            
            float progress  = (float)receivedSize / (float)expectedSize;
            
            
            [UIView animateWithDuration:0.15 animations:^{
//                loading.hidden = YES;
//                self.postImageView.alpha = 1 ;
                loading.frame = CGRectMake(0, 0, self.frame.size.width*progress, self.frame.size.height/7);
            }];
            
            if(progress == 1){
                loading.hidden = YES;
            }
            
//            NSLog(@"%f",(float)receivedSize / (float)expectedSize);
            
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            
            [UIView animateWithDuration:0.15 animations:^{
                
                self.postImageView.alpha = 1 ;
            } completion:^(BOOL completed){
                loading.hidden = YES;
            }];
            
        }];
        
//        [manager downloadImageWithURL:postItem.photoURL options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
//            
//        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
//            
//            [self.postImageView setImage:image];
//        }];
        
//        self.imageView sd_set
        
//        [self.postImageView sd_setImageWithURL:[NSURL URLWithString:@"http://www.domain.com/path/to/image.jpg"] placeholderImage:[UIImage imageNamed:@"placeholder.png"]];
//        [manager downloadWithURL:postItem.photoURL options:0 progress:^(NSUInteger receivedSize, long long expectedSize) {
//            
//        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
//            
//            if(image){
//                
//            }
//            
//        }];
//        [self.postImageView d];
        
//        [self.postImageView setImageWithURL:postItem.photoURL];
    }
}

- (UIImage *)photoImage
{
    _photoImage = self.postImageView.image;
    return _photoImage;
}

- (void)cancelImageLoading
{
    [self.profileImageView cancelImageRequestOperation];
    [self.profileImageView setCircleImageWithURL:nil placeholderImage:[UIImage imageNamed:@"ProfilePlaceholder"]];
    
//    [self.postImageView cancelImageRequestOperation];
    self.postImageView.image = nil;
}

#pragma mark - Actions

- (void)profileTapped:(UIGestureRecognizer *)recognizer
{
    if ([self.delegate respondsToSelector:@selector(feedCellWillShowPoster:)])
        [self.delegate feedCellWillShowPoster:[self.postItem user]];
}

@end
