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
#import "YYWebImage.h"
#import "MBProgressHUD.h"

@interface GLProfilePageViewController ()

@end

@implementation GLProfilePageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    
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
    
    self.userScore.text = [NSString stringWithFormat:@"%04d",[[[ShotVibeAppDelegate sharedDelegate].albumManager getShotVibeAPI] getUserGlanceScoreWithLong:self.userId]];
    
    
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
    
    
//    self.profileEditButton.layer.cornerRadius = self.pro
    // Do any additional setup after loading the view from its nib.
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

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
//    [MBProgressHUD hideHUDForView:[[ShotVibeAppDelegate sharedDelegate] window] animated:YES];
//    [MBProgressHUD hideHUDAddedTo: animated:YES];
}

- (IBAction)removePressed:(id)sender {

    
    
}

- (IBAction)reinvitePressed:(id)sender {

    

}
@end
