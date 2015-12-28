//
//  GLUserScore.m
//  shotvibe
//
//  Created by Tsah Kashkash on 17/12/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import "GLUserScore.h"
//#import "ShotVibeAppDelegate.h"

@implementation GLUserScore

-(instancetype)initWithView:(UIView *)view {
    self = [super init];
    if(self){
    
        self.isShown = NO;
        
        self.glanceLogo = [[UIImageView alloc] initWithFrame:CGRectMake((view.frame.size.width)-view.frame.size.width*0.3, 35, view.frame.size.width*0.25, 40)];
        self.glanceLogo.image = [UIImage imageNamed:@"glanceMainLogo"];
        
        long currentUserScore = [[NSUserDefaults standardUserDefaults] integerForKey:@"kUserScore"];
        self.view = [[UIView alloc] initWithFrame:CGRectMake(20, 40, 55, 55)];
        self.userScoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 1.5, 55, 55)];
        self.view.layer.cornerRadius = 27.5;
        
        if(currentUserScore < 10){
            self.userScoreLabel.font = [UIFont fontWithName:@"GothamRounded-Bold" size:26];
        } else if(currentUserScore < 100){
            self.userScoreLabel.font = [UIFont fontWithName:@"GothamRounded-Bold" size:24];
        } else if(currentUserScore < 999 && currentUserScore >= 100){
            self.userScoreLabel.font = [UIFont fontWithName:@"GothamRounded-Bold" size:20];
        } else if (currentUserScore < 9999 && currentUserScore > 999) {
            self.userScoreLabel.font = [UIFont fontWithName:@"GothamRounded-Bold" size:14];
        } else if (currentUserScore < 99999 && currentUserScore > 9999) {
            self.userScoreLabel.font = [UIFont fontWithName:@"GothamRounded-Bold" size:12];
        } else if (currentUserScore > 99999) {
            self.userScoreLabel.font = [UIFont fontWithName:@"GothamRounded-Bold" size:11];
        }
        
        
        self.view.backgroundColor = [UIColor clearColor];
        self.view.layer.borderWidth = 1;
        self.view.layer.borderColor = [UIColor whiteColor].CGColor;
        
        
        
        UITapGestureRecognizer * scoreTapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scoreTapped:)];
        [self.view addGestureRecognizer:scoreTapped];
        
        
        
        
        
        self.userScoreLabel.text = [NSString stringWithFormat:@"%ld",currentUserScore];
        self.userScoreLabel.textAlignment = NSTextAlignmentCenter;
        self.userScoreLabel.textColor = [UIColor whiteColor];
        
        
        
        
        [self.view addSubview:self.userScoreLabel];
        
        [view addSubview:self.glanceLogo];
        [view addSubview:self.view];
        
        
    }
    return self;
}

- (void)showUserScore {
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         
                         self.view.alpha = 1;
                         self.glanceLogo.alpha = 1;
                         self.isShown = YES;
                         
                     } completion:NULL];
}

- (void)hideUserScore {
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         
                         self.view.alpha = 0;
                         self.glanceLogo.alpha = 0;
                         self.isShown = NO;
                         
                     } completion:NULL];
}
- (void)updateScoreFromPush:(int)score {
    
    
    CATransition *animation = [CATransition animation];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.type = kCATransitionFade;
    animation.duration = 0.75;
    [self.userScoreLabel.layer addAnimation:animation forKey:@"kCATransitionFade"];
    
    [[NSUserDefaults standardUserDefaults] setInteger:score forKey:@"kUserScore"];
    self.userScoreLabel.text = [NSString stringWithFormat:@"%d",score];
    
}

-(void)scoreTapped:(UITapGestureRecognizer*)gest {
    
    
//    PubNub * client = [[ShotVibeAppDelegate sharedDelegate] pubNubCLient];
//    [client]
    
//    self.client = [PubNub client];
//    [[[ShotVibeAppDelegate sharedDelegate] pubNubCLient] publish:@{@"announcement": @"Welcome to PubNub!"}
//               toChannel:@"announcements" withCompletion:^(PNPublishStatus *status) {
//                   
//                   // Check whether request successfully completed or not.
//                   if (!status.isError) {
//                       NSLog(@"Message successfully published to specified channel.");
//                       // Message successfully published to specified channel.
//                   }
//                   
//                   // Request processing failed.
//                   else {
//                       NSLog(@"Request processing failed.");
//                       // Handle message publish error. Check 'category' property to find out possible issue
//                       // because of which request did fail.
//                       //
//                       // Request can be resent using: [status retry];
//                   }
//               }];

    
    
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         
                         self.view.transform = CGAffineTransformScale(self.view.transform, 1.5, 1.5);
                         self.view.alpha = 0;
                         
                     } completion:^(BOOL succeded){
                     
                         ShotVibeAppDelegate *appDelegate = (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];
                         GLScoreViewController * scoreView = [[GLScoreViewController alloc] init];
                         UINavigationController * nav = [[UINavigationController alloc] initWithRootViewController:scoreView];
                         nav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                         [nav setNavigationBarHidden:YES animated:NO];
                         [appDelegate.window.rootViewController presentViewController:nav animated:YES completion:^{
                             self.view.transform = CGAffineTransformIdentity;
                             self.view.alpha = 1;
                         }];
                         
                     }];

    
}

@end
