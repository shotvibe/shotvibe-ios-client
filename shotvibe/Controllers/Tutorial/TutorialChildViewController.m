//
//  TutorialChildViewController.m
//  shotvibe
//
//  Created by Salvatore Balzano on 18/03/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "TutorialChildViewController.h"

@interface TutorialChildViewController ()

- (IBAction)dismiss:(id)sender;

@end

@implementation TutorialChildViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dismiss:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kDismissTutorial" object:nil];
}

@end
