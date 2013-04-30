//
//  CaptureNavigationController.m
//  shotvibe
//
//  Created by John Gabelmann on 4/22/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "CaptureNavigationController.h"

@interface CaptureNavigationController ()

@end

@implementation CaptureNavigationController

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


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if (self.allowsRotation) {
        return YES;
    }
    
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(NSUInteger)supportedInterfaceOrientations{
    
    if (self.allowsRotation) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
    
    return UIInterfaceOrientationMaskPortrait;
}


@end
