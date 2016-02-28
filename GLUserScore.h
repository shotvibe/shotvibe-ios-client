//
//  GLUserScore.h
//  shotvibe
//
//  Created by Tsah Kashkash on 17/12/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ShotVibeAppDelegate.h"
#import "GLScoreViewController.h"
//#import <PubNub/PubNub.h>

@interface GLUserScore : NSObject

@property (nonatomic, retain) UIView * view;
@property (nonatomic,retain) UIImageView * glanceLogo;
@property (nonatomic, retain) UILabel * userScoreLabel;
@property (nonatomic) BOOL isShown;

- (void)showUserScore;
- (void)hideUserScore;
- (instancetype)initWithView:(UIView*)view;
- (void)updateScoreFromPush:(int)score;

@end
