//
//  SVNonRotatingNavigationControllerViewController.m
//  shotvibe
//
//  Created by Salvatore Balzano on 07/02/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "SVNonRotatingNavigationControllerViewController.h"
#import "SVInitialization.h"

@interface SVNonRotatingNavigationControllerViewController ()

@end

@implementation SVNonRotatingNavigationControllerViewController

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
    if (self = [super initWithRootViewController:rootViewController]) {
        [self.navigationBar setBackgroundImage:[SVInitialization imageWithColor:[UIColor blackColor]]
                                forBarPosition:UIBarPositionAny
                                    barMetrics:UIBarMetricsDefault];
    }

    return self;
}


- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


- (BOOL)shouldAutorotate
{
    return NO;
}


- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}


@end
