//
//  GLWelcomeViewController.m
//  shotvibe
//
//  Created by Tsah Kashkash on 05/11/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import "GLWelcomeViewController.h"
#import "SVRegistrationViewController.h"
//#import "GLSharedCamera.h"
#import "ShotVIbeAppDelegate.h"

@interface GLWelcomeViewController (){
    UIImageView *animationImageView;
}

@end

@implementation GLWelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [[[GLSharedCamera sharedInstance] cameraViewBackground] setHidden:YES];
//    self.signInButton.frame
    self.signInButton.hidden = YES;
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    
    CGRect frame = self.signInButton.frame;
    
    if([[ShotVibeAppDelegate sharedDelegate] platformTypeIsIphone5]){
        frame.origin.x = (self.view.frame.size.width/1.30/2)-((self.signInButton.frame.size.width/1.30)/2);
    } else if([[ShotVibeAppDelegate sharedDelegate] platformTypeIsIphone6plus]) {
        frame.origin.x = (self.view.frame.size.width/2)-(self.signInButton.frame.size.width/2)+20;
        frame.origin.y += 25;
    } else {
        frame.origin.x = (self.view.frame.size.width/1/2)-((self.signInButton.frame.size.width/1)/2);
    }
    
//    self.signInButton.frame = frame;
    btn.frame = frame;
    
    [btn setTitle:@"sign in" forState:UIControlStateNormal];
    [btn setTitleColor:UIColorFromRGB(0x626262) forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(signInTapped) forControlEvents:UIControlEventTouchUpInside];
    btn.titleLabel.font = self.signInButton.font;

    btn.layer.cornerRadius = 24;//half of the width
    btn.layer.borderColor= UIColorFromRGB(0x626262).CGColor;
    btn.layer.borderWidth=1.0f;
    
    [self.view addSubview:btn];
    
    
    NSArray *imageNames = @[@"seq1.png", @"seq2.png" ,@"seq3.png", @"seq4.png" ,@"seq5.png", @"seq6.png" ,@"seq7.png", @"seq8.png" ,@"seq9.png", @"seq10.png" ,@"seq11.png", @"seq12.png" ,@"seq13.png", @"seq14.png" ,@"seq15.png", @"seq16.png" ,@"seq17.png", @"seq18.png" ,@"seq19.png", @"seq20.png" ,@"seq21.png", @"seq22.png" ,@"seq23.png", @"seq24.png" ,@"seq25.png", @"seq26.png" ,@"seq27.png", @"seq28.png" ,@"seq29.png", @"seq30.png" ,@"seq31.png", @"seq32.png" ,@"seq33.png", @"seq34.png" ,@"seq35.png", @"seq36.png" ,@"seq37.png", @"seq38.png" ,@"seq39.png",@"seq39.png",@"seq39.png",@"seq39.png",@"seq39.png", @"seq40.png",@"seq40.png",@"seq40.png",@"seq40.png",@"seq40.png",@"seq40.png",@"seq40.png",@"seq40.png",@"seq40.png",@"seq40.png",@"seq40.png",@"seq40.png",@"seq40.png",@"seq40.png", @"seq39.png" ,@"seq39.png",@"seq39.png",@"seq39.png",@"seq39.png",@"seq39.png",@"seq39.png",@"seq39.png",@"seq38.png", @"seq37.png" ,@"seq36.png", @"seq35.png" ,@"seq34.png", @"seq33.png" ,@"seq32.png", @"seq31.png" ,@"seq30.png", @"seq29.png" ,@"seq28.png", @"seq27.png" ,@"seq26.png", @"seq25.png" ,@"seq24.png", @"seq23.png" ,@"seq22.png", @"seq21.png" ,@"seq20.png", @"seq19.png" ,@"seq18.png", @"seq17.png" ,@"seq16.png", @"seq15.png" ,@"seq14.png", @"seq13.png" ,@"seq12.png", @"seq11.png" ,@"seq10.png", @"seq9.png" ,@"seq8.png", @"seq7.png" ,@"seq6.png", @"seq5.png" ,@"seq4.png", @"seq3.png" ,@"seq2.png", @"seq1.png"];
    
    NSMutableArray *images = [[NSMutableArray alloc] init];
    for (int i = 0; i < imageNames.count; i++) {
        [images addObject:[UIImage imageNamed:[imageNames objectAtIndex:i]]];
    }
    CGRect r;
    if([[ShotVibeAppDelegate sharedDelegate] platformTypeIsIphone5]){
        r = CGRectMake(self.dmut.frame.origin.x/1.171, self.dmut.frame.origin.y/1.171, self.dmut.frame.size.width/1.171, self.dmut.frame.size.height/1.171);
    } else if([[ShotVibeAppDelegate sharedDelegate] platformTypeIsIphone6plus]){
        r = CGRectMake(self.dmut.frame.origin.x*1.103, self.dmut.frame.origin.y*1.103, self.dmut.frame.size.width*1.103, self.dmut.frame.size.height*1.103);
    } else {
        r = self.dmut.frame;
    }
    
    // Normal Animation
    animationImageView = [[UIImageView alloc] initWithFrame:r];
    animationImageView.animationImages = images;
    animationImageView.animationDuration = 3;
    //    animationImageView.animationRepeatCount = 1;
    
    [self.view addSubview:animationImageView];
    [animationImageView startAnimating];
    
    
    
    
    // Do any additional setup after loading the view from its nib.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
//    CGRect frame = self.signInButton.frame;
//    frame.origin.x = (self.view.frame.size.width/2)-(self.signInButton.frame.size.width/2);
//    self.signInButton.frame = frame;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
//    [KVNProgress showWithStatus:[NSString stringWithFormat:@"%f",self.view.frame.size.width]];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [animationImageView stopAnimating];
    animationImageView.animationImages = nil;
    animationImageView.image = nil;
    animationImageView = nil;
    
//    
    
    if (self.onClose) {
        __block GLWelcomeViewController *blocksafeSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            blocksafeSelf.onClose(nil);
        });
    }
}

- (void)dealloc {

    NSLog(@"Welcome Deallocated");

}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
}

-(void)signInTapped {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    SVRegistrationViewController * registratonVc = [[SVRegistrationViewController alloc] init];
    
    
    
//    [UIView  beginAnimations:nil context:NULL];
//    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
//    [UIView setAnimationDuration:0.75];
    [[[ShotVibeAppDelegate sharedDelegate] navigationController] pushViewController:registratonVc animated:NO];
//    [UIView setAnimationTransition:UIViewAnimationTransitio forView:self.navigationController.view cache:NO];
//    [UIView commitAnimations];
    
    
    
    
//    [UIView animateWithDuration:0.5 animations:^{
//        self.view.alpha = 0;
//    } completion:^(BOOL finished) {
//        
    
        
//        [[[ShotVibeAppDelegate sharedDelegate] window] setRootViewController:[[ShotVibeAppDelegate sharedDelegate] navigationController]];
//    }];

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

@end
