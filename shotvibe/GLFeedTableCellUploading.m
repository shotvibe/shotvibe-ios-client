//
//  GLFeedTableCell.m
//  shotvibe
//
//  Created by Tsah Kashkash on 26/10/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import "GLFeedTableCellUploading.h"
#import "AMTumblrHud.h"
#import "SL/AlbumUploadingMediaPhoto.h"
//#import "SL/AlbumUploadingMediaVideo.h"
#import "YYWebImage.h"
#import "UIImage+ImageEffects.h"


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
    
    
    self.postTempImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 89, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height*0.75)];
    
    self.postTempImage.contentMode = UIViewContentModeScaleAspectFill;
    self.postTempImage.clipsToBounds = YES;
    
    [self.contentView addSubview:self.postTempImage];
    

//    [self.postTempImage yy_setImageWithURL:[NSURL fileURLWithPath:filePath] options:YYWebImageOptionProgressiveBlur | YYWebImageOptionShowNetworkActivity | YYWebImageOptionSetImageWithFadeAnimation];
    
//    [self.postTempImage sd_setImageWithURL:[NSURL fileURLWithPath:filePath] placeholderImage:[UIImage imageNamed:@""] options:SDWebImageRefreshCached];
//    NSFileManager *fileManager = [NSFileManager defaultManager];
    self.postTempImage.image = [[UIImage alloc] init];
//    BOOL success = [fileManager removeItemAtPath:filePath error:nil];
    
    self.circleProgressView = [[CircleProgressView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width/5, self.frame.size.width/5)];
    self.circleProgressView.progressLabel.alpha = 0 ;
    self.circleProgressView.center = self.postImage.center;
    self.circleProgressView.timeLimit = 100;
    self.circleProgressView.tintColor = UIColorFromRGB(0x3eb4b6);
    
    //    self.circleProgressView.
    self.circleProgressView.elapsedTime = 0;
    
    [UIView animateWithDuration:1 animations:^{
        self.circleProgressView.alpha = 1;
    }];
//    self.circleProgressView.alpha = 1;
    [self.contentView addSubview:self.circleProgressView];
    
    
    
    UILabel * title = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, self.frame.size.width, 60)];
    title.text = @"Uploading";
    title.font = [UIFont fontWithName:@"GothamRounded-Bold" size:34];
    title.textAlignment = NSTextAlignmentCenter;
//    [self.contentView addSubview:title];
  
    
    self.profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 15, 60, 60)];
    [self.contentView addSubview:self.profileImageView];
    self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width/2;
    
    self.userName = [[UILabel alloc] initWithFrame:CGRectMake(80, 15, [[UIScreen mainScreen] bounds].size.width*0.5, 60)];
    self.userName.backgroundColor = [UIColor whiteColor];
    self.userName.textColor = UIColorFromRGB(0x626262);
    self.userName.font = [UIFont fontWithName:@"GothamRounded-Book" size:16];
    [self.contentView addSubview:self.userName];
    [self.contentView addSubview:self.profileImageView];
    self.userName.text = @"Uploading..";
    
    [self.profileImageView setImage:[UIImage imageNamed:@"CaptureButton"]];
    
    self.postTempImage = [[UIImageView alloc] initWithFrame:self.postImage.frame];
    [self.contentView addSubview:self.postTempImage];
    
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
    
    
    self.postImage.alpha = 1;
    self.postTempImage.alpha =1;
    CATransition *animation = [CATransition animation];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.type = kCATransitionFade;
    animation.duration = 0.1;
    [self.postTempImage.layer addAnimation:animation forKey:@"kCATransitionFade"];
    [self.postImage.layer addAnimation:animation forKey:@"kCATransitionFade"];

    
    

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
    
//    SLMediaTypeEnum * type = [albumMedia getMediaType];
    
    float progress = [albumMedia getProgress];
    NSLog(@"progress is :%f",progress);
    
    
//    if([albumMedia getMediaType] == [SLMediaTypeEnum VIDEO]){
//        NSString *previewImageFile = [[albumMedia getVideo] getPreviewImageFile];
//        [self.postImage.imageView_ sd_setImageWithURL:[NSURL fileURLWithPath:previewImageFile]];
//    } else {
    
        
        
        if(progress == 0.000000){
//            [self awakeFromNib];
//            SLAlbumUploadingMediaPhoto * photo;
//            SLAlbumUploadingMediaVideo * video;
            NSString * previewImageFile;
            
            if([albumMedia getMediaType] == [SLMediaTypeEnum VIDEO]){
//                photo = [albumMedia getVideo];
                previewImageFile = [[albumMedia getVideo] getPreviewImageFile];
                
            } else {
//                photo =[albumMedia getPhoto];
                previewImageFile = [[albumMedia getPhoto] getPreviewImageFile];
            }
            
//           self.postImage.alpha = 0;
            self.postImage.imageView_.image = [UIImage imageWithContentsOfFile:previewImageFile];
            
            self.circleProgressView.alpha = 1;
            self.circleProgressView.elapsedTime = 0;
//            self.ci
            
            self.postTempImage.alpha = 1;
            self.postTempImage.image = [[UIImage imageWithContentsOfFile:previewImageFile] applyBlurWithRadius:30 tintColor:[UIColor colorWithWhite:0.6 alpha:0.2] saturationDeltaFactor:1.0 maskImage:nil];
            
//             __weak typeof(self) weakSelf = self;
//            dispatch_async(dispatch_get_main_queue(), ^{
            
                
//            });
            
            
            
            

    
        }
//    }

    self.postTempImage.alpha = 1-progress;
    self.circleProgressView.elapsedTime = progress*100;
    if (progress == 1) {
        
        [UIView animateWithDuration:1 animations:^{
            self.circleProgressView.alpha = 0;
        }];
    }
    

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
