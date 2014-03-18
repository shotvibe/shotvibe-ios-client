//
//  TutorialViewController.h
//  shotvibe
//
//  Created by Salvatore Balzano on 18/03/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TutorialViewController : UIViewController <UIPageViewControllerDataSource>

@property (strong, nonatomic) UIPageViewController *pageController;

@end
