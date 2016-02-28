//
//  GLScoreViewController.h
//  shotvibe
//
//  Created by Tsah Kashkash on 15/11/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GLScoreViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *userScore;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
- (IBAction)backPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *settingsPressed;
- (IBAction)showSettings:(id)sender;

@end
