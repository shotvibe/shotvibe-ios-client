//
//  SVHelpViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 4/16/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVHelpViewController.h"
#import "SVDefines.h"

@interface SVHelpViewController ()
@property (nonatomic, strong) IBOutlet UITextView *helpTextView;
@end

@implementation SVHelpViewController

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
    
    if (!IS_IOS6_OR_GREATER) {
        self.helpTextView.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:12];
        self.helpTextView.textColor = [UIColor colorWithRed:0.46 green:0.50 blue:0.52 alpha:1.0];
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
