//
//  SVSettingsViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 4/10/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVSettingsViewController.h"

@interface SVSettingsViewController ()
- (IBAction)donePressed:(id)sender;

@end

@implementation SVSettingsViewController


#pragma mark - Actions

- (IBAction)donePressed:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

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
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end
