//
//  GLProfilePageViewController.m
//  shotvibe
//
//  Created by Tsah Kashkash on 16/11/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import "GLProfilePageViewController.h"
#import "ShotVibeAPI.h"
#import "ShotVibeAppDelegate.h"
#import "AlbumUser.h"
//#import "UIImageView+WebCache.h"
#import "UIImage+ImageEffects.h"
#import "YYWebImage.h"
#import "MBProgressHUD.h"
#import "GLContainersViewController.h"

@interface GLProfilePageViewController (){
    UIImageView * bg;
    BOOL imagePressed;
    CGRect origiImageFrame;
    CGPoint origiImageCenter;
}

@end

@implementation GLProfilePageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    imagePressed = NO;
    origiImageFrame = self.userProfileImage.frame;
    origiImageCenter = self.userProfileImage.center;
    self.userProfileImage.userInteractionEnabled = YES;
    
    UITapGestureRecognizer * profilePicTapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(profilePicPressed)];
    
    //    SLShotVibeAPI *shotvibeAPI = [[ShotVibeAppDelegate sharedDelegate].albumManager getShotVibeAPI];
    
    //    int64_t userId = (long)self.userId;//[[shotvibeAPI getAuthData] getUserId];
    SLAlbumUser * user = [self.slMemberObject getUser];
    
    if(self.imAdmin){
        //        self.reinviteButton.enabled = NO;
        self.removeButton.enabled = NO;
    } else {
        //        self.reinviteButton.enabled = YES;
        self.removeButton.enabled = YES;
    }
    
    
    if(self.fromPublicFeed){
        self.removeButton.hidden = YES;
        self.reinviteButton.hidden = YES;
    }
    //    self.userScore.text = [NSString stringWithFormat:@"%04ld",(long)[[NSUserDefaults standardUserDefaults] integerForKey:@"kUserScore"]];
    
    //    self.userScore.text = [NSString stringWithFormat:@"%04ld",(long)[[NSUserDefaults standardUserDefaults] integerForKey:@"kUserScore"]];
    
    self.userScore.text = [NSString stringWithFormat:@"%04d",[user getUserGlanceScore]];
    
    
    //    CGSize stringsize = [self.userScore.text sizeWithAttributes:@{}];
    //
    //    [self.userScore setFrame:CGRectMake(self.userScore.frame.origin.x,self.userScore.frame.origin.y,stringsize.width, stringsize.height)];
    
    
    
    
    
    self.userNickName.text = [user getMemberNickname];
    [self.userProfileImage yy_setImageWithURL:[NSURL URLWithString:[user getMemberAvatarUrl]] options:YYWebImageOptionProgressiveBlur | YYWebImageOptionShowNetworkActivity | YYWebImageOptionSetImageWithFadeAnimation];
    //    [self.userProfileImage sd_setImageWithURL:[NSURL URLWithString:[user getMemberAvatarUrl]]];
    
    self.userProfileImage.layer.cornerRadius = self.userProfileImage.frame.size.width/2;
    self.userProfileImage.clipsToBounds = YES;
    //    self.userProfileImage.
    
    self.removeButton.layer.borderWidth = 2;
    self.removeButton.layer.borderColor = self.removeButton.titleLabel.textColor.CGColor;
    self.removeButton.layer.cornerRadius = self.reinviteButton.frame.size.height/2;
    
    self.reinviteButton.layer.borderWidth = 2;
    self.reinviteButton.layer.borderColor = self.reinviteButton.titleLabel.textColor.CGColor;
    self.reinviteButton.layer.cornerRadius = self.reinviteButton.frame.size.height/2;
    
    [self.userProfileImage addGestureRecognizer:profilePicTapped];
    [self.view bringSubviewToFront:self.userProfileImage];
    
    bg = [[UIImageView alloc] initWithFrame:self.view.frame];
    bg.alpha = 0;
    bg.image = self.userProfileImage.image;
    [self.view addSubview:bg];
    bg.image = [bg.image applyBlurWithRadius:10 tintColor:[UIColor colorWithWhite:0.6 alpha:0.2] saturationDeltaFactor:1.0 maskImage:nil];
    [self.view sendSubviewToBack:bg];
    self.view.clipsToBounds = YES;
    //    self.profileEditButton.layer.cornerRadius = self.pro
    // Do any additional setup after loading the view from its nib.
}

-(void)viewWillDisappear:(BOOL)animated {

    
    [[GLContainersViewController sharedInstance] enableSideMembers];
    [super viewWillDisappear:animated];
    self.view.alpha = 0;
    
//    [UIView animateWithDuration:0.3 animations:^{
//        self.userProfileImage.transform = CGAffineTransformScale(self.userProfileImage.transform, 1.2, 1.2);
//    } completion:^(BOOL finished) {
//        [UIView animateWithDuration:0.15 animations:^{
//            self.userProfileImage.transform = CGAffineTransformIdentity;
//        } completion:^(BOOL finished) {
//            
//            [UIView animateWithDuration:0.5 animations:^{
//                
//                
//                
//                
//                //        self.userProfileImage.layer.cornerRadius = self.view.frame.size.width/2;
//                self.userProfileImage.center = origiImageCenter;
//                bg.alpha = 0;
//                
//                self.userNickName.alpha = 1;
//                self.userScore.alpha = 1;
//                self.scoreLabel.alpha = 1;
//                self.reinviteButton.alpha = 1;
//                self.removeButton.alpha = 1;
//                //
//            } completion:^(BOOL finished) {
//                
//                [UIView animateWithDuration:0.3 animations:^{
//                    
//                    //            CGRect frame = self.userProfileImage.frame;
//                    
//                    self.userProfileImage.transform = CGAffineTransformIdentity;
//                   
//                    //                    frame.size.width = self.view.frame.size.width;
//                    //                    frame.size.height = self.view.frame.size.width;
//                    //            self.userProfileImage.frame = CGRectMake(0, frame.origin.y, self.view.frame.size.width*0.9, self.view.frame.size.width*0.9);
//                }];
//                
//                
//            }];
//            
//        }];
//    }];

    
}


-(void)profilePicPressed {
    
    
    if(imagePressed){
        
        
        
        [UIView animateWithDuration:0.3 animations:^{
            self.userProfileImage.transform = CGAffineTransformScale(self.userProfileImage.transform, 1.2, 1.2);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.15 animations:^{
                self.userProfileImage.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                
                [UIView animateWithDuration:0.2 animations:^{
                    
                    
                    
                    
                    //        self.userProfileImage.layer.cornerRadius = self.view.frame.size.width/2;
                    self.userProfileImage.center = origiImageCenter;
                    bg.alpha = 0;
                    
                    self.userNickName.alpha = 1;
                    self.userScore.alpha = 1;
                    self.scoreLabel.alpha = 1;
                    self.reinviteButton.alpha = 1;
                    self.removeButton.alpha = 1;
                    //
                } completion:^(BOOL finished) {
                    
                    [UIView animateWithDuration:0.2 animations:^{
                        
                        //            CGRect frame = self.userProfileImage.frame;
                        
                        self.userProfileImage.transform = CGAffineTransformIdentity;
                        //                    frame.size.width = self.view.frame.size.width;
                        //                    frame.size.height = self.view.frame.size.width;
                        //            self.userProfileImage.frame = CGRectMake(0, frame.origin.y, self.view.frame.size.width*0.9, self.view.frame.size.width*0.9);
                    }];
                    
                    
                }];
                
            }];
        }];
        
        
    } else {
    
        [UIView animateWithDuration:0.3 animations:^{
            self.userProfileImage.transform = CGAffineTransformScale(self.userProfileImage.transform, 0.70, 0.70);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.15 animations:^{
                self.userProfileImage.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                
                [UIView animateWithDuration:0.2 animations:^{
                    
                    
                    
                    
                    //        self.userProfileImage.layer.cornerRadius = self.view.frame.size.width/2;
                    self.userProfileImage.center = self.view.center;
                    bg.alpha = 1;
                    
                    self.userNickName.alpha = 0;
                    self.userScore.alpha = 0;
                    self.scoreLabel.alpha = 0;
                    self.reinviteButton.alpha = 0;
                    self.removeButton.alpha = 0;
                    //
                } completion:^(BOOL finished) {
                    
                    [UIView animateWithDuration:0.2 animations:^{
                        
                        //            CGRect frame = self.userProfileImage.frame;
                        
                        self.userProfileImage.transform = CGAffineTransformScale(self.userProfileImage.transform, 2.8, 2.8);
                        //                    frame.size.width = self.view.frame.size.width;
                        //                    frame.size.height = self.view.frame.size.width;
                        //            self.userProfileImage.frame = CGRectMake(0, frame.origin.y, self.view.frame.size.width*0.9, self.view.frame.size.width*0.9);
                    }];
                    
                    
                }];
                
            }];
        }];
        
        
    }
    imagePressed = !imagePressed;
    
    
    
    
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
//-(void)viewWillDisappear:(BOOL)animated {
//    [super viewWillDisappear:animated];
//    [[GLContainersViewController sharedInstance] enableSideMembers];
//}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[GLContainersViewController sharedInstance] disableSideMembers];
    //    [MBProgressHUD hideHUDForView:[[ShotVibeAppDelegate sharedDelegate] window] animated:YES];
    //    [MBProgressHUD hideHUDAddedTo: animated:YES];
}




- (IBAction)removePressed:(id)sender {
    
    //Remove User
//    put in task
//    [[[ShotVibeAppDelegate sharedDelegate].albumManager getShotVibeAPI] albumRemoveMemberWithLong:@"album id" withLong:@"user id"];
    
    
    
    
}

- (IBAction)reinvitePressed:(id)sender {
    //Re Invite User to group
    //Only if you originally invited the user to the group;

    //Run In Task;
    
//    SLShotVibeAPI_AlbumMemberPhoneNumber * result = [[[ShotVibeAppDelegate sharedDelegate].albumManager getShotVibeAPI] getAlbumMemberPhoneNumberWithLong:@"albumid" withLong:@"userid"];
    
    
    //TODO send to i message with text .
//    [result getPhoneNumber];
    
}
@end
