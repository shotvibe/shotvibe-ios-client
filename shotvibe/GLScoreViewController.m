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
#import "ShotVibeAppDelegate.h"
@interface GLScoreViewController ()

@end

@implementation GLScoreViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(defaultsChanged:)
                   name:NSUserDefaultsDidChangeNotification
                 object:nil];
    self.userScore.text = [[[[GLSharedCamera sharedInstance] userScore] userScoreLabel] text];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
}

- (void)defaultsChanged:(NSNotification *)notification {
    NSUserDefaults *defaults = (NSUserDefaults *)[notification object];
    self.userScore.text = [NSString stringWithFormat:@"%ld",(long)[defaults integerForKey:@"kUserScore"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (IBAction)backPressed:(id)sender {
    ShotVibeAppDelegate *appDelegate = (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    [[GLSharedCamera sharedInstance] showGlCameraView];
    [appDelegate.window.rootViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}
- (IBAction)showSettings:(id)sender {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    SVSettingsViewController *settings = [storyboard instantiateViewControllerWithIdentifier:@"SVSettingsViewController"];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController pushViewController:settings animated:YES];
    
}
@end
