//
//  AppDelegate.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/5/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <UIKit/UIKit.h>
#import "JMC.h"

@interface ShotVibeAppDelegate : UIResponder <JMCCustomDataSource, UIApplicationDelegate>

#pragma mark - Properties

@property (strong, nonatomic) UIWindow *window;


#pragma mark - Class Methods

+ (ShotVibeAppDelegate *)sharedDelegate;

@end
