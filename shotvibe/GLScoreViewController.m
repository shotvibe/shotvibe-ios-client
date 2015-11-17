//
//  GLScoreViewController.m
//  shotvibe
//
//  Created by Tsah Kashkash on 15/11/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import "GLScoreViewController.h"
#import "ShotVibeAPI.h"
#import "GLSharedCamera.h"
#import "SVSettingsViewController.h"
@interface GLScoreViewController ()

@end

@implementation GLScoreViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
//     [[[GLSharedCamera sharedInstance] score] setText:]];
    
    
    self.userScore.text = [NSString stringWithFormat:@"%@",[NSString stringWithFormat:@"%ld",(long)[[NSUserDefaults standardUserDefaults] integerForKey:@"kUserScore"]]];
    
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


-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (IBAction)backPressed:(id)sender {
    ShotVibeAppDelegate *appDelegate = (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];
//    GLScoreViewController * scoreView = [[GLScoreViewController alloc] init];
    
    [[GLSharedCamera sharedInstance] showGlCameraView];
    [appDelegate.window.rootViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
//    [appDelegate.window.rootViewController presentViewController:scoreView animated:YES completion:^{
    
//    }];
}
- (IBAction)showSettings:(id)sender {
    
//    ShotVibeAppDelegate *appDelegate = (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
        SVSettingsViewController *settings = [storyboard instantiateViewControllerWithIdentifier:@"SVSettingsViewController"];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController pushViewController:settings animated:YES];
//    [appDelegate.window.rootViewController dismissViewControllerAnimated:YES completion:^{
//            [appDelegate.window.rootViewController presentViewController:settings animated:YES completion:nil];
//    }];
    
    
}
@end
