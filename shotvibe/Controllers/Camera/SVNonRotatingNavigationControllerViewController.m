//
//  SVNonRotatingNavigationControllerViewController.m
//  shotvibe
//
//  Created by Salvatore Balzano on 07/02/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "SVNonRotatingNavigationControllerViewController.h"

@interface SVNonRotatingNavigationControllerViewController ()

@end

@implementation SVNonRotatingNavigationControllerViewController


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
