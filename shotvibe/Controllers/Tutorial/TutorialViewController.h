//
//  TutorialViewController.h
//  shotvibe
//
//  Created by Salvatore Balzano on 18/03/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^CompletionBlock)(id);

@interface TutorialViewController : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (readwrite, copy) CompletionBlock onClose;
@property (strong, nonatomic) UIPageViewController *pageController;

@end
