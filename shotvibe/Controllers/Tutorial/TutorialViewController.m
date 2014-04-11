//
//  TutorialViewController.m
//  shotvibe
//
//  Created by Salvatore Balzano on 18/03/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "TutorialViewController.h"
#import "TutorialChildViewController.h"
#import "PageControl.h"

@interface TutorialViewController ()

@property (nonatomic, weak) IBOutlet UILabel *topLabel;
@property (nonatomic, weak) IBOutlet UILabel *bottomLabel;
@property (nonatomic, weak) IBOutlet PageControl *pageControl;

- (IBAction)dismiss:(id)sender;
- (IBAction)closeWelcomeScreen:(id)sender;

@end

@implementation TutorialViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];

    self.pageController.dataSource = self;
    self.pageController.delegate = self;
    [[self.pageController view] setFrame:[[self view] bounds]];

    TutorialChildViewController *initialViewController = [self viewControllerAtIndex:0];

    NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];

    [self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];

    [self addChildViewController:self.pageController];
    [[self view] insertSubview:[self.pageController view] atIndex:0];
    [self.pageController didMoveToParentViewController:self];

    [[Mixpanel sharedInstance] track:@"Welcome Screen Intro Viewed"];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (TutorialChildViewController *)viewControllerAtIndex:(NSUInteger)index
{
    TutorialChildViewController *childViewController = [[TutorialChildViewController alloc] init];
    childViewController.index = index;

    return childViewController;
}


- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = [(TutorialChildViewController *)viewController index];

    if (index == 0) {
        return nil;
    }

    // Decrease the index by 1 to return
    index--;

    return [self viewControllerAtIndex:index];
}


- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = [(TutorialChildViewController *)viewController index];

    index++;

    if (index == 7) {
        return nil;
    }

    return [self viewControllerAtIndex:index];
}


- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    TutorialChildViewController *viewController = [pageViewController.viewControllers firstObject];
    NSUInteger index = [viewController index];

    [[Mixpanel sharedInstance] track:@"Welcome Screen Viewed Page"
                          properties:@{ @"welcome_screen_page" : [NSNumber numberWithUnsignedInteger:index + 1] }];

    NSArray *topTexts = @[@"Create albums with a single tap",
                          @"Collaborative Albums",
                          @"Invite your friends to join your album",
                          @"Upload photos and videos directly to your album",
                          @"Take photos to the album",
                          @"Stored in the cloud",
                          @"Cross platform service"];

    NSArray *bottomTexts = @[@"It's super fast to create a new album. Just tap a single button and it's ready to go.",
                             @"Invite your friends and family to add their own photos and videos to the album.",
                             @"Say goodbye to fussing with email addresses. Simply invite your friends and family using your phone's contact list.",
                             @"Easily add photos and videos from your camera roll, or even shoot directly to your album.",
                             @"Take photos and video directly to your album. You can also edit and add filters to your photos.",
                             @"All albums are stored securely in the cloud, freeing up storage on your device and making your photos and videos easily shareable.",
                             @"Glance works on iOS, Android, and over the web using our web app, making your shared albums accessible just about everywhere."];

    self.pageControl.currentPage = index;

    self.topLabel.text = topTexts[index];
    self.bottomLabel.text = bottomTexts[index];
    self.bottomLabel.adjustsFontSizeToFitWidth = YES;
}


- (IBAction)dismiss:(id)sender
{
    [[Mixpanel sharedInstance] track:@"Welcome Screen Dismissed"];

    if (self.onClose) {
        __block TutorialViewController *blocksafeSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            blocksafeSelf.onClose(nil);
        }


                       );
    }
}


- (IBAction)closeWelcomeScreen:(id)sender
{
    [[Mixpanel sharedInstance] track:@"Welcome Screen Viewed Page"
                          properties:@{ @"welcome_screen_page" : [NSNumber numberWithUnsignedInteger:1] }];

    [[sender superview] removeFromSuperview];
}


#pragma mark -
#pragma mark - UIViewController Rotation

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
