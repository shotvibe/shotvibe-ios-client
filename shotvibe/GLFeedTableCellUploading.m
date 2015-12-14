//
//  GLFeedTableCell.m
//  shotvibe
//
//  Created by Tsah Kashkash on 26/10/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import "GLFeedTableCellUploading.h"
#import "AMTumblrHud.h"


@implementation GLFeedTableCellUploading

//-(void)
- (void)awakeFromNib {
    
//    self.contentView.layer.borderWidth = 1;
//    self.contentView.layer.borderColor = [UIColor redColor].CGColor;
    

    
    
    
    
//    [self addObserver:self forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew context:nil];
    // Initialization code
//    NSLog(@"testtest");
//    self.profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 15, 60, 60)];
//    [self.contentView addSubview:self.profileImageView];
//    
//    self.userName = [[UILabel alloc] initWithFrame:CGRectMake(80, 15, [[UIScreen mainScreen] bounds].size.width*0.5, 60)];
//    self.userName.backgroundColor = [UIColor whiteColor];
//    self.userName.textColor = UIColorFromRGB(0x626262);
//    self.userName.font = [UIFont fontWithName:@"GothamRounded-Book" size:16];
//    [self.contentView addSubview:self.userName];
//    
//    self.postedTime = [[UILabel alloc] initWithFrame:CGRectMake(self.userName.frame.size.width+self.userName.frame.origin.x+10, 15, [[UIScreen mainScreen] bounds].size.width*0.22, 60)];
//    
//    self.postedTime.backgroundColor = [UIColor whiteColor];
//    self.postedTime.textAlignment = NSTextAlignmentRight;
//    self.postedTime.font = [UIFont fontWithName:@"GothamRounded-Book" size:16];
//    self.postedTime.textColor = UIColorFromRGB(0x626262);
//    
//    [self.contentView addSubview:self.postedTime];
//    
    self.postImage = [[PhotoView alloc] initWithFrame:CGRectMake(0, 89, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height*0.75)];
    
    self.postImage.contentMode = UIViewContentModeScaleAspectFill;
    self.postImage.clipsToBounds = YES;
    
    [self.contentView addSubview:self.postImage];
    
    self.circleProgressView = [[CircleProgressView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width/5, self.frame.size.width/5)];
    self.circleProgressView.timeLimit = 100;
    self.circleProgressView.tintColor = UIColorFromRGB(0x3eb4b6);
    //    self.circleProgressView.
    self.circleProgressView.elapsedTime = 0;
    [self.contentView addSubview:self.circleProgressView];
    
    
    
    
//
//
//    
//    
//    self.postedTime.contentMode = UIViewContentModeScaleAspectFit;
//    self.postImage.backgroundColor = [UIColor whiteColor];
//    [self.contentView addSubview:self.postImage];
//    
//
//    
//    
//   
//  
//    
//
//    
//    
//    
//    
//    
//    
//    self.postImage.alpha = 1;
//    
//    
////    self.postImage.image = image;
//    
//    self.videoBadge = [[UIImageView alloc]initWithFrame:CGRectMake(13, 13, 30, 30)];
//    self.videoBadge.alpha = 0;
//    self.videoBadge.image = [UIImage imageNamed:@"glanceVideoIcon"];
//    [self.postImage addSubview:self.videoBadge];
    
    
    
   

    
    

}

- (void)updateProccesingStatus:(SLAlbumPhoto *)photo {

    self.circleProgressView.progressLabel.alpha = 0;
    self.circleProgressView.alpha = 0;
    
    AMTumblrHud *tumblrHUD = [[AMTumblrHud alloc] initWithFrame:CGRectMake((CGFloat) ((self.contentView.frame.size.width - 55) * 0.5),
                                                                           (CGFloat) ((self.contentView.frame.size.height - 20) * 0.5), 55, 20)];
    tumblrHUD.hudColor = UIColorFromRGB(0x3eb4b6);
    [self.contentView addSubview:tumblrHUD];
    
    [tumblrHUD showAnimated:YES];
    


}

- (void)updateUploadingStatus:(SLAlbumUploadingMedia*)albumMedia {
    
//    slalbum
    
    [albumMedia getMediaType];
    
    float progress = [albumMedia getProgress];
    
    NSString *previewImageFile = [[albumMedia getVideo] getPreviewImageFile];
    self.circleProgressView.elapsedTime = progress*100;
    
//    [[albumMedia getVideo] getThumbNailFile];
    
    __block NSString *filePath = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/Library/Caches/Photo%i.jpg", 0]];
    [self.postImage.imageView_ sd_setImageWithURL:[NSURL fileURLWithPath:filePath]];
    
}



//- (void)loadCellWithData:(NSArray*)data photoFilesManager:(PhotoFilesManager*)photoFilesManager_ {
//
//
//    SLAlbumPhoto *photo = [data objectAtIndex:1];
//    
//    
//    __weak typeof(self) weakSelf = self;
//    
//    [self.postImage.imageView_ sd_setImageWithURL:[NSURL URLWithString:@"http://weknowyourdreams.com/images/space/space-09.jpg"] placeholderImage:[UIImage imageNamed:@""] options:SDWebImageCacheMemoryOnly progress:^(NSInteger receivedSize, NSInteger expectedSize) {
//        
//            CGFloat progresses = ((CGFloat)receivedSize / (CGFloat)expectedSize);
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            weakSelf.circleProgressView.elapsedTime = progresses*100;
//        });
//        
////        if(progress){
////            progress();
////        }
////        NSLog(@"progress %f",progress);
//        
//        
//    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
//        
//    }];
//    
//    
////    long long userID = [[[[data objectAtIndex:0] objectForKey:@"user"] objectForKey:@"id"] longLongValue];
////    
////    [self.profileImageView setCircleImageWithURL:[NSURL URLWithString:[[[data objectAtIndex:0] objectForKey:@"user"] objectForKey:@"profile_picture"]] placeholderImage:[UIImage imageNamed:@"ProfilePlaceholder"] borderWidth:2];
////    
////        self.userName.text = [[[data objectAtIndex:0] objectForKey:@"user"] objectForKey:@"username"];
////        self.postedTime.text = [NSString stringWithFormat:@"%@ ago",[[[NSDate alloc] initWithTimeIntervalSince1970:[[[data objectAtIndex:0] objectForKey:@"created_time"] longLongValue]] distanceOfTimeInWords:[NSDate date] shortStyle:YES]];
////    
////    
////
////    
////    if([[photo getServerPhoto] getMediaType] == [SLAlbumServerPhoto_MediaTypeEnum VIDEO]){
////        
////        self.videoBadge.alpha = 1;
////        
////
////
////        NSString * videoUrl = [[[photo getServerPhoto] getVideo] getVideoUrl];
//////        [[GLSharedVideoPlayer sharedInstance] attachToView:self.moviePlayer withPhotoId:[[photo getServerPhoto] getId] withVideoUrl:videoUrl videoThumbNail:self.postImage.image];
////
////        
////        SDWebImageManager *manager = [SDWebImageManager sharedManager];
////        [manager downloadImageWithURL:[NSURL URLWithString:[[[photo getServerPhoto] getVideo] getVideoThumbnailUrl]] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {} completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL)
////        {
////            
////            if (image) {
////                self.postImage.image = image;
////                
//////                [self.contentView bringSubviewToFront:self.moviePlayer.view];
//////                [self.moviePlayer.view setAlpha:1];
////            }
////            
////         }];
////        
////
////        
////        
////
////        
////    } else {
////        
////        self.videoBadge.alpha = 0;
////        
////
////        [self.postImage setPhoto:[[photo getServerPhoto] getId] photoUrl:[[photo getServerPhoto] getUrl] photoSize:[PhotoSize FeedSize] manager:photoFilesManager_];
////        
////  
////        
////        
////    }
////    
//    
//
//
//
//}


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
